"""
사용자 관리 서비스 메인 애플리케이션
"""
import sys
import os
from pathlib import Path

# 프로젝트 루트를 Python 경로에 추가
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from contextlib import asynccontextmanager
import uvicorn
import logging

from shared.common.config import settings, get_settings
from shared.common.database import db_manager
from app.api.v1.api import api_router
from app.core.security import create_access_token
from app.core.logging import setup_logging

# 로깅 설정
setup_logging()
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """애플리케이션 생명주기 관리"""
    # 시작 시
    logger.info("사용자 관리 서비스 시작 중...")
    
    # 데이터베이스 연결 테스트
    try:
        # PostgreSQL 연결 테스트
        engine = db_manager.get_postgres_engine()
        with engine.connect() as conn:
            conn.execute("SELECT 1")
        logger.info("PostgreSQL 연결 성공")
        
        # Redis 연결 테스트
        redis_client = db_manager.get_redis_client()
        redis_client.ping()
        logger.info("Redis 연결 성공")
        
    except Exception as e:
        logger.error(f"데이터베이스 연결 실패: {e}")
        raise
    
    logger.info("사용자 관리 서비스 시작 완료")
    
    yield
    
    # 종료 시
    logger.info("사용자 관리 서비스 종료 중...")
    db_manager.close_connections()
    logger.info("사용자 관리 서비스 종료 완료")

def create_application() -> FastAPI:
    """FastAPI 애플리케이션 생성"""
    
    # FastAPI 인스턴스 생성
    app = FastAPI(
        title="CNUCNM User Management Service",
        description="사용자 관리 마이크로서비스",
        version="1.0.0",
        docs_url="/docs" if settings.DEBUG else None,
        redoc_url="/redoc" if settings.DEBUG else None,
        openapi_url="/openapi.json" if settings.DEBUG else None,
        lifespan=lifespan
    )
    
    # CORS 미들웨어 설정
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=settings.CORS_ALLOW_CREDENTIALS,
        allow_methods=settings.CORS_ALLOW_METHODS,
        allow_headers=settings.CORS_ALLOW_HEADERS,
    )
    
    # Trusted Host 미들웨어 (프로덕션 환경)
    if settings.ENVIRONMENT == "production":
        app.add_middleware(
            TrustedHostMiddleware,
            allowed_hosts=["*"]  # 실제 운영 시에는 구체적인 호스트 지정
        )
    
    # API 라우터 등록
    app.include_router(api_router, prefix="/api/v1")
    
    # 헬스 체크 엔드포인트
    @app.get("/health", tags=["Health"])
    async def health_check():
        """헬스 체크 엔드포인트"""
        try:
            # 데이터베이스 연결 확인
            engine = db_manager.get_postgres_engine()
            with engine.connect() as conn:
                conn.execute("SELECT 1")
            
            redis_client = db_manager.get_redis_client()
            redis_client.ping()
            
            return {
                "status": "healthy",
                "service": "user-management",
                "version": settings.APP_VERSION,
                "environment": settings.ENVIRONMENT
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
            "message": "CNUCNM User Management Service",
            "version": settings.APP_VERSION,
            "docs": "/docs" if settings.DEBUG else None
        }
    
    # 메타데이터 엔드포인트
    @app.get("/metadata", tags=["Metadata"])
    async def get_metadata():
        """서비스 메타데이터"""
        return {
            "service": "user-management",
            "version": settings.APP_VERSION,
            "environment": settings.ENVIRONMENT,
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
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower(),
        access_log=True
    )
