"""
동물 관련 데이터 모델
"""
from datetime import datetime
from typing import Optional
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, Enum, Float, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum

from shared.common.database import Base

class AnimalType(str, enum.Enum):
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

class AnimalGender(str, enum.Enum):
    """동물 성별"""
    MALE = "male"  # 수컷
    FEMALE = "female"  # 암컷
    CASTRATED = "castrated"  # 거세

class AnimalStatus(str, enum.Enum):
    """동물 상태"""
    ACTIVE = "active"  # 활성
    INACTIVE = "inactive"  # 비활성
    SOLD = "sold"  # 판매
    DEAD = "dead"  # 폐사
    TRANSFERRED = "transferred"  # 이전

class AnimalBreed(Base):
    """동물 품종"""
    __tablename__ = "animal_breeds"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    animal_type = Column(Enum(AnimalType), nullable=False)
    description = Column(Text)
    origin = Column(String(100))
    characteristics = Column(Text)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class Animal(Base):
    """동물 정보"""
    __tablename__ = "animals"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    animal_id = Column(String(50), unique=True, index=True, nullable=False)  # 농장 내 고유 ID
    name = Column(String(100))
    animal_type = Column(Enum(AnimalType), nullable=False)
    breed_id = Column(Integer, ForeignKey("animal_breeds.id"))
    gender = Column(Enum(AnimalGender), nullable=False)
    birth_date = Column(DateTime)
    weight = Column(Float)  # kg
    height = Column(Float)  # cm
    color = Column(String(50))
    status = Column(Enum(AnimalStatus), default=AnimalStatus.ACTIVE, nullable=False)
    
    # 부모 정보
    father_id = Column(Integer, ForeignKey("animals.id"))
    mother_id = Column(Integer, ForeignKey("animals.id"))
    
    # 농장 정보
    farm_location = Column(String(200))
    pen_number = Column(String(50))
    
    # 건강 정보
    health_status = Column(String(100))
    vaccination_history = Column(Text)
    medical_notes = Column(Text)
    
    # 생산 정보 (젖소의 경우)
    milk_production = Column(Float)  # L/day
    lactation_period = Column(Integer)  # days
    
    # 사료 정보
    current_feed_type = Column(String(100))
    daily_feed_intake = Column(Float)  # kg/day
    
    # 메타데이터
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # 관계
    user = relationship("User", back_populates="animals")
    breed = relationship("AnimalBreed")
    father = relationship("Animal", foreign_keys=[father_id], remote_side=[id])
    mother = relationship("Animal", foreign_keys=[mother_id], remote_side=[id])
    health_records = relationship("AnimalHealthRecord", back_populates="animal")
    weight_records = relationship("AnimalWeightRecord", back_populates="animal")
    feed_records = relationship("AnimalFeedRecord", back_populates="animal")

class AnimalHealthRecord(Base):
    """동물 건강 기록"""
    __tablename__ = "animal_health_records"
    
    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(Integer, ForeignKey("animals.id"), nullable=False)
    record_date = Column(DateTime, nullable=False)
    health_status = Column(String(100), nullable=False)
    temperature = Column(Float)  # 체온
    heart_rate = Column(Integer)  # 심박수
    respiratory_rate = Column(Integer)  # 호흡수
    symptoms = Column(Text)
    diagnosis = Column(Text)
    treatment = Column(Text)
    medication = Column(Text)
    veterinarian = Column(String(100))
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # 관계
    animal = relationship("Animal", back_populates="health_records")

class AnimalWeightRecord(Base):
    """동물 체중 기록"""
    __tablename__ = "animal_weight_records"
    
    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(Integer, ForeignKey("animals.id"), nullable=False)
    record_date = Column(DateTime, nullable=False)
    weight = Column(Float, nullable=False)  # kg
    measurement_method = Column(String(50))  # 측정 방법
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # 관계
    animal = relationship("Animal", back_populates="weight_records")

class AnimalFeedRecord(Base):
    """동물 사료 급여 기록"""
    __tablename__ = "animal_feed_records"
    
    id = Column(Integer, primary_key=True, index=True)
    animal_id = Column(Integer, ForeignKey("animals.id"), nullable=False)
    feed_date = Column(DateTime, nullable=False)
    feed_type = Column(String(100), nullable=False)
    feed_amount = Column(Float, nullable=False)  # kg
    feed_frequency = Column(String(50))  # 급여 빈도
    feed_time = Column(String(50))  # 급여 시간
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # 관계
    animal = relationship("Animal", back_populates="feed_records")

class AnimalGroup(Base):
    """동물 그룹"""
    __tablename__ = "animal_groups"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(100), nullable=False)
    description = Column(Text)
    animal_type = Column(Enum(AnimalType), nullable=False)
    group_type = Column(String(50))  # 그룹 유형 (연령별, 성별, 목적별 등)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class AnimalGroupMember(Base):
    """동물 그룹 멤버"""
    __tablename__ = "animal_group_members"
    
    id = Column(Integer, primary_key=True, index=True)
    group_id = Column(Integer, ForeignKey("animal_groups.id"), nullable=False)
    animal_id = Column(Integer, ForeignKey("animals.id"), nullable=False)
    joined_date = Column(DateTime, nullable=False)
    left_date = Column(DateTime)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
