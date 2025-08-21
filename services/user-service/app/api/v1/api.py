"""
API 라우터
"""
from fastapi import APIRouter

from app.api.v1.endpoints import auth, users, profile, admin

api_router = APIRouter()

# 인증 관련 엔드포인트
api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])

# 사용자 관리 엔드포인트
api_router.include_router(users.router, prefix="/users", tags=["users"])

# 프로필 관리 엔드포인트
api_router.include_router(profile.router, prefix="/profile", tags=["profile"])

# 관리자 엔드포인트
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
