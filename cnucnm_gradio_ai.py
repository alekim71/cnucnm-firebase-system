#!/usr/bin/env python3
"""
CNUCNM Gradio AI 모델 인터페이스
사료 배합 최적화, 영양 분석, 생산성 예측 AI 모델들
"""

import gradio as gr
import pandas as pd
import numpy as np
import sqlite3
from datetime import datetime
import plotly.express as px
import plotly.graph_objects as go
from pathlib import Path
import hashlib
import pulp
from scipy.optimize import minimize

# 데이터베이스 초기화
def init_database():
    """데이터베이스 초기화"""
    db_path = Path("cnucnm_data/cnucnm.db")
    db_path.parent.mkdir(exist_ok=True)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # 사료 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS feeds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            feed_name TEXT NOT NULL,
            feed_type TEXT,
            protein REAL,
            fat REAL,
            fiber REAL,
            ash REAL,
            calcium REAL,
            phosphorus REAL,
            price_per_kg REAL,
            supplier TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 동물 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS animals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            animal_id TEXT UNIQUE NOT NULL,
            species TEXT NOT NULL,
            breed TEXT,
            gender TEXT,
            birth_date DATE,
            initial_weight REAL,
            current_weight REAL,
            status TEXT DEFAULT 'active',
            owner_id INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 샘플 사료 데이터 생성
    if cursor.execute("SELECT COUNT(*) FROM feeds").fetchone()[0] == 0:
        sample_feeds = [
            ('옥수수', '곡류', 8.5, 3.8, 2.2, 1.5, 0.02, 0.25, 250, '농협'),
            ('대두박', '단백질원', 44.0, 1.8, 7.0, 6.5, 0.25, 0.65, 800, '농협'),
            ('밀기울', '부산물', 15.0, 4.0, 12.0, 5.0, 0.15, 1.20, 300, '농협'),
            ('미강', '부산물', 12.0, 15.0, 8.0, 8.0, 0.08, 1.60, 400, '농협'),
            ('조사료', '조사료', 8.0, 2.0, 25.0, 8.0, 0.40, 0.20, 150, '농협'),
            ('어분', '단백질원', 60.0, 8.0, 1.0, 15.0, 4.0, 2.5, 1200, '수산협회'),
            ('비타민미네랄', '첨가제', 0.0, 0.0, 0.0, 0.0, 20.0, 15.0, 5000, '제약회사')
        ]
        
        for feed in sample_feeds:
            cursor.execute("""
                INSERT INTO feeds (feed_name, feed_type, protein, fat, fiber, ash, 
                                 calcium, phosphorus, price_per_kg, supplier)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, feed)
    
    # 샘플 동물 데이터
    if cursor.execute("SELECT COUNT(*) FROM animals").fetchone()[0] == 0:
        sample_animals = [
            ('ANM001', '한우', '한우', '수', '2022-01-15', 300, 450, 'active', 1),
            ('ANM002', '한우', '한우', '암', '2021-06-20', 280, 420, 'active', 1),
            ('ANM003', '홀스타인', '홀스타인', '암', '2020-12-05', 350, 550, 'active', 1)
        ]
        
        for animal in sample_animals:
            cursor.execute("""
                INSERT INTO animals (animal_id, species, breed, gender, birth_date,
                                   initial_weight, current_weight, status, owner_id)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, animal)
    
    conn.commit()
    conn.close()
    return db_path

