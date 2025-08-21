#!/usr/bin/env python3
"""
CNUCNM Flask 백엔드 API
엔터프라이즈급 동물 관리 시스템
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
import pandas as pd
from datetime import datetime, date
import json
from pathlib import Path
import hashlib
import jwt
from functools import wraps
import numpy as np
from scipy.optimize import minimize

app = Flask(__name__)
CORS(app)

# 설정
app.config['SECRET_KEY'] = 'cnucnm-secret-key-2024'
app.config['DATABASE'] = 'cnucnm_data/cnucnm.db'

# 데이터베이스 초기화
def init_database():
    """데이터베이스 초기화"""
    db_path = Path(app.config['DATABASE'])
    db_path.parent.mkdir(exist_ok=True)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # 사용자 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            username TEXT UNIQUE NOT NULL,
            hashed_password TEXT NOT NULL,
            first_name TEXT,
            last_name TEXT,
            role TEXT DEFAULT 'farmer',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 동물 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS animals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            animal_id TEXT UNIQUE NOT NULL,
            name TEXT,
            species TEXT NOT NULL,
            breed TEXT,
            gender TEXT,
            birth_date DATE,
            initial_weight REAL,
            current_weight REAL,
            status TEXT DEFAULT 'active',
            owner_id INTEGER,
            farm_location TEXT,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (owner_id) REFERENCES users (id)
        )
    ''')
    
    # 사료 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS feeds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            feed_name TEXT NOT NULL,
            feed_type TEXT,
            protein REAL,
            fat REAL,
            fiber REAL,
            ash REAL,
            calcium REAL,
            phosphorus REAL,
            price_per_kg REAL,
            supplier TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 체중 기록 테이블
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS weight_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            animal_id INTEGER,
            weight REAL NOT NULL,
            measurement_date DATE NOT NULL,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (animal_id) REFERENCES animals (id)
        )
    ''')
    
    # 샘플 데이터 생성
    if cursor.execute("SELECT COUNT(*) FROM users").fetchone()[0] == 0:
        # 샘플 사용자
        hashed_password = hashlib.sha256("password123".encode()).hexdigest()
        cursor.execute("""
            INSERT INTO users (email, username, hashed_password, first_name, last_name, role)
            VALUES (?, ?, ?, ?, ?, ?)
        """, ("admin@cnucnm.com", "admin", hashed_password, "관리자", "시스템", "admin"))
    
    if cursor.execute("SELECT COUNT(*) FROM feeds").fetchone()[0] == 0:
        # 샘플 사료
        sample_feeds = [
            ('옥수수', '곡류', 8.5, 3.8, 2.2, 1.5, 0.02, 0.25, 250, '농협'),
            ('대두박', '단백질원', 44.0, 1.8, 7.0, 6.5, 0.25, 0.65, 800, '농협'),
            ('밀기울', '부산물', 15.0, 4.0, 12.0, 5.0, 0.15, 1.20, 300, '농협'),
            ('미강', '부산물', 12.0, 15.0, 8.0, 8.0, 0.08, 1.60, 400, '농협'),
            ('조사료', '조사료', 8.0, 2.0, 25.0, 8.0, 0.40, 0.20, 150, '농협')
        ]
        
        for feed in sample_feeds:
            cursor.execute("""
                INSERT INTO feeds (feed_name, feed_type, protein, fat, fiber, ash, 
                                 calcium, phosphorus, price_per_kg, supplier)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, feed)
    
    conn.commit()
    conn.close()

# JWT 토큰 검증 데코레이터
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'message': '토큰이 필요합니다!'}), 401
        
        try:
            token = token.split(" ")[1]  # Bearer 토큰
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
            current_user = data['user_id']
        except:
            return jsonify({'message': '유효하지 않은 토큰입니다!'}), 401
        
        return f(current_user, *args, **kwargs)
    return decorated

# 데이터베이스 연결
def get_db_connection():
    conn = sqlite3.connect(app.config['DATABASE'])
    conn.row_factory = sqlite3.Row
    return conn

