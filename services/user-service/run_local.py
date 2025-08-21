#!/usr/bin/env python3
"""
로컬 개발 환경 실행 스크립트
Docker 없이도 사용자 관리 서비스를 실행할 수 있습니다.
"""
import os
import sys
import subprocess
import time
import sqlite3
from pathlib import Path

def check_python_version():
    """Python 버전 확인"""
    if sys.version_info < (3, 8):
        print("❌ Python 3.8 이상이 필요합니다.")
        sys.exit(1)
    print(f"✅ Python {sys.version_info.major}.{sys.version_info.minor} 확인됨")

def install_dependencies():
    """의존성 설치"""
    print("📦 의존성 설치 중...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
        print("✅ 의존성 설치 완료")
    except subprocess.CalledProcessError as e:
        print(f"❌ 의존성 설치 실패: {e}")
        sys.exit(1)

def setup_sqlite_database():
    """SQLite 데이터베이스 설정"""
    print("🗄️ SQLite 데이터베이스 설정 중...")
    
    # 데이터베이스 디렉토리 생성
    db_dir = Path("data")
    db_dir.mkdir(exist_ok=True)
    
    db_path = db_dir / "cnucnm.db"
    
    # SQLite 데이터베이스 생성 및 테이블 생성
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
            status TEXT DEFAULT 'pending',
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
    
    # 사용자 세션 테이블 생성
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            session_token TEXT UNIQUE NOT NULL,
            refresh_token TEXT UNIQUE NOT NULL,
            ip_address TEXT,
            user_agent TEXT,
            device_type TEXT,
            expires_at TIMESTAMP NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            is_active BOOLEAN DEFAULT 1
        )
    ''')
    
    # 사용자 인증 테이블 생성
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_verifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            verification_type TEXT NOT NULL,
            verification_token TEXT UNIQUE NOT NULL,
            target TEXT NOT NULL,
            is_used BOOLEAN DEFAULT 0,
            expires_at TIMESTAMP NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            used_at TIMESTAMP
        )
    ''')
    
    # 사용자 활동 로그 테이블 생성
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_activities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            activity_type TEXT NOT NULL,
            description TEXT,
            ip_address TEXT,
            user_agent TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 관리자 계정 생성
    cursor.execute('''
        INSERT OR IGNORE INTO users (
            email, username, hashed_password, role, status, 
            is_email_verified, is_active, first_name, last_name
        ) VALUES (
            'admin@cnucnm.com', 'admin', 
            '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.iK8i', -- password: Admin123!
            'admin', 'active', 1, 1, '관리자', '시스템'
        )
    ''')
    
    conn.commit()
    conn.close()
    
    print(f"✅ SQLite 데이터베이스 설정 완료: {db_path}")
    return str(db_path)

def create_env_file():
    """환경 변수 파일 생성"""
    print("⚙️ 환경 변수 파일 생성 중...")
    
    env_content = """# CNUCNM 사용자 관리 서비스 로컬 개발 환경

# 기본 설정
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=INFO

# 서버 설정
HOST=0.0.0.0
PORT=8000

# SQLite 데이터베이스 설정
DATABASE_URL=sqlite:///data/cnucnm.db

# JWT 설정
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS 설정
CORS_ORIGINS=["http://localhost:3000","http://localhost:8080"]
CORS_ALLOW_CREDENTIALS=true
CORS_ALLOW_METHODS=["GET","POST","PUT","DELETE","OPTIONS"]
CORS_ALLOW_HEADERS=["*"]

# 보안 설정
PASSWORD_MIN_LENGTH=8
PASSWORD_REQUIRE_UPPERCASE=true
PASSWORD_REQUIRE_LOWERCASE=true
PASSWORD_REQUIRE_DIGIT=true
PASSWORD_REQUIRE_SPECIAL=true

# 비즈니스 로직 설정
DEFAULT_PAGE_SIZE=20
MAX_PAGE_SIZE=100

# NASEM 설정
NASEM_VERSION=2024
"""
    
    with open(".env", "w", encoding="utf-8") as f:
        f.write(env_content)
    
    print("✅ 환경 변수 파일 생성 완료")

def update_database_config():
    """데이터베이스 설정 업데이트"""
    print("🔧 데이터베이스 설정 업데이트 중...")
    
    # SQLite용 데이터베이스 설정 파일 생성
    db_config_content = '''"""
SQLite 데이터베이스 설정
"""
import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# SQLite 데이터베이스 URL
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///data/cnucnm.db")

# SQLite 엔진 생성
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False}  # SQLite용 설정
)

# 세션 팩토리 생성
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base 클래스
Base = declarative_base()

def get_db():
    """데이터베이스 세션 반환"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
'''
    
    with open("app/database.py", "w", encoding="utf-8") as f:
        f.write(db_config_content)
    
    print("✅ 데이터베이스 설정 업데이트 완료")

def start_server():
    """서버 시작"""
    print("🚀 서버 시작 중...")
    print("📊 서비스 접속 정보:")
    print("  - API 문서: http://localhost:8000/docs")
    print("  - ReDoc: http://localhost:8000/redoc")
    print("  - 헬스 체크: http://localhost:8000/health")
    print("")
    print("🔑 기본 관리자 계정:")
    print("  - 이메일: admin@cnucnm.com")
    print("  - 비밀번호: Admin123!")
    print("")
    print("🛑 서버 중지: Ctrl+C")
    print("-" * 50)
    
    try:
        subprocess.run([
            sys.executable, "-m", "uvicorn", 
            "app.main:app", 
            "--host", "0.0.0.0", 
            "--port", "8000", 
            "--reload"
        ])
    except KeyboardInterrupt:
        print("\n👋 서버가 중지되었습니다.")

def main():
    """메인 실행 함수"""
    print("🎯 CNUCNM 사용자 관리 서비스 - 로컬 개발 환경")
    print("=" * 50)
    
    # Python 버전 확인
    check_python_version()
    
    # 의존성 설치
    install_dependencies()
    
    # SQLite 데이터베이스 설정
    setup_sqlite_database()
    
    # 환경 변수 파일 생성
    create_env_file()
    
    # 데이터베이스 설정 업데이트
    update_database_config()
    
    # 서버 시작
    start_server()

if __name__ == "__main__":
    main()