# AI 모델 1: 사료 배합 최적화 (선형계획법)
def optimize_feed_formulation(animal_weight, target_protein, target_fat, max_cost, min_fiber=8.0):
    """사료 배합 최적화 AI 모델 (선형계획법)"""
    
    # 사료 데이터 로드
    conn = sqlite3.connect("cnucnm_data/cnucnm.db")
    feeds_df = pd.read_sql_query("SELECT * FROM feeds", conn)
    conn.close()
    
    n_feeds = len(feeds_df)
    
    # 선형계획법 문제 생성
    prob = pulp.LpProblem("Feed_Formulation", pulp.LpMinimize)
    
    # 결정변수: 각 사료의 배합 비율
    feed_vars = [pulp.LpVariable(f"feed_{i}", 0, 1) for i in range(n_feeds)]
    
    # 목적함수: 비용 최소화
    costs = feeds_df['price_per_kg'].values
    prob += pulp.lpSum([feed_vars[i] * costs[i] for i in range(n_feeds)])
    
    # 제약조건 1: 배합 비율 합 = 1 (100%)
    prob += pulp.lpSum([feed_vars[i] for i in range(n_feeds)]) == 1
    
    # 제약조건 2: 단백질 목표
    proteins = feeds_df['protein'].values
    prob += pulp.lpSum([feed_vars[i] * proteins[i] for i in range(n_feeds)]) >= target_protein
    
    # 제약조건 3: 지방 목표
    fats = feeds_df['fat'].values
    prob += pulp.lpSum([feed_vars[i] * fats[i] for i in range(n_feeds)]) >= target_fat
    
    # 제약조건 4: 섬유질 최소
    fibers = feeds_df['fiber'].values
    prob += pulp.lpSum([feed_vars[i] * fibers[i] for i in range(n_feeds)]) >= min_fiber
    
    # 제약조건 5: 비용 제한
    prob += pulp.lpSum([feed_vars[i] * costs[i] for i in range(n_feeds)]) <= max_cost
    
    # 문제 해결
    prob.solve()
    
    if prob.status == pulp.LpStatusOptimal:
        # 결과 추출
        ratios = [feed_vars[i].value() for i in range(n_feeds)]
        
        # 결과 계산
        total_protein = sum(ratios[i] * proteins[i] for i in range(n_feeds))
        total_fat = sum(ratios[i] * fats[i] for i in range(n_feeds))
        total_fiber = sum(ratios[i] * fibers[i] for i in range(n_feeds))
        total_cost = sum(ratios[i] * costs[i] for i in range(n_feeds))
        
        # 결과 데이터프레임 생성
        result_df = pd.DataFrame({
            '사료명': feeds_df['feed_name'],
            '배합비율(%)': [r * 100 for r in ratios],
            '단백질(%)': feeds_df['protein'],
            '지방(%)': feeds_df['fat'],
            '섬유질(%)': feeds_df['fiber'],
            '가격(원/kg)': feeds_df['price_per_kg']
        })
        
        # 요약 정보
        summary = f"""
        **🎯 최적 배합 결과:**
        
        **영양소 분석:**
        - 총 단백질: {total_protein:.1f}% (목표: {target_protein}%)
        - 총 지방: {total_fat:.1f}% (목표: {target_fat}%)
        - 총 섬유질: {total_fiber:.1f}% (최소: {min_fiber}%)
        
        **경제성 분석:**
        - 총 비용: {total_cost:.0f}원/kg (제한: {max_cost}원/kg)
        - 비용 효율성: {(total_protein / total_cost * 1000):.1f}% 단백질/1000원
        
        **AI 최적화 상태:**
        - 최적화 성공: ✅
        - 제약조건 만족: ✅
        """
        
        return result_df, summary
    else:
        return pd.DataFrame(), "❌ 최적화 실패: 제약조건을 만족하는 해를 찾을 수 없습니다."

