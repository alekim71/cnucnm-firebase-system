#!/usr/bin/env python3
"""
CNUCNM 알림 시스템
체중 측정 알림, 사료 재고 부족 알림, 건강 상태 이상 알림, 예약 알림
"""

import streamlit as st
import pandas as pd
import numpy as np
import sqlite3
from datetime import datetime, timedelta
import plotly.express as px
import plotly.graph_objects as go
from pathlib import Path
import json

# 페이지 설정
st.set_page_config(
    page_title="CNUCNM 알림 시스템",
    page_icon="🔔",
    layout="wide",
    initial_sidebar_state="expanded"
)

# 커스텀 CSS
st.markdown("""
<style>
    .main-header {
        background: linear-gradient(90deg, #ff6b6b, #4ecdc4);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        font-size: 2.5rem;
        font-weight: bold;
        text-align: center;
        margin-bottom: 2rem;
    }
    .alert-card {
        background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
        padding: 1rem;
        border-radius: 10px;
        color: white;
        margin: 0.5rem 0;
        border-left: 4px solid #c44569;
    }
    .warning-card {
        background: linear-gradient(135deg, #feca57 0%, #ff9ff3 100%);
        padding: 1rem;
        border-radius: 10px;
        color: white;
        margin: 0.5rem 0;
        border-left: 4px solid #f39c12;
    }
    .info-card {
        background: linear-gradient(135deg, #48dbfb 0%, #0abde3 100%);
        padding: 1rem;
        border-radius: 10px;
        color: white;
        margin: 0.5rem 0;
        border-left: 4px solid #54a0ff;
    }
    .success-card {
        background: linear-gradient(135deg, #1dd1a1 0%, #10ac84 100%);
        padding: 1rem;
        border-radius: 10px;
        color: white;
        margin: 0.5rem 0;
        border-left: 4px solid #00b894;
    }
    .notification-item {
        background: #f8f9fa;
        padding: 1rem;
        border-radius: 8px;
        margin: 0.5rem 0;
        border-left: 4px solid #007bff;
        transition: all 0.3s ease;
    }
    .notification-item:hover {
        transform: translateX(5px);
        box-shadow: 0 4px 8px rgba(0,0,0,0.1);
    }
</style>
""", unsafe_allow_html=True)

def init_database():
    """데이터베이스 초기화"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    cursor = conn.cursor()
    
    # 알림 설정 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS notification_settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER DEFAULT 1,
            alert_type TEXT NOT NULL,
            enabled BOOLEAN DEFAULT 1,
            threshold_value REAL,
            frequency TEXT DEFAULT 'daily',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 알림 기록 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS notification_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            alert_type TEXT NOT NULL,
            animal_id TEXT,
            message TEXT NOT NULL,
            severity TEXT DEFAULT 'info',
            is_read BOOLEAN DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 사료 재고 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS feed_inventory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            feed_name TEXT NOT NULL,
            current_stock REAL NOT NULL,
            min_stock_level REAL NOT NULL,
            unit TEXT DEFAULT 'kg',
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 건강 상태 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS health_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            animal_id TEXT NOT NULL,
            check_date DATE NOT NULL,
            temperature REAL,
            heart_rate INTEGER,
            respiratory_rate INTEGER,
            appetite_score INTEGER,
            activity_score INTEGER,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 샘플 데이터 생성
    if cursor.execute("SELECT COUNT(*) FROM notification_settings").fetchone()[0] == 0:
        sample_settings = [
            ('weight_measurement', 1, 7, 'weekly'),
            ('feed_inventory', 1, 100, 'daily'),
            ('health_check', 1, 30, 'daily'),
            ('vaccination', 1, 0, 'monthly'),
            ('breeding_cycle', 1, 0, 'weekly'),
        ]
        
        for setting in sample_settings:
            cursor.execute("""
                INSERT INTO notification_settings (alert_type, enabled, threshold_value, frequency)
                VALUES (?, ?, ?, ?)
            """, setting)
    
    if cursor.execute("SELECT COUNT(*) FROM feed_inventory").fetchone()[0] == 0:
        sample_inventory = [
            ('옥수수', 500, 200),
            ('대두박', 300, 100),
            ('밀기울', 800, 300),
            ('미강', 400, 150),
            ('조사료', 1000, 400),
            ('어분', 200, 50),
            ('비타민미네랄', 50, 20),
        ]
        
        for inventory in sample_inventory:
            cursor.execute("""
                INSERT INTO feed_inventory (feed_name, current_stock, min_stock_level)
                VALUES (?, ?, ?)
            """, inventory)
    
    if cursor.execute("SELECT COUNT(*) FROM health_records").fetchone()[0] == 0:
        sample_health = [
            ('ANM001', '2024-01-01', 38.5, 72, 20, 4, 4, '정상'),
            ('ANM001', '2024-01-15', 38.8, 75, 22, 3, 3, '약간 식욕부진'),
            ('ANM002', '2024-01-01', 38.2, 70, 18, 5, 5, '정상'),
            ('ANM002', '2024-01-15', 39.1, 80, 25, 2, 2, '체온 상승, 활동성 저하'),
            ('ANM003', '2024-01-01', 38.6, 73, 21, 4, 4, '정상'),
            ('ANM003', '2024-01-15', 38.4, 71, 19, 5, 5, '정상'),
        ]
        
        for health in sample_health:
            cursor.execute("""
                INSERT INTO health_records (animal_id, check_date, temperature, heart_rate, 
                                          respiratory_rate, appetite_score, activity_score, notes)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, health)
    
    conn.commit()
    conn.close()

