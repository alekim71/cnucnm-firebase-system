#!/usr/bin/env python3
"""
CNUCNM 사용자 관리 시스템 - Streamlit 버전
완전히 독립적인 웹 애플리케이션
"""

import streamlit as st
import sqlite3
import pandas as pd
from datetime import datetime
import hashlib
import os
from pathlib import Path

# 페이지 설정
st.set_page_config(
    page_title="CNUCNM 사용자 관리 시스템",
    page_icon="🐄",
    layout="wide",
    initial_sidebar_state="expanded"
)

# 데이터베이스 초기화
def init_database():
    """데이터베이스 초기화"""
    db_path = Path("cnucnm_data/cnucnm.db")
    db_path.parent.mkdir(exist_ok=True)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # 사용자 테이블 생성
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            username TEXT UNIQUE NOT NULL,
            hashed_password TEXT NOT NULL,
            first_name TEXT,
            last_name TEXT,
            phone TEXT,
            role TEXT DEFAULT 'farmer',
            status TEXT DEFAULT 'active',
            farm_name TEXT,
            farm_address TEXT,
            farm_size INTEGER,
            farm_type TEXT,
            is_email_verified BOOLEAN DEFAULT 0,
            is_phone_verified BOOLEAN DEFAULT 0,
            is_active BOOLEAN DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_login_at TIMESTAMP,
            profile_image_url TEXT,
            language TEXT DEFAULT 'ko',
            timezone TEXT DEFAULT 'Asia/Seoul',
            notification_email BOOLEAN DEFAULT 1,
            notification_sms BOOLEAN DEFAULT 0,
            notification_push BOOLEAN DEFAULT 1
        )
    ''')
    
    # 관리자 계정 생성 (존재하지 않는 경우)
    cursor.execute("SELECT id FROM users WHERE email = 'admin@cnucnm.com'")
    if not cursor.fetchone():
        admin_password = hashlib.sha256("Admin123!".encode()).hexdigest()
        cursor.execute("""
            INSERT INTO users (email, username, hashed_password, first_name, last_name, role, status)
            VALUES ('admin@cnucnm.com', 'admin', ?, 'System', 'Administrator', 'admin', 'active')
        """, (admin_password,))
    
    # 샘플 사용자 생성
    cursor.execute("SELECT COUNT(*) FROM users WHERE role = 'farmer'")
    if cursor.fetchone()[0] == 0:
        sample_users = [
            ('farmer1@cnucnm.com', 'farmer1', hashlib.sha256("password123".encode()).hexdigest(), '농부', '김', 'farmer'),
            ('farmer2@cnucnm.com', 'farmer2', hashlib.sha256("password123".encode()).hexdigest(), '목장주', '이', 'farmer'),
            ('vet@cnucnm.com', 'veterinarian', hashlib.sha256("password123".encode()).hexdigest(), '수의사', '박', 'veterinarian')
        ]
        
        for user in sample_users:
            cursor.execute("""
                INSERT INTO users (email, username, hashed_password, first_name, last_name, role, status)
                VALUES (?, ?, ?, ?, ?, ?, 'active')
            """, user)
    
    conn.commit()
    conn.close()
    return db_path

# 데이터베이스 연결
def get_db_connection():
    """데이터베이스 연결"""
    db_path = Path("cnucnm_data/cnucnm.db")
    if not db_path.exists():
        init_database()
    return sqlite3.connect(db_path)

# 사용자 등록
def register_user(email, username, password, first_name, last_name, role, farm_name, farm_address, farm_size, farm_type):
    """사용자 등록"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # 중복 확인
        cursor.execute("SELECT id FROM users WHERE email = ? OR username = ?", (email, username))
        if cursor.fetchone():
            return False, "이메일 또는 사용자명이 이미 존재합니다."
        
        # 비밀번호 해싱
        hashed_password = hashlib.sha256(password.encode()).hexdigest()
        
        # 사용자 생성
        cursor.execute("""
            INSERT INTO users (email, username, hashed_password, first_name, last_name, role, 
                             farm_name, farm_address, farm_size, farm_type, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')
        """, (email, username, hashed_password, first_name, last_name, role, 
              farm_name, farm_address, farm_size, farm_type))
        
        conn.commit()
        conn.close()
        return True, "사용자가 성공적으로 등록되었습니다."
    except Exception as e:
        return False, f"등록 실패: {str(e)}"

# 사용자 목록 조회
def get_users():
    """사용자 목록 조회"""
    try:
        conn = get_db_connection()
        query = """
            SELECT id, email, username, first_name, last_name, role, status, 
                   farm_name, farm_address, farm_size, farm_type, created_at
            FROM users
            ORDER BY created_at DESC
        """
        df = pd.read_sql_query(query, conn)
        conn.close()
        return df
    except Exception as e:
        st.error(f"사용자 목록 조회 실패: {str(e)}")
        return pd.DataFrame()

# 사용자 검색
def search_users(search_term, search_by):
    """사용자 검색"""
    try:
        conn = get_db_connection()
        if search_by == "이메일":
            query = "SELECT * FROM users WHERE email LIKE ? ORDER BY created_at DESC"
        elif search_by == "사용자명":
            query = "SELECT * FROM users WHERE username LIKE ? ORDER BY created_at DESC"
        elif search_by == "이름":
            query = "SELECT * FROM users WHERE first_name LIKE ? OR last_name LIKE ? ORDER BY created_at DESC"
        else:
            query = "SELECT * FROM users WHERE role LIKE ? ORDER BY created_at DESC"
        
        if search_by == "이름":
            df = pd.read_sql_query(query, conn, params=[f"%{search_term}%", f"%{search_term}%"])
        else:
            df = pd.read_sql_query(query, conn, params=[f"%{search_term}%"])
        
        conn.close()
        return df
    except Exception as e:
        st.error(f"검색 실패: {str(e)}")
        return pd.DataFrame()

# 통계 정보
def get_statistics():
    """통계 정보 조회"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # 전체 사용자 수
        cursor.execute("SELECT COUNT(*) FROM users")
        total_users = cursor.fetchone()[0]
        
        # 역할별 사용자 수
        cursor.execute("SELECT role, COUNT(*) FROM users GROUP BY role")
        role_counts = dict(cursor.fetchall())
        
        # 활성 사용자 수
        cursor.execute("SELECT COUNT(*) FROM users WHERE status = 'active'")
        active_users = cursor.fetchone()[0]
        
        # 오늘 가입한 사용자 수
        cursor.execute("SELECT COUNT(*) FROM users WHERE DATE(created_at) = DATE('now')")
        today_users = cursor.fetchone()[0]
        
        conn.close()
        
        return {
            'total_users': total_users,
            'role_counts': role_counts,
            'active_users': active_users,
            'today_users': today_users
        }
    except Exception as e:
        st.error(f"통계 조회 실패: {str(e)}")
        return {}

# 메인 앱
def main():
    # 사이드바
    st.sidebar.title("🐄 CNUCNM")
    st.sidebar.markdown("### 사용자 관리 시스템")
    
    # 메뉴 선택
    menu = st.sidebar.selectbox(
        "메뉴 선택",
        ["🏠 대시보드", "👤 사용자 등록", "📋 사용자 목록", "🔍 사용자 검색", "📊 통계", "⚙️ 설정"]
    )
    
    # 데이터베이스 초기화
    if not Path("cnucnm_data/cnucnm.db").exists():
        with st.spinner("데이터베이스를 초기화하는 중..."):
            init_database()
        st.success("데이터베이스가 성공적으로 초기화되었습니다!")
    
    # 메뉴별 페이지
    if menu == "🏠 대시보드":
        show_dashboard()
    elif menu == "👤 사용자 등록":
        show_user_registration()
    elif menu == "📋 사용자 목록":
        show_user_list()
    elif menu == "🔍 사용자 검색":
        show_user_search()
    elif menu == "📊 통계":
        show_statistics()
    elif menu == "⚙️ 설정":
        show_settings()

def show_dashboard():
    """대시보드 페이지"""
    st.title("🏠 CNUCNM 대시보드")
    st.markdown("### 사용자 관리 시스템에 오신 것을 환영합니다!")
    
    # 통계 정보
    stats = get_statistics()
    
    if stats:
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric("전체 사용자", stats['total_users'])
        
        with col2:
            st.metric("활성 사용자", stats['active_users'])
        
        with col3:
            st.metric("오늘 가입", stats['today_users'])
        
        with col4:
            st.metric("농부 수", stats['role_counts'].get('farmer', 0))
        
        # 역할별 분포
        st.subheader("📊 역할별 사용자 분포")
        if stats['role_counts']:
            role_df = pd.DataFrame(list(stats['role_counts'].items()), columns=['역할', '사용자 수'])
            st.bar_chart(role_df.set_index('역할'))
    
    # 최근 사용자
    st.subheader("👥 최근 등록된 사용자")
    users_df = get_users()
    if not users_df.empty:
        recent_users = users_df.head(5)[['username', 'email', 'role', 'created_at']]
        st.dataframe(recent_users, use_container_width=True)

def show_user_registration():
    """사용자 등록 페이지"""
    st.title("👤 사용자 등록")
    
    with st.form("user_registration"):
        st.subheader("기본 정보")
        col1, col2 = st.columns(2)
        
        with col1:
            email = st.text_input("이메일 *", placeholder="user@example.com")
            username = st.text_input("사용자명 *", placeholder="username")
            password = st.text_input("비밀번호 *", type="password")
            confirm_password = st.text_input("비밀번호 확인 *", type="password")
        
        with col2:
            first_name = st.text_input("이름", placeholder="홍길동")
            last_name = st.text_input("성", placeholder="김")
            phone = st.text_input("전화번호", placeholder="010-1234-5678")
            role = st.selectbox("역할", ["farmer", "veterinarian", "admin", "researcher"])
        
        st.subheader("농장 정보")
        col3, col4 = st.columns(2)
        
        with col3:
            farm_name = st.text_input("농장명", placeholder="행복한 목장")
            farm_address = st.text_input("농장 주소", placeholder="경기도 수원시...")
        
        with col4:
            farm_size = st.number_input("농장 규모 (두)", min_value=0, value=100)
            farm_type = st.selectbox("농장 유형", ["육우", "젖소", "혼합", "기타"])
        
        submitted = st.form_submit_button("사용자 등록")
        
        if submitted:
            if not all([email, username, password, confirm_password]):
                st.error("필수 항목을 모두 입력해주세요.")
            elif password != confirm_password:
                st.error("비밀번호가 일치하지 않습니다.")
            else:
                success, message = register_user(
                    email, username, password, first_name, last_name, role,
                    farm_name, farm_address, farm_size, farm_type
                )
                
                if success:
                    st.success(message)
                    st.balloons()
                else:
                    st.error(message)

def show_user_list():
    """사용자 목록 페이지"""
    st.title("📋 사용자 목록")
    
    # 필터링 옵션
    col1, col2 = st.columns(2)
    with col1:
        role_filter = st.selectbox("역할 필터", ["전체", "farmer", "veterinarian", "admin", "researcher"])
    with col2:
        status_filter = st.selectbox("상태 필터", ["전체", "active", "inactive"])
    
    # 사용자 목록 조회
    users_df = get_users()
    
    if not users_df.empty:
        # 필터링 적용
        if role_filter != "전체":
            users_df = users_df[users_df['role'] == role_filter]
        if status_filter != "전체":
            users_df = users_df[users_df['status'] == status_filter]
        
        # 표시할 컬럼 선택
        display_columns = ['username', 'email', 'first_name', 'last_name', 'role', 'status', 'farm_name', 'created_at']
        display_df = users_df[display_columns].copy()
        
        # 컬럼명 한글화
        display_df.columns = ['사용자명', '이메일', '이름', '성', '역할', '상태', '농장명', '가입일']
        
        st.dataframe(display_df, use_container_width=True)
        
        # 다운로드 버튼
        csv = display_df.to_csv(index=False, encoding='utf-8-sig')
        st.download_button(
            label="📥 CSV 다운로드",
            data=csv,
            file_name=f"cnucnm_users_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
            mime="text/csv"
        )
    else:
        st.info("등록된 사용자가 없습니다.")

def show_user_search():
    """사용자 검색 페이지"""
    st.title("🔍 사용자 검색")
    
    col1, col2 = st.columns([3, 1])
    
    with col1:
        search_term = st.text_input("검색어 입력", placeholder="검색할 내용을 입력하세요...")
    
    with col2:
        search_by = st.selectbox("검색 기준", ["이메일", "사용자명", "이름", "역할"])
    
    if st.button("🔍 검색") and search_term:
        with st.spinner("검색 중..."):
            results_df = search_users(search_term, search_by)
            
            if not results_df.empty:
                st.success(f"{len(results_df)}명의 사용자를 찾았습니다.")
                
                # 표시할 컬럼 선택
                display_columns = ['username', 'email', 'first_name', 'last_name', 'role', 'status', 'farm_name']
                display_df = results_df[display_columns].copy()
                display_df.columns = ['사용자명', '이메일', '이름', '성', '역할', '상태', '농장명']
                
                st.dataframe(display_df, use_container_width=True)
            else:
                st.warning("검색 결과가 없습니다.")
    elif not search_term:
        st.info("검색어를 입력하고 검색 버튼을 클릭하세요.")

def show_statistics():
    """통계 페이지"""
    st.title("📊 통계")
    
    stats = get_statistics()
    
    if stats:
        # 주요 지표
        st.subheader("📈 주요 지표")
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric("전체 사용자", stats['total_users'])
        
        with col2:
            st.metric("활성 사용자", stats['active_users'])
        
        with col3:
            st.metric("오늘 가입", stats['today_users'])
        
        with col4:
            inactive_users = stats['total_users'] - stats['active_users']
            st.metric("비활성 사용자", inactive_users)
        
        # 역할별 분포
        st.subheader("👥 역할별 분포")
        if stats['role_counts']:
            role_df = pd.DataFrame(list(stats['role_counts'].items()), columns=['역할', '사용자 수'])
            
            col1, col2 = st.columns(2)
            
            with col1:
                st.bar_chart(role_df.set_index('역할'))
            
            with col2:
                st.dataframe(role_df, use_container_width=True)
        
        # 사용자 목록 (전체)
        st.subheader("📋 전체 사용자 목록")
        users_df = get_users()
        if not users_df.empty:
            st.dataframe(users_df, use_container_width=True)

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
    st.info(f"🐍 Python 버전: {os.sys.version}")
    st.info(f"📁 작업 디렉토리: {os.getcwd()}")
    
    # 데이터베이스 재초기화
    st.subheader("데이터베이스 관리")
    if st.button("🔄 데이터베이스 재초기화"):
        with st.spinner("데이터베이스를 재초기화하는 중..."):
            init_database()
        st.success("데이터베이스가 성공적으로 재초기화되었습니다!")

if __name__ == "__main__":
    main()


