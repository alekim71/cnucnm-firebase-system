"""
사용자 관리 서비스 메인 애플리케이션 (로컬 개발용)
"""
import sys
import os
from pathlib import Path

# 프로젝트 루트를 Python 경로에 추가
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import logging
import sqlite3

from app.api.v1.api import api_router

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """애플리케이션 생명주기 관리"""
    # 시작 시
    logger.info("사용자 관리 서비스 시작 중...")
    
    # SQLite 데이터베이스 연결 테스트
    try:
        db_path = Path("data/cnucnm.db")
        if not db_path.exists():
            logger.warning("SQLite 데이터베이스가 존재하지 않습니다. run_local.py를 먼저 실행하세요.")
        else:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            conn.close()
            logger.info("SQLite 데이터베이스 연결 성공")
        
    except Exception as e:
        logger.error(f"데이터베이스 연결 실패: {e}")
        raise
    
    logger.info("사용자 관리 서비스 시작 완료")
    
    yield
    
    # 종료 시
    logger.info("사용자 관리 서비스 종료 중...")
    logger.info("사용자 관리 서비스 종료 완료")

def create_application() -> FastAPI:
    """FastAPI 애플리케이션 생성"""
    
    # FastAPI 인스턴스 생성
    app = FastAPI(
        title="CNUCNM User Management Service (Local)",
        description="사용자 관리 마이크로서비스 - 로컬 개발용",
        version="1.0.0",
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
        lifespan=lifespan
    )
    
    # CORS 미들웨어 설정
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # API 라우터 등록
    app.include_router(api_router, prefix="/api/v1")
    
    # 헬스 체크 엔드포인트
    @app.get("/health", tags=["Health"])
    async def health_check():
        """헬스 체크 엔드포인트"""
        try:
            # SQLite 데이터베이스 연결 확인
            db_path = Path("data/cnucnm.db")
            if db_path.exists():
                conn = sqlite3.connect(db_path)
                cursor = conn.cursor()
                cursor.execute("SELECT 1")
                conn.close()
                
                return {
                    "status": "healthy",
                    "service": "user-management",
                    "version": "1.0.0",
                    "environment": "local",
                    "database": "sqlite"
                }
            else:
                return {
                    "status": "warning",
                    "service": "user-management",
                    "version": "1.0.0",
                    "environment": "local",
                    "database": "sqlite",
                    "message": "Database file not found"
                }
        except Exception as e:
            logger.error(f"헬스 체크 실패: {e}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Service unhealthy"
            )
    
    # 루트 엔드포인트
    @app.get("/", tags=["Root"])
    async def root():
        """루트 엔드포인트"""
        return {
            "message": "CNUCNM User Management Service (Local)",
            "version": "1.0.0",
            "docs": "/docs",
            "environment": "local"
        }
    
    # 메타데이터 엔드포인트
    @app.get("/metadata", tags=["Metadata"])
    async def get_metadata():
        """서비스 메타데이터"""
        return {
            "service": "user-management",
            "version": "1.0.0",
            "environment": "local",
            "database": "sqlite",
            "features": [
                "user_registration",
                "user_authentication",
                "profile_management",
                "role_based_access_control",
                "email_verification",
                "phone_verification",
                "password_reset",
                "user_activity_logging"
            ]
        }
    
    return app

# 애플리케이션 인스턴스 생성
app = create_application()

if __name__ == "__main__":
    # 개발 환경에서 직접 실행
    uvicorn.run(
        "main_local:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info",
        access_log=True
    )
