import streamlit as st
import pandas as pd
import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from datetime import datetime
import sqlite3
import json

# 페이지 설정
st.set_page_config(
    page_title="CNUCNM - 영양 요구량 계산",
    page_icon="🐄",
    layout="wide",
    initial_sidebar_state="expanded"
)

# CSS 스타일
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #1f77b4;
        text-align: center;
        margin-bottom: 2rem;
    }
    .metric-card {
        background-color: #f0f2f6;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 4px solid #1f77b4;
    }
    .success-message {
        background-color: #d4edda;
        color: #155724;
        padding: 1rem;
        border-radius: 0.5rem;
        border: 1px solid #c3e6cb;
    }
</style>
""", unsafe_allow_html=True)

def init_database():
    """데이터베이스 초기화"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    cursor = conn.cursor()
    
    # 영양 요구량 계산 기록 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS nutrition_requirements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            animal_id INTEGER,
            animal_name TEXT,
            breed TEXT,
            weight REAL,
            age_months INTEGER,
            production_stage TEXT,
            milk_yield REAL,
            pregnancy_stage INTEGER,
            calculation_date TIMESTAMP,
            requirements_data TEXT,
            FOREIGN KEY (animal_id) REFERENCES animals (id)
        )
    ''')
    
    # NASEM 영양소 표준 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS nasem_standards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nutrient_name TEXT,
            unit TEXT,
            category TEXT,
            min_value REAL,
            max_value REAL,
            recommended_value REAL,
            description TEXT
        )
    ''')
    
    # NASEM 표준 데이터 삽입 (기본값)
    nasem_data = [
        ('CP', '%', '단백질', 12.0, 18.0, 16.0, '조단백질'),
        ('NDF', '%', '섬유질', 25.0, 35.0, 30.0, '중성세제불용성섬유'),
        ('ADF', '%', '섬유질', 18.0, 25.0, 21.0, '산성세제불용성섬유'),
        ('Ca', '%', '미네랄', 0.6, 1.2, 0.9, '칼슘'),
        ('P', '%', '미네랄', 0.3, 0.5, 0.4, '인'),
        ('Mg', '%', '미네랄', 0.2, 0.4, 0.3, '마그네슘'),
        ('K', '%', '미네랄', 0.8, 1.5, 1.2, '칼륨'),
        ('Na', '%', '미네랄', 0.1, 0.3, 0.2, '나트륨'),
        ('Cl', '%', '미네랄', 0.2, 0.4, 0.3, '염소'),
        ('S', '%', '미네랄', 0.2, 0.3, 0.25, '황'),
        ('Fe', 'mg/kg', '미량원소', 50, 100, 75, '철'),
        ('Cu', 'mg/kg', '미량원소', 10, 20, 15, '구리'),
        ('Zn', 'mg/kg', '미량원소', 40, 80, 60, '아연'),
        ('Mn', 'mg/kg', '미량원소', 20, 40, 30, '망간'),
        ('Se', 'mg/kg', '미량원소', 0.1, 0.3, 0.2, '셀레늄'),
        ('Co', 'mg/kg', '미량원소', 0.1, 0.2, 0.15, '코발트'),
        ('I', 'mg/kg', '미량원소', 0.5, 1.0, 0.75, '요오드'),
        ('Vit_A', 'IU/kg', '비타민', 2000, 4000, 3000, '비타민 A'),
        ('Vit_D', 'IU/kg', '비타민', 300, 600, 450, '비타민 D'),
        ('Vit_E', 'IU/kg', '비타민', 15, 30, 22.5, '비타민 E')
    ]
    
    cursor.execute('DELETE FROM nasem_standards')
    cursor.executemany('''
        INSERT INTO nasem_standards 
        (nutrient_name, unit, category, min_value, max_value, recommended_value, description)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', nasem_data)
    
    conn.commit()
    conn.close()

def calculate_maintenance_requirements(weight, breed_factor=1.0):
    """유지 요구량 계산 (NASEM 2021 기준)"""
    # 기초 대사율 (kcal/day)
    basal_metabolic_rate = 70 * (weight ** 0.75)
    
    # 활동 요구량 (기초 대사율의 10-20%)
    activity_requirement = basal_metabolic_rate * 0.15
    
    # 총 유지 요구량
    maintenance_energy = (basal_metabolic_rate + activity_requirement) * breed_factor
    
    # 단백질 유지 요구량 (g/day)
    maintenance_protein = 3.8 * (weight ** 0.75)
    
    return {
        'energy_kcal': maintenance_energy,
        'protein_g': maintenance_protein,
        'dry_matter_kg': weight * 0.02  # 체중의 2%
    }

def calculate_production_requirements(production_stage, milk_yield=0, pregnancy_stage=0):
    """생산 요구량 계산"""
    production_energy = 0
    production_protein = 0
    
    if production_stage == "유우":
        # 유우 에너지 요구량 (kcal/kg milk)
        energy_per_kg_milk = 750
        production_energy = milk_yield * energy_per_kg_milk
        
        # 유우 단백질 요구량 (g/kg milk)
        protein_per_kg_milk = 85
        production_protein = milk_yield * protein_per_kg_milk
        
    elif production_stage == "임신":
        # 임신 단계별 요구량 증가
        pregnancy_factors = {
            1: 0.1,  # 1-3개월: 10% 증가
            2: 0.2,  # 4-6개월: 20% 증가
            3: 0.4   # 7-9개월: 40% 증가
        }
        factor = pregnancy_factors.get(pregnancy_stage, 0.1)
        production_energy = 5000 * factor  # 기본 임신 에너지 요구량
        production_protein = 200 * factor   # 기본 임신 단백질 요구량
        
    elif production_stage == "성장":
        # 성장 요구량 (체중 증가 1kg당)
        production_energy = 3000  # kcal/kg 체중 증가
        production_protein = 150   # g/kg 체중 증가
        
    return {
        'energy_kcal': production_energy,
        'protein_g': production_protein
    }

def calculate_total_requirements(weight, age_months, production_stage, milk_yield=0, pregnancy_stage=0):
    """총 영양 요구량 계산"""
    # 유지 요구량
    maintenance = calculate_maintenance_requirements(weight)
    
    # 생산 요구량
    production = calculate_production_requirements(production_stage, milk_yield, pregnancy_stage)
    
    # 총 요구량
    total_energy = maintenance['energy_kcal'] + production['energy_kcal']
    total_protein = maintenance['protein_g'] + production['protein_g']
    
    # 건물 섭취량 (체중의 2-3%)
    dry_matter_intake = weight * 0.025
    
    # 영양소 농도 계산
    energy_concentration = total_energy / (dry_matter_intake * 1000)  # Mcal/kg DM
    protein_concentration = (total_protein / 1000) / dry_matter_intake * 100  # % DM
    
    return {
        'maintenance': maintenance,
        'production': production,
        'total': {
            'energy_kcal': total_energy,
            'energy_mcal': total_energy / 1000,
            'protein_g': total_protein,
            'protein_percent': protein_concentration,
            'dry_matter_kg': dry_matter_intake
        },
        'concentrations': {
            'energy_mcal_kg': energy_concentration,
            'protein_percent': protein_concentration
        }
    }

def save_requirements(animal_id, animal_name, breed, weight, age_months, 
                      production_stage, milk_yield, pregnancy_stage, requirements):
    """영양 요구량 계산 결과 저장"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    cursor = conn.cursor()
    
    cursor.execute('''
        INSERT INTO nutrition_requirements 
        (animal_id, animal_name, breed, weight, age_months, production_stage, 
         milk_yield, pregnancy_stage, calculation_date, requirements_data)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        animal_id, animal_name, breed, weight, age_months, production_stage,
        milk_yield, pregnancy_stage, datetime.now(), json.dumps(requirements)
    ))
    
    conn.commit()
    conn.close()

