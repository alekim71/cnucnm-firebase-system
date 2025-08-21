"""
사료 관련 데이터 모델
"""
from datetime import datetime
from typing import Optional
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, Enum, Float, ForeignKey, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum

from shared.common.database import Base

class FeedCategory(str, enum.Enum):
    """사료 카테고리"""
    CONCENTRATE = "concentrate"  # 농후사료
    ROUGHAGE = "roughage"  # 조사료
    MINERAL = "mineral"  # 무기질
    VITAMIN = "vitamin"  # 비타민
    ADDITIVE = "additive"  # 첨가제
    COMPLETE = "complete"  # 완전사료
    SUPPLEMENT = "supplement"  # 보충사료
    OTHER = "other"  # 기타

class FeedType(str, enum.Enum):
    """사료 유형"""
    GRAIN = "grain"  # 곡물
    OILSEED = "oilseed"  # 유지종자
    BYPRODUCT = "byproduct"  # 부산물
    FORAGE = "forage"  # 목초
    SILAGE = "silage"  # 사일리지
    HAY = "hay"  # 건초
    MINERAL_MIX = "mineral_mix"  # 무기질 혼합
    VITAMIN_MIX = "vitamin_mix"  # 비타민 혼합
    ENZYME = "enzyme"  # 효소
    PROBIOTIC = "probiotic"  # 프로바이오틱
    OTHER = "other"  # 기타

class FeedStatus(str, enum.Enum):
    """사료 상태"""
    ACTIVE = "active"  # 활성
    INACTIVE = "inactive"  # 비활성
    DEPRECATED = "deprecated"  # 폐기
    PENDING = "pending"  # 검토 대기

class Feed(Base):
    """사료 정보"""
    __tablename__ = "feeds"
    
    id = Column(Integer, primary_key=True, index=True)
    feed_code = Column(String(50), unique=True, index=True, nullable=False)  # 사료 코드
    name = Column(String(200), nullable=False)  # 사료명
    english_name = Column(String(200))  # 영문명
    category = Column(Enum(FeedCategory), nullable=False)  # 카테고리
    feed_type = Column(Enum(FeedType), nullable=False)  # 사료 유형
    description = Column(Text)  # 설명
    status = Column(Enum(FeedStatus), default=FeedStatus.ACTIVE, nullable=False)
    
    # 영양성분 (기본)
    dry_matter = Column(Float)  # 건물률 (%)
    crude_protein = Column(Float)  # 조단백질 (%)
    crude_fat = Column(Float)  # 조지방 (%)
    crude_fiber = Column(Float)  # 조섬유 (%)
    ash = Column(Float)  # 조회분 (%)
    nitrogen_free_extract = Column(Float)  # 가용성 무질소물 (%)
    
    # 에너지
    total_digestible_nutrients = Column(Float)  # TDN (%)
    net_energy_lactation = Column(Float)  # NEL (Mcal/kg)
    net_energy_maintenance = Column(Float)  # NEM (Mcal/kg)
    net_energy_gain = Column(Float)  # NEG (Mcal/kg)
    metabolizable_energy = Column(Float)  # ME (Mcal/kg)
    gross_energy = Column(Float)  # GE (Mcal/kg)
    
    # 아미노산
    lysine = Column(Float)  # 라이신 (%)
    methionine = Column(Float)  # 메티오닌 (%)
    threonine = Column(Float)  # 트레오닌 (%)
    tryptophan = Column(Float)  # 트립토판 (%)
    arginine = Column(Float)  # 아르기닌 (%)
    histidine = Column(Float)  # 히스티딘 (%)
    isoleucine = Column(Float)  # 이소류신 (%)
    leucine = Column(Float)  # 류신 (%)
    valine = Column(Float)  # 발린 (%)
    phenylalanine = Column(Float)  # 페닐알라닌 (%)
    
    # 무기질
    calcium = Column(Float)  # 칼슘 (%)
    phosphorus = Column(Float)  # 인 (%)
    magnesium = Column(Float)  # 마그네슘 (%)
    potassium = Column(Float)  # 칼륨 (%)
    sodium = Column(Float)  # 나트륨 (%)
    chlorine = Column(Float)  # 염소 (%)
    sulfur = Column(Float)  # 황 (%)
    iron = Column(Float)  # 철 (mg/kg)
    zinc = Column(Float)  # 아연 (mg/kg)
    copper = Column(Float)  # 구리 (mg/kg)
    manganese = Column(Float)  # 망간 (mg/kg)
    selenium = Column(Float)  # 셀레늄 (mg/kg)
    cobalt = Column(Float)  # 코발트 (mg/kg)
    iodine = Column(Float)  # 요오드 (mg/kg)
    
    # 비타민
    vitamin_a = Column(Float)  # 비타민 A (IU/kg)
    vitamin_d = Column(Float)  # 비타민 D (IU/kg)
    vitamin_e = Column(Float)  # 비타민 E (IU/kg)
    vitamin_k = Column(Float)  # 비타민 K (mg/kg)
    thiamine = Column(Float)  # 티아민 (mg/kg)
    riboflavin = Column(Float)  # 리보플라빈 (mg/kg)
    niacin = Column(Float)  # 나이아신 (mg/kg)
    pantothenic_acid = Column(Float)  # 판토텐산 (mg/kg)
    pyridoxine = Column(Float)  # 피리독신 (mg/kg)
    biotin = Column(Float)  # 비오틴 (mg/kg)
    folic_acid = Column(Float)  # 엽산 (mg/kg)
    vitamin_b12 = Column(Float)  # 비타민 B12 (mg/kg)
    choline = Column(Float)  # 콜린 (mg/kg)
    
    # 기타 영양성분
    starch = Column(Float)  # 전분 (%)
    sugar = Column(Float)  # 당 (%)
    ndf = Column(Float)  # NDF (%)
    adf = Column(Float)  # ADF (%)
    lignin = Column(Float)  # 리그닌 (%)
    ether_extract = Column(Float)  # 에테르 추출물 (%)
    
    # 물리적 특성
    bulk_density = Column(Float)  # 용적밀도 (kg/m³)
    particle_size = Column(String(100))  # 입자 크기
    color = Column(String(50))  # 색상
    odor = Column(String(100))  # 냄새
    texture = Column(String(100))  # 질감
    
    # 저장 및 안전성
    shelf_life = Column(Integer)  # 유통기한 (일)
    storage_conditions = Column(Text)  # 저장 조건
    safety_notes = Column(Text)  # 안전성 주의사항
    max_inclusion_rate = Column(Float)  # 최대 첨가율 (%)
    
    # 메타데이터
    source = Column(String(200))  # 출처
    reference = Column(Text)  # 참고문헌
    notes = Column(Text)  # 기타 참고사항
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # 관계
    feed_analyses = relationship("FeedAnalysis", back_populates="feed")
    feed_prices = relationship("FeedPrice", back_populates="feed")
    feed_suppliers = relationship("FeedSupplier", back_populates="feed")

