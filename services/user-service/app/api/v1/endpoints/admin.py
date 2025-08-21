"""
관리자 엔드포인트
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from shared.common.database import get_postgres_session
from app.models.user import User, UserActivity
from app.schemas.user import (
    UserResponse, UserStatusUpdate, UserRoleUpdate, UserListResponse
)
from app.api.v1.endpoints.auth import get_current_user
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)

def get_admin_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """관리자 권한 확인"""
    if current_user.role.value != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="관리자 권한이 필요합니다"
        )
    return current_user

@router.get("/users", response_model=UserListResponse)
async def get_all_users(
    page: int = 1,
    size: int = 20,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_postgres_session)
):
    """모든 사용자 목록 조회 (관리자용)"""
    try:
        query = db.query(User)
        total = query.count()
        
        offset = (page - 1) * size
        users = query.offset(offset).limit(size).all()
        
        pages = (total + size - 1) // size
        
        return UserListResponse(
            users=users,
            total=total,
            page=page,
            size=size,
            pages=pages
        )
        
    except Exception as e:
        logger.error(f"사용자 목록 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="사용자 목록 조회 중 오류가 발생했습니다"
        )

@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user_by_id_admin(
    user_id: int,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_postgres_session)
):
    """사용자 정보 조회 (관리자용)"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="사용자를 찾을 수 없습니다"
        )
    
    return user

@router.put("/users/{user_id}/status")
async def update_user_status(
    user_id: int,
    status_data: UserStatusUpdate,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_postgres_session)
):
    """사용자 상태 업데이트 (관리자용)"""
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="사용자를 찾을 수 없습니다"
            )
        
        # 관리자는 자신의 상태를 변경할 수 없음
        if user.id == admin_user.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="자신의 상태는 변경할 수 없습니다"
            )
        
        old_status = user.status
        user.status = status_data.status
        
        # 활동 로그 기록
        activity = UserActivity(
            user_id=admin_user.id,
            activity_type="admin_user_status_update",
            description=f"사용자 상태 변경: {user.email} ({old_status} -> {status_data.status})"
        )
        db.add(activity)
        
        db.commit()
        
        logger.info(f"사용자 상태 변경: {user.email} ({old_status} -> {status_data.status})")
        
        return {
            "message": "사용자 상태가 업데이트되었습니다",
            "user_id": user.id,
            "old_status": old_status,
            "new_status": status_data.status
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"사용자 상태 변경 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="사용자 상태 변경 중 오류가 발생했습니다"
        )

@router.put("/users/{user_id}/role")
async def update_user_role(
    user_id: int,
    role_data: UserRoleUpdate,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_postgres_session)
):
    """사용자 역할 업데이트 (관리자용)"""
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="사용자를 찾을 수 없습니다"
            )
        
        # 관리자는 자신의 역할을 변경할 수 없음
        if user.id == admin_user.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="자신의 역할은 변경할 수 없습니다"
            )
        
        old_role = user.role
        user.role = role_data.role
        
        # 활동 로그 기록
        activity = UserActivity(
            user_id=admin_user.id,
            activity_type="admin_user_role_update",
            description=f"사용자 역할 변경: {user.email} ({old_role} -> {role_data.role})"
        )
        db.add(activity)
        
        db.commit()
        
        logger.info(f"사용자 역할 변경: {user.email} ({old_role} -> {role_data.role})")
        
        return {
            "message": "사용자 역할이 업데이트되었습니다",
            "user_id": user.id,
            "old_role": old_role,
            "new_role": role_data.role
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"사용자 역할 변경 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="사용자 역할 변경 중 오류가 발생했습니다"
        )

@router.delete("/users/{user_id}")
async def delete_user_admin(
    user_id: int,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_postgres_session)
):
    """사용자 삭제 (관리자용)"""
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="사용자를 찾을 수 없습니다"
            )
        
        # 관리자는 자신을 삭제할 수 없음
        if user.id == admin_user.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="자신을 삭제할 수 없습니다"
            )
        
        # 실제 삭제 대신 비활성화
        user.is_active = False
        user.status = "inactive"
        
        # 활동 로그 기록
        activity = UserActivity(
            user_id=admin_user.id,
            activity_type="admin_user_delete",
            description=f"사용자 삭제: {user.email}"
        )
        db.add(activity)
        
        db.commit()
        
        logger.info(f"관리자에 의한 사용자 삭제: {user.email}")
        
        return {"message": "사용자가 삭제되었습니다"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"사용자 삭제 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="사용자 삭제 중 오류가 발생했습니다"
        )

@router.get("/statistics")
async def get_admin_statistics(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_postgres_session)
):
    """관리자 통계 정보"""
    try:
        # 전체 사용자 수
        total_users = db.query(User).count()
        
        # 활성 사용자 수
        active_users = db.query(User).filter(User.is_active == True).count()
        
        # 역할별 사용자 수
        role_counts = {}
        for role in ["admin", "farmer", "researcher", "consultant", "viewer"]:
            count = db.query(User).filter(User.role == role).count()
            role_counts[role] = count
        
        # 상태별 사용자 수
        status_counts = {}
        for status in ["active", "inactive", "suspended", "pending"]:
            count = db.query(User).filter(User.status == status).count()
            status_counts[status] = count
        
        # 최근 가입자 수 (최근 30일)
        from datetime import datetime, timedelta
        thirty_days_ago = datetime.utcnow() - timedelta(days=30)
        recent_users = db.query(User).filter(
            User.created_at >= thirty_days_ago
        ).count()
        
        return {
            "total_users": total_users,
            "active_users": active_users,
            "role_counts": role_counts,
            "status_counts": status_counts,
            "recent_users": recent_users
        }
        
    except Exception as e:
        logger.error(f"관리자 통계 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="통계 정보 조회 중 오류가 발생했습니다"
        )
