"""
완전히 독립적인 사용자 관리 서비스
"""
from fastapi import FastAPI, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
import logging
import sqlite3
from pathlib import Path
from typing import Optional, List

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Pydantic 모델들
class UserRegister(BaseModel):
    email: str
    username: str
    password: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None

class UserResponse(BaseModel):
    id: int
    email: str
    username: str
    role: str
    status: str
    created_at: str

def create_application() -> FastAPI:
    """FastAPI 애플리케이션 생성"""
    
    app = FastAPI(
        title="CNUCNM User Management Service (Standalone)",
        description="완전히 독립적인 사용자 관리 서비스",
        version="1.0.0",
        docs_url="/docs",
        redoc_url="/redoc"
    )
    
    # CORS 설정
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    @app.get("/", tags=["Root"])
    async def root():
        """루트 엔드포인트"""
        return {
            "message": "CNUCNM User Management Service (Standalone)",
            "version": "1.0.0",
            "docs": "/docs",
            "status": "running"
        }
    
    @app.get("/health", tags=["Health"])
    async def health_check():
        """헬스 체크"""
        try:
            db_path = Path("data/cnucnm.db")
            if db_path.exists():
                conn = sqlite3.connect(db_path)
                cursor = conn.cursor()
                cursor.execute("SELECT COUNT(*) FROM users")
                user_count = cursor.fetchone()[0]
                conn.close()
                
                return {
                    "status": "healthy",
                    "database": "connected",
                    "user_count": user_count,
                    "version": "1.0.0"
                }
            else:
                return {
                    "status": "warning",
                    "database": "not_found",
                    "message": "Database file not found. Run setup first."
                }
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return {
                "status": "unhealthy",
                "error": str(e)
            }
    
    @app.post("/api/v1/auth/register", response_model=dict, tags=["Authentication"])
    async def register_user(user_data: UserRegister):
        """사용자 등록"""
        try:
            db_path = Path("data/cnucnm.db")
            if not db_path.exists():
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Database not initialized. Please run setup first."
                )
            
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            # 중복 확인
            cursor.execute("SELECT id FROM users WHERE email = ? OR username = ?", 
                         (user_data.email, user_data.username))
            if cursor.fetchone():
                conn.close()
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email or username already exists"
                )
            
            # 사용자 생성
            cursor.execute("""
                INSERT INTO users (email, username, hashed_password, first_name, last_name, role, status)
                VALUES (?, ?, ?, ?, ?, 'farmer', 'active')
            """, (user_data.email, user_data.username, f"hashed_{user_data.password}", 
                  user_data.first_name, user_data.last_name))
            
            user_id = cursor.lastrowid
            conn.commit()
            conn.close()
            
            return {
                "message": "User registered successfully",
                "user_id": user_id,
                "email": user_data.email,
                "username": user_data.username
            }
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Registration failed: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Registration failed"
            )
    
    @app.get("/api/v1/users", response_model=dict, tags=["Users"])
    async def get_users(
        limit: int = Query(default=10, le=100),
        offset: int = Query(default=0, ge=0)
    ):
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
            
            # 전체 개수 조회
            cursor.execute("SELECT COUNT(*) FROM users")
            total = cursor.fetchone()[0]
            
            # 사용자 목록 조회
            cursor.execute("""
                SELECT id, email, username, first_name, last_name, role, status, created_at
                FROM users
                ORDER BY created_at DESC
                LIMIT ? OFFSET ?
            """, (limit, offset))
            
            users = []
            for row in cursor.fetchall():
                users.append({
                    "id": row[0],
                    "email": row[1],
                    "username": row[2],
                    "first_name": row[3],
                    "last_name": row[4],
                    "role": row[5],
                    "status": row[6],
                    "created_at": row[7]
                })
            
            conn.close()
            
            return {
                "users": users,
                "total": total,
                "limit": limit,
                "offset": offset
            }
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch users: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to fetch users"
            )
    
    @app.get("/api/v1/users/{user_id}", response_model=dict, tags=["Users"])
    async def get_user(user_id: int):
        """특정 사용자 조회"""
        try:
            db_path = Path("data/cnucnm.db")
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT id, email, username, first_name, last_name, role, status, created_at
                FROM users WHERE id = ?
            """, (user_id,))
            
            row = cursor.fetchone()
            conn.close()
            
            if not row:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="User not found"
                )
            
            return {
                "id": row[0],
                "email": row[1],
                "username": row[2],
                "first_name": row[3],
                "last_name": row[4],
                "role": row[5],
                "status": row[6],
                "created_at": row[7]
            }
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to fetch user: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to fetch user"
            )
    
    @app.get("/setup", tags=["Setup"])
    async def setup_database():
        """데이터베이스 초기 설정"""
        try:
            # 데이터베이스 디렉토리 생성
            db_dir = Path("data")
            db_dir.mkdir(exist_ok=True)
            
            db_path = db_dir / "cnucnm.db"
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
                    status TEXT DEFAULT 'active',
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
            
            # 관리자 계정 생성 (존재하지 않는 경우)
            cursor.execute("SELECT id FROM users WHERE email = 'admin@cnucnm.com'")
            if not cursor.fetchone():
                cursor.execute("""
                    INSERT INTO users (email, username, hashed_password, first_name, last_name, role, status)
                    VALUES ('admin@cnucnm.com', 'admin', 'hashed_Admin123!', 'System', 'Administrator', 'admin', 'active')
                """)
            
            conn.commit()
            conn.close()
            
            return {
                "message": "Database setup completed successfully",
                "database_path": str(db_path),
                "admin_account": {
                    "email": "admin@cnucnm.com",
                    "username": "admin",
                    "password": "Admin123!"
                }
            }
            
        except Exception as e:
            logger.error(f"Database setup failed: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Database setup failed: {str(e)}"
            )
    
    return app

# 애플리케이션 인스턴스
app = create_application()

if __name__ == "__main__":
    uvicorn.run(
        "standalone_server:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )


