"""
인증 관련 엔드포인트
"""
from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
import logging

from shared.common.database import get_postgres_session
from app.models.user import User, UserSession, UserActivity
from app.schemas.user import (
    UserCreate, UserLogin, UserLoginResponse, TokenRefresh, 
    TokenRefreshResponse, PasswordReset, PasswordResetConfirm
)
from app.core.security import (
    verify_password, get_password_hash, create_access_token, 
    create_refresh_token, verify_token, generate_verification_token
)
from app.core.logging import get_logger

router = APIRouter()
security = HTTPBearer()
logger = get_logger(__name__)

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_postgres_session)
) -> User:
    """현재 사용자 가져오기"""
    token = credentials.credentials
    payload = verify_token(token)
    
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="유효하지 않은 토큰입니다",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user_id: int = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="토큰에 사용자 정보가 없습니다",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="사용자를 찾을 수 없습니다",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.can_login:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="로그인이 불가능한 계정입니다",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return user

@router.post("/register", response_model=dict)
async def register(
    user_data: UserCreate,
    request: Request,
    db: Session = Depends(get_postgres_session)
):
    """사용자 등록"""
    try:
        # 이메일 중복 확인
        existing_user = db.query(User).filter(User.email == user_data.email).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미 등록된 이메일입니다"
            )
        
        # 사용자명 중복 확인
        existing_username = db.query(User).filter(User.username == user_data.username).first()
        if existing_username:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미 사용 중인 사용자명입니다"
            )
        
        # 사용자 생성
        hashed_password = get_password_hash(user_data.password)
        user = User(
            email=user_data.email,
            username=user_data.username,
            hashed_password=hashed_password,
            first_name=user_data.first_name,
            last_name=user_data.last_name,
            phone=user_data.phone,
            role=user_data.role,
            farm_name=user_data.farm_name,
            farm_address=user_data.farm_address,
            farm_size=user_data.farm_size,
            farm_type=user_data.farm_type
        )
        
        db.add(user)
        db.commit()
        db.refresh(user)
        
        # 활동 로그 기록
        activity = UserActivity(
            user_id=user.id,
            activity_type="user_registration",
            description="사용자 등록",
            ip_address=request.client.host,
            user_agent=request.headers.get("user-agent")
        )
        db.add(activity)
        db.commit()
        
        logger.info(f"새 사용자 등록: {user.email}")
        
        return {
            "message": "사용자 등록이 완료되었습니다",
            "user_id": user.id,
            "email": user.email
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"사용자 등록 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="사용자 등록 중 오류가 발생했습니다"
        )

@router.post("/login", response_model=UserLoginResponse)
async def login(
    user_data: UserLogin,
    request: Request,
    db: Session = Depends(get_postgres_session)
):
    """사용자 로그인"""
    try:
        # 사용자 확인
        user = db.query(User).filter(User.email == user_data.email).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="이메일 또는 비밀번호가 올바르지 않습니다"
            )
        
        # 비밀번호 확인
        if not verify_password(user_data.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="이메일 또는 비밀번호가 올바르지 않습니다"
            )
        
        # 로그인 가능 여부 확인
        if not user.can_login:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="로그인이 불가능한 계정입니다"
            )
        
        # 토큰 생성
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        if user_data.remember_me:
            refresh_token_expires = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
        else:
            refresh_token_expires = timedelta(hours=24)
        
        access_token = create_access_token(
            data={"sub": str(user.id), "email": user.email, "role": user.role.value},
            expires_delta=access_token_expires
        )
        
        refresh_token = create_refresh_token(
            data={"sub": str(user.id)},
            expires_delta=refresh_token_expires
        )
        
        # 세션 저장
        session = UserSession(
            user_id=user.id,
            session_token=access_token,
            refresh_token=refresh_token,
            ip_address=request.client.host,
            user_agent=request.headers.get("user-agent"),
            device_type="web",  # TODO: 디바이스 타입 감지
            expires_at=datetime.utcnow() + access_token_expires
        )
        db.add(session)
        
        # 마지막 로그인 시간 업데이트
        user.last_login_at = datetime.utcnow()
        
        # 활동 로그 기록
        activity = UserActivity(
            user_id=user.id,
            activity_type="login",
            description="사용자 로그인",
            ip_address=request.client.host,
            user_agent=request.headers.get("user-agent")
        )
        db.add(activity)
        
        db.commit()
        
        logger.info(f"사용자 로그인: {user.email}")
        
        return UserLoginResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user=user
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"로그인 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="로그인 중 오류가 발생했습니다"
        )

