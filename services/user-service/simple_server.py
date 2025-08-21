"""
간단한 사용자 관리 서비스 (로컬 개발용)
"""
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import logging
import sqlite3
from pathlib import Path

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_application() -> FastAPI:
    """FastAPI 애플리케이션 생성"""
    
    # FastAPI 인스턴스 생성
    app = FastAPI(
        title="CNUCNM User Management Service (Simple)",
        description="사용자 관리 마이크로서비스 - 간단한 로컬 개발용",
        version="1.0.0",
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json"
    )
    
    # CORS 미들웨어 설정
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
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
            "message": "CNUCNM User Management Service (Simple)",
            "version": "1.0.0",
            "docs": "/docs",
            "environment": "local"
        }
    
    # 사용자 등록 엔드포인트 (간단한 버전)
    @app.post("/api/v1/auth/register", tags=["Authentication"])
    async def register_user(email: str, password: str, username: str):
        """사용자 등록 (간단한 버전)"""
        try:
            db_path = Path("data/cnucnm.db")
            if not db_path.exists():
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Database not found"
                )
            
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            # 사용자 존재 여부 확인
            cursor.execute("SELECT id FROM users WHERE email = ?", (email,))
            if cursor.fetchone():
                conn.close()
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="User already exists"
                )
            
            # 간단한 비밀번호 해싱 (실제로는 bcrypt 사용)
            hashed_password = f"hashed_{password}"
            
            # 사용자 생성
            cursor.execute("""
                INSERT INTO users (email, username, hashed_password, role, status)
                VALUES (?, ?, ?, 'farmer', 'active')
            """, (email, username, hashed_password))
            
            conn.commit()
            conn.close()
            
            return {
                "message": "User registered successfully",
                "email": email,
                "username": username
            }
            
        except Exception as e:
            logger.error(f"사용자 등록 실패: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Registration failed"
            )
    
    # 사용자 목록 조회 엔드포인트
    @app.get("/api/v1/users", tags=["Users"])
    async def get_users():
        """사용자 목록 조회"""
        try:
            db_path = Path("data/cnucnm.db")
            if not db_path.exists():
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Database not found"
                )
            
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT id, email, username, role, status, created_at
                FROM users
                ORDER BY created_at DESC
            """)
            
            users = []
            for row in cursor.fetchall():
                users.append({
                    "id": row[0],
                    "email": row[1],
                    "username": row[2],
                    "role": row[3],
                    "status": row[4],
                    "created_at": row[5]
                })
            
            conn.close()
            
            return {
                "users": users,
                "total": len(users)
            }
            
        except Exception as e:
            logger.error(f"사용자 목록 조회 실패: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to fetch users"
            )
    
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
                "user_listing",
                "health_check",
                "basic_authentication"
            ]
        }
    
    return app

# 애플리케이션 인스턴스 생성
app = create_application()

if __name__ == "__main__":
    # 개발 환경에서 직접 실행
    uvicorn.run(
        "simple_server:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info",
        access_log=True
    )
