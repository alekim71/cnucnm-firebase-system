"""
사용자 모델
"""
from datetime import datetime
from typing import Optional
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum

from shared.common.database import Base

class UserRole(str, enum.Enum):
    """사용자 역할"""
    ADMIN = "admin"
    FARMER = "farmer"
    RESEARCHER = "researcher"
    CONSULTANT = "consultant"
    VIEWER = "viewer"

class UserStatus(str, enum.Enum):
    """사용자 상태"""
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"
    PENDING = "pending"

class User(Base):
    """사용자 모델"""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    first_name = Column(String(100), nullable=True)
    last_name = Column(String(100), nullable=True)
    phone = Column(String(20), nullable=True)
    
    # 역할 및 상태
    role = Column(Enum(UserRole), default=UserRole.FARMER, nullable=False)
    status = Column(Enum(UserStatus), default=UserStatus.PENDING, nullable=False)
    
    # 농장 정보
    farm_name = Column(String(200), nullable=True)
    farm_address = Column(Text, nullable=True)
    farm_size = Column(Integer, nullable=True)  # 헥타르
    farm_type = Column(String(100), nullable=True)  # 한우, 젖소, 혼합 등
    
    # 계정 설정
    is_email_verified = Column(Boolean, default=False, nullable=False)
    is_phone_verified = Column(Boolean, default=False, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    
    # 메타데이터
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    last_login_at = Column(DateTime(timezone=True), nullable=True)
    
    # 프로필 이미지
    profile_image_url = Column(String(500), nullable=True)
    
    # 설정
    language = Column(String(10), default="ko", nullable=False)
    timezone = Column(String(50), default="Asia/Seoul", nullable=False)
    notification_email = Column(Boolean, default=True, nullable=False)
    notification_sms = Column(Boolean, default=False, nullable=False)
    notification_push = Column(Boolean, default=True, nullable=False)
    
    def __repr__(self):
        return f"<User(id={self.id}, email='{self.email}', username='{self.username}')>"
    
    @property
    def full_name(self) -> str:
        """전체 이름 반환"""
        if self.first_name and self.last_name:
            return f"{self.first_name} {self.last_name}"
        elif self.first_name:
            return self.first_name
        elif self.last_name:
            return self.last_name
        else:
            return self.username
    
    @property
    def is_verified(self) -> bool:
        """이메일 인증 완료 여부"""
        return self.is_email_verified
    
    @property
    def can_login(self) -> bool:
        """로그인 가능 여부"""
        return self.is_active and self.status == UserStatus.ACTIVE

class UserSession(Base):
    """사용자 세션 모델"""
    __tablename__ = "user_sessions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    session_token = Column(String(255), unique=True, index=True, nullable=False)
    refresh_token = Column(String(255), unique=True, index=True, nullable=False)
    
    # 세션 정보
    ip_address = Column(String(45), nullable=True)  # IPv6 지원
    user_agent = Column(Text, nullable=True)
    device_type = Column(String(50), nullable=True)  # web, mobile, tablet
    
    # 만료 시간
    expires_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # 활성화 상태
    is_active = Column(Boolean, default=True, nullable=False)
    
    def __repr__(self):
        return f"<UserSession(id={self.id}, user_id={self.user_id})>"

class UserVerification(Base):
    """사용자 인증 모델"""
    __tablename__ = "user_verifications"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    verification_type = Column(String(20), nullable=False)  # email, phone, password_reset
    verification_token = Column(String(255), unique=True, index=True, nullable=False)
    
    # 인증 정보
    target = Column(String(255), nullable=False)  # 이메일 주소 또는 전화번호
    is_used = Column(Boolean, default=False, nullable=False)
    
    # 만료 시간
    expires_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    used_at = Column(DateTime(timezone=True), nullable=True)
    
    def __repr__(self):
        return f"<UserVerification(id={self.id}, user_id={self.user_id}, type='{self.verification_type}')>"

class UserActivity(Base):
    """사용자 활동 로그 모델"""
    __tablename__ = "user_activities"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    
    # 활동 정보
    activity_type = Column(String(50), nullable=False)  # login, logout, password_change, profile_update 등
    description = Column(Text, nullable=True)
    
    # 메타데이터
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    def __repr__(self):
        return f"<UserActivity(id={self.id}, user_id={self.user_id}, type='{self.activity_type}')>"
