#!/usr/bin/env python3
"""
CNUCNM 동물 관리 시스템
동물 등록, 조회, 수정, 삭제 및 생산성 추적
"""

import streamlit as st
import sqlite3
import pandas as pd
from datetime import datetime, date
import uuid
from pathlib import Path
import plotly.express as px
import plotly.graph_objects as go

# 데이터베이스 초기화
def init_animal_database():
    """동물 관리 데이터베이스 초기화"""
    db_path = Path("cnucnm_data/cnucnm.db")
    db_path.parent.mkdir(exist_ok=True)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # 동물 테이블 생성
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS animals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            animal_id TEXT UNIQUE NOT NULL,
            name TEXT,
            species TEXT NOT NULL,
            breed TEXT,
            gender TEXT,
            birth_date DATE,
            initial_weight REAL,
            current_weight REAL,
            status TEXT DEFAULT 'active',
            owner_id INTEGER,
            farm_location TEXT,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (owner_id) REFERENCES users (id)
        )
    ''')
    
    # 체중 기록 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS weight_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            animal_id INTEGER,
            weight REAL NOT NULL,
            measurement_date DATE NOT NULL,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (animal_id) REFERENCES animals (id)
        )
    ''')
    
    # 건강 기록 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS health_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            animal_id INTEGER,
            health_status TEXT NOT NULL,
            symptoms TEXT,
            treatment TEXT,
            veterinarian TEXT,
            record_date DATE NOT NULL,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (animal_id) REFERENCES animals (id)
        )
    ''')
    
    # 샘플 동물 데이터 생성
    if cursor.execute("SELECT COUNT(*) FROM animals").fetchone()[0] == 0:
        sample_animals = [
            ('ANM001', '황소1', '한우', '한우', '수', '2022-01-15', 300, 450, 'active', 1, 'A구역'),
            ('ANM002', '암소1', '한우', '한우', '암', '2021-06-20', 280, 420, 'active', 1, 'B구역'),
            ('ANM003', '송아지1', '한우', '한우', '수', '2023-03-10', 50, 120, 'active', 1, 'C구역'),
            ('ANM004', '젖소1', '홀스타인', '홀스타인', '암', '2020-12-05', 350, 550, 'active', 1, 'D구역'),
            ('ANM005', '황소2', '한우', '한우', '수', '2022-08-12', 320, 480, 'active', 1, 'A구역')
        ]
        
        for animal in sample_animals:
            cursor.execute("""
                INSERT INTO animals (animal_id, name, species, breed, gender, birth_date, 
                                   initial_weight, current_weight, status, owner_id, farm_location)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, animal)
        
        # 샘플 체중 기록
        weight_records = [
            (1, 300, '2023-01-01'),
            (1, 320, '2023-02-01'),
            (1, 350, '2023-03-01'),
            (1, 380, '2023-04-01'),
            (1, 410, '2023-05-01'),
            (1, 450, '2023-06-01'),
            (2, 280, '2023-01-01'),
            (2, 300, '2023-02-01'),
            (2, 320, '2023-03-01'),
            (2, 350, '2023-04-01'),
            (2, 380, '2023-05-01'),
            (2, 420, '2023-06-01')
        ]
        
        for record in weight_records:
            cursor.execute("""
                INSERT INTO weight_records (animal_id, weight, measurement_date)
                VALUES (?, ?, ?)
            """, record)
    
    conn.commit()
    conn.close()
    return db_path

# 동물 등록
def register_animal(animal_id, name, species, breed, gender, birth_date, 
                   initial_weight, owner_id, farm_location, notes):
    """동물 등록"""
    try:
        conn = sqlite3.connect("cnucnm_data/cnucnm.db")
        cursor = conn.cursor()
        
        # 중복 확인
        cursor.execute("SELECT id FROM animals WHERE animal_id = ?", (animal_id,))
        if cursor.fetchone():
            return False, "동물 ID가 이미 존재합니다."
        
        # 동물 등록
        cursor.execute("""
            INSERT INTO animals (animal_id, name, species, breed, gender, birth_date,
                               initial_weight, current_weight, owner_id, farm_location, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (animal_id, name, species, breed, gender, birth_date, 
              initial_weight, initial_weight, owner_id, farm_location, notes))
        
        animal_db_id = cursor.lastrowid
        
        # 초기 체중 기록
        cursor.execute("""
            INSERT INTO weight_records (animal_id, weight, measurement_date)
            VALUES (?, ?, ?)
        """, (animal_db_id, initial_weight, date.today()))
        
        conn.commit()
        conn.close()
        return True, "동물이 성공적으로 등록되었습니다."
    except Exception as e:
        return False, f"등록 실패: {str(e)}"

# 동물 목록 조회
def get_animals():
    """동물 목록 조회"""
    try:
        conn = sqlite3.connect("cnucnm_data/cnucnm.db")
        query = """
            SELECT a.id, a.animal_id, a.name, a.species, a.breed, a.gender,
                   a.birth_date, a.initial_weight, a.current_weight, a.status,
                   a.farm_location, a.created_at,
                   u.first_name || ' ' || u.last_name as owner_name
            FROM animals a
            LEFT JOIN users u ON a.owner_id = u.id
            ORDER BY a.created_at DESC
        """
        df = pd.read_sql_query(query, conn)
        conn.close()
        return df
    except Exception as e:
        st.error(f"동물 목록 조회 실패: {str(e)}")
        return pd.DataFrame()

# 동물 검색
def search_animals(search_term, search_by):
    """동물 검색"""
    try:
        conn = sqlite3.connect("cnucnm_data/cnucnm.db")
        
        if search_by == "동물ID":
            query = """
                SELECT a.*, u.first_name || ' ' || u.last_name as owner_name
                FROM animals a
                LEFT JOIN users u ON a.owner_id = u.id
                WHERE a.animal_id LIKE ?
                ORDER BY a.created_at DESC
            """
        elif search_by == "이름":
            query = """
                SELECT a.*, u.first_name || ' ' || u.last_name as owner_name
                FROM animals a
                LEFT JOIN users u ON a.owner_id = u.id
                WHERE a.name LIKE ?
                ORDER BY a.created_at DESC
            """
        elif search_by == "종":
            query = """
                SELECT a.*, u.first_name || ' ' || u.last_name as owner_name
                FROM animals a
                LEFT JOIN users u ON a.owner_id = u.id
                WHERE a.species LIKE ?
                ORDER BY a.created_at DESC
            """
        else:  # 품종
            query = """
                SELECT a.*, u.first_name || ' ' || u.last_name as owner_name
                FROM animals a
                LEFT JOIN users u ON a.owner_id = u.id
                WHERE a.breed LIKE ?
                ORDER BY a.created_at DESC
            """
        
        df = pd.read_sql_query(query, conn, params=[f"%{search_term}%"])
        conn.close()
        return df
    except Exception as e:
        st.error(f"검색 실패: {str(e)}")
        return pd.DataFrame()

# 체중 기록 추가
def add_weight_record(animal_id, weight, measurement_date, notes):
    """체중 기록 추가"""
    try:
        conn = sqlite3.connect("cnucnm_data/cnucnm.db")
        cursor = conn.cursor()
        
        # 체중 기록 추가
        cursor.execute("""
            INSERT INTO weight_records (animal_id, weight, measurement_date, notes)
            VALUES (?, ?, ?, ?)
        """, (animal_id, weight, measurement_date, notes))
        
        # 현재 체중 업데이트
        cursor.execute("""
            UPDATE animals SET current_weight = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        """, (weight, animal_id))
        
        conn.commit()
        conn.close()
        return True, "체중 기록이 추가되었습니다."
    except Exception as e:
        return False, f"체중 기록 추가 실패: {str(e)}"

# 체중 기록 조회
def get_weight_records(animal_id):
    """체중 기록 조회"""
    try:
        conn = sqlite3.connect("cnucnm_data/cnucnm.db")
        query = """
            SELECT measurement_date, weight, notes
            FROM weight_records
            WHERE animal_id = ?
            ORDER BY measurement_date
        """
        df = pd.read_sql_query(query, conn, params=[animal_id])
        conn.close()
        return df
    except Exception as e:
        st.error(f"체중 기록 조회 실패: {str(e)}")
        return pd.DataFrame()

# 동물 통계
def get_animal_statistics():
    """동물 통계 정보"""
    try:
        conn = sqlite3.connect("cnucnm_data/cnucnm.db")
        cursor = conn.cursor()
        
        # 전체 동물 수
        cursor.execute("SELECT COUNT(*) FROM animals")
        total_animals = cursor.fetchone()[0]
        
        # 종별 동물 수
        cursor.execute("SELECT species, COUNT(*) FROM animals GROUP BY species")
        species_counts = dict(cursor.fetchall())
        
        # 성별 동물 수
        cursor.execute("SELECT gender, COUNT(*) FROM animals GROUP BY gender")
        gender_counts = dict(cursor.fetchall())
        
        # 활성 동물 수
        cursor.execute("SELECT COUNT(*) FROM animals WHERE status = 'active'")
        active_animals = cursor.fetchone()[0]
        
        # 평균 체중
        cursor.execute("SELECT AVG(current_weight) FROM animals WHERE current_weight > 0")
        avg_weight = cursor.fetchone()[0] or 0
        
        conn.close()
        
        return {
            'total_animals': total_animals,
            'species_counts': species_counts,
            'gender_counts': gender_counts,
            'active_animals': active_animals,
            'avg_weight': avg_weight
        }
    except Exception as e:
        st.error(f"통계 조회 실패: {str(e)}")
        return {}

# 메인 앱
def main():
    # 페이지 설정
    st.set_page_config(
        page_title="CNUCNM 동물 관리 시스템",
        page_icon="🐄",
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    # 사이드바
    st.sidebar.title("🐄 CNUCNM")
    st.sidebar.markdown("### 동물 관리 시스템")
    
    # 메뉴 선택
    menu = st.sidebar.selectbox(
        "메뉴 선택",
        ["🏠 대시보드", "🐄 동물 등록", "📋 동물 목록", "🔍 동물 검색", 
         "⚖️ 체중 관리", "📊 통계", "⚙️ 설정"]
    )
    
    # 데이터베이스 초기화
    if not Path("cnucnm_data/cnucnm.db").exists():
        with st.spinner("데이터베이스를 초기화하는 중..."):
            init_animal_database()
        st.success("데이터베이스가 성공적으로 초기화되었습니다!")
    
    # 메뉴별 페이지
    if menu == "🏠 대시보드":
        show_dashboard()
    elif menu == "🐄 동물 등록":
        show_animal_registration()
    elif menu == "📋 동물 목록":
        show_animal_list()
    elif menu == "🔍 동물 검색":
        show_animal_search()
    elif menu == "⚖️ 체중 관리":
        show_weight_management()
    elif menu == "📊 통계":
        show_statistics()
    elif menu == "⚙️ 설정":
        show_settings()

def show_dashboard():
    """대시보드 페이지"""
    st.title("🏠 CNUCNM 동물 관리 대시보드")
    
    # 통계 정보
    stats = get_animal_statistics()
    
    if stats:
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric("전체 동물", stats['total_animals'])
        
        with col2:
            st.metric("활성 동물", stats['active_animals'])
        
        with col3:
            st.metric("평균 체중", f"{stats['avg_weight']:.1f}kg")
        
        with col4:
            st.metric("한우 수", stats['species_counts'].get('한우', 0))
        
        # 종별 분포
        st.subheader("📊 종별 동물 분포")
        if stats['species_counts']:
            species_df = pd.DataFrame(list(stats['species_counts'].items()), 
                                    columns=['종', '마리 수'])
            st.bar_chart(species_df.set_index('종'))
        
        # 성별 분포
        st.subheader("👥 성별 분포")
        if stats['gender_counts']:
            gender_df = pd.DataFrame(list(stats['gender_counts'].items()), 
                                   columns=['성별', '마리 수'])
            st.bar_chart(gender_df.set_index('성별'))
    
    # 최근 등록된 동물
    st.subheader("🐄 최근 등록된 동물")
    animals_df = get_animals()
    if not animals_df.empty:
        recent_animals = animals_df.head(5)[['animal_id', 'name', 'species', 'breed', 'current_weight']]
        st.dataframe(recent_animals, use_container_width=True)

def show_animal_registration():
    """동물 등록 페이지"""
    st.title("🐄 동물 등록")
    
    with st.form("animal_registration"):
        st.subheader("기본 정보")
        col1, col2 = st.columns(2)
        
        with col1:
            animal_id = st.text_input("동물 ID *", placeholder="ANM001")
            name = st.text_input("이름", placeholder="황소1")
            species = st.selectbox("종 *", ["한우", "홀스타인", "젖소", "육우", "기타"])
            breed = st.text_input("품종", placeholder="한우")
        
        with col2:
            gender = st.selectbox("성별 *", ["수", "암"])
            birth_date = st.date_input("생년월일", value=date.today())
            initial_weight = st.number_input("초기 체중 (kg) *", min_value=0.0, value=300.0, step=10.0)
            farm_location = st.text_input("사육 위치", placeholder="A구역")
        
        notes = st.text_area("비고", placeholder="추가 정보를 입력하세요...")
        
        submitted = st.form_submit_button("동물 등록")
        
        if submitted:
            if not animal_id:
                st.error("동물 ID를 입력해주세요.")
            else:
                success, message = register_animal(
                    animal_id, name, species, breed, gender, birth_date,
                    initial_weight, 1, farm_location, notes  # owner_id는 1로 고정
                )
                
                if success:
                    st.success(message)
                    st.balloons()
                else:
                    st.error(message)

def show_animal_list():
    """동물 목록 페이지"""
    st.title("📋 동물 목록")
    
    # 필터링 옵션
    col1, col2 = st.columns(2)
    with col1:
        species_filter = st.selectbox("종 필터", ["전체", "한우", "홀스타인", "젖소", "육우", "기타"])
    with col2:
        status_filter = st.selectbox("상태 필터", ["전체", "active", "inactive"])
    
    # 동물 목록 조회
    animals_df = get_animals()
    
    if not animals_df.empty:
        # 필터링 적용
        if species_filter != "전체":
            animals_df = animals_df[animals_df['species'] == species_filter]
        if status_filter != "전체":
            animals_df = animals_df[animals_df['status'] == status_filter]
        
        # 표시할 컬럼 선택
        display_columns = ['animal_id', 'name', 'species', 'breed', 'gender', 
                          'current_weight', 'farm_location', 'owner_name']
        display_df = animals_df[display_columns].copy()
        
        # 컬럼명 한글화
        display_df.columns = ['동물ID', '이름', '종', '품종', '성별', '현재체중(kg)', '사육위치', '소유자']
        
        st.dataframe(display_df, use_container_width=True)
        
        # 다운로드 버튼
        csv = display_df.to_csv(index=False, encoding='utf-8-sig')
        st.download_button(
            label="📥 CSV 다운로드",
            data=csv,
            file_name=f"cnucnm_animals_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
            mime="text/csv"
        )
    else:
        st.info("등록된 동물이 없습니다.")

def show_animal_search():
    """동물 검색 페이지"""
    st.title("🔍 동물 검색")
    
    col1, col2 = st.columns([3, 1])
    
    with col1:
        search_term = st.text_input("검색어 입력", placeholder="검색할 내용을 입력하세요...")
    
    with col2:
        search_by = st.selectbox("검색 기준", ["동물ID", "이름", "종", "품종"])
    
    if st.button("🔍 검색") and search_term:
        with st.spinner("검색 중..."):
            results_df = search_animals(search_term, search_by)
            
            if not results_df.empty:
                st.success(f"{len(results_df)}마리의 동물을 찾았습니다.")
                
                # 표시할 컬럼 선택
                display_columns = ['animal_id', 'name', 'species', 'breed', 'gender', 
                                  'current_weight', 'farm_location', 'owner_name']
                display_df = results_df[display_columns].copy()
                display_df.columns = ['동물ID', '이름', '종', '품종', '성별', '현재체중(kg)', '사육위치', '소유자']
                
                st.dataframe(display_df, use_container_width=True)
            else:
                st.warning("검색 결과가 없습니다.")
    elif not search_term:
        st.info("검색어를 입력하고 검색 버튼을 클릭하세요.")

def show_weight_management():
    """체중 관리 페이지"""
    st.title("⚖️ 체중 관리")
    
    # 동물 선택
    animals_df = get_animals()
    if not animals_df.empty:
        animal_options = animals_df[['id', 'animal_id', 'name', 'species']].apply(
            lambda x: f"{x['animal_id']} - {x['name']} ({x['species']})", axis=1
        ).tolist()
        
        selected_animal = st.selectbox("동물 선택", animal_options)
        
        if selected_animal:
            animal_id = animals_df.iloc[animal_options.index(selected_animal)]['id']
            
            # 체중 기록 추가
            st.subheader("📝 체중 기록 추가")
            with st.form("weight_record"):
                col1, col2 = st.columns(2)
                
                with col1:
                    weight = st.number_input("체중 (kg)", min_value=0.0, value=0.0, step=0.1)
                    measurement_date = st.date_input("측정일", value=date.today())
                
                with col2:
                    notes = st.text_area("비고", placeholder="특이사항을 입력하세요...")
                
                submitted = st.form_submit_button("체중 기록 추가")
                
                if submitted and weight > 0:
                    success, message = add_weight_record(animal_id, weight, measurement_date, notes)
                    if success:
                        st.success(message)
                    else:
                        st.error(message)
            
            # 체중 기록 조회 및 차트
            st.subheader("📊 체중 변화 그래프")
            weight_records = get_weight_records(animal_id)
            
            if not weight_records.empty:
                # Plotly 차트 생성
                fig = px.line(weight_records, x='measurement_date', y='weight',
                            title=f"{selected_animal} 체중 변화",
                            markers=True)
                fig.update_layout(xaxis_title="날짜", yaxis_title="체중 (kg)")
                st.plotly_chart(fig, use_container_width=True)
                
                # 체중 기록 테이블
                st.subheader("📋 체중 기록 목록")
                st.dataframe(weight_records, use_container_width=True)
            else:
                st.info("체중 기록이 없습니다.")
    else:
        st.info("등록된 동물이 없습니다.")

def show_statistics():
    """통계 페이지"""
    st.title("📊 동물 통계")
    
    stats = get_animal_statistics()
    
    if stats:
        # 주요 지표
        st.subheader("📈 주요 지표")
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric("전체 동물", stats['total_animals'])
        
        with col2:
            st.metric("활성 동물", stats['active_animals'])
        
        with col3:
            st.metric("평균 체중", f"{stats['avg_weight']:.1f}kg")
        
        with col4:
            inactive_animals = stats['total_animals'] - stats['active_animals']
            st.metric("비활성 동물", inactive_animals)
        
        # 종별 분포
        st.subheader("🐄 종별 분포")
        if stats['species_counts']:
            species_df = pd.DataFrame(list(stats['species_counts'].items()), 
                                    columns=['종', '마리 수'])
            
            col1, col2 = st.columns(2)
            
            with col1:
                st.bar_chart(species_df.set_index('종'))
            
            with col2:
                st.dataframe(species_df, use_container_width=True)
        
        # 성별 분포
        st.subheader("👥 성별 분포")
        if stats['gender_counts']:
            gender_df = pd.DataFrame(list(stats['gender_counts'].items()), 
                                   columns=['성별', '마리 수'])
            
            col1, col2 = st.columns(2)
            
            with col1:
                st.bar_chart(gender_df.set_index('성별'))
            
            with col2:
                st.dataframe(gender_df, use_container_width=True)
        
        # 동물 목록 (전체)
        st.subheader("📋 전체 동물 목록")
        animals_df = get_animals()
        if not animals_df.empty:
            st.dataframe(animals_df, use_container_width=True)

def show_settings():
    """설정 페이지"""
    st.title("⚙️ 설정")
    
    st.subheader("데이터베이스 정보")
    
    db_path = Path("cnucnm_data/cnucnm.db")
    if db_path.exists():
        st.success(f"✅ 데이터베이스 위치: {db_path.absolute()}")
        
        # 데이터베이스 크기
        size_mb = db_path.stat().st_size / (1024 * 1024)
        st.info(f"📊 데이터베이스 크기: {size_mb:.2f} MB")
        
        # 마지막 수정 시간
        mtime = datetime.fromtimestamp(db_path.stat().st_mtime)
        st.info(f"🕒 마지막 수정: {mtime.strftime('%Y-%m-%d %H:%M:%S')}")
    else:
        st.error("❌ 데이터베이스 파일을 찾을 수 없습니다.")
    
    st.subheader("시스템 정보")
    st.info(f"🐍 Python 버전: {pd.__version__}")
    st.info(f"📁 작업 디렉토리: {Path.cwd()}")
    
    # 데이터베이스 재초기화
    st.subheader("데이터베이스 관리")
    if st.button("🔄 데이터베이스 재초기화"):
        with st.spinner("데이터베이스를 재초기화하는 중..."):
            init_animal_database()
        st.success("데이터베이스가 성공적으로 재초기화되었습니다!")

if __name__ == "__main__":
    main()
