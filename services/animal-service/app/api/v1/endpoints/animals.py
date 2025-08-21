"""
동물 관리 엔드포인트
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func

from shared.common.database import get_postgres_session
from app.models.animal import Animal, AnimalBreed, AnimalHealthRecord, AnimalWeightRecord, AnimalFeedRecord
from app.schemas.animal import (
    AnimalCreate, AnimalUpdate, AnimalResponse, AnimalListResponse, AnimalSearch,
    AnimalBreedCreate, AnimalBreedUpdate, AnimalBreedResponse,
    AnimalHealthRecordCreate, AnimalHealthRecordUpdate, AnimalHealthRecordResponse,
    AnimalWeightRecordCreate, AnimalWeightRecordUpdate, AnimalWeightRecordResponse,
    AnimalFeedRecordCreate, AnimalFeedRecordUpdate, AnimalFeedRecordResponse,
    AnimalStatistics
)
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)

def get_current_user_id() -> int:
    """현재 사용자 ID 반환 (임시 - 실제로는 JWT 토큰에서 추출)"""
    # TODO: JWT 토큰에서 사용자 ID 추출
    return 1

@router.post("/", response_model=AnimalResponse)
async def create_animal(
    animal_data: AnimalCreate,
    db: Session = Depends(get_postgres_session)
):
    """동물 등록"""
    try:
        current_user_id = get_current_user_id()
        
        # 동물 ID 중복 확인
        existing_animal = db.query(Animal).filter(
            Animal.animal_id == animal_data.animal_id,
            Animal.user_id == current_user_id
        ).first()
        
        if existing_animal:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미 등록된 동물 ID입니다"
            )
        
        # 품종 확인
        if animal_data.breed_id:
            breed = db.query(AnimalBreed).filter(
                AnimalBreed.id == animal_data.breed_id,
                AnimalBreed.is_active == True
            ).first()
            if not breed:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="존재하지 않는 품종입니다"
                )
        
        # 동물 생성
        animal = Animal(
            user_id=current_user_id,
            **animal_data.dict()
        )
        
        db.add(animal)
        db.commit()
        db.refresh(animal)
        
        logger.info(f"새 동물 등록: {animal.animal_id} ({animal.animal_type})")
        
        return animal
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"동물 등록 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="동물 등록 중 오류가 발생했습니다"
        )

@router.get("/{animal_id}", response_model=AnimalResponse)
async def get_animal(
    animal_id: int,
    db: Session = Depends(get_postgres_session)
):
    """동물 정보 조회"""
    current_user_id = get_current_user_id()
    
    animal = db.query(Animal).filter(
        Animal.id == animal_id,
        Animal.user_id == current_user_id
    ).first()
    
    if not animal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="동물을 찾을 수 없습니다"
        )
    
    return animal

@router.get("/", response_model=AnimalListResponse)
async def get_animals(
    search: AnimalSearch = Depends(),
    db: Session = Depends(get_postgres_session)
):
    """동물 목록 조회"""
    try:
        current_user_id = get_current_user_id()
        
        # 쿼리 빌드
        query = db.query(Animal).filter(Animal.user_id == current_user_id)
        
        # 검색 조건 적용
        if search.animal_id:
            query = query.filter(Animal.animal_id.ilike(f"%{search.animal_id}%"))
        
        if search.name:
            query = query.filter(Animal.name.ilike(f"%{search.name}%"))
        
        if search.animal_type:
            query = query.filter(Animal.animal_type == search.animal_type)
        
        if search.breed_id:
            query = query.filter(Animal.breed_id == search.breed_id)
        
        if search.gender:
            query = query.filter(Animal.gender == search.gender)
        
        if search.status:
            query = query.filter(Animal.status == search.status)
        
        if search.farm_location:
            query = query.filter(Animal.farm_location.ilike(f"%{search.farm_location}%"))
        
        if search.pen_number:
            query = query.filter(Animal.pen_number.ilike(f"%{search.pen_number}%"))
        
        # 전체 개수 조회
        total = query.count()
        
        # 페이징 적용
        offset = (search.page - 1) * search.size
        animals = query.offset(offset).limit(search.size).all()
        
        # 페이지 수 계산
        pages = (total + search.size - 1) // search.size
        
        return AnimalListResponse(
            animals=animals,
            total=total,
            page=search.page,
            size=search.size,
            pages=pages
        )
        
    except Exception as e:
        logger.error(f"동물 목록 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="동물 목록 조회 중 오류가 발생했습니다"
        )

@router.put("/{animal_id}", response_model=AnimalResponse)
async def update_animal(
    animal_id: int,
    animal_data: AnimalUpdate,
    db: Session = Depends(get_postgres_session)
):
    """동물 정보 업데이트"""
    try:
        current_user_id = get_current_user_id()
        
        animal = db.query(Animal).filter(
            Animal.id == animal_id,
            Animal.user_id == current_user_id
        ).first()
        
        if not animal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="동물을 찾을 수 없습니다"
            )
        
        # 품종 확인
        if animal_data.breed_id:
            breed = db.query(AnimalBreed).filter(
                AnimalBreed.id == animal_data.breed_id,
                AnimalBreed.is_active == True
            ).first()
            if not breed:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="존재하지 않는 품종입니다"
                )
        
        # 업데이트할 필드들
        update_data = animal_data.dict(exclude_unset=True)
        
        for field, value in update_data.items():
            if hasattr(animal, field):
                setattr(animal, field, value)
        
        db.commit()
        db.refresh(animal)
        
        logger.info(f"동물 정보 업데이트: {animal.animal_id}")
        
        return animal
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"동물 정보 업데이트 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="동물 정보 업데이트 중 오류가 발생했습니다"
        )

@router.delete("/{animal_id}")
async def delete_animal(
    animal_id: int,
    db: Session = Depends(get_postgres_session)
):
    """동물 삭제"""
    try:
        current_user_id = get_current_user_id()
        
        animal = db.query(Animal).filter(
            Animal.id == animal_id,
            Animal.user_id == current_user_id
        ).first()
        
        if not animal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="동물을 찾을 수 없습니다"
            )
        
        # 실제 삭제 대신 비활성화
        animal.is_active = False
        animal.status = "inactive"
        
        db.commit()
        
        logger.info(f"동물 삭제: {animal.animal_id}")
        
        return {"message": "동물이 삭제되었습니다"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"동물 삭제 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="동물 삭제 중 오류가 발생했습니다"
        )

# 품종 관리 엔드포인트
@router.post("/breeds", response_model=AnimalBreedResponse)
async def create_breed(
    breed_data: AnimalBreedCreate,
    db: Session = Depends(get_postgres_session)
):
    """품종 등록"""
    try:
        # 품종명 중복 확인
        existing_breed = db.query(AnimalBreed).filter(
            AnimalBreed.name == breed_data.name,
            AnimalBreed.animal_type == breed_data.animal_type
        ).first()
        
        if existing_breed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미 등록된 품종입니다"
            )
        
        breed = AnimalBreed(**breed_data.dict())
        db.add(breed)
        db.commit()
        db.refresh(breed)
        
        logger.info(f"새 품종 등록: {breed.name} ({breed.animal_type})")
        
        return breed
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"품종 등록 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="품종 등록 중 오류가 발생했습니다"
        )

@router.get("/breeds", response_model=List[AnimalBreedResponse])
async def get_breeds(
    animal_type: Optional[str] = None,
    db: Session = Depends(get_postgres_session)
):
    """품종 목록 조회"""
    try:
        query = db.query(AnimalBreed).filter(AnimalBreed.is_active == True)
        
        if animal_type:
            query = query.filter(AnimalBreed.animal_type == animal_type)
        
        breeds = query.all()
        return breeds
        
    except Exception as e:
        logger.error(f"품종 목록 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="품종 목록 조회 중 오류가 발생했습니다"
        )

# 건강 기록 엔드포인트
@router.post("/{animal_id}/health-records", response_model=AnimalHealthRecordResponse)
async def create_health_record(
    animal_id: int,
    health_data: AnimalHealthRecordCreate,
    db: Session = Depends(get_postgres_session)
):
    """건강 기록 등록"""
    try:
        current_user_id = get_current_user_id()
        
        # 동물 확인
        animal = db.query(Animal).filter(
            Animal.id == animal_id,
            Animal.user_id == current_user_id
        ).first()
        
        if not animal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="동물을 찾을 수 없습니다"
            )
        
        health_record = AnimalHealthRecord(
            animal_id=animal_id,
            **health_data.dict()
        )
        
        db.add(health_record)
        db.commit()
        db.refresh(health_record)
        
        logger.info(f"건강 기록 등록: {animal.animal_id}")
        
        return health_record
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"건강 기록 등록 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="건강 기록 등록 중 오류가 발생했습니다"
        )

@router.get("/{animal_id}/health-records", response_model=List[AnimalHealthRecordResponse])
async def get_health_records(
    animal_id: int,
    db: Session = Depends(get_postgres_session)
):
    """건강 기록 목록 조회"""
    try:
        current_user_id = get_current_user_id()
        
        # 동물 확인
        animal = db.query(Animal).filter(
            Animal.id == animal_id,
            Animal.user_id == current_user_id
        ).first()
        
        if not animal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="동물을 찾을 수 없습니다"
            )
        
        health_records = db.query(AnimalHealthRecord).filter(
            AnimalHealthRecord.animal_id == animal_id
        ).order_by(AnimalHealthRecord.record_date.desc()).all()
        
        return health_records
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"건강 기록 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="건강 기록 조회 중 오류가 발생했습니다"
        )

# 체중 기록 엔드포인트
@router.post("/{animal_id}/weight-records", response_model=AnimalWeightRecordResponse)
async def create_weight_record(
    animal_id: int,
    weight_data: AnimalWeightRecordCreate,
    db: Session = Depends(get_postgres_session)
):
    """체중 기록 등록"""
    try:
        current_user_id = get_current_user_id()
        
        # 동물 확인
        animal = db.query(Animal).filter(
            Animal.id == animal_id,
            Animal.user_id == current_user_id
        ).first()
        
        if not animal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="동물을 찾을 수 없습니다"
            )
        
        weight_record = AnimalWeightRecord(
            animal_id=animal_id,
            **weight_data.dict()
        )
        
        db.add(weight_record)
        db.commit()
        db.refresh(weight_record)
        
        # 동물의 현재 체중 업데이트
        animal.weight = weight_data.weight
        db.commit()
        
        logger.info(f"체중 기록 등록: {animal.animal_id} ({weight_data.weight}kg)")
        
        return weight_record
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"체중 기록 등록 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="체중 기록 등록 중 오류가 발생했습니다"
        )

@router.get("/{animal_id}/weight-records", response_model=List[AnimalWeightRecordResponse])
async def get_weight_records(
    animal_id: int,
    db: Session = Depends(get_postgres_session)
):
    """체중 기록 목록 조회"""
    try:
        current_user_id = get_current_user_id()
        
        # 동물 확인
        animal = db.query(Animal).filter(
            Animal.id == animal_id,
            Animal.user_id == current_user_id
        ).first()
        
        if not animal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="동물을 찾을 수 없습니다"
            )
        
        weight_records = db.query(AnimalWeightRecord).filter(
            AnimalWeightRecord.animal_id == animal_id
        ).order_by(AnimalWeightRecord.record_date.desc()).all()
        
        return weight_records
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"체중 기록 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="체중 기록 조회 중 오류가 발생했습니다"
        )

# 사료 급여 기록 엔드포인트
@router.post("/{animal_id}/feed-records", response_model=AnimalFeedRecordResponse)
async def create_feed_record(
    animal_id: int,
    feed_data: AnimalFeedRecordCreate,
    db: Session = Depends(get_postgres_session)
):
    """사료 급여 기록 등록"""
    try:
        current_user_id = get_current_user_id()
        
        # 동물 확인
        animal = db.query(Animal).filter(
            Animal.id == animal_id,
            Animal.user_id == current_user_id
        ).first()
        
        if not animal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="동물을 찾을 수 없습니다"
            )
        
        feed_record = AnimalFeedRecord(
            animal_id=animal_id,
            **feed_data.dict()
        )
        
        db.add(feed_record)
        db.commit()
        db.refresh(feed_record)
        
        logger.info(f"사료 급여 기록 등록: {animal.animal_id} ({feed_data.feed_type})")
        
        return feed_record
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"사료 급여 기록 등록 실패: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="사료 급여 기록 등록 중 오류가 발생했습니다"
        )

@router.get("/{animal_id}/feed-records", response_model=List[AnimalFeedRecordResponse])
async def get_feed_records(
    animal_id: int,
    db: Session = Depends(get_postgres_session)
):
    """사료 급여 기록 목록 조회"""
    try:
        current_user_id = get_current_user_id()
        
        # 동물 확인
        animal = db.query(Animal).filter(
            Animal.id == animal_id,
            Animal.user_id == current_user_id
        ).first()
        
        if not animal:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="동물을 찾을 수 없습니다"
            )
        
        feed_records = db.query(AnimalFeedRecord).filter(
            AnimalFeedRecord.animal_id == animal_id
        ).order_by(AnimalFeedRecord.feed_date.desc()).all()
        
        return feed_records
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"사료 급여 기록 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="사료 급여 기록 조회 중 오류가 발생했습니다"
        )

# 통계 엔드포인트
@router.get("/statistics", response_model=AnimalStatistics)
async def get_animal_statistics(
    db: Session = Depends(get_postgres_session)
):
    """동물 통계 정보"""
    try:
        current_user_id = get_current_user_id()
        
        # 전체 동물 수
        total_animals = db.query(Animal).filter(
            Animal.user_id == current_user_id
        ).count()
        
        # 활성 동물 수
        active_animals = db.query(Animal).filter(
            Animal.user_id == current_user_id,
            Animal.is_active == True
        ).count()
        
        # 동물 종류별 통계
        animals_by_type = db.query(
            Animal.animal_type,
            func.count(Animal.id)
        ).filter(
            Animal.user_id == current_user_id
        ).group_by(Animal.animal_type).all()
        
        # 동물 상태별 통계
        animals_by_status = db.query(
            Animal.status,
            func.count(Animal.id)
        ).filter(
            Animal.user_id == current_user_id
        ).group_by(Animal.status).all()
        
        # 동물 성별 통계
        animals_by_gender = db.query(
            Animal.gender,
            func.count(Animal.id)
        ).filter(
            Animal.user_id == current_user_id
        ).group_by(Animal.gender).all()
        
        # 평균 체중
        avg_weight_result = db.query(func.avg(Animal.weight)).filter(
            Animal.user_id == current_user_id,
            Animal.weight.isnot(None)
        ).scalar()
        average_weight = float(avg_weight_result) if avg_weight_result else None
        
        # 총 우유 생산량 (젖소만)
        total_milk_result = db.query(func.sum(Animal.milk_production)).filter(
            Animal.user_id == current_user_id,
            Animal.animal_type == "dairy_cow",
            Animal.milk_production.isnot(None)
        ).scalar()
        total_milk_production = float(total_milk_result) if total_milk_result else None
        
        return AnimalStatistics(
            total_animals=total_animals,
            active_animals=active_animals,
            animals_by_type=dict(animals_by_type),
            animals_by_status=dict(animals_by_status),
            animals_by_gender=dict(animals_by_gender),
            average_weight=average_weight,
            total_milk_production=total_milk_production
        )
        
    except Exception as e:
        logger.error(f"동물 통계 조회 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="동물 통계 조회 중 오류가 발생했습니다"
        )