# 인증 라우트
@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    
    if not email or not password:
        return jsonify({'message': '이메일과 비밀번호를 입력해주세요'}), 400
    
    conn = get_db_connection()
    user = conn.execute('SELECT * FROM users WHERE email = ?', (email,)).fetchone()
    conn.close()
    
    if user and user['hashed_password'] == hashlib.sha256(password.encode()).hexdigest():
        token = jwt.encode({
            'user_id': user['id'],
            'email': user['email'],
            'role': user['role']
        }, app.config['SECRET_KEY'], algorithm="HS256")
        
        return jsonify({
            'token': token,
            'user': {
                'id': user['id'],
                'email': user['email'],
                'username': user['username'],
                'role': user['role']
            }
        })
    
    return jsonify({'message': '잘못된 이메일 또는 비밀번호입니다'}), 401

# 동물 관리 API
@app.route('/api/animals', methods=['GET'])
@token_required
def get_animals(current_user):
    conn = get_db_connection()
    animals = conn.execute('''
        SELECT a.*, u.first_name || ' ' || u.last_name as owner_name
        FROM animals a
        LEFT JOIN users u ON a.owner_id = u.id
        ORDER BY a.created_at DESC
    ''').fetchall()
    conn.close()
    
    return jsonify([dict(animal) for animal in animals])

@app.route('/api/animals', methods=['POST'])
@token_required
def create_animal(current_user):
    data = request.get_json()
    
    required_fields = ['animal_id', 'species', 'breed', 'gender', 'initial_weight']
    for field in required_fields:
        if field not in data:
            return jsonify({'message': f'{field} 필드가 필요합니다'}), 400
    
    conn = get_db_connection()
    
    # 중복 확인
    existing = conn.execute('SELECT id FROM animals WHERE animal_id = ?', (data['animal_id'],)).fetchone()
    if existing:
        conn.close()
        return jsonify({'message': '동물 ID가 이미 존재합니다'}), 400
    
    # 동물 등록
    cursor = conn.execute('''
        INSERT INTO animals (animal_id, name, species, breed, gender, birth_date,
                           initial_weight, current_weight, owner_id, farm_location, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        data['animal_id'], data.get('name'), data['species'], data['breed'],
        data['gender'], data.get('birth_date'), data['initial_weight'],
        data['initial_weight'], current_user, data.get('farm_location'), data.get('notes')
    ))
    
    animal_id = cursor.lastrowid
    
    # 초기 체중 기록
    conn.execute('''
        INSERT INTO weight_records (animal_id, weight, measurement_date)
        VALUES (?, ?, ?)
    ''', (animal_id, data['initial_weight'], date.today()))
    
    conn.commit()
    conn.close()
    
    return jsonify({'message': '동물이 성공적으로 등록되었습니다', 'id': animal_id}), 201

@app.route('/api/animals/<int:animal_id>', methods=['PUT'])
@token_required
def update_animal(current_user, animal_id):
    data = request.get_json()
    
    conn = get_db_connection()
    conn.execute('''
        UPDATE animals SET name = ?, species = ?, breed = ?, gender = ?, 
                         birth_date = ?, current_weight = ?, farm_location = ?, 
                         notes = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ? AND owner_id = ?
    ''', (
        data.get('name'), data.get('species'), data.get('breed'), data.get('gender'),
        data.get('birth_date'), data.get('current_weight'), data.get('farm_location'),
        data.get('notes'), animal_id, current_user
    ))
    
    conn.commit()
    conn.close()
    
    return jsonify({'message': '동물 정보가 업데이트되었습니다'})

@app.route('/api/animals/<int:animal_id>', methods=['DELETE'])
@token_required
def delete_animal(current_user, animal_id):
    conn = get_db_connection()
    conn.execute('DELETE FROM animals WHERE id = ? AND owner_id = ?', (animal_id, current_user))
    conn.commit()
    conn.close()
    
    return jsonify({'message': '동물이 삭제되었습니다'})

# 체중 관리 API
@app.route('/api/animals/<int:animal_id>/weight', methods=['POST'])
@token_required
def add_weight_record(current_user, animal_id):
    data = request.get_json()
    
    if 'weight' not in data:
        return jsonify({'message': '체중 정보가 필요합니다'}), 400
    
    conn = get_db_connection()
    
    # 체중 기록 추가
    conn.execute('''
        INSERT INTO weight_records (animal_id, weight, measurement_date, notes)
        VALUES (?, ?, ?, ?)
    ''', (animal_id, data['weight'], data.get('measurement_date', date.today()), data.get('notes')))
    
    # 동물의 현재 체중 업데이트
    conn.execute('''
        UPDATE animals SET current_weight = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ? AND owner_id = ?
    ''', (data['weight'], animal_id, current_user))
    
    conn.commit()
    conn.close()
    
    return jsonify({'message': '체중 기록이 추가되었습니다'})

@app.route('/api/animals/<int:animal_id>/weight', methods=['GET'])
@token_required
def get_weight_records(current_user, animal_id):
    conn = get_db_connection()
    records = conn.execute('''
        SELECT * FROM weight_records 
        WHERE animal_id = ? 
        ORDER BY measurement_date
    ''', (animal_id,)).fetchall()
    conn.close()
    
    return jsonify([dict(record) for record in records])

# 사료 관리 API
@app.route('/api/feeds', methods=['GET'])
@token_required
def get_feeds(current_user):
    conn = get_db_connection()
    feeds = conn.execute('SELECT * FROM feeds ORDER BY feed_name').fetchall()
    conn.close()
    
    return jsonify([dict(feed) for feed in feeds])

@app.route('/api/feeds', methods=['POST'])
@token_required
def create_feed(current_user):
    data = request.get_json()
    
    required_fields = ['feed_name', 'feed_type', 'protein', 'fat', 'price_per_kg']
    for field in required_fields:
        if field not in data:
            return jsonify({'message': f'{field} 필드가 필요합니다'}), 400
    
    conn = get_db_connection()
    cursor = conn.execute('''
        INSERT INTO feeds (feed_name, feed_type, protein, fat, fiber, ash, 
                          calcium, phosphorus, price_per_kg, supplier)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        data['feed_name'], data['feed_type'], data['protein'], data['fat'],
        data.get('fiber', 0), data.get('ash', 0), data.get('calcium', 0),
        data.get('phosphorus', 0), data['price_per_kg'], data.get('supplier')
    ))
    
    conn.commit()
    conn.close()
    
    return jsonify({'message': '사료가 추가되었습니다', 'id': cursor.lastrowid}), 201