class FeedAnalysis(Base):
    """사료 분석 결과"""
    __tablename__ = "feed_analyses"
    
    id = Column(Integer, primary_key=True, index=True)
    feed_id = Column(Integer, ForeignKey("feeds.id"), nullable=False)
    analysis_date = Column(DateTime, nullable=False)
    laboratory = Column(String(200))  # 분석 실험실
    sample_id = Column(String(100))  # 시료 ID
    batch_number = Column(String(100))  # 배치 번호
    
    # 분석 결과 (JSON 형태로 저장)
    analysis_results = Column(JSON)  # 분석 결과 데이터
    
    # 품질 정보
    moisture = Column(Float)  # 수분 (%)
    protein_quality = Column(String(100))  # 단백질 품질
    digestibility = Column(Float)  # 소화율 (%)
    
    # 안전성 검사
    mycotoxin_level = Column(Float)  # 곰팡이독소 (ppb)
    heavy_metal_level = Column(Float)  # 중금속 (mg/kg)
    pesticide_residue = Column(Float)  # 농약 잔류 (mg/kg)
    
    # 메타데이터
    analyst = Column(String(100))  # 분석자
    notes = Column(Text)  # 분석 노트
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # 관계
    feed = relationship("Feed", back_populates="feed_analyses")

class FeedPrice(Base):
    """사료 가격 정보"""
    __tablename__ = "feed_prices"
    
    id = Column(Integer, primary_key=True, index=True)
    feed_id = Column(Integer, ForeignKey("feeds.id"), nullable=False)
    price_date = Column(DateTime, nullable=False)
    price = Column(Float, nullable=False)  # 가격 (원/kg)
    currency = Column(String(10), default="KRW")  # 통화
    price_type = Column(String(50))  # 가격 유형 (소매, 도매, 계약 등)
    supplier = Column(String(200))  # 공급업체
    location = Column(String(200))  # 지역
    quantity_unit = Column(String(20), default="kg")  # 수량 단위
    minimum_quantity = Column(Float)  # 최소 주문량
    delivery_cost = Column(Float)  # 배송비
    payment_terms = Column(String(100))  # 결제 조건
    notes = Column(Text)  # 기타 참고사항
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # 관계
    feed = relationship("Feed", back_populates="feed_prices")

class FeedSupplier(Base):
    """사료 공급업체"""
    __tablename__ = "feed_suppliers"
    
    id = Column(Integer, primary_key=True, index=True)
    feed_id = Column(Integer, ForeignKey("feeds.id"), nullable=False)
    supplier_name = Column(String(200), nullable=False)
    contact_person = Column(String(100))
    phone = Column(String(50))
    email = Column(String(200))
    website = Column(String(200))
    address = Column(Text)
    business_number = Column(String(50))  # 사업자등록번호
    certification = Column(Text)  # 인증 정보
    quality_rating = Column(Float)  # 품질 등급 (1-5)
    reliability_rating = Column(Float)  # 신뢰도 등급 (1-5)
    delivery_time = Column(String(100))  # 배송 시간
    minimum_order = Column(Float)  # 최소 주문량
    payment_methods = Column(Text)  # 결제 방법
    notes = Column(Text)  # 기타 참고사항
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # 관계
    feed = relationship("Feed", back_populates="feed_suppliers")

class FeedFormulation(Base):
    """사료 배합"""
    __tablename__ = "feed_formulations"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(200), nullable=False)  # 배합명
    description = Column(Text)  # 설명
    target_animal = Column(String(100))  # 대상 동물
    target_stage = Column(String(100))  # 대상 단계
    target_weight = Column(Float)  # 대상 체중 (kg)
    target_production = Column(Float)  # 목표 생산량
    
    # 배합 비율 (JSON 형태로 저장)
    formulation_ratios = Column(JSON)  # {feed_id: ratio}
    
    # 목표 영양성분
    target_crude_protein = Column(Float)  # 목표 조단백질 (%)
    target_energy = Column(Float)  # 목표 에너지 (Mcal/kg)
    target_calcium = Column(Float)  # 목표 칼슘 (%)
    target_phosphorus = Column(Float)  # 목표 인 (%)
    
    # 계산된 영양성분
    calculated_nutrition = Column(JSON)  # 계산된 영양성분
    
    # 비용 정보
    total_cost = Column(Float)  # 총 비용 (원/kg)
    cost_breakdown = Column(JSON)  # 비용 세부내역
    
    # 메타데이터
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
