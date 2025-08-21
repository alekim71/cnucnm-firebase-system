#!/usr/bin/env python3
"""
CNUCNM Firebase 기반 동물 관리 시스템
Firebase Realtime Database + Authentication 사용
"""

import streamlit as st
import firebase_admin
from firebase_admin import credentials, db, auth
import pandas as pd
from datetime import datetime, date
import json
from pathlib import Path

# Firebase 초기화
def init_firebase():
    """Firebase 초기화"""
    try:
        # 실제 Firebase 설정 정보
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

# 사용자 인증
def authenticate_user(email, password):
    """사용자 인증"""
    try:
        user = auth.get_user_by_email(email)
        return True, user
    except:
        return False, None

# 동물 등록
def register_animal_firebase(animal_data):
    """Firebase에 동물 등록"""
    try:
        ref = db.reference('animals')
        animal_data['created_at'] = datetime.now().isoformat()
        animal_data['updated_at'] = datetime.now().isoformat()
        
        # 동물 ID 중복 확인
        existing = ref.order_by_child('animal_id').equal_to(animal_data['animal_id']).get()
        if existing:
            return False, "동물 ID가 이미 존재합니다."
        
        # 동물 등록
        new_animal = ref.push(animal_data)
        
        # 체중 기록도 추가
        weight_data = {
            'animal_id': new_animal.key,
            'weight': animal_data['initial_weight'],
            'measurement_date': date.today().isoformat(),
            'notes': '초기 체중',
            'created_at': datetime.now().isoformat()
        }
        
        weight_ref = db.reference('weight_records')
        weight_ref.push(weight_data)
        
        return True, "동물이 성공적으로 등록되었습니다."
    except Exception as e:
        return False, f"등록 실패: {str(e)}"

# 동물 목록 조회
def get_animals_firebase():
    """Firebase에서 동물 목록 조회"""
    try:
        ref = db.reference('animals')
        animals = ref.get()
        
        if animals:
            # 딕셔너리를 DataFrame으로 변환
            animals_list = []
            for key, value in animals.items():
                value['id'] = key
                animals_list.append(value)
            
            df = pd.DataFrame(animals_list)
            return df
        else:
            return pd.DataFrame()
    except Exception as e:
        st.error(f"동물 목록 조회 실패: {str(e)}")
        return pd.DataFrame()

# 체중 기록 추가
def add_weight_record_firebase(animal_id, weight, measurement_date, notes):
    """Firebase에 체중 기록 추가"""
    try:
        weight_data = {
            'animal_id': animal_id,
            'weight': weight,
            'measurement_date': measurement_date.isoformat(),
            'notes': notes,
            'created_at': datetime.now().isoformat()
        }
        
        ref = db.reference('weight_records')
        ref.push(weight_data)
        
        # 동물의 현재 체중 업데이트
        animal_ref = db.reference(f'animals/{animal_id}')
        animal_ref.update({
            'current_weight': weight,
            'updated_at': datetime.now().isoformat()
        })
        
        return True, "체중 기록이 추가되었습니다."
    except Exception as e:
        return False, f"체중 기록 추가 실패: {str(e)}"

# 체중 기록 조회
def get_weight_records_firebase(animal_id):
    """Firebase에서 체중 기록 조회"""
    try:
        ref = db.reference('weight_records')
        records = ref.order_by_child('animal_id').equal_to(animal_id).get()
        
        if records:
            records_list = []
            for key, value in records.items():
                records_list.append(value)
            
            df = pd.DataFrame(records_list)
            return df
        else:
            return pd.DataFrame()
    except Exception as e:
        st.error(f"체중 기록 조회 실패: {str(e)}")
        return pd.DataFrame()