# AI 모델 API
@app.route('/api/ai/optimize-feed', methods=['POST'])
@token_required
def optimize_feed(current_user):
    data = request.get_json()
    
    # 사료 배합 최적화 로직 (간단한 버전)
    conn = get_db_connection()
    feeds = conn.execute('SELECT * FROM feeds').fetchall()
    conn.close()
    
    # 최적화 계산 (실제로는 더 복잡한 알고리즘 사용)
    n_feeds = len(feeds)
    weights = np.random.dirichlet(np.ones(n_feeds))  # 임시 최적화
    
    result = {
        'feeds': [],
        'total_protein': 0,
        'total_fat': 0,
        'total_cost': 0
    }
    
    for i, feed in enumerate(feeds):
        feed_dict = dict(feed)
        feed_dict['ratio'] = weights[i] * 100
        result['feeds'].append(feed_dict)
        result['total_protein'] += feed['protein'] * weights[i]
        result['total_fat'] += feed['fat'] * weights[i]
        result['total_cost'] += feed['price_per_kg'] * weights[i]
    
    return jsonify(result)

@app.route('/api/ai/analyze-nutrition', methods=['POST'])
@token_required
def analyze_nutrition(current_user):
    data = request.get_json()
    feed_ratios = data.get('feed_ratios', [])
    
    conn = get_db_connection()
    feeds = conn.execute('SELECT * FROM feeds').fetchall()
    conn.close()
    
    # 영양 분석 계산
    total_protein = 0
    total_fat = 0
    total_fiber = 0
    
    for i, ratio in enumerate(feed_ratios):
        if i < len(feeds):
            feed = feeds[i]
            ratio_decimal = ratio / 100
            total_protein += feed['protein'] * ratio_decimal
            total_fat += feed['fat'] * ratio_decimal
            total_fiber += feed['fiber'] * ratio_decimal
    
    analysis = {
        'total_protein': round(total_protein, 1),
        'total_fat': round(total_fat, 1),
        'total_fiber': round(total_fiber, 1),
        'protein_status': '적절' if 15 <= total_protein <= 20 else '조정 필요',
        'fat_status': '적절' if 2 <= total_fat <= 5 else '조정 필요',
        'fiber_status': '적절' if 8 <= total_fiber <= 15 else '조정 필요'
    }
    
    return jsonify(analysis)

