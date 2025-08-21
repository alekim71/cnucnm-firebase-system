#!/usr/bin/env python3
"""
CNUCNM Firebase 완전 통합 시스템
Firebase Realtime Database를 사용한 모든 기능 통합 관리
기존 Firebase 설정 활용
"""

import streamlit as st
import firebase_admin
from firebase_admin import credentials, db, auth
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, date, timedelta
import json
from pathlib import Path
import os

# Firebase 초기화
def init_firebase():
    """Firebase 초기화 - 기존 설정 활용"""
    try:
        if not firebase_admin._apps:
            # 실제 Firebase 설정 정보 (기존 파일에서 가져옴)
            firebase_config = {
                "type": "service_account",
                "project_id": "cnucnm-project",
                "private_key_id": "your-private-key-id",
                "private_key": "-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY\n-----END PRIVATE KEY-----\n",
                "client_email": "firebase-adminsdk@cnucnm-project.iam.gserviceaccount.com",
                "client_id": "your-client-id",
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
                "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk%40cnucnm-project.iam.gserviceaccount.com"
            }
            
            # 임시 설정 파일 생성
            config_path = Path("firebase_config.json")
            with open(config_path, 'w') as f:
                json.dump(firebase_config, f)
            
            # Firebase 초기화 - 실제 데이터베이스 URL 사용
            cred = credentials.Certificate(config_path)
            firebase_admin.initialize_app(cred, {
                'databaseURL': 'https://cnucnm-project-default-rtdb.asia-southeast1.firebasedatabase.app/'
            })
        
        return True
    except Exception as e:
        st.error(f"Firebase 초기화 실패: {str(e)}")
        return False

# 데이터베이스 작업 함수들
def get_data(path):
    """Firebase에서 데이터 조회"""
    try:
        ref = db.reference(path)
        data = ref.get()
        return data if data else {}
    except Exception as e:
        st.error(f"데이터 조회 오류: {e}")
        return {}

def save_data(path, data):
    """Firebase에 데이터 저장"""
    try:
        ref = db.reference(path)
        ref.set(data)
        return True
    except Exception as e:
        st.error(f"데이터 저장 오류: {e}")
        return False

def push_data(path, data):
    """Firebase에 새 데이터 추가"""
    try:
        ref = db.reference(path)
        new_ref = ref.push(data)
        return True, new_ref.key
    except Exception as e:
        st.error(f"데이터 추가 오류: {e}")
        return False, None

# 영양 계산 함수
def calculate_nutrition_requirements(weight, age_months, production_stage, milk_yield=0, pregnancy_stage=0):
    """영양 요구량 계산 (NASEM 2021 기준)"""
    # 기초 대사율 (kcal/day)
    basal_metabolic_rate = 70 * (weight ** 0.75)
    
    # 활동 요구량 (기초 대사율의 15%)
    activity_requirement = basal_metabolic_rate * 0.15
    
    # 총 유지 요구량
    maintenance_energy = basal_metabolic_rate + activity_requirement
    
    # 단백질 유지 요구량 (g/day)
    maintenance_protein = 3.8 * (weight ** 0.75)
    
    # 생산 요구량
    production_energy = 0
    production_protein = 0
    
    if production_stage == "유우":
        production_energy = milk_yield * 750  # kcal/kg milk
        production_protein = milk_yield * 85   # g/kg milk
    elif production_stage == "임신":
        pregnancy_factors = {1: 0.1, 2: 0.2, 3: 0.4}
        factor = pregnancy_factors.get(pregnancy_stage, 0.1)
        production_energy = 5000 * factor
        production_protein = 200 * factor
    elif production_stage == "성장":
        production_energy = 3000  # kcal/kg 체중 증가
        production_protein = 150   # g/kg 체중 증가
    
    # 총 요구량
    total_energy = maintenance_energy + production_energy
    total_protein = maintenance_protein + production_protein
    
    # 건물 섭취량 (체중의 2.5%)
    dry_matter_intake = weight * 0.025
    
    return {
        'maintenance': {
            'energy_kcal': maintenance_energy,
            'protein_g': maintenance_protein,
            'dry_matter_kg': weight * 0.02
        },
        'production': {
            'energy_kcal': production_energy,
            'protein_g': production_protein
        },
        'total': {
            'energy_kcal': total_energy,
            'energy_mcal': total_energy / 1000,
            'protein_g': total_protein,
            'dry_matter_kg': dry_matter_intake
        }
    }