# 메인 앱
def main():
    # 페이지 설정
    st.set_page_config(
        page_title="CNUCNM Firebase 동물 관리",
        page_icon="🔥",
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    # Firebase 초기화
    if not firebase_admin._apps:
        if not init_firebase():
            st.error("Firebase 초기화에 실패했습니다. 설정을 확인해주세요.")
            return
    
    # 사이드바
    st.sidebar.title("🔥 CNUCNM Firebase")
    st.sidebar.markdown("### 동물 관리 시스템")
    
    # 메뉴 선택
    menu = st.sidebar.selectbox(
        "메뉴 선택",
        ["🏠 대시보드", "🐄 동물 등록", "📋 동물 목록", "⚖️ 체중 관리", "📊 통계", "⚙️ 설정"]
    )
    
    # 메뉴별 페이지
    if menu == "🏠 대시보드":
        show_dashboard()
    elif menu == "🐄 동물 등록":
        show_animal_registration()
    elif menu == "📋 동물 목록":
        show_animal_list()
    elif menu == "⚖️ 체중 관리":
        show_weight_management()
    elif menu == "📊 통계":
        show_statistics()
    elif menu == "⚙️ 설정":
        show_settings()

def show_dashboard():
    """대시보드 페이지"""
    st.title("🏠 CNUCNM Firebase 동물 관리 대시보드")
    
    # Firebase 연결 상태
    st.success("✅ Firebase 연결됨")
    
    # 동물 통계
    animals_df = get_animals_firebase()
    
    if not animals_df.empty:
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric("전체 동물", len(animals_df))
        
        with col2:
            active_animals = len(animals_df[animals_df['status'] == 'active'])
            st.metric("활성 동물", active_animals)
        
        with col3:
            avg_weight = animals_df['current_weight'].mean()
            st.metric("평균 체중", f"{avg_weight:.1f}kg")
        
        with col4:
            hanwoo_count = len(animals_df[animals_df['species'] == '한우'])
            st.metric("한우 수", hanwoo_count)
        
        # 최근 등록된 동물
        st.subheader("🐄 최근 등록된 동물")
        recent_animals = animals_df.head(5)[['animal_id', 'name', 'species', 'breed', 'current_weight']]
        st.dataframe(recent_animals, use_container_width=True)
    else:
        st.info("등록된 동물이 없습니다.")

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
                animal_data = {
                    'animal_id': animal_id,
                    'name': name,
                    'species': species,
                    'breed': breed,
                    'gender': gender,
                    'birth_date': birth_date.isoformat(),
                    'initial_weight': initial_weight,
                    'current_weight': initial_weight,
                    'status': 'active',
                    'owner_id': 1,
                    'farm_location': farm_location,
                    'notes': notes
                }
                
                success, message = register_animal_firebase(animal_data)
                
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
    animals_df = get_animals_firebase()
    
    if not animals_df.empty:
        # 필터링 적용
        if species_filter != "전체":
            animals_df = animals_df[animals_df['species'] == species_filter]
        if status_filter != "전체":
            animals_df = animals_df[animals_df['status'] == status_filter]
        
        # 표시할 컬럼 선택
        display_columns = ['animal_id', 'name', 'species', 'breed', 'gender', 
                          'current_weight', 'farm_location']
        display_df = animals_df[display_columns].copy()
        
        # 컬럼명 한글화
        display_df.columns = ['동물ID', '이름', '종', '품종', '성별', '현재체중(kg)', '사육위치']
        
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

def show_weight_management():
    """체중 관리 페이지"""
    st.title("⚖️ 체중 관리")
    
    # 동물 선택
    animals_df = get_animals_firebase()
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
                    success, message = add_weight_record_firebase(animal_id, weight, measurement_date, notes)
                    if success:
                        st.success(message)
                    else:
                        st.error(message)
            
            # 체중 기록 조회
            st.subheader("📋 체중 기록 목록")
            weight_records = get_weight_records_firebase(animal_id)
            
            if not weight_records.empty:
                st.dataframe(weight_records, use_container_width=True)
            else:
                st.info("체중 기록이 없습니다.")
    else:
        st.info("등록된 동물이 없습니다.")

def show_statistics():
    """통계 페이지"""
    st.title("📊 동물 통계")
    
    animals_df = get_animals_firebase()
    
    if not animals_df.empty:
        # 주요 지표
        st.subheader("📈 주요 지표")
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric("전체 동물", len(animals_df))
        
        with col2:
            active_animals = len(animals_df[animals_df['status'] == 'active'])
            st.metric("활성 동물", active_animals)
        
        with col3:
            avg_weight = animals_df['current_weight'].mean()
            st.metric("평균 체중", f"{avg_weight:.1f}kg")
        
        with col4:
            inactive_animals = len(animals_df) - active_animals
            st.metric("비활성 동물", inactive_animals)
        
        # 종별 분포
        st.subheader("🐄 종별 분포")
        species_counts = animals_df['species'].value_counts()
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.bar_chart(species_counts)
        
        with col2:
            species_df = pd.DataFrame(species_counts).reset_index()
            species_df.columns = ['종', '마리 수']
            st.dataframe(species_df, use_container_width=True)
        
        # 성별 분포
        st.subheader("👥 성별 분포")
        gender_counts = animals_df['gender'].value_counts()
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.bar_chart(gender_counts)
        
        with col2:
            gender_df = pd.DataFrame(gender_counts).reset_index()
            gender_df.columns = ['성별', '마리 수']
            st.dataframe(gender_df, use_container_width=True)
    else:
        st.info("등록된 동물이 없습니다.")

def show_settings():
    """설정 페이지"""
    st.title("⚙️ Firebase 설정")
    
    st.subheader("Firebase 연결 정보")
    st.success("✅ Firebase Realtime Database 연결됨")
    st.info("🔥 프로젝트 ID: cnucnm-project")
    st.info("🌐 데이터베이스 URL: https://cnucnm-project-default-rtdb.firebaseio.com/")
    
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
    pip install firebase-admin streamlit pandas
    ```
    """)

if __name__ == "__main__":
    main()