def check_weight_measurement_alerts():
    """체중 측정 알림 확인"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    
    # 최근 체중 측정 기록 확인
    weight_records = pd.read_sql_query("""
        SELECT animal_id, MAX(measurement_date) as last_measurement
        FROM growth_records 
        GROUP BY animal_id
    """, conn)
    
    # 동물 목록 조회
    animals_df = pd.read_sql_query("SELECT animal_id FROM animals WHERE status = 'active'", conn)
    conn.close()
    
    alerts = []
    today = datetime.now().date()
    
    for _, animal in animals_df.iterrows():
        animal_id = animal['animal_id']
        
        # 해당 동물의 최근 측정 기록 확인
        animal_record = weight_records[weight_records['animal_id'] == animal_id]
        
        if animal_record.empty:
            # 측정 기록이 없는 경우
            alerts.append({
                'type': 'weight_measurement',
                'animal_id': animal_id,
                'message': f'{animal_id}: 체중 측정 기록이 없습니다. 측정을 권장합니다.',
                'severity': 'warning',
                'days_overdue': None
            })
        else:
            last_measurement = pd.to_datetime(animal_record.iloc[0]['last_measurement']).date()
            days_overdue = (today - last_measurement).days
            
            if days_overdue > 7:
                alerts.append({
                    'type': 'weight_measurement',
                    'animal_id': animal_id,
                    'message': f'{animal_id}: 체중 측정이 {days_overdue}일 지연되었습니다.',
                    'severity': 'alert',
                    'days_overdue': days_overdue
                })
    
    return alerts

def check_feed_inventory_alerts():
    """사료 재고 알림 확인"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    
    inventory_df = pd.read_sql_query("""
        SELECT feed_name, current_stock, min_stock_level, unit
        FROM feed_inventory
    """, conn)
    conn.close()
    
    alerts = []
    
    for _, row in inventory_df.iterrows():
        if row['current_stock'] <= row['min_stock_level']:
            alerts.append({
                'type': 'feed_inventory',
                'feed_name': row['feed_name'],
                'message': f'{row["feed_name"]}: 재고 부족! 현재 {row["current_stock"]}{row["unit"]}, 최소 {row["min_stock_level"]}{row["unit"]} 필요',
                'severity': 'alert',
                'current_stock': row['current_stock'],
                'min_stock': row['min_stock_level']
            })
        elif row['current_stock'] <= row['min_stock_level'] * 1.5:
            alerts.append({
                'type': 'feed_inventory',
                'feed_name': row['feed_name'],
                'message': f'{row["feed_name"]}: 재고 주의! 현재 {row["current_stock"]}{row["unit"]}',
                'severity': 'warning',
                'current_stock': row['current_stock'],
                'min_stock': row['min_stock_level']
            })
    
    return alerts

def check_health_alerts():
    """건강 상태 알림 확인"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    
    # 최근 건강 기록 조회
    health_df = pd.read_sql_query("""
        SELECT animal_id, check_date, temperature, heart_rate, respiratory_rate, 
               appetite_score, activity_score, notes
        FROM health_records 
        WHERE check_date >= date('now', '-7 days')
        ORDER BY check_date DESC
    """, conn)
    conn.close()
    
    alerts = []
    
    for _, record in health_df.iterrows():
        animal_id = record['animal_id']
        alerts_for_animal = []
        
        # 체온 체크 (정상: 38.0-39.0°C)
        if record['temperature'] > 39.0:
            alerts_for_animal.append(f'체온 상승: {record["temperature"]}°C')
        elif record['temperature'] < 38.0:
            alerts_for_animal.append(f'체온 저하: {record["temperature"]}°C')
        
        # 심박수 체크 (정상: 60-80회/분)
        if record['heart_rate'] > 80:
            alerts_for_animal.append(f'심박수 증가: {record["heart_rate"]}회/분')
        elif record['heart_rate'] < 60:
            alerts_for_animal.append(f'심박수 감소: {record["heart_rate"]}회/분')
        
        # 식욕 점수 체크 (1-5점, 3점 이하 주의)
        if record['appetite_score'] <= 3:
            alerts_for_animal.append(f'식욕 저하: {record["appetite_score"]}점')
        
        # 활동성 점수 체크 (1-5점, 3점 이하 주의)
        if record['activity_score'] <= 3:
            alerts_for_animal.append(f'활동성 저하: {record["activity_score"]}점')
        
        if alerts_for_animal:
            alerts.append({
                'type': 'health_check',
                'animal_id': animal_id,
                'message': f'{animal_id}: {" | ".join(alerts_for_animal)}',
                'severity': 'alert',
                'check_date': record['check_date']
            })
    
    return alerts

def save_notification_log(alert_type, animal_id, message, severity):
    """알림 로그 저장"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    cursor = conn.cursor()
    
    cursor.execute("""
        INSERT INTO notification_logs (alert_type, animal_id, message, severity)
        VALUES (?, ?, ?, ?)
    """, (alert_type, animal_id, message, severity))
    
    conn.commit()
    conn.close()