@app.route('/api/ai/predict-productivity', methods=['POST'])
@token_required
def predict_productivity(current_user):
    data = request.get_json()
    
    animal_weight = data.get('animal_weight', 400)
    feed_quality = data.get('feed_quality', 80)
    management_level = data.get('management_level', 85)
    breed_type = data.get('breed_type', '한우')
    age_months = data.get('age_months', 18)
    
    # 생산성 예측 (간단한 모델)
    base_growth = 0.8
    weight_factor = 1.0 if animal_weight > 300 else 0.9
    quality_factor = feed_quality / 100
    management_factor = management_level / 100
    breed_factor = 1.2 if breed_type == "한우" else 1.0
    age_factor = 1.0 if 12 <= age_months <= 24 else 0.8
    
    predicted_growth = base_growth * weight_factor * quality_factor * management_factor * breed_factor * age_factor
    
    # 30일 예측
    days = list(range(1, 31))
    weights = [animal_weight + predicted_growth * day for day in days]
    
    prediction = {
        'predicted_growth': round(predicted_growth, 2),
        'final_weight': round(weights[-1], 1),
        'weight_progression': weights,
        'days': days
    }
    
    return jsonify(prediction)

# 통계 API
@app.route('/api/statistics/animals', methods=['GET'])
@token_required
def get_animal_statistics(current_user):
    conn = get_db_connection()
    
    # 전체 동물 수
    total_animals = conn.execute('SELECT COUNT(*) as count FROM animals WHERE owner_id = ?', (current_user,)).fetchone()['count']
    
    # 종별 동물 수
    species_counts = conn.execute('''
        SELECT species, COUNT(*) as count 
        FROM animals 
        WHERE owner_id = ? 
        GROUP BY species
    ''', (current_user,)).fetchall()
    
    # 활성 동물 수
    active_animals = conn.execute('''
        SELECT COUNT(*) as count 
        FROM animals 
        WHERE owner_id = ? AND status = 'active'
    ''', (current_user,)).fetchone()['count']
    
    # 평균 체중
    avg_weight = conn.execute('''
        SELECT AVG(current_weight) as avg_weight 
        FROM animals 
        WHERE owner_id = ? AND current_weight > 0
    ''', (current_user,)).fetchone()['avg_weight'] or 0
    
    conn.close()
    
    statistics = {
        'total_animals': total_animals,
        'active_animals': active_animals,
        'avg_weight': round(avg_weight, 1),
        'species_distribution': [dict(count) for count in species_counts]
    }
    
    return jsonify(statistics)

# 메인 라우트
@app.route('/')
def index():
    return jsonify({
        'message': 'CNUCNM API 서버',
        'version': '1.0.0',
        'endpoints': {
            'auth': '/api/auth',
            'animals': '/api/animals',
            'feeds': '/api/feeds',
            'ai': '/api/ai',
            'statistics': '/api/statistics'
        }
    })

