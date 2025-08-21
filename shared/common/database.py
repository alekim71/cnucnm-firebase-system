"""
공통 데이터베이스 연결 모듈
"""
import os
from typing import Optional
from sqlalchemy import create_engine, Engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import StaticPool
import redis
from pymongo import MongoClient
from elasticsearch import Elasticsearch
import logging

logger = logging.getLogger(__name__)

# SQLAlchemy Base
Base = declarative_base()

class DatabaseManager:
    """데이터베이스 연결 관리자"""
    
    def __init__(self):
        self._postgres_engine: Optional[Engine] = None
        self._postgres_session: Optional[Session] = None
        self._redis_client: Optional[redis.Redis] = None
        self._mongo_client: Optional[MongoClient] = None
        self._elasticsearch_client: Optional[Elasticsearch] = None
        
    def get_postgres_engine(self) -> Engine:
        """PostgreSQL 엔진 반환"""
        if self._postgres_engine is None:
            database_url = os.getenv(
                "DATABASE_URL", 
                "postgresql://cnucnm_user:cnucnm_password@localhost:5432/cnucnm"
            )
            
            # 개발 환경에서는 연결 풀 크기 제한
            if os.getenv("ENVIRONMENT") == "development":
                self._postgres_engine = create_engine(
                    database_url,
                    poolclass=StaticPool,
                    pool_size=10,
                    max_overflow=20,
                    pool_pre_ping=True,
                    echo=os.getenv("SQL_ECHO", "false").lower() == "true"
                )
            else:
                self._postgres_engine = create_engine(
                    database_url,
                    pool_pre_ping=True,
                    echo=os.getenv("SQL_ECHO", "false").lower() == "true"
                )
            
            logger.info("PostgreSQL 엔진 초기화 완료")
            
        return self._postgres_engine
    
    def get_postgres_session(self) -> Session:
        """PostgreSQL 세션 반환"""
        if self._postgres_session is None:
            engine = self.get_postgres_engine()
            SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
            self._postgres_session = SessionLocal()
            
        return self._postgres_session
    
    def get_redis_client(self) -> redis.Redis:
        """Redis 클라이언트 반환"""
        if self._redis_client is None:
            redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
            self._redis_client = redis.from_url(
                redis_url,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5,
                retry_on_timeout=True
            )
            
            # 연결 테스트
            try:
                self._redis_client.ping()
                logger.info("Redis 연결 성공")
            except redis.ConnectionError as e:
                logger.error(f"Redis 연결 실패: {e}")
                raise
                
        return self._redis_client
    
    def get_mongo_client(self) -> MongoClient:
        """MongoDB 클라이언트 반환"""
        if self._mongo_client is None:
            mongo_url = os.getenv(
                "MONGO_URL", 
                "mongodb://cnucnm_admin:cnucnm_password@localhost:27017/cnucnm"
            )
            self._mongo_client = MongoClient(
                mongo_url,
                serverSelectionTimeoutMS=5000,
                connectTimeoutMS=5000,
                socketTimeoutMS=5000
            )
            
            # 연결 테스트
            try:
                self._mongo_client.admin.command('ping')
                logger.info("MongoDB 연결 성공")
            except Exception as e:
                logger.error(f"MongoDB 연결 실패: {e}")
                raise
                
        return self._mongo_client
    
    def get_elasticsearch_client(self) -> Elasticsearch:
        """Elasticsearch 클라이언트 반환"""
        if self._elasticsearch_client is None:
            es_url = os.getenv("ELASTICSEARCH_URL", "http://localhost:9200")
            self._elasticsearch_client = Elasticsearch(
                [es_url],
                timeout=30,
                max_retries=3,
                retry_on_timeout=True
            )
            
            # 연결 테스트
            try:
                if self._elasticsearch_client.ping():
                    logger.info("Elasticsearch 연결 성공")
                else:
                    raise ConnectionError("Elasticsearch ping 실패")
            except Exception as e:
                logger.error(f"Elasticsearch 연결 실패: {e}")
                raise
                
        return self._elasticsearch_client
    
    def close_connections(self):
        """모든 데이터베이스 연결 종료"""
        if self._postgres_session:
            self._postgres_session.close()
            self._postgres_session = None
            
        if self._postgres_engine:
            self._postgres_engine.dispose()
            self._postgres_engine = None
            
        if self._redis_client:
            self._redis_client.close()
            self._redis_client = None
            
        if self._mongo_client:
            self._mongo_client.close()
            self._mongo_client = None
            
        if self._elasticsearch_client:
            self._elasticsearch_client.close()
            self._elasticsearch_client = None
            
        logger.info("모든 데이터베이스 연결 종료")

# 전역 데이터베이스 매니저 인스턴스
db_manager = DatabaseManager()

# 의존성 주입을 위한 함수들
def get_postgres_engine() -> Engine:
    """PostgreSQL 엔진 의존성"""
    return db_manager.get_postgres_engine()

def get_postgres_session() -> Session:
    """PostgreSQL 세션 의존성"""
    return db_manager.get_postgres_session()

def get_redis_client() -> redis.Redis:
    """Redis 클라이언트 의존성"""
    return db_manager.get_redis_client()

def get_mongo_client() -> MongoClient:
    """MongoDB 클라이언트 의존성"""
    return db_manager.get_mongo_client()

def get_elasticsearch_client() -> Elasticsearch:
    """Elasticsearch 클라이언트 의존성"""
    return db_manager.get_elasticsearch_client()