# AI 모델 2: 영양 분석
def analyze_nutrition(*feed_ratios):
    """영양 분석 AI 모델"""
    
    # 사료 데이터 로드
    conn = sqlite3.connect("cnucnm_data/cnucnm.db")
    feeds_df = pd.read_sql_query("SELECT * FROM feeds", conn)
    conn.close()
    
    # 영양소 계산
    total_protein = 0
    total_fat = 0
    total_fiber = 0
    total_ash = 0
    total_calcium = 0
    total_phosphorus = 0
    
    feed_names = feeds_df['feed_name'].tolist()
    for i, ratio in enumerate(feed_ratios):
        if i < len(feed_names):
            feed_name = feed_names[i]
            feed_data = feeds_df[feeds_df['feed_name'] == feed_name]
            if not feed_data.empty:
                ratio_decimal = ratio / 100
                total_protein += feed_data['protein'].iloc[0] * ratio_decimal
                total_fat += feed_data['fat'].iloc[0] * ratio_decimal
                total_fiber += feed_data['fiber'].iloc[0] * ratio_decimal
                total_ash += feed_data['ash'].iloc[0] * ratio_decimal
                total_calcium += feed_data['calcium'].iloc[0] * ratio_decimal
                total_phosphorus += feed_data['phosphorus'].iloc[0] * ratio_decimal
    
    # 영양 균형 평가
    ca_p_ratio = total_calcium / total_phosphorus if total_phosphorus > 0 else 0
    energy_estimate = total_protein * 4 + total_fat * 9 + total_fiber * 2  # kcal/100g
    
    # 영양 상태 평가
    protein_status = "적절" if 15 <= total_protein <= 20 else "조정 필요"
    fat_status = "적절" if 2 <= total_fat <= 5 else "조정 필요"
    fiber_status = "적절" if 8 <= total_fiber <= 15 else "조정 필요"
    ca_p_status = "적절" if 1.5 <= ca_p_ratio <= 2.5 else "조정 필요"
    
    analysis_result = f"""
    **🔬 영양 분석 결과:**
    
    **주요 영양소:**
    - 단백질: {total_protein:.1f}% ({protein_status})
    - 지방: {total_fat:.1f}% ({fat_status})
    - 섬유질: {total_fiber:.1f}% ({fiber_status})
    - 회분: {total_ash:.1f}%
    - 칼슘: {total_calcium:.2f}%
    - 인: {total_phosphorus:.2f}%
    
    **영양 균형:**
    - Ca:P 비율: {ca_p_ratio:.1f}:1 ({ca_p_status})
    - 추정 에너지: {energy_estimate:.0f} kcal/100g
    
    **AI 평가:**
    - 전반적 영양 상태: {'🟢 양호' if all([protein_status == '적절', fat_status == '적절', fiber_status == '적절', ca_p_status == '적절']) else '🟡 개선 필요'}
    - 권장사항: {'현재 배합이 적절합니다.' if all([protein_status == '적절', fat_status == '적절', fiber_status == '적절', ca_p_status == '적절']) else '영양소 비율 조정을 권장합니다.'}
    """
    
    return analysis_result