def get_requirements_history():
    """영양 요구량 계산 기록 조회"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    df = pd.read_sql_query('''
        SELECT * FROM nutrition_requirements 
        ORDER BY calculation_date DESC 
        LIMIT 50
    ''', conn)
    conn.close()
    return df

def main():
    st.markdown('<h1 class="main-header">🐄 CNUCNM 영양 요구량 계산 시스템</h1>', unsafe_allow_html=True)
    
    # 데이터베이스 초기화
    init_database()
    
    # 사이드바 - 동물 정보 입력
    st.sidebar.header("📋 동물 정보")
    
    animal_name = st.sidebar.text_input("동물 이름", "홀스타인_001")
    breed = st.sidebar.selectbox("품종", ["홀스타인", "저지", "에어셔", "브라운스위스", "기타"])
    weight = st.sidebar.number_input("체중 (kg)", min_value=100.0, max_value=1000.0, value=600.0, step=10.0)
    age_months = st.sidebar.number_input("월령", min_value=1, max_value=120, value=24, step=1)
    
    production_stage = st.sidebar.selectbox(
        "생산 단계", 
        ["유지", "유우", "임신", "성장"]
    )
    
    milk_yield = 0
    pregnancy_stage = 0
    
    if production_stage == "유우":
        milk_yield = st.sidebar.number_input("일일 착유량 (kg)", min_value=0.0, max_value=50.0, value=25.0, step=0.5)
    elif production_stage == "임신":
        pregnancy_stage = st.sidebar.selectbox("임신 단계", [1, 2, 3], format_func=lambda x: f"{x}단계")
    
    # 계산 버튼
    if st.sidebar.button("🎯 영양 요구량 계산", type="primary"):
        with st.spinner("영양 요구량을 계산하고 있습니다..."):
            requirements = calculate_total_requirements(
                weight, age_months, production_stage, milk_yield, pregnancy_stage
            )
            
            # 결과 저장
            save_requirements(
                1, animal_name, breed, weight, age_months, 
                production_stage, milk_yield, pregnancy_stage, requirements
            )
            
            st.success("✅ 영양 요구량 계산이 완료되었습니다!")
            
            # 결과 표시
            col1, col2, col3 = st.columns(3)
            
            with col1:
                st.metric("총 에너지 요구량", f"{requirements['total']['energy_mcal']:.1f} Mcal/day")
                
            with col2:
                st.metric("총 단백질 요구량", f"{requirements['total']['protein_g']:.0f} g/day")
                
            with col3:
                st.metric("건물 섭취량", f"{requirements['total']['dry_matter_kg']:.1f} kg/day")
            
            # 상세 결과
            st.subheader("📊 상세 영양 요구량")
            
            col1, col2 = st.columns(2)
            
            with col1:
                st.markdown("**유지 요구량**")
                maintenance_df = pd.DataFrame({
                    '영양소': ['에너지 (Mcal/day)', '단백질 (g/day)', '건물 섭취량 (kg/day)'],
                    '요구량': [
                        requirements['maintenance']['energy_kcal'] / 1000,
                        requirements['maintenance']['protein_g'],
                        requirements['maintenance']['dry_matter_kg']
                    ]
                })
                st.dataframe(maintenance_df, use_container_width=True)
            
            with col2:
                st.markdown("**생산 요구량**")
                production_df = pd.DataFrame({
                    '영양소': ['에너지 (Mcal/day)', '단백질 (g/day)'],
                    '요구량': [
                        requirements['production']['energy_kcal'] / 1000,
                        requirements['production']['protein_g']
                    ]
                })
                st.dataframe(production_df, use_container_width=True)
            
            # 영양소 농도 차트
            st.subheader("📈 사료 영양소 농도 권장사항")
            
            concentrations = requirements['concentrations']
            
            fig = go.Figure()
            
            fig.add_trace(go.Bar(
                x=['에너지 (Mcal/kg DM)', '단백질 (%)'],
                y=[concentrations['energy_mcal_kg'], concentrations['protein_percent']],
                name='권장 농도',
                marker_color=['#1f77b4', '#ff7f0e']
            ))
            
            fig.update_layout(
                title="사료 영양소 농도 권장사항",
                yaxis_title="농도",
                showlegend=False,
                height=400
            )
            
            st.plotly_chart(fig, use_container_width=True)
            
            # NASEM 표준과 비교
            st.subheader("📋 NASEM 영양소 표준")
            
            conn = sqlite3.connect('cnucnm_data/cnucnm.db')
            nasem_df = pd.read_sql_query('SELECT * FROM nasem_standards', conn)
            conn.close()
            
            st.dataframe(nasem_df, use_container_width=True)
    
    # 계산 기록
    st.subheader("📚 최근 계산 기록")
    
    history_df = get_requirements_history()
    
    if not history_df.empty:
        # JSON 데이터를 파싱하여 표시 가능한 형태로 변환
        history_df['calculation_date'] = pd.to_datetime(history_df['calculation_date'])
        history_df['calculation_date'] = history_df['calculation_date'].dt.strftime('%Y-%m-%d %H:%M')
        
        display_df = history_df[['animal_name', 'breed', 'weight', 'production_stage', 'calculation_date']].copy()
        display_df.columns = ['동물명', '품종', '체중(kg)', '생산단계', '계산일시']
        
        st.dataframe(display_df, use_container_width=True)
        
        # 통계 차트
        if len(history_df) > 1:
            st.subheader("📊 계산 통계")
            
            col1, col2 = st.columns(2)
            
            with col1:
                # 품종별 분포
                breed_counts = history_df['breed'].value_counts()
                fig1 = px.pie(values=breed_counts.values, names=breed_counts.index, title="품종별 분포")
                st.plotly_chart(fig1, use_container_width=True)
            
            with col2:
                # 체중 분포
                fig2 = px.histogram(history_df, x='weight', nbins=10, title="체중 분포")
                st.plotly_chart(fig2, use_container_width=True)
    else:
        st.info("아직 계산 기록이 없습니다. 위에서 동물 정보를 입력하고 계산해보세요!")

if __name__ == "__main__":
    main()
