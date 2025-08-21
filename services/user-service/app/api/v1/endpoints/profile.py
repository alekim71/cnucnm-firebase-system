"""
프로필 관리 엔드포인트
"""
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session

from shared.common.database import get_postgres_session
from app.models.user import User, UserActivity
from app.schemas.user import (
    ProfileUpdate, NotificationSettings, UserResponse
)
from app.api.v1.endpoints.auth import get_current_user
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)

@router.get("/", response_model=UserResponse)
async def get_profile(
    current_user: User = Depends(get_current_user)
):
    """프로필 정보 조회"""
    return current_user

@router.put("/", response_model=UserResponse)
async def update_profile(
    profile_data: ProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_postgres_session)
):
    """프로필 정보 업데이트"""
    try:
        # 업데이트할 필드들
        update_data = profile_data.dict(exclude_unset=True)
        
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
        
        logger.info(f"프로필 정보 업데이트: {current_user.email}")
        
        return current_user
        
    except Exception as e:
        logger.error(f"프로필 정보 업데이트 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="프로필 정보 업데이트 중 오류가 발생했습니다"
        )

@router.put("/notifications")
async def update_notification_settings(
    settings: NotificationSettings,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_postgres_session)
):
    """알림 설정 업데이트"""
    try:
        current_user.notification_email = settings.notification_email
        current_user.notification_sms = settings.notification_sms
        current_user.notification_push = settings.notification_push
        
        db.commit()
        
        # 활동 로그 기록
        activity = UserActivity(
            user_id=current_user.id,
            activity_type="notification_settings_update",
            description="알림 설정 업데이트"
        )
        db.add(activity)
        db.commit()
        
        logger.info(f"알림 설정 업데이트: {current_user.email}")
        
        return {"message": "알림 설정이 업데이트되었습니다"}
        
    except Exception as e:
        logger.error(f"알림 설정 업데이트 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="알림 설정 업데이트 중 오류가 발생했습니다"
        )

@router.post("/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_postgres_session)
):
    """프로필 이미지 업로드"""
    try:
        # 파일 타입 검증
        if not file.content_type.startswith('image/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미지 파일만 업로드 가능합니다"
            )
        
        # 파일 크기 검증 (5MB 제한)
        if file.size and file.size > 5 * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="파일 크기는 5MB 이하여야 합니다"
            )
        
        # TODO: 실제 파일 업로드 로직 구현 (MinIO, AWS S3 등)
        # 현재는 임시로 파일명만 저장
        file_extension = file.filename.split('.')[-1] if '.' in file.filename else 'jpg'
        avatar_url = f"/avatars/{current_user.id}.{file_extension}"
        
        current_user.profile_image_url = avatar_url
        db.commit()
        
        # 활동 로그 기록
        activity = UserActivity(
            user_id=current_user.id,
            activity_type="avatar_upload",
            description="프로필 이미지 업로드"
        )
        db.add(activity)
        db.commit()
        
        logger.info(f"프로필 이미지 업로드: {current_user.email}")
        
        return {
            "message": "프로필 이미지가 업로드되었습니다",
            "avatar_url": avatar_url
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"프로필 이미지 업로드 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="프로필 이미지 업로드 중 오류가 발생했습니다"
        )

@router.delete("/avatar")
async def delete_avatar(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_postgres_session)
):
    """프로필 이미지 삭제"""
    try:
        if not current_user.profile_image_url:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="삭제할 프로필 이미지가 없습니다"
            )
        
        # TODO: 실제 파일 삭제 로직 구현
        current_user.profile_image_url = None
        db.commit()
        
        # 활동 로그 기록
        activity = UserActivity(
            user_id=current_user.id,
            activity_type="avatar_delete",
            description="프로필 이미지 삭제"
        )
        db.add(activity)
        db.commit()
        
        logger.info(f"프로필 이미지 삭제: {current_user.email}")
        
        return {"message": "프로필 이미지가 삭제되었습니다"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"프로필 이미지 삭제 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="프로필 이미지 삭제 중 오류가 발생했습니다"
        )
