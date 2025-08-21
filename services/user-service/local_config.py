"""
로컬 개발용 설정
"""
import os
from pathlib import Path

class LocalSettings:
    """로컬 개발용 설정"""
    
    # 기본 설정
    APP_NAME = "CNUCNM User Management Service"
    APP_VERSION = "1.0.0"
    DEBUG = True
    ENVIRONMENT = "local"
    
    # 서버 설정
    HOST = "0.0.0.0"
    PORT = 8000
    
    # 데이터베이스 설정
    DATABASE_URL = f"sqlite:///{Path('data/cnucnm.db').absolute()}"
    
    # JWT 설정
    SECRET_KEY = "local-development-secret-key-change-in-production"
    ALGORITHM = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES = 30
    
    # CORS 설정
    CORS_ORIGINS = ["*"]
    CORS_ALLOW_CREDENTIALS = True
    CORS_ALLOW_METHODS = ["*"]
    CORS_ALLOW_HEADERS = ["*"]
    
    # 로깅 설정
    LOG_LEVEL = "INFO"

# 전역 설정 인스턴스
settings = LocalSettings()