# AI 모델 3: 생산성 예측 (머신러닝 기반)
def predict_productivity(animal_weight, feed_quality, management_level, breed_type, age_months):
    """생산성 예측 AI 모델 (머신러닝 기반)"""
    
    # 기본 성장 모델 (실제로는 더 복잡한 ML 모델 사용)
    base_growth_rate = 0.8  # kg/day
    
    # 요인별 조정 계수
    weight_factor = 1.0 if animal_weight > 300 else 0.9
    quality_factor = feed_quality / 100
    management_factor = management_level / 100
    breed_factor = 1.2 if breed_type == "한우" else 1.0
    age_factor = 1.0 if 12 <= age_months <= 24 else 0.8
    
    # 예측 성장률
    predicted_growth = base_growth_rate * weight_factor * quality_factor * management_factor * breed_factor * age_factor
    
    # 수익성 계산
    feed_cost_per_day = 15  # 원/일
    meat_price_per_kg = 8000  # 원/kg (한우 기준)
    daily_revenue = predicted_growth * meat_price_per_kg
    daily_profit = daily_revenue - feed_cost_per_day
    
    # 30일 예측
    days = list(range(1, 31))
    weights = [animal_weight + predicted_growth * day for day in days]
    profits = [daily_profit * day for day in days]
    
    # Plotly 차트 생성
    fig_weight = px.line(x=days, y=weights, title="체중 증가 예측 (30일)")
    fig_weight.update_layout(xaxis_title="일수", yaxis_title="체중 (kg)")
    
    fig_profit = px.line(x=days, y=profits, title="누적 수익 예측 (30일)")
    fig_profit.update_layout(xaxis_title="일수", yaxis_title="누적 수익 (원)")
    
    # ROI 계산
    total_investment = feed_cost_per_day * 30
    total_return = profits[-1]
    roi = (total_return / total_investment * 100) if total_investment > 0 else 0
    
    prediction_result = f"""
    **🔮 생산성 예측 결과:**
    
    **입력 조건:**
    - 현재 체중: {animal_weight} kg
    - 사료 품질: {feed_quality}%
    - 관리 수준: {management_level}%
    - 품종: {breed_type}
    - 월령: {age_months}개월
    
    **예측 결과:**
    - 일일 성장률: {predicted_growth:.2f} kg/일
    - 30일 후 체중: {weights[-1]:.1f} kg
    - 일일 수익: {daily_profit:,.0f}원
    - 30일 누적 수익: {profits[-1]:,.0f}원
    
    **투자 분석:**
    - 총 투자: {total_investment:,.0f}원 (30일 사료비)
    - 총 수익: {total_return:,.0f}원
    - ROI: {roi:.1f}%
    - 수익성 등급: {'🟢 우수' if roi > 50 else '🟡 보통' if roi > 20 else '🔴 개선 필요'}
    """
    
    return prediction_result, fig_weight, fig_profit

