#!/usr/bin/env python3
"""
CNUCNM 보고서 및 분석 시스템
월간/연간 성과 보고서, 비용 분석, ROI 계산, 동물별 성장 추이 분석
"""

import streamlit as st
import pandas as pd
import numpy as np
import sqlite3
from datetime import datetime, timedelta
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import calendar
from pathlib import Path

# 페이지 설정
st.set_page_config(
    page_title="CNUCNM 보고서 및 분석",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# 커스텀 CSS
st.markdown("""
<style>
    .main-header {
        background: linear-gradient(90deg, #1f77b4, #ff7f0e);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        font-size: 2.5rem;
        font-weight: bold;
        text-align: center;
        margin-bottom: 2rem;
    }
    .metric-card {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        padding: 1rem;
        border-radius: 10px;
        color: white;
        text-align: center;
        margin: 0.5rem 0;
    }
    .metric-value {
        font-size: 2rem;
        font-weight: bold;
    }
    .metric-label {
        font-size: 0.9rem;
        opacity: 0.9;
    }
    .report-section {
        background: #f8f9fa;
        padding: 1.5rem;
        border-radius: 10px;
        margin: 1rem 0;
        border-left: 4px solid #1f77b4;
    }
</style>
""", unsafe_allow_html=True)

def init_database():
    """데이터베이스 초기화"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    cursor = conn.cursor()
    
    # 동물 성장 기록 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS growth_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            animal_id TEXT NOT NULL,
            measurement_date DATE NOT NULL,
            weight REAL NOT NULL,
            daily_gain REAL,
            feed_intake REAL,
            feed_cost REAL,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 비용 기록 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS cost_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_date DATE NOT NULL,
            category TEXT NOT NULL,
            description TEXT,
            amount REAL NOT NULL,
            animal_id TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 수익 기록 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS revenue_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_date DATE NOT NULL,
            category TEXT NOT NULL,
            description TEXT,
            amount REAL NOT NULL,
            animal_id TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 샘플 데이터 생성
    if cursor.execute("SELECT COUNT(*) FROM growth_records").fetchone()[0] == 0:
        # 성장 기록 샘플 데이터
        sample_growth = [
            ('ANM001', '2024-01-01', 300, 0.8, 8.5, 2125),
            ('ANM001', '2024-01-15', 312, 0.9, 9.0, 2250),
            ('ANM001', '2024-02-01', 327, 1.0, 9.5, 2375),
            ('ANM002', '2024-01-01', 280, 0.7, 7.5, 1875),
            ('ANM002', '2024-01-15', 290, 0.8, 8.0, 2000),
            ('ANM002', '2024-02-01', 304, 0.9, 8.5, 2125),
            ('ANM003', '2024-01-01', 350, 1.1, 10.0, 2500),
            ('ANM003', '2024-01-15', 366, 1.2, 10.5, 2625),
            ('ANM003', '2024-02-01', 384, 1.3, 11.0, 2750),
        ]
        
        for record in sample_growth:
            cursor.execute("""
                INSERT INTO growth_records (animal_id, measurement_date, weight, daily_gain, feed_intake, feed_cost)
                VALUES (?, ?, ?, ?, ?, ?)
            """, record)
    
    if cursor.execute("SELECT COUNT(*) FROM cost_records").fetchone()[0] == 0:
        # 비용 기록 샘플 데이터
        sample_costs = [
            ('2024-01-01', '사료비', '1월 사료 구매', 50000, 'ANM001'),
            ('2024-01-15', '사료비', '1월 중순 사료 구매', 45000, 'ANM001'),
            ('2024-01-01', '의료비', '예방접종', 15000, 'ANM001'),
            ('2024-01-01', '사료비', '1월 사료 구매', 40000, 'ANM002'),
            ('2024-01-15', '사료비', '1월 중순 사료 구매', 38000, 'ANM002'),
            ('2024-01-01', '의료비', '예방접종', 15000, 'ANM002'),
            ('2024-01-01', '사료비', '1월 사료 구매', 60000, 'ANM003'),
            ('2024-01-15', '사료비', '1월 중순 사료 구매', 55000, 'ANM003'),
            ('2024-01-01', '의료비', '예방접종', 15000, 'ANM003'),
        ]
        
        for record in sample_costs:
            cursor.execute("""
                INSERT INTO cost_records (record_date, category, description, amount, animal_id)
                VALUES (?, ?, ?, ?, ?)
            """, record)
    
    if cursor.execute("SELECT COUNT(*) FROM revenue_records").fetchone()[0] == 0:
        # 수익 기록 샘플 데이터 (도축 판매 시뮬레이션)
        sample_revenue = [
            ('2024-06-01', '도축판매', 'ANM001 도축 판매', 2400000, 'ANM001'),
            ('2024-07-01', '도축판매', 'ANM002 도축 판매', 2200000, 'ANM002'),
            ('2024-08-01', '도축판매', 'ANM003 도축 판매', 2800000, 'ANM003'),
        ]
        
        for record in sample_revenue:
            cursor.execute("""
                INSERT INTO revenue_records (record_date, category, description, amount, animal_id)
                VALUES (?, ?, ?, ?, ?)
            """, record)
    
    conn.commit()
    conn.close()

def calculate_monthly_performance(year, month):
    """월간 성과 계산"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    
    # 월간 비용
    costs_df = pd.read_sql_query("""
        SELECT category, SUM(amount) as total_amount
        FROM cost_records 
        WHERE strftime('%Y-%m', record_date) = ?
        GROUP BY category
    """, conn, params=[f"{year:04d}-{month:02d}"])
    
    # 월간 수익
    revenue_df = pd.read_sql_query("""
        SELECT category, SUM(amount) as total_amount
        FROM revenue_records 
        WHERE strftime('%Y-%m', record_date) = ?
        GROUP BY category
    """, conn, params=[f"{year:04d}-{month:02d}"])
    
    # 월간 성장 데이터
    growth_df = pd.read_sql_query("""
        SELECT animal_id, 
               AVG(daily_gain) as avg_daily_gain,
               SUM(feed_cost) as total_feed_cost,
               COUNT(*) as measurement_count
        FROM growth_records 
        WHERE strftime('%Y-%m', measurement_date) = ?
        GROUP BY animal_id
    """, conn, params=[f"{year:04d}-{month:02d}"])
    
    conn.close()
    
    total_cost = costs_df['total_amount'].sum() if not costs_df.empty else 0
    total_revenue = revenue_df['total_amount'].sum() if not revenue_df.empty else 0
    net_profit = total_revenue - total_cost
    roi = (net_profit / total_cost * 100) if total_cost > 0 else 0
    
    avg_daily_gain = growth_df['avg_daily_gain'].mean() if not growth_df.empty else 0
    total_feed_cost = growth_df['total_feed_cost'].sum() if not growth_df.empty else 0
    
    return {
        'total_cost': total_cost,
        'total_revenue': total_revenue,
        'net_profit': net_profit,
        'roi': roi,
        'avg_daily_gain': avg_daily_gain,
        'total_feed_cost': total_feed_cost,
        'costs_by_category': costs_df,
        'revenue_by_category': revenue_df,
        'growth_data': growth_df
    }

def create_growth_trend_chart(animal_id, months=6):
    """동물별 성장 추이 차트 생성"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    
    # 최근 N개월 데이터 조회
    end_date = datetime.now()
    start_date = end_date - timedelta(days=months*30)
    
    growth_df = pd.read_sql_query("""
        SELECT measurement_date, weight, daily_gain, feed_intake, feed_cost
        FROM growth_records 
        WHERE animal_id = ? AND measurement_date >= ?
        ORDER BY measurement_date
    """, conn, params=[animal_id, start_date.strftime('%Y-%m-%d')])
    
    conn.close()
    
    if growth_df.empty:
        return None
    
    # 성장 추이 차트
    fig = make_subplots(
        rows=2, cols=2,
        subplot_titles=('체중 변화', '일일 증체량', '사료 섭취량', '사료 비용'),
        specs=[[{"secondary_y": False}, {"secondary_y": False}],
               [{"secondary_y": False}, {"secondary_y": False}]]
    )
    
    # 체중 변화
    fig.add_trace(
        go.Scatter(x=growth_df['measurement_date'], y=growth_df['weight'],
                  mode='lines+markers', name='체중', line=dict(color='blue')),
        row=1, col=1
    )
    
    # 일일 증체량
    fig.add_trace(
        go.Bar(x=growth_df['measurement_date'], y=growth_df['daily_gain'],
               name='일일 증체량', marker_color='green'),
        row=1, col=2
    )
    
    # 사료 섭취량
    fig.add_trace(
        go.Scatter(x=growth_df['measurement_date'], y=growth_df['feed_intake'],
                  mode='lines+markers', name='사료 섭취량', line=dict(color='orange')),
        row=2, col=1
    )
    
    # 사료 비용
    fig.add_trace(
        go.Scatter(x=growth_df['measurement_date'], y=growth_df['feed_cost'],
                  mode='lines+markers', name='사료 비용', line=dict(color='red')),
        row=2, col=2
    )
    
    fig.update_layout(height=600, title_text=f"{animal_id} 성장 추이 분석")
    return fig

def create_roi_analysis_chart():
    """ROI 분석 차트 생성"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    
    # 월별 ROI 데이터
    roi_data = []
    for year in [2024]:
        for month in range(1, 13):
            performance = calculate_monthly_performance(year, month)
            roi_data.append({
                'month': f"{year}-{month:02d}",
                'roi': performance['roi'],
                'net_profit': performance['net_profit'],
                'total_cost': performance['total_cost']
            })
    
    conn.close()
    
    roi_df = pd.DataFrame(roi_data)
    
    # ROI 추이 차트
    fig = make_subplots(
        rows=2, cols=1,
        subplot_titles=('월별 ROI 추이', '월별 수익/비용'),
        specs=[[{"secondary_y": False}],
               [{"secondary_y": False}]]
    )
    
    # ROI 추이
    fig.add_trace(
        go.Scatter(x=roi_df['month'], y=roi_df['roi'],
                  mode='lines+markers', name='ROI (%)', line=dict(color='purple')),
        row=1, col=1
    )
    
    # 수익/비용
    fig.add_trace(
        go.Bar(x=roi_df['month'], y=roi_df['net_profit'],
               name='순이익', marker_color='green'),
        row=2, col=1
    )
    
    fig.add_trace(
        go.Bar(x=roi_df['month'], y=roi_df['total_cost'],
               name='총비용', marker_color='red'),
        row=2, col=1
    )
    
    fig.update_layout(height=600, title_text="ROI 분석")
    return fig

def main():
    st.markdown('<h1 class="main-header">📊 CNUCNM 보고서 및 분석 시스템</h1>', unsafe_allow_html=True)
    
    # 데이터베이스 초기화
    init_database()
    
    # 사이드바 - 보고서 설정
    st.sidebar.header("📋 보고서 설정")
    
    report_type = st.sidebar.selectbox(
        "보고서 유형",
        ["월간 성과 보고서", "연간 종합 보고서", "동물별 성장 분석", "ROI 분석", "비용 분석"]
    )
    
    if report_type in ["월간 성과 보고서", "연간 종합 보고서"]:
        year = st.sidebar.selectbox("연도", [2024, 2023, 2022], index=0)
        month = st.sidebar.selectbox("월", range(1, 13), index=0)
    
    # 탭 생성
    tab1, tab2, tab3, tab4 = st.tabs(["📈 성과 지표", "📊 상세 분석", "📋 보고서 생성", "🔍 데이터 탐색"])
    
    with tab1:
        st.header("📈 성과 지표")
        
        if report_type == "월간 성과 보고서":
            performance = calculate_monthly_performance(year, month)
            
            # 주요 지표 카드
            col1, col2, col3, col4 = st.columns(4)
            
            with col1:
                st.markdown(f"""
                <div class="metric-card">
                    <div class="metric-value">{performance['net_profit']:,.0f}원</div>
                    <div class="metric-label">순이익</div>
                </div>
                """, unsafe_allow_html=True)
            
            with col2:
                st.markdown(f"""
                <div class="metric-card">
                    <div class="metric-value">{performance['roi']:.1f}%</div>
                    <div class="metric-label">ROI</div>
                </div>
                """, unsafe_allow_html=True)
            
            with col3:
                st.markdown(f"""
                <div class="metric-card">
                    <div class="metric-value">{performance['avg_daily_gain']:.2f}kg</div>
                    <div class="metric-label">평균 일일 증체량</div>
                </div>
                """, unsafe_allow_html=True)
            
            with col4:
                st.markdown(f"""
                <div class="metric-card">
                    <div class="metric-value">{performance['total_feed_cost']:,.0f}원</div>
                    <div class="metric-label">총 사료비</div>
                </div>
                """, unsafe_allow_html=True)
    
    with tab2:
        st.header("📊 상세 분석")
        
        if report_type == "동물별 성장 분석":
            # 동물 선택
            conn = sqlite3.connect('cnucnm_data/cnucnm.db')
            animals_df = pd.read_sql_query("SELECT DISTINCT animal_id FROM growth_records", conn)
            conn.close()
            
            selected_animal = st.selectbox("동물 선택", animals_df['animal_id'].tolist())
            
            if selected_animal:
                growth_chart = create_growth_trend_chart(selected_animal)
                if growth_chart:
                    st.plotly_chart(growth_chart, use_container_width=True)
                else:
                    st.info("해당 동물의 성장 데이터가 없습니다.")
        
        elif report_type == "ROI 분석":
            roi_chart = create_roi_analysis_chart()
            st.plotly_chart(roi_chart, use_container_width=True)
    
    with tab3:
        st.header("📋 보고서 생성")
        
        if report_type == "월간 성과 보고서":
            performance = calculate_monthly_performance(year, month)
            
            st.markdown(f"""
            <div class="report-section">
                <h3>📅 {year}년 {month}월 성과 보고서</h3>
                <p><strong>생성일:</strong> {datetime.now().strftime('%Y년 %m월 %d일')}</p>
            </div>
            """, unsafe_allow_html=True)
            
            # 비용 분석
            st.subheader("💰 비용 분석")
            if not performance['costs_by_category'].empty:
                cost_fig = px.pie(performance['costs_by_category'], 
                                values='total_amount', names='category',
                                title="비용 구성")
                st.plotly_chart(cost_fig, use_container_width=True)
            
            # 수익 분석
            st.subheader("💵 수익 분석")
            if not performance['revenue_by_category'].empty:
                revenue_fig = px.pie(performance['revenue_by_category'], 
                                   values='total_amount', names='category',
                                   title="수익 구성")
                st.plotly_chart(revenue_fig, use_container_width=True)
            
            # 성장 분석
            st.subheader("📈 성장 분석")
            if not performance['growth_data'].empty:
                st.dataframe(performance['growth_data'])
    
    with tab4:
        st.header("🔍 데이터 탐색")
        
        # 데이터베이스 연결
        conn = sqlite3.connect('cnucnm_data/cnucnm.db')
        
        # 성장 기록 조회
        st.subheader("성장 기록")
        growth_df = pd.read_sql_query("""
            SELECT * FROM growth_records 
            ORDER BY measurement_date DESC 
            LIMIT 20
        """, conn)
        st.dataframe(growth_df)
        
        # 비용 기록 조회
        st.subheader("비용 기록")
        cost_df = pd.read_sql_query("""
            SELECT * FROM cost_records 
            ORDER BY record_date DESC 
            LIMIT 20
        """, conn)
        st.dataframe(cost_df)
        
        # 수익 기록 조회
        st.subheader("수익 기록")
        revenue_df = pd.read_sql_query("""
            SELECT * FROM revenue_records 
            ORDER BY record_date DESC 
            LIMIT 20
        """, conn)
        st.dataframe(revenue_df)
        
        conn.close()

if __name__ == "__main__":
    main()
