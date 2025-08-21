"""
동물 관련 Pydantic 스키마
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, validator
from enum import Enum

class AnimalType(str, Enum):
    """동물 종류"""
    DAIRY_COW = "dairy_cow"  # 젖소
    BEEF_CATTLE = "beef_cattle"  # 육우
    PIG = "pig"  # 돼지
    CHICKEN = "chicken"  # 닭
    DUCK = "duck"  # 오리
    GOAT = "goat"  # 염소
    SHEEP = "sheep"  # 양
    HORSE = "horse"  # 말
    OTHER = "other"  # 기타

class AnimalGender(str, Enum):
    """동물 성별"""
    MALE = "male"  # 수컷
    FEMALE = "female"  # 암컷
    CASTRATED = "castrated"  # 거세

class AnimalStatus(str, Enum):
    """동물 상태"""
    ACTIVE = "active"  # 활성
    INACTIVE = "inactive"  # 비활성
    SOLD = "sold"  # 판매
    DEAD = "dead"  # 폐사
    TRANSFERRED = "transferred"  # 이전

# 품종 스키마
class AnimalBreedBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    animal_type: AnimalType
    description: Optional[str] = None
    origin: Optional[str] = Field(None, max_length=100)
    characteristics: Optional[str] = None

class AnimalBreedCreate(AnimalBreedBase):
    pass

class AnimalBreedUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    origin: Optional[str] = Field(None, max_length=100)
    characteristics: Optional[str] = None
    is_active: Optional[bool] = None

class AnimalBreedResponse(AnimalBreedBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# 동물 스키마
class AnimalBase(BaseModel):
    animal_id: str = Field(..., min_length=1, max_length=50)
    name: Optional[str] = Field(None, max_length=100)
    animal_type: AnimalType
    breed_id: Optional[int] = None
    gender: AnimalGender
    birth_date: Optional[datetime] = None
    weight: Optional[float] = Field(None, ge=0)
    height: Optional[float] = Field(None, ge=0)
    color: Optional[str] = Field(None, max_length=50)
    status: AnimalStatus = AnimalStatus.ACTIVE
    
    # 부모 정보
    father_id: Optional[int] = None
    mother_id: Optional[int] = None
    
    # 농장 정보
    farm_location: Optional[str] = Field(None, max_length=200)
    pen_number: Optional[str] = Field(None, max_length=50)
    
    # 건강 정보
    health_status: Optional[str] = Field(None, max_length=100)
    vaccination_history: Optional[str] = None
    medical_notes: Optional[str] = None
    
    # 생산 정보
    milk_production: Optional[float] = Field(None, ge=0)  # L/day
    lactation_period: Optional[int] = Field(None, ge=0)  # days
    
    # 사료 정보
    current_feed_type: Optional[str] = Field(None, max_length=100)
    daily_feed_intake: Optional[float] = Field(None, ge=0)  # kg/day

class AnimalCreate(AnimalBase):
    @validator('animal_id')
    def validate_animal_id(cls, v):
        if not v.strip():
            raise ValueError('동물 ID는 비어있을 수 없습니다')
        return v.strip()

class AnimalUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    breed_id: Optional[int] = None
    weight: Optional[float] = Field(None, ge=0)
    height: Optional[float] = Field(None, ge=0)
    color: Optional[str] = Field(None, max_length=50)
    status: Optional[AnimalStatus] = None
    
    # 농장 정보
    farm_location: Optional[str] = Field(None, max_length=200)
    pen_number: Optional[str] = Field(None, max_length=50)
    
    # 건강 정보
    health_status: Optional[str] = Field(None, max_length=100)
    vaccination_history: Optional[str] = None
    medical_notes: Optional[str] = None
    
    # 생산 정보
    milk_production: Optional[float] = Field(None, ge=0)
    lactation_period: Optional[int] = Field(None, ge=0)
    
    # 사료 정보
    current_feed_type: Optional[str] = Field(None, max_length=100)
    daily_feed_intake: Optional[float] = Field(None, ge=0)

class AnimalResponse(AnimalBase):
    id: int
    user_id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# 동물 검색 스키마
class AnimalSearch(BaseModel):
    animal_id: Optional[str] = None
    name: Optional[str] = None
    animal_type: Optional[AnimalType] = None
    breed_id: Optional[int] = None
    gender: Optional[AnimalGender] = None
    status: Optional[AnimalStatus] = None
    farm_location: Optional[str] = None
    pen_number: Optional[str] = None
    page: int = Field(1, ge=1)
    size: int = Field(20, ge=1, le=100)

# 동물 목록 응답 스키마
class AnimalListResponse(BaseModel):
    animals: List[AnimalResponse]
    total: int
    page: int
    size: int
    pages: int

# 건강 기록 스키마
class AnimalHealthRecordBase(BaseModel):
    record_date: datetime
    health_status: str = Field(..., min_length=1, max_length=100)
    temperature: Optional[float] = Field(None, ge=30, le=45)  # 정상 체온 범위
    heart_rate: Optional[int] = Field(None, ge=0)
    respiratory_rate: Optional[int] = Field(None, ge=0)
    symptoms: Optional[str] = None
    diagnosis: Optional[str] = None
    treatment: Optional[str] = None
    medication: Optional[str] = None
    veterinarian: Optional[str] = Field(None, max_length=100)
    notes: Optional[str] = None

class AnimalHealthRecordCreate(AnimalHealthRecordBase):
    pass

class AnimalHealthRecordUpdate(BaseModel):
    health_status: Optional[str] = Field(None, min_length=1, max_length=100)
    temperature: Optional[float] = Field(None, ge=30, le=45)
    heart_rate: Optional[int] = Field(None, ge=0)
    respiratory_rate: Optional[int] = Field(None, ge=0)
    symptoms: Optional[str] = None
    diagnosis: Optional[str] = None
    treatment: Optional[str] = None
    medication: Optional[str] = None
    veterinarian: Optional[str] = Field(None, max_length=100)
    notes: Optional[str] = None

class AnimalHealthRecordResponse(AnimalHealthRecordBase):
    id: int
    animal_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# 체중 기록 스키마
class AnimalWeightRecordBase(BaseModel):
    record_date: datetime
    weight: float = Field(..., ge=0)
    measurement_method: Optional[str] = Field(None, max_length=50)
    notes: Optional[str] = None

class AnimalWeightRecordCreate(AnimalWeightRecordBase):
    pass

class AnimalWeightRecordUpdate(BaseModel):
    weight: Optional[float] = Field(None, ge=0)
    measurement_method: Optional[str] = Field(None, max_length=50)
    notes: Optional[str] = None

class AnimalWeightRecordResponse(AnimalWeightRecordBase):
    id: int
    animal_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# 사료 급여 기록 스키마
class AnimalFeedRecordBase(BaseModel):
    feed_date: datetime
    feed_type: str = Field(..., min_length=1, max_length=100)
    feed_amount: float = Field(..., ge=0)
    feed_frequency: Optional[str] = Field(None, max_length=50)
    feed_time: Optional[str] = Field(None, max_length=50)
    notes: Optional[str] = None

class AnimalFeedRecordCreate(AnimalFeedRecordBase):
    pass

class AnimalFeedRecordUpdate(BaseModel):
    feed_type: Optional[str] = Field(None, min_length=1, max_length=100)
    feed_amount: Optional[float] = Field(None, ge=0)
    feed_frequency: Optional[str] = Field(None, max_length=50)
    feed_time: Optional[str] = Field(None, max_length=50)
    notes: Optional[str] = None

class AnimalFeedRecordResponse(AnimalFeedRecordBase):
    id: int
    animal_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# 동물 그룹 스키마
class AnimalGroupBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    animal_type: AnimalType
    group_type: Optional[str] = Field(None, max_length=50)

class AnimalGroupCreate(AnimalGroupBase):
    pass

class AnimalGroupUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    group_type: Optional[str] = Field(None, max_length=50)
    is_active: Optional[bool] = None

class AnimalGroupResponse(AnimalGroupBase):
    id: int
    user_id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# 동물 그룹 멤버 스키마
class AnimalGroupMemberBase(BaseModel):
    animal_id: int
    joined_date: datetime
    left_date: Optional[datetime] = None

class AnimalGroupMemberCreate(AnimalGroupMemberBase):
    pass

class AnimalGroupMemberUpdate(BaseModel):
    left_date: Optional[datetime] = None
    is_active: Optional[bool] = None

class AnimalGroupMemberResponse(AnimalGroupMemberBase):
    id: int
    group_id: int
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# 통계 스키마
class AnimalStatistics(BaseModel):
    total_animals: int
    active_animals: int
    animals_by_type: dict
    animals_by_status: dict
    animals_by_gender: dict
    average_weight: Optional[float] = None
    total_milk_production: Optional[float] = None
