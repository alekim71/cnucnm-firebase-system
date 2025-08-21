"""
사용자 관리 엔드포인트
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_

from shared.common.database import get_postgres_session
from app.models.user import User, UserActivity
from app.schemas.user import (
    UserResponse, UserUpdate, UserListResponse, UserSearch,
    UserActivityResponse, UserActivityList
)
from app.api.v1.endpoints.auth import get_current_user
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: User = Depends(get_current_user)
):
    """현재 사용자 정보 조회"""
    return current_user

@router.put("/me", response_model=UserResponse)
async def update_current_user(
    user_data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_postgres_session)
):
    """현재 사용자 정보 업데이트"""
    try:
        # 업데이트할 필드들
        update_data = user_data.dict(exclude_unset=True)
        
        for field, value in update_data.items():
            if hasattr(current_user, field):
                setattr(current_user, field, value)
        
        db.commit()
        db.refresh(current_user)
        
        # 활동 로그 기록
        activity = UserActivity(
            user_id=current_user.id,
            activity_type="profile_update",
            description="프로필 정보 업데이트"
        )
        db.add(activity)
        db.commit()
        
        logger.info(f"사용자 정보 업데이트: {current_user.email}")
        
        return current_user
        
    except Exception as e:
        logger.error(f"사용자 정보 업데이트 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="사용자 정보 업데이트 중 오류가 발생했습니다"
        )

@router.get("/{user_id}", response_model=UserResponse)
async def get_user_by_id(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_postgres_session)
):
    """사용자 ID로 사용자 정보 조회"""
    # 본인 또는 관리자만 조회 가능
    if current_user.id != user_id and current_user.role.value != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="다른 사용자의 정보를 조회할 권한이 없습니다"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="사용자를 찾을 수 없습니다"
        )
    
    return user

@router.get("/", response_model=UserListResponse)
async def get_users(
    search: UserSearch = Depends(),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_postgres_session)
):
    """사용자 목록 조회 (관리자용)"""
    # 관리자만 조회 가능
    if current_user.role.value != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="사용자 목록을 조회할 권한이 없습니다"
        )
    
    try:
        # 쿼리 빌드
        query = db.query(User)
        
        # 검색 조건 적용
        if search.email:
            query = query.filter(User.email.ilike(f"%{search.email}%"))
        
        if search.username:
            query = query.filter(User.username.ilike(f"%{search.username}%"))
        
        if search.role:
            query = query.filter(User.role == search.role)
        
        if search.status:
            query = query.filter(User.status == search.status)
        
        if search.farm_type:
            query = query.filter(User.farm_type.ilike(f"%{search.farm_type}%"))
        
        # 전체 개수 조회
        total = query.count()
        
        # 페이징 적용
        offset = (search.page - 1) * search.size
        users = query.offset(offset).limit(search.size).all()
        
        # 페이지 수 계산
        pages = (total + search.size - 1) // search.size
        
        return UserListResponse(
            users=users,
            total=total,
            page=search.page,
            size=search.size,
            pages=pages
        )
        
    except Exception as e:
        logger.error(f"사용자 목록 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="사용자 목록 조회 중 오류가 발생했습니다"
        )

@router.get("/me/activities", response_model=UserActivityList)
async def get_current_user_activities(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_postgres_session)
):
    """현재 사용자의 활동 로그 조회"""
    try:
        # 활동 로그 쿼리
        query = db.query(UserActivity).filter(
            UserActivity.user_id == current_user.id
        ).order_by(UserActivity.created_at.desc())
        
        # 전체 개수 조회
        total = query.count()
        
        # 페이징 적용
        offset = (page - 1) * size
        activities = query.offset(offset).limit(size).all()
        
        # 페이지 수 계산
        pages = (total + size - 1) // size
        
        return UserActivityList(
            activities=activities,
            total=total,
            page=page,
            size=size,
            pages=pages
        )
        
    except Exception as e:
        logger.error(f"사용자 활동 로그 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="활동 로그 조회 중 오류가 발생했습니다"
        )

@router.delete("/me")
async def delete_current_user(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_postgres_session)
):
    """현재 사용자 계정 삭제"""
    try:
        # 사용자 비활성화 (실제 삭제 대신)
        current_user.is_active = False
        current_user.status = "inactive"
        
        # 활동 로그 기록
        activity = UserActivity(
            user_id=current_user.id,
            activity_type="account_deletion",
            description="계정 삭제 요청"
        )
        db.add(activity)
        
        db.commit()
        
        logger.info(f"사용자 계정 삭제: {current_user.email}")
        
        return {"message": "계정이 성공적으로 삭제되었습니다"}
        
    except Exception as e:
        logger.error(f"사용자 계정 삭제 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="계정 삭제 중 오류가 발생했습니다"
        )