def get_notification_settings():
    """알림 설정 조회"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    settings_df = pd.read_sql_query("SELECT * FROM notification_settings", conn)
    conn.close()
    return settings_df

def update_notification_settings(alert_type, enabled, threshold_value, frequency):
    """알림 설정 업데이트"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    cursor = conn.cursor()
    
    cursor.execute("""
        UPDATE notification_settings 
        SET enabled = ?, threshold_value = ?, frequency = ?
        WHERE alert_type = ?
    """, (enabled, threshold_value, frequency, alert_type))
    
    conn.commit()
    conn.close()

def get_notification_history(limit=50):
    """알림 히스토리 조회"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    history_df = pd.read_sql_query("""
        SELECT * FROM notification_logs 
        ORDER BY created_at DESC 
        LIMIT ?
    """, conn, params=[limit])
    conn.close()
    return history_df

def main():
    st.markdown('<h1 class="main-header">🔔 CNUCNM 알림 시스템</h1>', unsafe_allow_html=True)
    
    # 데이터베이스 초기화
    init_database()
    
    # 탭 생성
    tab1, tab2, tab3, tab4 = st.tabs(["🚨 실시간 알림", "⚙️ 알림 설정", "📊 알림 통계", "📋 알림 히스토리"])
    
    with tab1:
        st.header("🚨 실시간 알림")
        
        # 알림 확인 버튼
        if st.button("🔄 알림 새로고침", type="primary"):
            st.rerun()
        
        # 각종 알림 확인
        weight_alerts = check_weight_measurement_alerts()
        feed_alerts = check_feed_inventory_alerts()
        health_alerts = check_health_alerts()
        
        all_alerts = weight_alerts + feed_alerts + health_alerts
        
        # 알림을 심각도별로 정렬
        severity_order = {'alert': 0, 'warning': 1, 'info': 2}
        all_alerts.sort(key=lambda x: severity_order.get(x['severity'], 3))
        
        # 알림 표시
        if not all_alerts:
            st.markdown("""
            <div class="success-card">
                <h3>✅ 모든 시스템 정상</h3>
                <p>현재 주의가 필요한 알림이 없습니다.</p>
            </div>
            """, unsafe_allow_html=True)
        else:
            st.subheader(f"📢 총 {len(all_alerts)}개의 알림이 있습니다")
            
            for alert in all_alerts:
                if alert['severity'] == 'alert':
                    st.markdown(f"""
                    <div class="alert-card">
                        <h4>🚨 {alert['type'].replace('_', ' ').title()}</h4>
                        <p>{alert['message']}</p>
                        <small>생성: {datetime.now().strftime('%Y-%m-%d %H:%M')}</small>
                    </div>
                    """, unsafe_allow_html=True)
                elif alert['severity'] == 'warning':
                    st.markdown(f"""
                    <div class="warning-card">
                        <h4>⚠️ {alert['type'].replace('_', ' ').title()}</h4>
                        <p>{alert['message']}</p>
                        <small>생성: {datetime.now().strftime('%Y-%m-%d %H:%M')}</small>
                    </div>
                    """, unsafe_allow_html=True)
                else:
                    st.markdown(f"""
                    <div class="info-card">
                        <h4>ℹ️ {alert['type'].replace('_', ' ').title()}</h4>
                        <p>{alert['message']}</p>
                        <small>생성: {datetime.now().strftime('%Y-%m-%d %H:%M')}</small>
                    </div>
                    """, unsafe_allow_html=True)
                
                # 알림 로그에 저장
                save_notification_log(
                    alert['type'], 
                    alert.get('animal_id', alert.get('feed_name', 'system')), 
                    alert['message'], 
                    alert['severity']
                )
    
    with tab2:
        st.header("⚙️ 알림 설정")
        
        settings_df = get_notification_settings()
        
        st.subheader("알림 유형별 설정")
        
        for _, setting in settings_df.iterrows():
            with st.expander(f"🔔 {setting['alert_type'].replace('_', ' ').title()}"):
                col1, col2, col3, col4 = st.columns(4)
                
                with col1:
                    enabled = st.checkbox("활성화", value=bool(setting['enabled']), key=f"enabled_{setting['id']}")
                
                with col2:
                    threshold = st.number_input(
                        "임계값", 
                        value=float(setting['threshold_value']), 
                        key=f"threshold_{setting['id']}"
                    )
                
                with col3:
                    frequency = st.selectbox(
                        "빈도",
                        ["daily", "weekly", "monthly"],
                        index=["daily", "weekly", "monthly"].index(setting['frequency']),
                        key=f"frequency_{setting['id']}"
                    )
                
                with col4:
                    if st.button("저장", key=f"save_{setting['id']}"):
                        update_notification_settings(
                            setting['alert_type'], 
                            enabled, 
                            threshold, 
                            frequency
                        )
                        st.success("설정이 저장되었습니다!")
    
    with tab3:
        st.header("📊 알림 통계")
        
        # 알림 히스토리 조회
        history_df = get_notification_history(1000)
        
        if not history_df.empty:
            # 알림 유형별 통계
            col1, col2 = st.columns(2)
            
            with col1:
                st.subheader("알림 유형별 분포")
                alert_type_counts = history_df['alert_type'].value_counts()
                fig1 = px.pie(values=alert_type_counts.values, names=alert_type_counts.index, title="알림 유형별 분포")
                st.plotly_chart(fig1, use_container_width=True)
            
            with col2:
                st.subheader("심각도별 분포")
                severity_counts = history_df['severity'].value_counts()
                fig2 = px.bar(x=severity_counts.index, y=severity_counts.values, title="심각도별 알림 수")
                st.plotly_chart(fig2, use_container_width=True)
            
            # 시간별 알림 추이
            st.subheader("시간별 알림 추이")
            history_df['created_at'] = pd.to_datetime(history_df['created_at'])
            history_df['date'] = history_df['created_at'].dt.date
            
            daily_alerts = history_df.groupby('date').size().reset_index(name='count')
            fig3 = px.line(daily_alerts, x='date', y='count', title="일별 알림 발생 추이")
            st.plotly_chart(fig3, use_container_width=True)
        else:
            st.info("아직 알림 기록이 없습니다.")
    
    with tab4:
        st.header("📋 알림 히스토리")
        
        history_df = get_notification_history(100)
        
        if not history_df.empty:
            # 필터링 옵션
            col1, col2, col3 = st.columns(3)
            
            with col1:
                alert_types = ['전체'] + history_df['alert_type'].unique().tolist()
                selected_type = st.selectbox("알림 유형", alert_types)
            
            with col2:
                severities = ['전체'] + history_df['severity'].unique().tolist()
                selected_severity = st.selectbox("심각도", severities)
            
            with col3:
                read_status = st.selectbox("읽음 상태", ['전체', '읽음', '읽지 않음'])
            
            # 필터링 적용
            filtered_df = history_df.copy()
            
            if selected_type != '전체':
                filtered_df = filtered_df[filtered_df['alert_type'] == selected_type]
            
            if selected_severity != '전체':
                filtered_df = filtered_df[filtered_df['severity'] == selected_severity]
            
            if read_status == '읽음':
                filtered_df = filtered_df[filtered_df['is_read'] == 1]
            elif read_status == '읽지 않음':
                filtered_df = filtered_df[filtered_df['is_read'] == 0]
            
            # 결과 표시
            st.subheader(f"총 {len(filtered_df)}개의 알림")
            
            for _, alert in filtered_df.iterrows():
                severity_color = {
                    'alert': '#ff6b6b',
                    'warning': '#feca57',
                    'info': '#48dbfb'
                }.get(alert['severity'], '#007bff')
                
                st.markdown(f"""
                <div class="notification-item" style="border-left-color: {severity_color}">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <strong>{alert['alert_type'].replace('_', ' ').title()}</strong>
                            <span style="color: {severity_color}; font-weight: bold;"> [{alert['severity'].upper()}]</span>
                        </div>
                        <small>{alert['created_at']}</small>
                    </div>
                    <p style="margin: 0.5rem 0;">{alert['message']}</p>
                    <small>동물/항목: {alert['animal_id'] if alert['animal_id'] else '시스템'}</small>
                </div>
                """, unsafe_allow_html=True)
        else:
            st.info("알림 히스토리가 없습니다.")

if __name__ == "__main__":
    main()
