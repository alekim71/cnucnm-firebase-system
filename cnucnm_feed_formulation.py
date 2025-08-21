import streamlit as st
import pandas as pd
import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from datetime import datetime
import sqlite3
import json
from pulp import *

# 페이지 설정
st.set_page_config(
    page_title="CNUCNM - 사료 배합 최적화",
    page_icon="🌾",
    layout="wide",
    initial_sidebar_state="expanded"
)

# CSS 스타일
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #2e8b57;
        text-align: center;
        margin-bottom: 2rem;
    }
    .metric-card {
        background-color: #f0f2f6;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 4px solid #2e8b57;
    }
    .optimization-result {
        background-color: #e8f5e8;
        padding: 1rem;
        border-radius: 0.5rem;
        border: 1px solid #2e8b57;
    }
</style>
""", unsafe_allow_html=True)

def init_database():
    """데이터베이스 초기화"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    cursor = conn.cursor()
    
    # 사료 배합 최적화 기록 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS feed_formulations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            formulation_name TEXT,
            animal_id INTEGER,
            animal_name TEXT,
            target_energy REAL,
            target_protein REAL,
            target_dry_matter REAL,
            total_cost REAL,
            formulation_date TIMESTAMP,
            formulation_data TEXT,
            FOREIGN KEY (animal_id) REFERENCES animals (id)
        )
    ''')
    
    # 사료 원료 테이블 (기본 데이터)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS feed_ingredients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ingredient_name TEXT,
            category TEXT,
            dry_matter REAL,
            crude_protein REAL,
            energy_mcal REAL,
            ndf REAL,
            adf REAL,
            ca REAL,
            p REAL,
            price_per_kg REAL,
            max_inclusion REAL,
            min_inclusion REAL,
            description TEXT
        )
    ''')
    
    # 기본 사료 원료 데이터
    ingredients_data = [
        ('옥수수', '곡류', 88.0, 8.5, 3.4, 9.0, 2.5, 0.02, 0.25, 350, 60.0, 5.0, '주요 에너지원'),
        ('대두박', '단백질원료', 90.0, 44.0, 2.8, 7.0, 5.0, 0.25, 0.65, 1200, 25.0, 10.0, '주요 단백질원'),
        ('밀기울', '부산물', 88.0, 15.0, 2.2, 35.0, 12.0, 0.12, 1.0, 400, 20.0, 5.0, '섬유질 공급원'),
        ('알팔파', '조사료', 90.0, 18.0, 2.1, 40.0, 30.0, 1.2, 0.25, 800, 30.0, 10.0, '고품질 조사료'),
        ('면실박', '단백질원료', 92.0, 41.0, 2.9, 25.0, 18.0, 0.15, 1.2, 900, 15.0, 5.0, '단백질 보조원료'),
        ('쌀겨', '부산물', 90.0, 12.0, 2.8, 25.0, 15.0, 0.08, 1.5, 300, 15.0, 3.0, '에너지 보조원료'),
        ('비트펄프', '부산물', 92.0, 9.0, 2.4, 20.0, 18.0, 0.5, 0.1, 200, 10.0, 2.0, '섬유질 보조원료'),
        ('어분', '동물성단백질', 92.0, 60.0, 3.2, 1.0, 1.0, 5.0, 3.0, 2500, 8.0, 2.0, '고단백 원료'),
        ('석회석', '미네랄', 100.0, 0.0, 0.0, 0.0, 0.0, 38.0, 0.0, 150, 3.0, 1.0, '칼슘 보충제'),
        ('인산이수소칼슘', '미네랄', 100.0, 0.0, 0.0, 0.0, 0.0, 23.0, 18.0, 800, 2.0, 0.5, '인 보충제'),
        ('소금', '미네랄', 100.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 100, 1.0, 0.3, '나트륨 보충제'),
        ('비타민프리믹스', '비타민', 100.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5000, 1.0, 0.5, '비타민 보충제'),
        ('미네랄프리믹스', '미네랄', 100.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3000, 1.0, 0.5, '미네랄 보충제')
    ]
    
    cursor.execute('DELETE FROM feed_ingredients')
    cursor.executemany('''
        INSERT INTO feed_ingredients 
        (ingredient_name, category, dry_matter, crude_protein, energy_mcal, ndf, adf, ca, p, price_per_kg, max_inclusion, min_inclusion, description)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', ingredients_data)
    
    conn.commit()
    conn.close()

def get_ingredients():
    """사료 원료 데이터 조회"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    df = pd.read_sql_query('SELECT * FROM feed_ingredients ORDER BY category, ingredient_name', conn)
    conn.close()
    return df

def optimize_feed_formulation(ingredients_df, target_energy, target_protein, target_dry_matter, 
                            max_ingredients=10, cost_weight=1.0, quality_weight=1.0):
    """사료 배합 최적화 (선형계획법)"""
    
    # 문제 정의
    prob = LpProblem("Feed_Formulation_Optimization", LpMinimize)
    
    # 의사결정 변수 (각 원료의 비율)
    ingredient_vars = LpVariable.dicts("Ingredient",
                                     ingredients_df['ingredient_name'],
                                     lowBound=0,
                                     upBound=1)
    
    # 목적함수: 비용 최소화 + 품질 편차 최소화
    cost_objective = lpSum([ingredient_vars[name] * ingredients_df[ingredients_df['ingredient_name'] == name]['price_per_kg'].iloc[0] 
                           for name in ingredients_df['ingredient_name']])
    
    # 제약조건
    # 1. 총 비율 = 100%
    prob += lpSum([ingredient_vars[name] for name in ingredients_df['ingredient_name']]) == 1.0
    
    # 2. 에너지 요구량 충족
    energy_constraint = lpSum([ingredient_vars[name] * ingredients_df[ingredients_df['ingredient_name'] == name]['energy_mcal'].iloc[0] 
                              for name in ingredients_df['ingredient_name']])
    prob += energy_constraint >= target_energy * 0.95  # 95% 이상 충족
    prob += energy_constraint <= target_energy * 1.05  # 105% 이하
    
    # 3. 단백질 요구량 충족
    protein_constraint = lpSum([ingredient_vars[name] * ingredients_df[ingredients_df['ingredient_name'] == name]['crude_protein'].iloc[0] 
                               for name in ingredients_df['ingredient_name']])
    prob += protein_constraint >= target_protein * 0.95  # 95% 이상 충족
    prob += protein_constraint <= target_protein * 1.05  # 105% 이하
    
    # 4. 건물 함량
    dm_constraint = lpSum([ingredient_vars[name] * ingredients_df[ingredients_df['ingredient_name'] == name]['dry_matter'].iloc[0] 
                          for name in ingredients_df['ingredient_name']])
    prob += dm_constraint >= target_dry_matter * 0.95
    
    # 5. 각 원료의 최대/최소 함량 제한
    for _, row in ingredients_df.iterrows():
        name = row['ingredient_name']
        prob += ingredient_vars[name] <= row['max_inclusion'] / 100.0
        prob += ingredient_vars[name] >= row['min_inclusion'] / 100.0
    
    # 6. NDF 함량 제한 (25-35%)
    ndf_constraint = lpSum([ingredient_vars[name] * ingredients_df[ingredients_df['ingredient_name'] == name]['ndf'].iloc[0] 
                           for name in ingredients_df['ingredient_name']])
    prob += ndf_constraint >= 25.0
    prob += ndf_constraint <= 35.0
    
    # 7. Ca:P 비율 (1.5:1 ~ 2.5:1)
    ca_constraint = lpSum([ingredient_vars[name] * ingredients_df[ingredients_df['ingredient_name'] == name]['ca'].iloc[0] 
                          for name in ingredients_df['ingredient_name']])
    p_constraint = lpSum([ingredient_vars[name] * ingredients_df[ingredients_df['ingredient_name'] == name]['p'].iloc[0] 
                         for name in ingredients_df['ingredient_name']])
    prob += ca_constraint >= 1.5 * p_constraint
    prob += ca_constraint <= 2.5 * p_constraint
    
    # 목적함수 설정
    prob += cost_objective
    
    # 최적화 실행
    prob.solve()
    
    if LpStatus[prob.status] == 'Optimal':
        # 결과 추출
        formulation = {}
        total_cost = 0
        
        for name in ingredients_df['ingredient_name']:
            ratio = ingredient_vars[name].varValue
            if ratio > 0.001:  # 0.1% 이상인 원료만 포함
                formulation[name] = ratio * 100  # 퍼센트로 변환
                price = ingredients_df[ingredients_df['ingredient_name'] == name]['price_per_kg'].iloc[0]
                total_cost += ratio * price
        
        # 영양소 함량 계산
        nutrients = {
            'energy_mcal': sum([formulation.get(name, 0) / 100 * ingredients_df[ingredients_df['ingredient_name'] == name]['energy_mcal'].iloc[0] 
                               for name in ingredients_df['ingredient_name']]),
            'crude_protein': sum([formulation.get(name, 0) / 100 * ingredients_df[ingredients_df['ingredient_name'] == name]['crude_protein'].iloc[0] 
                                 for name in ingredients_df['ingredient_name']]),
            'dry_matter': sum([formulation.get(name, 0) / 100 * ingredients_df[ingredients_df['ingredient_name'] == name]['dry_matter'].iloc[0] 
                              for name in ingredients_df['ingredient_name']]),
            'ndf': sum([formulation.get(name, 0) / 100 * ingredients_df[ingredients_df['ingredient_name'] == name]['ndf'].iloc[0] 
                       for name in ingredients_df['ingredient_name']]),
            'ca': sum([formulation.get(name, 0) / 100 * ingredients_df[ingredients_df['ingredient_name'] == name]['ca'].iloc[0] 
                      for name in ingredients_df['ingredient_name']]),
            'p': sum([formulation.get(name, 0) / 100 * ingredients_df[ingredients_df['ingredient_name'] == name]['p'].iloc[0] 
                     for name in ingredients_df['ingredient_name']])
        }
        
        return {
            'status': 'success',
            'formulation': formulation,
            'total_cost': total_cost,
            'nutrients': nutrients,
            'target_met': {
                'energy': nutrients['energy_mcal'] >= target_energy * 0.95 and nutrients['energy_mcal'] <= target_energy * 1.05,
                'protein': nutrients['crude_protein'] >= target_protein * 0.95 and nutrients['crude_protein'] <= target_protein * 1.05,
                'dry_matter': nutrients['dry_matter'] >= target_dry_matter * 0.95
            }
        }
    else:
        return {
            'status': 'infeasible',
            'message': '주어진 제약조건으로 최적해를 찾을 수 없습니다.'
        }

def save_formulation(formulation_name, animal_id, animal_name, target_energy, target_protein, 
                     target_dry_matter, total_cost, formulation_data):
    """사료 배합 결과 저장"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    cursor = conn.cursor()
    
    cursor.execute('''
        INSERT INTO feed_formulations 
        (formulation_name, animal_id, animal_name, target_energy, target_protein, 
         target_dry_matter, total_cost, formulation_date, formulation_data)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        formulation_name, animal_id, animal_name, target_energy, target_protein,
        target_dry_matter, total_cost, datetime.now(), json.dumps(formulation_data)
    ))
    
    conn.commit()
    conn.close()