@router.post("/refresh", response_model=TokenRefreshResponse)
async def refresh_token(
    token_data: TokenRefresh,
    db: Session = Depends(get_postgres_session)
):
    """토큰 갱신"""
    try:
        # 리프레시 토큰 검증
        payload = verify_token(token_data.refresh_token)
        if payload is None or payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="유효하지 않은 리프레시 토큰입니다"
            )
        
        user_id = int(payload.get("sub"))
        user = db.query(User).filter(User.id == user_id).first()
        
        if not user or not user.can_login:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="유효하지 않은 사용자입니다"
            )
        
        # 새로운 액세스 토큰 생성
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(user.id), "email": user.email, "role": user.role.value},
            expires_delta=access_token_expires
        )
        
        # 세션 업데이트
        session = db.query(UserSession).filter(
            UserSession.refresh_token == token_data.refresh_token,
            UserSession.is_active == True
        ).first()
        
        if session:
            session.session_token = access_token
            session.expires_at = datetime.utcnow() + access_token_expires
            db.commit()
        
        return TokenRefreshResponse(
            access_token=access_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"토큰 갱신 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="토큰 갱신 중 오류가 발생했습니다"
        )

@router.post("/logout")
async def logout(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_postgres_session)
):
    """사용자 로그아웃"""
    try:
        # 활성 세션 비활성화
        db.query(UserSession).filter(
            UserSession.user_id == current_user.id,
            UserSession.is_active == True
        ).update({"is_active": False})
        
        # 활동 로그 기록
        activity = UserActivity(
            user_id=current_user.id,
            activity_type="logout",
            description="사용자 로그아웃"
        )
        db.add(activity)
        
        db.commit()
        
        logger.info(f"사용자 로그아웃: {current_user.email}")
        
        return {"message": "로그아웃이 완료되었습니다"}
        
    except Exception as e:
        logger.error(f"로그아웃 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="로그아웃 중 오류가 발생했습니다"
        )

@router.post("/password-reset")
async def request_password_reset(
    reset_data: PasswordReset,
    db: Session = Depends(get_postgres_session)
):
    """비밀번호 재설정 요청"""
    try:
        user = db.query(User).filter(User.email == reset_data.email).first()
        if not user:
            # 보안을 위해 사용자가 존재하지 않아도 성공 응답
            return {"message": "비밀번호 재설정 이메일이 발송되었습니다"}
        
        # 인증 토큰 생성
        token = generate_verification_token()
        expires_at = datetime.utcnow() + timedelta(hours=1)
        
        # 기존 토큰 비활성화
        db.query(UserVerification).filter(
            UserVerification.user_id == user.id,
            UserVerification.verification_type == "password_reset",
            UserVerification.is_used == False
        ).update({"is_used": True})
        
        # 새 토큰 저장
        verification = UserVerification(
            user_id=user.id,
            verification_type="password_reset",
            verification_token=token,
            target=user.email,
            expires_at=expires_at
        )
        db.add(verification)
        db.commit()
        
        # TODO: 이메일 발송 로직 구현
        
        logger.info(f"비밀번호 재설정 요청: {user.email}")
        
        return {"message": "비밀번호 재설정 이메일이 발송되었습니다"}
        
    except Exception as e:
        logger.error(f"비밀번호 재설정 요청 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="비밀번호 재설정 요청 중 오류가 발생했습니다"
        )

@router.post("/password-reset/confirm")
async def confirm_password_reset(
    reset_data: PasswordResetConfirm,
    db: Session = Depends(get_postgres_session)
):
    """비밀번호 재설정 확인"""
    try:
        # 토큰 검증
        verification = db.query(UserVerification).filter(
            UserVerification.verification_token == reset_data.token,
            UserVerification.verification_type == "password_reset",
            UserVerification.is_used == False,
            UserVerification.expires_at > datetime.utcnow()
        ).first()
        
        if not verification:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="유효하지 않거나 만료된 토큰입니다"
            )
        
        # 사용자 확인
        user = db.query(User).filter(User.id == verification.user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="사용자를 찾을 수 없습니다"
            )
        
        # 비밀번호 업데이트
        user.hashed_password = get_password_hash(reset_data.new_password)
        verification.is_used = True
        verification.used_at = datetime.utcnow()
        
        # 활동 로그 기록
        activity = UserActivity(
            user_id=user.id,
            activity_type="password_reset",
            description="비밀번호 재설정"
        )
        db.add(activity)
        
        db.commit()
        
        logger.info(f"비밀번호 재설정 완료: {user.email}")
        
        return {"message": "비밀번호가 성공적으로 변경되었습니다"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"비밀번호 재설정 확인 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="비밀번호 재설정 중 오류가 발생했습니다"
        )
