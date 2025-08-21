"""
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