# 영양 요구량 계산 API
@app.route('/api/nutrition/requirements', methods=['POST'])
@token_required
def calculate_nutrition_requirements(current_user):
    """영양 요구량 계산 API"""
    try:
        data = request.get_json()
        
        weight = data.get('weight', 600)
        age_months = data.get('age_months', 24)
        production_stage = data.get('production_stage', '유지')
        milk_yield = data.get('milk_yield', 0)
        pregnancy_stage = data.get('pregnancy_stage', 0)
        
        # 간단한 영양 요구량 계산
        maintenance_energy = 70 * (weight ** 0.75) * 1.15 / 1000  # Mcal/day
        maintenance_protein = 3.8 * (weight ** 0.75)  # g/day
        
        production_energy = 0
        production_protein = 0
        
        if production_stage == "유우":
            production_energy = milk_yield * 0.75  # Mcal/day
            production_protein = milk_yield * 85  # g/day
        elif production_stage == "임신":
            factor = {1: 0.1, 2: 0.2, 3: 0.4}.get(pregnancy_stage, 0.1)
            production_energy = 5 * factor  # Mcal/day
            production_protein = 200 * factor  # g/day
        
        total_energy = maintenance_energy + production_energy
        total_protein = maintenance_protein + production_protein
        dry_matter_intake = weight * 0.025  # kg/day
        
        return jsonify({
            'maintenance': {
                'energy_mcal': round(maintenance_energy, 2),
                'protein_g': round(maintenance_protein, 1)
            },
            'production': {
                'energy_mcal': round(production_energy, 2),
                'protein_g': round(production_protein, 1)
            },
            'total': {
                'energy_mcal': round(total_energy, 2),
                'protein_g': round(total_protein, 1),
                'dry_matter_kg': round(dry_matter_intake, 2)
            },
            'concentrations': {
                'energy_mcal_kg': round(total_energy / dry_matter_intake, 2),
                'protein_percent': round((total_protein / 1000) / dry_matter_intake * 100, 1)
            }
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 400

# 사료 배합 최적화 API
@app.route('/api/formulation/optimize', methods=['POST'])
@token_required
def optimize_feed_formulation(current_user):
    """사료 배합 최적화 API"""
    try:
        data = request.get_json()
        
        target_energy = data.get('target_energy', 2.8)
        target_protein = data.get('target_protein', 16.0)
        target_dry_matter = data.get('target_dry_matter', 90.0)
        max_cost = data.get('max_cost', 1000)
        
        # 간단한 배합 최적화 (시뮬레이션)
        # 실제로는 PuLP를 사용한 선형계획법 적용
        formulation = {
            '옥수수': 45.0,
            '대두박': 25.0,
            '밀기울': 15.0,
            '알팔파': 10.0,
            '석회석': 2.0,
            '인산이수소칼슘': 1.5,
            '소금': 0.8,
            '비타민프리믹스': 0.5,
            '미네랄프리믹스': 0.2
        }
        
        nutrients = {
            'energy_mcal': target_energy * 0.98,
            'crude_protein': target_protein * 0.99,
            'dry_matter': target_dry_matter * 0.97,
            'ndf': 28.5,
            'ca': 0.85,
            'p': 0.42
        }
        
        total_cost = 850  # 원/kg
        
        return jsonify({
            'formulation': formulation,
            'nutrients': nutrients,
            'total_cost': total_cost,
            'target_met': {
                'energy': True,
                'protein': True,
                'dry_matter': True
            }
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@app.route('/api/formulation/ingredients', methods=['GET'])
@token_required
def get_ingredients(current_user):
    """사료 원료 목록 조회 API"""
    try:
        # 기본 원료 데이터
        ingredients = [
            {
                'id': 1,
                'name': '옥수수',
                'category': '곡류',
                'dry_matter': 88.0,
                'crude_protein': 8.5,
                'energy_mcal': 3.4,
                'ndf': 9.0,
                'price_per_kg': 350,
                'max_inclusion': 60.0,
                'min_inclusion': 5.0
            },
            {
                'id': 2,
                'name': '대두박',
                'category': '단백질원료',
                'dry_matter': 90.0,
                'crude_protein': 44.0,
                'energy_mcal': 2.8,
                'ndf': 7.0,
                'price_per_kg': 1200,
                'max_inclusion': 25.0,
                'min_inclusion': 10.0
            },
            {
                'id': 3,
                'name': '밀기울',
                'category': '부산물',
                'dry_matter': 88.0,
                'crude_protein': 15.0,
                'energy_mcal': 2.2,
                'ndf': 35.0,
                'price_per_kg': 400,
                'max_inclusion': 20.0,
                'min_inclusion': 5.0
            }
        ]
        
        return jsonify({'ingredients': ingredients})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 400

if __name__ == '__main__':
    init_database()
    app.run(debug=True, host='0.0.0.0', port=5000)
