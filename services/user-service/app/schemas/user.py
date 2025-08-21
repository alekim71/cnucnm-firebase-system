"""
사용자 스키마
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field, validator
from enum import Enum

class UserRole(str, Enum):
    """사용자 역할"""
    ADMIN = "admin"
    FARMER = "farmer"
    RESEARCHER = "researcher"
    CONSULTANT = "consultant"
    VIEWER = "viewer"

class UserStatus(str, Enum):
    """사용자 상태"""
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"
    PENDING = "pending"

# Base Schemas
class UserBase(BaseModel):
    """사용자 기본 스키마"""
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=100)
    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    farm_name: Optional[str] = Field(None, max_length=200)
    farm_address: Optional[str] = None
    farm_size: Optional[int] = Field(None, ge=0)  # 헥타르
    farm_type: Optional[str] = Field(None, max_length=100)

class UserCreate(UserBase):
    """사용자 생성 스키마"""
    password: str = Field(..., min_length=8, max_length=128)
    confirm_password: str = Field(..., min_length=8, max_length=128)
    role: UserRole = UserRole.FARMER
    
    @validator('confirm_password')
    def passwords_match(cls, v, values):
        if 'password' in values and v != values['password']:
            raise ValueError('비밀번호가 일치하지 않습니다')
        return v
    
    @validator('password')
    def validate_password(cls, v):
        """비밀번호 복잡도 검증"""
        if len(v) < 8:
            raise ValueError('비밀번호는 최소 8자 이상이어야 합니다')
        
        has_upper = any(c.isupper() for c in v)
        has_lower = any(c.islower() for c in v)
        has_digit = any(c.isdigit() for c in v)
        has_special = any(c in '!@#$%^&*()_+-=[]{}|;:,.<>?' for c in v)
        
        if not (has_upper and has_lower and has_digit and has_special):
            raise ValueError('비밀번호는 대문자, 소문자, 숫자, 특수문자를 포함해야 합니다')
        
        return v

class UserUpdate(BaseModel):
    """사용자 업데이트 스키마"""
    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    farm_name: Optional[str] = Field(None, max_length=200)
    farm_address: Optional[str] = None
    farm_size: Optional[int] = Field(None, ge=0)
    farm_type: Optional[str] = Field(None, max_length=100)
    profile_image_url: Optional[str] = Field(None, max_length=500)
    language: Optional[str] = Field(None, max_length=10)
    timezone: Optional[str] = Field(None, max_length=50)
    notification_email: Optional[bool] = None
    notification_sms: Optional[bool] = None
    notification_push: Optional[bool] = None

class UserResponse(UserBase):
    """사용자 응답 스키마"""
    id: int
    role: UserRole
    status: UserStatus
    is_email_verified: bool
    is_phone_verified: bool
    is_active: bool
    created_at: datetime
    updated_at: datetime
    last_login_at: Optional[datetime]
    profile_image_url: Optional[str]
    language: str
    timezone: str
    notification_email: bool
    notification_sms: bool
    notification_push: bool
    
    class Config:
        from_attributes = True

class UserListResponse(BaseModel):
    """사용자 목록 응답 스키마"""
    users: list[UserResponse]
    total: int
    page: int
    size: int
    pages: int

# Authentication Schemas
class UserLogin(BaseModel):
    """사용자 로그인 스키마"""
    email: EmailStr
    password: str
    remember_me: bool = False

class UserLoginResponse(BaseModel):
    """사용자 로그인 응답 스키마"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserResponse

class TokenRefresh(BaseModel):
    """토큰 갱신 스키마"""
    refresh_token: str

class TokenRefreshResponse(BaseModel):
    """토큰 갱신 응답 스키마"""
    access_token: str
    token_type: str = "bearer"
    expires_in: int

class PasswordReset(BaseModel):
    """비밀번호 재설정 요청 스키마"""
    email: EmailStr

class PasswordResetConfirm(BaseModel):
    """비밀번호 재설정 확인 스키마"""
    token: str
    new_password: str = Field(..., min_length=8, max_length=128)
    confirm_password: str = Field(..., min_length=8, max_length=128)
    
    @validator('confirm_password')
    def passwords_match(cls, v, values):
        if 'new_password' in values and v != values['new_password']:
            raise ValueError('비밀번호가 일치하지 않습니다')
        return v

class PasswordChange(BaseModel):
    """비밀번호 변경 스키마"""
    current_password: str
    new_password: str = Field(..., min_length=8, max_length=128)
    confirm_password: str = Field(..., min_length=8, max_length=128)
    
    @validator('confirm_password')
    def passwords_match(cls, v, values):
        if 'new_password' in values and v != values['new_password']:
            raise ValueError('비밀번호가 일치하지 않습니다')
        return v

# Verification Schemas
class EmailVerification(BaseModel):
    """이메일 인증 스키마"""
    token: str

class PhoneVerification(BaseModel):
    """전화번호 인증 스키마"""
    phone: str = Field(..., max_length=20)
    verification_code: str = Field(..., max_length=6)

class PhoneVerificationRequest(BaseModel):
    """전화번호 인증 요청 스키마"""
    phone: str = Field(..., max_length=20)

# Profile Schemas
class ProfileUpdate(BaseModel):
    """프로필 업데이트 스키마"""
    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    farm_name: Optional[str] = Field(None, max_length=200)
    farm_address: Optional[str] = None
    farm_size: Optional[int] = Field(None, ge=0)
    farm_type: Optional[str] = Field(None, max_length=100)
    language: Optional[str] = Field(None, max_length=10)
    timezone: Optional[str] = Field(None, max_length=50)

class NotificationSettings(BaseModel):
    """알림 설정 스키마"""
    notification_email: bool
    notification_sms: bool
    notification_push: bool

# Admin Schemas
class UserStatusUpdate(BaseModel):
    """사용자 상태 업데이트 스키마 (관리자용)"""
    status: UserStatus
    reason: Optional[str] = None

class UserRoleUpdate(BaseModel):
    """사용자 역할 업데이트 스키마 (관리자용)"""
    role: UserRole

class UserSearch(BaseModel):
    """사용자 검색 스키마"""
    email: Optional[str] = None
    username: Optional[str] = None
    role: Optional[UserRole] = None
    status: Optional[UserStatus] = None
    farm_type: Optional[str] = None
    page: int = Field(1, ge=1)
    size: int = Field(20, ge=1, le=100)

# Activity Schemas
class UserActivityResponse(BaseModel):
    """사용자 활동 응답 스키마"""
    id: int
    user_id: int
    activity_type: str
    description: Optional[str]
    ip_address: Optional[str]
    user_agent: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True

class UserActivityList(BaseModel):
    """사용자 활동 목록 스키마"""
    activities: list[UserActivityResponse]
    total: int
    page: int
    size: int
    pages: int