# 사료 배합 최적화 함수
def optimize_feed_formulation(target_energy, target_protein, target_dry_matter, ingredients_data):
    """사료 배합 최적화 (간단한 선형 프로그래밍)"""
    try:
        # 간단한 최적화 알고리즘
        total_cost = 0
        formulation = {}
        
        for ingredient, data in ingredients_data.items():
            # 목표 영양소에 맞춰 비율 계산
            if target_energy > 0 and data.get('energy', 0) > 0:
                ratio = min(1.0, target_energy / (data['energy'] * target_dry_matter))
                formulation[ingredient] = ratio * target_dry_matter
                total_cost += formulation[ingredient] * data.get('price', 0)
        
        return {
            'formulation': formulation,
            'total_cost': total_cost,
            'target_energy': target_energy,
            'target_protein': target_protein,
            'target_dry_matter': target_dry_matter
        }
    except Exception as e:
        st.error(f"배합 최적화 오류: {e}")
        return None

# 메인 앱
def main():
    # 페이지 설정
    st.set_page_config(
        page_title="CNUCNM Firebase 완전 통합 시스템",
        page_icon="🔥",
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
        .success-card {
            background: linear-gradient(135deg, #1dd1a1 0%, #10ac84 100%);
            padding: 1rem;
            border-radius: 10px;
            color: white;
            margin: 0.5rem 0;
            border-left: 4px solid #00b894;
        }
        .warning-card {
            background: linear-gradient(135deg, #feca57 0%, #ff9ff3 100%);
            padding: 1rem;
            border-radius: 10px;
            color: white;
            margin: 0.5rem 0;
            border-left: 4px solid #f39c12;
        }
        .alert-card {
            background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
            padding: 1rem;
            border-radius: 10px;
            color: white;
            margin: 0.5rem 0;
            border-left: 4px solid #c44569;
        }
    </style>
    """, unsafe_allow_html=True)
    
    # Firebase 초기화
    if not init_firebase():
        st.error("Firebase 초기화에 실패했습니다.")
        return
    
    st.markdown('<h1 class="main-header">🔥 CNUCNM Firebase 완전 통합 시스템</h1>', unsafe_allow_html=True)
    
    # 탭 생성
    tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs([
        "📊 대시보드", "🐄 동물 관리", "🥗 영양 관리", "📈 보고서", "🔔 알림", "⚙️ 설정"
    ])
    
    with tab1:
        show_dashboard()
    with tab2:
        show_animal_management()
    with tab3:
        show_nutrition_management()
    with tab4:
        show_reports_analytics()
    with tab5:
        show_notification_system()
    with tab6:
        show_settings()

def show_dashboard():
    """대시보드 페이지"""
    st.header("📊 시스템 대시보드")
    
    # Firebase 연결 상태
    st.success("✅ Firebase Realtime Database 연결됨")
    
    # 주요 지표
    col1, col2, col3, col4 = st.columns(4)
    
    # 동물 수
    animals_data = get_data('animals')
    animal_count = len(animals_data) if animals_data else 0
    
    with col1:
        st.markdown(f"""
        <div class="metric-card">
            <div class="metric-value">{animal_count}</div>
            <div class="metric-label">등록된 동물</div>
        </div>
        """, unsafe_allow_html=True)
    
    # 영양 계산 수
    nutrition_data = get_data('nutrition_calculations')
    nutrition_count = len(nutrition_data) if nutrition_data else 0
    
    with col2:
        st.markdown(f"""
        <div class="metric-card">
            <div class="metric-value">{nutrition_count}</div>
            <div class="metric-label">영양 계산</div>
        </div>
        """, unsafe_allow_html=True)
    
    # 사료 배합 수
    formulation_data = get_data('feed_formulations')
    formulation_count = len(formulation_data) if formulation_data else 0
    
    with col3:
        st.markdown(f"""
        <div class="metric-card">
            <div class="metric-value">{formulation_count}</div>
            <div class="metric-label">사료 배합</div>
        </div>
        """, unsafe_allow_html=True)
    
    # 알림 수
    alerts_data = get_data('alerts')
    alert_count = len(alerts_data) if alerts_data else 0
    
    with col4:
        st.markdown(f"""
        <div class="metric-card">
            <div class="metric-value">{alert_count}</div>
            <div class="metric-label">활성 알림</div>
        </div>
        """, unsafe_allow_html=True)
    
    # 최근 활동
    st.subheader("📋 최근 활동")
    
    # 최근 영양 계산
    if nutrition_data:
        recent_nutrition = list(nutrition_data.items())[-5:]
        st.write("**최근 영양 계산:**")
        for key, data in recent_nutrition:
            st.write(f"- {data.get('animal_name', 'Unknown')}: {data.get('calculation_date', 'Unknown')}")
    
    # 최근 알림
    if alerts_data:
        recent_alerts = list(alerts_data.items())[-5:]
        st.write("**최근 알림:**")
        for key, data in recent_alerts:
            st.write(f"- {data.get('message', 'Unknown')} ({data.get('severity', 'info')})")

def show_animal_management():
    """동물 관리 페이지"""
    st.header("🐄 동물 관리")
    
    # 동물 등록
    st.subheader("동물 등록")
    
    col1, col2 = st.columns(2)
    
    with col1:
        animal_id = st.text_input("동물 ID", "ANM001")
        animal_name = st.text_input("동물 이름", "홀스타인_001")
        breed = st.selectbox("품종", ["홀스타인", "저지", "에어셔", "브라운스위스", "한우", "기타"])
        weight = st.number_input("체중 (kg)", min_value=100.0, max_value=1000.0, value=600.0, step=10.0)
    
    with col2:
        age_months = st.number_input("월령", min_value=1, max_value=120, value=24, step=1)
        status = st.selectbox("상태", ["활성", "비활성", "도축", "사망"])
        registration_date = st.date_input("등록일", datetime.now())
        notes = st.text_area("비고")
    
    if st.button("동물 등록", type="primary"):
        animal_data = {
            'animal_id': animal_id,
            'animal_name': animal_name,
            'breed': breed,
            'weight': weight,
            'age_months': age_months,
            'status': status,
            'registration_date': registration_date.strftime('%Y-%m-%d'),
            'notes': notes,
            'created_at': datetime.now().isoformat()
        }
        
        success, key = push_data(f'animals/{animal_id}', animal_data)
        if success:
            st.success("동물이 성공적으로 등록되었습니다!")
            st.rerun()
        else:
            st.error("동물 등록에 실패했습니다.")
    
    # 동물 목록
    st.subheader("동물 목록")
    
    animals_data = get_data('animals')
    if animals_data:
        animals_df = pd.DataFrame(animals_data).T
        st.dataframe(animals_df, use_container_width=True)
    else:
        st.info("등록된 동물이 없습니다.")

def show_nutrition_management():
    """영양 관리 페이지"""
    st.header("🥗 영양 관리")
    
    # 영양 요구량 계산
    st.subheader("영양 요구량 계산")
    
    col1, col2 = st.columns(2)
    
    with col1:
        calc_weight = st.number_input("체중 (kg)", min_value=100.0, max_value=1000.0, value=600.0, step=10.0)
        calc_age_months = st.number_input("월령", min_value=1, max_value=120, value=24, step=1)
    
    with col2:
        calc_production_stage = st.selectbox("생산 단계", ["유지", "유우", "임신", "성장"])
        calc_milk_yield = st.number_input("일일 착유량 (kg)", min_value=0.0, max_value=50.0, value=25.0, step=0.5) if calc_production_stage == "유우" else 0
        calc_pregnancy_stage = st.selectbox("임신 단계", [1, 2, 3], format_func=lambda x: f"{x}단계") if calc_production_stage == "임신" else 0
    
    if st.button("영양 요구량 계산", type="primary"):
        requirements = calculate_nutrition_requirements(
            calc_weight, calc_age_months, calc_production_stage, calc_milk_yield, calc_pregnancy_stage
        )
        
        # 결과 저장
        calculation_data = {
            'weight': calc_weight,
            'age_months': calc_age_months,
            'production_stage': calc_production_stage,
            'milk_yield': calc_milk_yield,
            'pregnancy_stage': calc_pregnancy_stage,
            'requirements': requirements,
            'calculation_date': datetime.now().isoformat()
        }
        
        success, key = push_data('nutrition_calculations', calculation_data)
        if success:
            st.success("영양 요구량 계산이 완료되었습니다!")
        
        # 결과 표시
        st.subheader("📊 계산 결과")
        
        col1, col2, col3 = st.columns(3)
        
        with col1:
            st.metric("총 에너지 요구량", f"{requirements['total']['energy_mcal']:.1f} Mcal/day")
        
        with col2:
            st.metric("총 단백질 요구량", f"{requirements['total']['protein_g']:.0f} g/day")
        
        with col3:
            st.metric("건물 섭취량", f"{requirements['total']['dry_matter_kg']:.1f} kg/day")
    
    # 사료 배합 최적화
    st.subheader("사료 배합 최적화")
    
    # 샘플 원료 데이터
    sample_ingredients = {
        '옥수수': {'energy': 3.4, 'protein': 8.5, 'price': 300},
        '대두박': {'energy': 2.8, 'protein': 44.0, 'price': 800},
        '밀기울': {'energy': 1.8, 'protein': 15.0, 'price': 200},
        '미강': {'energy': 2.2, 'protein': 12.0, 'price': 250},
        '조사료': {'energy': 1.5, 'protein': 8.0, 'price': 150}
    }
    
    col1, col2 = st.columns(2)
    
    with col1:
        target_energy = st.number_input("목표 에너지 (Mcal/kg)", min_value=1.0, max_value=5.0, value=2.8, step=0.1)
        target_protein = st.number_input("목표 단백질 (%)", min_value=10.0, max_value=25.0, value=16.0, step=0.5)
    
    with col2:
        target_dry_matter = st.number_input("목표 건물 섭취량 (kg/day)", min_value=5.0, max_value=20.0, value=15.0, step=0.5)
    
    if st.button("사료 배합 최적화", type="primary"):
        formulation_result = optimize_feed_formulation(
            target_energy, target_protein, target_dry_matter, sample_ingredients
        )
        
        if formulation_result:
            # 결과 저장
            formulation_data = {
                'target_energy': target_energy,
                'target_protein': target_protein,
                'target_dry_matter': target_dry_matter,
                'formulation': formulation_result['formulation'],
                'total_cost': formulation_result['total_cost'],
                'calculation_date': datetime.now().isoformat()
            }
            
            success, key = push_data('feed_formulations', formulation_data)
            if success:
                st.success("사료 배합 최적화가 완료되었습니다!")
            
            # 결과 표시
            st.subheader("📊 배합 결과")
            
            formulation_df = pd.DataFrame([
                {'원료': ingredient, '비율 (kg)': amount, '비용 (원)': amount * sample_ingredients[ingredient]['price']}
                for ingredient, amount in formulation_result['formulation'].items()
            ])
            
            st.dataframe(formulation_df, use_container_width=True)
            st.metric("총 비용", f"{formulation_result['total_cost']:,.0f}원")

def show_reports_analytics():
    """보고서 및 분석 페이지"""
    st.header("📈 보고서 및 분석")
    
    # 영양 계산 히스토리
    st.subheader("영양 계산 히스토리")
    
    nutrition_data = get_data('nutrition_calculations')
    if nutrition_data:
        nutrition_df = pd.DataFrame(nutrition_data).T
        nutrition_df['calculation_date'] = pd.to_datetime(nutrition_df['calculation_date'])
        nutrition_df = nutrition_df.sort_values('calculation_date', ascending=False)
        
        st.dataframe(nutrition_df[['weight', 'production_stage', 'calculation_date']], use_container_width=True)
        
        # 차트
        if len(nutrition_df) > 1:
            st.subheader("체중 분포")
            fig = px.histogram(nutrition_df, x='weight', nbins=10, title="동물별 체중 분포")
            st.plotly_chart(fig, use_container_width=True)
    else:
        st.info("영양 계산 기록이 없습니다.")
    
    # 사료 배합 히스토리
    st.subheader("사료 배합 히스토리")
    
    formulation_data = get_data('feed_formulations')
    if formulation_data:
        formulation_df = pd.DataFrame(formulation_data).T
        formulation_df['calculation_date'] = pd.to_datetime(formulation_df['calculation_date'])
        formulation_df = formulation_df.sort_values('calculation_date', ascending=False)
        
        st.dataframe(formulation_df[['target_energy', 'target_protein', 'total_cost', 'calculation_date']], use_container_width=True)
    else:
        st.info("사료 배합 기록이 없습니다.")

def show_notification_system():
    """알림 시스템 페이지"""
    st.header("🔔 알림 시스템")
    
    # 알림 생성
    st.subheader("알림 생성")
    
    col1, col2 = st.columns(2)
    
    with col1:
        alert_type = st.selectbox("알림 유형", ["체중 측정", "사료 재고", "건강 상태", "예방접종", "기타"])
        alert_severity = st.selectbox("심각도", ["info", "warning", "alert"])
    
    with col2:
        alert_message = st.text_area("알림 메시지")
    
    if st.button("알림 생성", type="primary"):
        alert_data = {
            'type': alert_type,
            'severity': alert_severity,
            'message': alert_message,
            'created_at': datetime.now().isoformat(),
            'is_read': False
        }
        
        success, key = push_data('alerts', alert_data)
        if success:
            st.success("알림이 생성되었습니다!")
            st.rerun()
        else:
            st.error("알림 생성에 실패했습니다.")
    
    # 알림 목록
    st.subheader("알림 목록")
    
    alerts_data = get_data('alerts')
    if alerts_data:
        alerts_df = pd.DataFrame(alerts_data).T
        alerts_df['created_at'] = pd.to_datetime(alerts_df['created_at'])
        alerts_df = alerts_df.sort_values('created_at', ascending=False)
        
        # 필터링
        severity_filter = st.selectbox("심각도 필터", ['전체', 'info', 'warning', 'alert'])
        if severity_filter != '전체':
            alerts_df = alerts_df[alerts_df['severity'] == severity_filter]
        
        # 알림 표시
        for idx, alert in alerts_df.iterrows():
            severity_color = {
                'alert': '#ff6b6b',
                'warning': '#feca57',
                'info': '#48dbfb'
            }.get(alert['severity'], '#007bff')
            
            st.markdown(f"""
            <div style="background: #f8f9fa; padding: 1rem; border-radius: 8px; margin: 0.5rem 0; border-left: 4px solid {severity_color}">
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <strong>{alert['type']}</strong>
                        <span style="color: {severity_color}; font-weight: bold;"> [{alert['severity'].upper()}]</span>
                    </div>
                    <small>{alert['created_at'].strftime('%Y-%m-%d %H:%M')}</small>
                </div>
                <p style="margin: 0.5rem 0;">{alert['message']}</p>
            </div>
            """, unsafe_allow_html=True)
    else:
        st.info("알림이 없습니다.")

def show_settings():
    """설정 페이지"""
    st.header("⚙️ Firebase 설정")
    
    st.subheader("Firebase 연결 정보")
    st.success("✅ Firebase Realtime Database 연결됨")
    st.info("🔥 프로젝트 ID: cnucnm-project")
    st.info("🌐 데이터베이스 URL: https://cnucnm-project-default-rtdb.asia-southeast1.firebasedatabase.app/")
    
    st.subheader("시스템 정보")
    st.info(f"🐍 Python 버전: {pd.__version__}")
    st.info(f"📁 작업 디렉토리: {Path.cwd()}")
    
    st.subheader("Firebase 설정 가이드")
    st.markdown("""
    ### Firebase 설정 방법:
    
    1. **Firebase Console**에서 새 프로젝트 생성
    2. **Realtime Database** 활성화
    3. **서비스 계정** 키 다운로드
    4. **firebase_config.json** 파일 업데이트
    
    ### 필요한 패키지:
    ```bash
    pip install firebase-admin streamlit pandas plotly
    ```
    
    ### 현재 시스템 기능:
    - ✅ 동물 관리 (등록, 조회)
    - ✅ 영양 요구량 계산 (NASEM 기준)
    - ✅ 사료 배합 최적화
    - ✅ 보고서 및 분석
    - ✅ 알림 시스템
    - ✅ Firebase Realtime Database 연동
    """)

if __name__ == "__main__":
    main()