# Gradio 인터페이스 생성
def create_interface():
    """Gradio 인터페이스 생성"""
    
    # 데이터베이스 초기화
    init_database()
    
    with gr.Blocks(
        title="CNUCNM AI 모델 인터페이스",
        theme=gr.themes.Soft(
            primary_hue="green",
            secondary_hue="blue",
            neutral_hue="slate"
        )
    ) as interface:
        
        gr.Markdown("""
        # 🐄 CNUCNM AI 모델 인터페이스
        
        **사료 배합 최적화 • 영양 분석 • 생산성 예측**
        
        ---
        """)
        
        with gr.Tabs():
            
            # 탭 1: 사료 배합 최적화
            with gr.Tab("⚖️ 사료 배합 최적화"):
                gr.Markdown("### AI 기반 사료 배합 최적화 (선형계획법)")
                
                with gr.Row():
                    with gr.Column():
                        animal_weight = gr.Slider(
                            minimum=100, maximum=800, value=400, step=10,
                            label="동물 체중 (kg)"
                        )
                        target_protein = gr.Slider(
                            minimum=10, maximum=25, value=16, step=0.5,
                            label="목표 단백질 (%)"
                        )
                        target_fat = gr.Slider(
                            minimum=1, maximum=10, value=3, step=0.5,
                            label="목표 지방 (%)"
                        )
                        max_cost = gr.Slider(
                            minimum=200, maximum=1000, value=500, step=50,
                            label="최대 비용 (원/kg)"
                        )
                        
                        optimize_btn = gr.Button("🎯 최적화 실행", variant="primary")
                    
                    with gr.Column():
                        result_table = gr.Dataframe(
                            headers=["사료명", "배합비율(%)", "단백질(%)", "지방(%)", "섬유질(%)", "가격(원/kg)"],
                            label="최적 배합 결과"
                        )
                        summary_text = gr.Markdown(label="분석 요약")
                
                optimize_btn.click(
                    fn=optimize_feed_formulation,
                    inputs=[animal_weight, target_protein, target_fat, max_cost],
                    outputs=[result_table, summary_text]
                )
            
            # 탭 2: 영양 분석
            with gr.Tab("🔬 영양 분석"):
                gr.Markdown("### 사료 배합 영양 분석")
                
                with gr.Row():
                    with gr.Column():
                        gr.Markdown("**배합 비율 입력 (%):**")
                        
                        # 사료 데이터 로드
                        conn = sqlite3.connect("cnucnm_data/cnucnm.db")
                        feeds_df = pd.read_sql_query("SELECT feed_name FROM feeds", conn)
                        conn.close()
                        
                        feed_inputs = {}
                        for feed_name in feeds_df['feed_name']:
                            feed_inputs[feed_name] = gr.Slider(
                                minimum=0, maximum=100, value=20, step=5,
                                label=f"{feed_name} (%)"
                            )
                        
                        analyze_btn = gr.Button("🔬 영양 분석", variant="primary")
                    
                    with gr.Column():
                        analysis_result = gr.Markdown(label="영양 분석 결과")
                
                analyze_btn.click(
                    fn=analyze_nutrition,
                    inputs=list(feed_inputs.values()),
                    outputs=analysis_result
                )
            
            # 탭 3: 생산성 예측
            with gr.Tab("📈 생산성 예측"):
                gr.Markdown("### AI 기반 생산성 예측")
                
                with gr.Row():
                    with gr.Column():
                        current_weight = gr.Slider(
                            minimum=100, maximum=800, value=400, step=10,
                            label="현재 체중 (kg)"
                        )
                        feed_quality = gr.Slider(
                            minimum=50, maximum=100, value=80, step=5,
                            label="사료 품질 (%)"
                        )
                        management_level = gr.Slider(
                            minimum=50, maximum=100, value=85, step=5,
                            label="관리 수준 (%)"
                        )
                        breed_type = gr.Dropdown(
                            choices=["한우", "홀스타인", "젖소", "육우"],
                            value="한우",
                            label="품종"
                        )
                        age_months = gr.Slider(
                            minimum=6, maximum=36, value=18, step=1,
                            label="월령 (개월)"
                        )
                        
                        predict_btn = gr.Button("🔮 예측 실행", variant="primary")
                    
                    with gr.Column():
                        prediction_result = gr.Markdown(label="예측 결과")
                
                with gr.Row():
                    weight_chart = gr.Plot(label="체중 증가 예측")
                    profit_chart = gr.Plot(label="수익 예측")
                
                predict_btn.click(
                    fn=predict_productivity,
                    inputs=[current_weight, feed_quality, management_level, breed_type, age_months],
                    outputs=[prediction_result, weight_chart, profit_chart]
                )
            
            # 탭 4: 데이터 관리
            with gr.Tab("🗄️ 데이터 관리"):
                gr.Markdown("### 시스템 데이터 관리")
                
                with gr.Row():
                    with gr.Column():
                        gr.Markdown("**사료 데이터**")
                        feed_table = gr.Dataframe(
                            headers=["ID", "사료명", "종류", "단백질(%)", "지방(%)", "가격(원/kg)"],
                            label="사료 목록"
                        )
                    
                    with gr.Column():
                        gr.Markdown("**동물 데이터**")
                        animal_table = gr.Dataframe(
                            headers=["ID", "동물ID", "종", "품종", "체중", "상태"],
                            label="동물 목록"
                        )
                
                refresh_btn = gr.Button("🔄 데이터 새로고침")
                
                def load_data():
                    conn = sqlite3.connect("cnucnm_data/cnucnm.db")
                    feeds_df = pd.read_sql_query("""
                        SELECT id, feed_name, feed_type, protein, fat, price_per_kg 
                        FROM feeds LIMIT 10
                    """, conn)
                    animals_df = pd.read_sql_query("""
                        SELECT id, animal_id, species, breed, current_weight, status 
                        FROM animals LIMIT 10
                    """, conn)
                    conn.close()
                    return feeds_df, animals_df
                
                refresh_btn.click(
                    fn=load_data,
                    outputs=[feed_table, animal_table]
                )
    
    return interface

# 메인 실행
if __name__ == "__main__":
    interface = create_interface()
    interface.launch(
        server_name="127.0.0.1",
        server_port=7863,
        share=False,
        debug=True
    )
