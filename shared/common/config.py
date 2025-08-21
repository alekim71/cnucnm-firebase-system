"""
공통 설정 모듈
"""
import os
from typing import Optional
from pydantic_settings import BaseSettings
from pydantic import Field
from functools import lru_cache

class Settings(BaseSettings):
    """애플리케이션 설정"""
    
    # 기본 설정
    APP_NAME: str = "CNUCNM Microservices"
    APP_VERSION: str = "1.0.0"
    ENVIRONMENT: str = Field(default="development", env="ENVIRONMENT")
    DEBUG: bool = Field(default=True, env="DEBUG")
    
    # 서버 설정
    HOST: str = Field(default="0.0.0.0", env="HOST")
    PORT: int = Field(default=8000, env="PORT")
    
    # 데이터베이스 설정
    DATABASE_URL: str = Field(
        default="postgresql://cnucnm_user:cnucnm_password@localhost:5432/cnucnm",
        env="DATABASE_URL"
    )
    REDIS_URL: str = Field(
        default="redis://localhost:6379",
        env="REDIS_URL"
    )
    MONGO_URL: str = Field(
        default="mongodb://cnucnm_admin:cnucnm_password@localhost:27017/cnucnm",
        env="MONGO_URL"
    )
    ELASTICSEARCH_URL: str = Field(
        default="http://localhost:9200",
        env="ELASTICSEARCH_URL"
    )
    
    # JWT 설정
    SECRET_KEY: str = Field(
        default="your-secret-key-change-in-production",
        env="SECRET_KEY"
    )
    ALGORITHM: str = Field(default="HS256", env="ALGORITHM")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=30, env="ACCESS_TOKEN_EXPIRE_MINUTES")
    REFRESH_TOKEN_EXPIRE_DAYS: int = Field(default=7, env="REFRESH_TOKEN_EXPIRE_DAYS")
    
    # CORS 설정
    CORS_ORIGINS: list = Field(
        default=["http://localhost:3000", "http://localhost:8080"],
        env="CORS_ORIGINS"
    )
    CORS_ALLOW_CREDENTIALS: bool = Field(default=True, env="CORS_ALLOW_CREDENTIALS")
    CORS_ALLOW_METHODS: list = Field(
        default=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        env="CORS_ALLOW_METHODS"
    )
    CORS_ALLOW_HEADERS: list = Field(
        default=["*"],
        env="CORS_ALLOW_HEADERS"
    )
    
    # 로깅 설정
    LOG_LEVEL: str = Field(default="INFO", env="LOG_LEVEL")
    LOG_FORMAT: str = Field(
        default="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        env="LOG_FORMAT"
    )
    
    # 캐시 설정
    CACHE_TTL: int = Field(default=3600, env="CACHE_TTL")  # 1시간
    CACHE_PREFIX: str = Field(default="cnucnm:", env="CACHE_PREFIX")
    
    # 파일 업로드 설정
    MAX_FILE_SIZE: int = Field(default=10 * 1024 * 1024, env="MAX_FILE_SIZE")  # 10MB
    ALLOWED_FILE_TYPES: list = Field(
        default=["jpg", "jpeg", "png", "gif", "pdf", "xlsx", "xls"],
        env="ALLOWED_FILE_TYPES"
    )
    
    # 이메일 설정
    SMTP_HOST: Optional[str] = Field(default=None, env="SMTP_HOST")
    SMTP_PORT: int = Field(default=587, env="SMTP_PORT")
    SMTP_USER: Optional[str] = Field(default=None, env="SMTP_USER")
    SMTP_PASSWORD: Optional[str] = Field(default=None, env="SMTP_PASSWORD")
    SMTP_TLS: bool = Field(default=True, env="SMTP_TLS")
    
    # SMS 설정
    SMS_PROVIDER: Optional[str] = Field(default=None, env="SMS_PROVIDER")
    SMS_API_KEY: Optional[str] = Field(default=None, env="SMS_API_KEY")
    SMS_API_SECRET: Optional[str] = Field(default=None, env="SMS_API_SECRET")
    
    # MinIO 설정
    MINIO_URL: str = Field(default="localhost:9000", env="MINIO_URL")
    MINIO_ACCESS_KEY: str = Field(default="cnucnm_admin", env="MINIO_ACCESS_KEY")
    MINIO_SECRET_KEY: str = Field(default="cnucnm_password", env="MINIO_SECRET_KEY")
    MINIO_BUCKET: str = Field(default="cnucnm-files", env="MINIO_BUCKET")
    MINIO_SECURE: bool = Field(default=False, env="MINIO_SECURE")
    
    # RabbitMQ 설정
    RABBITMQ_URL: str = Field(
        default="amqp://cnucnm_user:cnucnm_password@localhost:5672/",
        env="RABBITMQ_URL"
    )
    
    # 모니터링 설정
    ENABLE_METRICS: bool = Field(default=True, env="ENABLE_METRICS")
    METRICS_PORT: int = Field(default=9090, env="METRICS_PORT")
    
    # 보안 설정
    RATE_LIMIT_PER_MINUTE: int = Field(default=100, env="RATE_LIMIT_PER_MINUTE")
    PASSWORD_MIN_LENGTH: int = Field(default=8, env="PASSWORD_MIN_LENGTH")
    PASSWORD_REQUIRE_UPPERCASE: bool = Field(default=True, env="PASSWORD_REQUIRE_UPPERCASE")
    PASSWORD_REQUIRE_LOWERCASE: bool = Field(default=True, env="PASSWORD_REQUIRE_LOWERCASE")
    PASSWORD_REQUIRE_DIGIT: bool = Field(default=True, env="PASSWORD_REQUIRE_DIGIT")
    PASSWORD_REQUIRE_SPECIAL: bool = Field(default=True, env="PASSWORD_REQUIRE_SPECIAL")
    
    # 비즈니스 로직 설정
    DEFAULT_PAGE_SIZE: int = Field(default=20, env="DEFAULT_PAGE_SIZE")
    MAX_PAGE_SIZE: int = Field(default=100, env="MAX_PAGE_SIZE")
    
    # NASEM 설정
    NASEM_VERSION: str = Field(default="2024", env="NASEM_VERSION")
    
    class Config:
        env_file = ".env"
        case_sensitive = True

@lru_cache()
def get_settings() -> Settings:
    """설정 인스턴스 반환 (캐시됨)"""
    return Settings()

# 전역 설정 인스턴스
settings = get_settings()

def get_database_url() -> str:
    """데이터베이스 URL 반환"""
    return settings.DATABASE_URL

def get_redis_url() -> str:
    """Redis URL 반환"""
    return settings.REDIS_URL

def get_mongo_url() -> str:
    """MongoDB URL 반환"""
    return settings.MONGO_URL

def get_elasticsearch_url() -> str:
    """Elasticsearch URL 반환"""
    return settings.ELASTICSEARCH_URL

def get_secret_key() -> str:
    """시크릿 키 반환"""
    return settings.SECRET_KEY

def is_development() -> bool:
    """개발 환경 여부 확인"""
    return settings.ENVIRONMENT.lower() == "development"

def is_production() -> bool:
    """프로덕션 환경 여부 확인"""
    return settings.ENVIRONMENT.lower() == "production"

def is_testing() -> bool:
    """테스트 환경 여부 확인"""
    return settings.ENVIRONMENT.lower() == "testing"
