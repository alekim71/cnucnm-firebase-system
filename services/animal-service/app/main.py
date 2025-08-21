"""
동물 관리 서비스 메인 애플리케이션
"""
import sys
import os
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import logging

from shared.common.config import settings
from shared.common.database import db_manager
from app.api.v1.endpoints import animals
from app.core.logging import setup_logging

@asynccontextmanager
async def lifespan(app: FastAPI):
    """애플리케이션 생명주기 관리"""
    # 시작 시
    setup_logging()
    logger = logging.getLogger(__name__)
    logger.info("동물 관리 서비스 시작 중...")
    
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
    
    yield
    
    # 종료 시
    logger.info("동물 관리 서비스 종료 중...")
    db_manager.close_connections()
    logger.info("동물 관리 서비스가 종료되었습니다.")

def create_application() -> FastAPI:
    """FastAPI 애플리케이션 생성"""
    app = FastAPI(
        title="CNUCNM Animal Management Service",
        description="동물 관리 마이크로서비스",
        version="1.0.0",
        docs_url="/docs" if settings.DEBUG else None,
        redoc_url="/redoc" if settings.DEBUG else None,
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
    
    # API 라우터 포함
    app.include_router(animals.router, prefix="/api/v1/animals", tags=["animals"])
    
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
                "service": "animal-management",
                "version": "1.0.0",
                "database": "connected",
                "cache": "connected"
            }
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"서비스 상태 불량: {str(e)}"
            )
    
    @app.get("/", tags=["Root"])
    async def root():
        """루트 엔드포인트"""
        return {
            "message": "CNUCNM Animal Management Service",
            "version": "1.0.0",
            "docs": "/docs" if settings.DEBUG else None
        }
    
    @app.get("/metadata", tags=["Metadata"])
    async def get_metadata():
        """서비스 메타데이터"""
        return {
            "service_name": "animal-management",
            "version": "1.0.0",
            "description": "동물 관리 마이크로서비스",
            "features": [
                "동물 정보 관리",
                "품종 관리",
                "건강 기록 관리",
                "체중 기록 관리",
                "사료 급여 기록 관리",
                "동물 통계"
            ],
            "supported_animal_types": [
                "dairy_cow", "beef_cattle", "pig", "chicken", 
                "duck", "goat", "sheep", "horse", "other"
            ]
        }
    
    return app

app = create_application()

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower()
    )