def get_formulation_history():
    """사료 배합 기록 조회"""
    conn = sqlite3.connect('cnucnm_data/cnucnm.db')
    df = pd.read_sql_query('''
        SELECT * FROM feed_formulations 
        ORDER BY formulation_date DESC 
        LIMIT 50
    ''', conn)
    conn.close()
    return df

def main():
    st.markdown('<h1 class="main-header">🌾 CNUCNM 사료 배합 최적화 시스템</h1>', unsafe_allow_html=True)
    
    # 데이터베이스 초기화
    init_database()
    
    # 탭 생성
    tab1, tab2, tab3 = st.tabs(["🎯 배합 최적화", "📊 원료 관리", "📚 배합 기록"])
    
    with tab1:
        st.subheader("🎯 사료 배합 최적화")
        
        col1, col2 = st.columns([1, 1])
        
        with col1:
            st.markdown("**📋 동물 정보**")
            animal_name = st.text_input("동물 이름", "홀스타인_001")
            formulation_name = st.text_input("배합명", "최적배합_001")
            
            st.markdown("**🎯 목표 영양소**")
            target_energy = st.number_input("목표 에너지 (Mcal/kg DM)", min_value=2.0, max_value=4.0, value=2.8, step=0.1)
            target_protein = st.number_input("목표 단백질 (%)", min_value=12.0, max_value=20.0, value=16.0, step=0.5)
            target_dry_matter = st.number_input("목표 건물 함량 (%)", min_value=85.0, max_value=95.0, value=90.0, step=0.5)
            
            st.markdown("**⚙️ 최적화 설정**")
            max_ingredients = st.slider("최대 원료 수", min_value=5, max_value=15, value=10)
            cost_weight = st.slider("비용 가중치", min_value=0.1, max_value=2.0, value=1.0, step=0.1)
            
        with col2:
            st.markdown("**📈 현재 원료 가격**")
            ingredients_df = get_ingredients()
            
            # 원료별 가격 표시
            price_df = ingredients_df[['ingredient_name', 'category', 'price_per_kg']].copy()
            price_df.columns = ['원료명', '분류', '가격(원/kg)']
            st.dataframe(price_df, use_container_width=True, height=300)
        
        # 최적화 실행 버튼
        if st.button("🚀 배합 최적화 실행", type="primary"):
            with st.spinner("사료 배합을 최적화하고 있습니다..."):
                result = optimize_feed_formulation(
                    ingredients_df, target_energy, target_protein, target_dry_matter, 
                    max_ingredients, cost_weight
                )
                
                if result['status'] == 'success':
                    st.success("✅ 사료 배합 최적화가 완료되었습니다!")
                    
                    # 결과 저장
                    save_formulation(
                        formulation_name, 1, animal_name, target_energy, target_protein,
                        target_dry_matter, result['total_cost'], result
                    )
                    
                    # 결과 표시
                    col1, col2, col3 = st.columns(3)
                    
                    with col1:
                        st.metric("총 비용", f"{result['total_cost']:.0f} 원/kg")
                        
                    with col2:
                        st.metric("에너지 함량", f"{result['nutrients']['energy_mcal']:.2f} Mcal/kg DM")
                        
                    with col3:
                        st.metric("단백질 함량", f"{result['nutrients']['crude_protein']:.1f} %")
                    
                    # 배합 비율 차트
                    st.subheader("📊 최적 배합 비율")
                    
                    formulation_df = pd.DataFrame([
                        {'원료명': name, '비율(%)': ratio}
                        for name, ratio in result['formulation'].items()
                    ])
                    
                    fig = px.pie(formulation_df, values='비율(%)', names='원료명', 
                               title="사료 배합 비율")
                    st.plotly_chart(fig, use_container_width=True)
                    
                    # 상세 배합 정보
                    st.subheader("📋 상세 배합 정보")
                    
                    col1, col2 = st.columns(2)
                    
                    with col1:
                        st.markdown("**배합 비율**")
                        st.dataframe(formulation_df, use_container_width=True)
                    
                    with col2:
                        st.markdown("**영양소 함량**")
                        nutrients_df = pd.DataFrame({
                            '영양소': ['에너지 (Mcal/kg DM)', '단백질 (%)', '건물 (%)', 'NDF (%)', 'Ca (%)', 'P (%)'],
                            '함량': [
                                result['nutrients']['energy_mcal'],
                                result['nutrients']['crude_protein'],
                                result['nutrients']['dry_matter'],
                                result['nutrients']['ndf'],
                                result['nutrients']['ca'],
                                result['nutrients']['p']
                            ]
                        })
                        st.dataframe(nutrients_df, use_container_width=True)
                    
                    # 목표 달성도
                    st.subheader("🎯 목표 달성도")
                    
                    target_met = result['target_met']
                    col1, col2, col3 = st.columns(3)
                    
                    with col1:
                        status = "✅ 달성" if target_met['energy'] else "❌ 미달성"
                        st.metric("에너지 목표", status)
                        
                    with col2:
                        status = "✅ 달성" if target_met['protein'] else "❌ 미달성"
                        st.metric("단백질 목표", status)
                        
                    with col3:
                        status = "✅ 달성" if target_met['dry_matter'] else "❌ 미달성"
                        st.metric("건물 목표", status)
                        
                else:
                    st.error(f"❌ 최적화 실패: {result['message']}")
    
    with tab2:
        st.subheader("📊 원료 관리")
        
        ingredients_df = get_ingredients()
        
        # 원료별 상세 정보
        st.markdown("**📋 원료 상세 정보**")
        st.dataframe(ingredients_df, use_container_width=True)
        
        # 원료별 영양소 분포 차트
        st.subheader("📈 원료별 영양소 분포")
        
        col1, col2 = st.columns(2)
        
        with col1:
            # 단백질 함량
            fig1 = px.bar(ingredients_df, x='ingredient_name', y='crude_protein',
                         title="원료별 단백질 함량 (%)",
                         color='category')
            st.plotly_chart(fig1, use_container_width=True)
        
        with col2:
            # 에너지 함량
            fig2 = px.bar(ingredients_df, x='ingredient_name', y='energy_mcal',
                         title="원료별 에너지 함량 (Mcal/kg DM)",
                         color='category')
            st.plotly_chart(fig2, use_container_width=True)
        
        # 가격 분석
        st.subheader("💰 원료 가격 분석")
        
        fig3 = px.scatter(ingredients_df, x='crude_protein', y='price_per_kg',
                         size='energy_mcal', color='category',
                         hover_data=['ingredient_name'],
                         title="단백질 함량 vs 가격 (크기: 에너지 함량)")
        st.plotly_chart(fig3, use_container_width=True)
    
    with tab3:
        st.subheader("📚 배합 기록")
        
        history_df = get_formulation_history()
        
        if not history_df.empty:
            # JSON 데이터를 파싱하여 표시 가능한 형태로 변환
            history_df['formulation_date'] = pd.to_datetime(history_df['formulation_date'])
            history_df['formulation_date'] = history_df['formulation_date'].dt.strftime('%Y-%m-%d %H:%M')
            
            display_df = history_df[['formulation_name', 'animal_name', 'target_energy', 
                                   'target_protein', 'total_cost', 'formulation_date']].copy()
            display_df.columns = ['배합명', '동물명', '목표에너지', '목표단백질', '총비용(원/kg)', '배합일시']
            
            st.dataframe(display_df, use_container_width=True)
            
            # 통계 차트
            if len(history_df) > 1:
                st.subheader("📊 배합 통계")
                
                col1, col2 = st.columns(2)
                
                with col1:
                    # 비용 분포
                    fig1 = px.histogram(history_df, x='total_cost', nbins=10, 
                                      title="배합 비용 분포")
                    st.plotly_chart(fig1, use_container_width=True)
                
                with col2:
                    # 목표 에너지 vs 단백질
                    fig2 = px.scatter(history_df, x='target_energy', y='target_protein',
                                    size='total_cost', color='total_cost',
                                    title="목표 에너지 vs 단백질 (크기: 비용)")
                    st.plotly_chart(fig2, use_container_width=True)
        else:
            st.info("아직 배합 기록이 없습니다. 위에서 배합 최적화를 실행해보세요!")

if __name__ == "__main__":
    main()
