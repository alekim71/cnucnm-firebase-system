-- CNUCNM 완전한 영양소 계산 시스템 데이터베이스
-- MySQL/MariaDB용 SQL 스크립트

-- 데이터베이스 생성
CREATE DATABASE IF NOT EXISTS CNUCNM_System;
USE CNUCNM_System;

-- 수식 카테고리 테이블
CREATE TABLE formula_categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(50) NOT NULL,
    category_icon VARCHAR(10),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 수식 위치 테이블
CREATE TABLE formula_locations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    location_name VARCHAR(50) NOT NULL,
    location_icon VARCHAR(10),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 수식 테이블
CREATE TABLE formulas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    formula_name VARCHAR(100) NOT NULL UNIQUE,
    full_name VARCHAR(200),
    expression TEXT NOT NULL,
    description TEXT,
    level INT DEFAULT 0,
    category_id INT,
    location_id INT,
    is_input_value BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES formula_categories(id),
    FOREIGN KEY (location_id) REFERENCES formula_locations(id)
);

-- 수식 의존성 테이블
CREATE TABLE formula_dependencies (
    id INT PRIMARY KEY AUTO_INCREMENT,
    formula_id INT,
    dependency_formula_id INT,
    dependency_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (formula_id) REFERENCES formulas(id),
    FOREIGN KEY (dependency_formula_id) REFERENCES formulas(id)
);

-- 카테고리 데이터 삽입
INSERT INTO formula_categories (category_name, category_icon, description) VALUES
('protein', '🥩', '단백질 관련 수식'),
('energy', '⚡', '에너지 관련 수식'),
('carbohydrate', '🌾', '탄수화물 관련 수식'),
('fat', '🫘', '지방 관련 수식'),
('mineral', '🪨', '미네랄 관련 수식'),
('vitamin', '💊', '비타민 관련 수식'),
('intake', '🍽️', '섭취량 관련 수식');

-- 위치 데이터 삽입
INSERT INTO formula_locations (location_name, location_icon, description) VALUES
('rumen', '🐄', '반추위'),
('small-intestine', '🫀', '소장'),
('large-intestine', '🫁', '대장'),
('liver', '🧠', '간'),
('systemic', '💪', '전신');

-- 단백질 반추위 수식들
INSERT INTO formulas (formula_name, full_name, expression, description, level, category_id, location_id) VALUES
('MP', 'MP (Metabolizable Protein)', 'MP = MPfeed + MPbact', '대사성 단백질 = 사료 단백질 + 미생물 단백질', 0, 1, 1),
('MPfeed', 'MPfeed (Feed Protein)', 'MPfeed = DIGPB1 + DIGPB2 + DIGPB3', '사료 단백질 = 소화 가능 단백질 1 + 2 + 3', 1, 1, 1),
('MPbact', 'MPbact (Bacterial Protein)', 'MPbact = MCP x 0.64', '미생물 단백질 = 미생물 조단백질 x 효율성', 1, 1, 1),
('DIGPB1', 'DIGPB1 (Digestible Protein 1)', 'DIGPB1 = ID_Protein_1 x adjREPB1', '소화 가능 단백질 1 = 소화율 x 조정된 효율성', 2, 1, 1),
('DIGPB2', 'DIGPB2 (Digestible Protein 2)', 'DIGPB2 = ID_Protein_2 x adjREPB2', '소화 가능 단백질 2 = 소화율 x 조정된 효율성', 2, 1, 1),
('DIGPB3', 'DIGPB3 (Digestible Protein 3)', 'DIGPB3 = ID_Protein_3 x adjREPB3', '소화 가능 단백질 3 = 소화율 x 조정된 효율성', 2, 1, 1),
('MCP', 'MCP (Microbial Crude Protein)', 'MCP = RDPEP x 0.13', '미생물 조단백질 = 분해 단백질 효율성 x 0.13', 2, 1, 1);

-- 에너지 반추위 수식들
INSERT INTO formulas (formula_name, full_name, expression, description, level, category_id, location_id) VALUES
('ME', 'ME (Metabolizable Energy)', 'ME = GE - FE - UE - CH4E', '대사성 에너지 = 총에너지 - 분에너지 - 요에너지 - 메탄에너지', 0, 2, 1),
('GE', 'GE (Gross Energy)', 'GE = (9.4 x EE + 5.65 x CP + 4.2 x (NDF + NFC)) / 100', '총에너지 = 지방 x 9.4 + 단백질 x 5.65 + 탄수화물 x 4.2', 1, 2, 1),
('FE', 'FE (Fecal Energy)', 'FE = GE x (1 - 소화율)', '분에너지 = 총에너지 x (1 - 소화율)', 1, 2, 1),
('UE', 'UE (Urinary Energy)', 'UE = CP x 0.031', '요에너지 = 단백질 x 0.031', 1, 2, 1),
('CH4E', 'CH4E (Methane Energy)', 'CH4E = GE x 0.06', '메탄에너지 = 총에너지 x 0.06', 1, 2, 1);

-- 탄수화물 반추위 수식들
INSERT INTO formulas (formula_name, full_name, expression, description, level, category_id, location_id) VALUES
('CHO', 'CHO (Carbohydrate)', 'CHO = NDF + NFC', '탄수화물 = 중성세제 불용성 섬유 + 비섬유성 탄수화물', 0, 3, 1),
('NDF_Digest', 'NDF_Digest (NDF Digestibility)', 'NDF_Digest = NDF x NDF_소화율', 'NDF 소화량 = NDF x NDF 소화율', 1, 3, 1),
('NFC_Digest', 'NFC_Digest (NFC Digestibility)', 'NFC_Digest = NFC x NFC_소화율', 'NFC 소화량 = NFC x NFC 소화율', 1, 3, 1);

-- 지방 반추위 수식들
INSERT INTO formulas (formula_name, full_name, expression, description, level, category_id, location_id) VALUES
('Fat', 'Fat (Total Fat)', 'Fat = EE', '총 지방 = 에테르 추출물', 0, 4, 1),
('Fat_Digest', 'Fat_Digest (Fat Digestibility)', 'Fat_Digest = EE x Fat_소화율', '지방 소화량 = 에테르 추출물 x 지방 소화율', 1, 4, 1);

-- 미네랄 반추위 수식들
INSERT INTO formulas (formula_name, full_name, expression, description, level, category_id, location_id) VALUES
('Ca', 'Ca (Calcium)', 'Ca = 사료 칼슘 함량', '칼슘 = 사료 칼슘 함량', 0, 5, 1),
('P', 'P (Phosphorus)', 'P = 사료 인 함량', '인 = 사료 인 함량', 0, 5, 1),
('Mg', 'Mg (Magnesium)', 'Mg = 사료 마그네슘 함량', '마그네슘 = 사료 마그네슘 함량', 0, 5, 1),
('K', 'K (Potassium)', 'K = 사료 칼륨 함량', '칼륨 = 사료 칼륨 함량', 0, 5, 1),
('Na', 'Na (Sodium)', 'Na = 사료 나트륨 함량', '나트륨 = 사료 나트륨 함량', 0, 5, 1),
('Cl', 'Cl (Chloride)', 'Cl = 사료 염소 함량', '염소 = 사료 염소 함량', 0, 5, 1),
('S', 'S (Sulfur)', 'S = 사료 황 함량', '황 = 사료 황 함량', 0, 5, 1);

-- 비타민 반추위 수식들
INSERT INTO formulas (formula_name, full_name, expression, description, level, category_id, location_id) VALUES
('VitA', 'VitA (Vitamin A)', 'VitA = 사료 비타민 A 함량', '비타민 A = 사료 비타민 A 함량', 0, 6, 1),
('VitD', 'VitD (Vitamin D)', 'VitD = 사료 비타민 D 함량', '비타민 D = 사료 비타민 D 함량', 0, 6, 1),
('VitE', 'VitE (Vitamin E)', 'VitE = 사료 비타민 E 함량', '비타민 E = 사료 비타민 E 함량', 0, 6, 1),
('VitK', 'VitK (Vitamin K)', 'VitK = 사료 비타민 K 함량', '비타민 K = 사료 비타민 K 함량', 0, 6, 1),
('VitB1', 'VitB1 (Thiamine)', 'VitB1 = 사료 티아민 함량', '티아민 = 사료 티아민 함량', 0, 6, 1),
('VitB2', 'VitB2 (Riboflavin)', 'VitB2 = 사료 리보플라빈 함량', '리보플라빈 = 사료 리보플라빈 함량', 0, 6, 1),
('VitB6', 'VitB6 (Pyridoxine)', 'VitB6 = 사료 피리독신 함량', '피리독신 = 사료 피리독신 함량', 0, 6, 1),
('VitB12', 'VitB12 (Cobalamin)', 'VitB12 = 사료 코발라민 함량', '코발라민 = 사료 코발라민 함량', 0, 6, 1),
('Niacin', 'Niacin (Nicotinic Acid)', 'Niacin = 사료 나이아신 함량', '나이아신 = 사료 나이아신 함량', 0, 6, 1),
('Pantothenic', 'Pantothenic Acid', 'Pantothenic = 사료 판토텐산 함량', '판토텐산 = 사료 판토텐산 함량', 0, 6, 1),
('Biotin', 'Biotin', 'Biotin = 사료 비오틴 함량', '비오틴 = 사료 비오틴 함량', 0, 6, 1),
('Folic', 'Folic Acid', 'Folic = 사료 엽산 함량', '엽산 = 사료 엽산 함량', 0, 6, 1),
('Choline', 'Choline', 'Choline = 사료 콜린 함량', '콜린 = 사료 콜린 함량', 0, 6, 1);

-- 소장 모델 수식들
INSERT INTO formulas (formula_name, full_name, expression, description, level, category_id, location_id) VALUES
('SI_Protein', 'SI_Protein (Small Intestine Protein)', 'SI_Protein = MP x SI_Protein_효율성', '소장 단백질 = 대사성 단백질 x 소장 효율성', 0, 1, 2),
('SI_Energy', 'SI_Energy (Small Intestine Energy)', 'SI_Energy = ME x SI_Energy_효율성', '소장 에너지 = 대사성 에너지 x 소장 효율성', 0, 2, 2),
('SI_Carbohydrate', 'SI_Carbohydrate (Small Intestine Carbohydrate)', 'SI_Carbohydrate = CHO x SI_Carb_효율성', '소장 탄수화물 = 탄수화물 x 소장 효율성', 0, 3, 2),
('SI_Fat', 'SI_Fat (Small Intestine Fat)', 'SI_Fat = Fat x SI_Fat_효율성', '소장 지방 = 지방 x 소장 효율성', 0, 4, 2),
('SI_Ca', 'SI_Ca (Small Intestine Calcium)', 'SI_Ca = Ca x SI_Ca_효율성', '소장 칼슘 = 칼슘 x 소장 효율성', 0, 5, 2),
('SI_P', 'SI_P (Small Intestine Phosphorus)', 'SI_P = P x SI_P_효율성', '소장 인 = 인 x 소장 효율성', 0, 5, 2),
('SI_VitA', 'SI_VitA (Small Intestine Vitamin A)', 'SI_VitA = VitA x SI_VitA_효율성', '소장 비타민 A = 비타민 A x 소장 효율성', 0, 6, 2);

-- 대장 모델 수식들
INSERT INTO formulas (formula_name, full_name, expression, description, level, category_id, location_id) VALUES
('LI_Protein', 'LI_Protein (Large Intestine Protein)', 'LI_Protein = SI_Protein x LI_Protein_효율성', '대장 단백질 = 소장 단백질 x 대장 효율성', 0, 1, 3),
('LI_Energy', 'LI_Energy (Large Intestine Energy)', 'LI_Energy = SI_Energy x LI_Energy_효율성', '대장 에너지 = 소장 에너지 x 대장 효율성', 0, 2, 3);

-- 간 모델 수식들
INSERT INTO formulas (formula_name, full_name, expression, description, level, category_id, location_id) VALUES
('Liver_Protein', 'Liver_Protein (Liver Protein)', 'Liver_Protein = SI_Protein x Liver_Protein_효율성', '간 단백질 = 소장 단백질 x 간 효율성', 0, 1, 4),
('Liver_Energy', 'Liver_Energy (Liver Energy)', 'Liver_Energy = SI_Energy x Liver_Energy_효율성', '간 에너지 = 소장 에너지 x 간 효율성', 0, 2, 4);

-- 전신 모델 수식들
INSERT INTO formulas (formula_name, full_name, expression, description, level, category_id, location_id) VALUES
('Systemic_Protein', 'Systemic_Protein (Systemic Protein)', 'Systemic_Protein = Liver_Protein x Systemic_Protein_효율성', '전신 단백질 = 간 단백질 x 전신 효율성', 0, 1, 5),
('Systemic_Energy', 'Systemic_Energy (Systemic Energy)', 'Systemic_Energy = Liver_Energy x Systemic_Energy_효율성', '전신 에너지 = 간 에너지 x 전신 효율성', 0, 2, 5);

-- 섭취량 모델 수식들
INSERT INTO formulas (formula_name, full_name, expression, description, level, category_id, location_id) VALUES
('DMI', 'DMI (Dry Matter Intake)', 'DMI = 기본 섭취량 x 조정 계수들', '건물 섭취량 = 기본 섭취량 x 조정 계수들', 0, 7, 1),
('기본 섭취량', '기본 섭취량 (Base Intake)', '기본 섭취량 = 체중 x 0.025', '기본 섭취량 = 체중 x 2.5%', 1, 7, 1),
('조정 계수들', '조정 계수들 (Adjustment Factors)', '조정 계수들 = 온도조정 x 습도조정 x 임신조정', '조정 계수들 = 온도 x 습도 x 임신 조정', 1, 7, 1);

-- 입력값들 (잎 노드)
INSERT INTO formulas (formula_name, full_name, expression, description, level, category_id, location_id, is_input_value) VALUES
('체중', '체중 (Body Weight)', '체중 = 입력값', '체중 = 사용자 입력값', 2, 7, 1, TRUE),
('온도', '온도 (Temperature)', '온도 = 입력값', '온도 = 사용자 입력값', 3, 7, 1, TRUE),
('습도', '습도 (Humidity)', '습도 = 입력값', '습도 = 사용자 입력값', 3, 7, 1, TRUE),
('임신일', '임신일 (Pregnancy Day)', '임신일 = 입력값', '임신일 = 사용자 입력값', 3, 7, 1, TRUE),
('사료 단백질 B1 함량', '사료 단백질 B1 함량', '사료 단백질 B1 함량 = 입력값', '사료 단백질 B1 함량 = 사용자 입력값', 5, 1, 1, TRUE),
('사료 단백질 B2 함량', '사료 단백질 B2 함량', '사료 단백질 B2 함량 = 입력값', '사료 단백질 B2 함량 = 사용자 입력값', 5, 1, 1, TRUE),
('사료 단백질 B3 함량', '사료 단백질 B3 함량', '사료 단백질 B3 함량 = 입력값', '사료 단백질 B3 함량 = 사용자 입력값', 5, 1, 1, TRUE),
('사료 지방 함량', '사료 지방 함량', '사료 지방 함량 = 입력값', '사료 지방 함량 = 사용자 입력값', 2, 2, 1, TRUE),
('사료 질소 함량', '사료 질소 함량', '사료 질소 함량 = 입력값', '사료 질소 함량 = 사용자 입력값', 3, 2, 1, TRUE),
('사료 NDF 함량', '사료 NDF 함량', '사료 NDF 함량 = 입력값', '사료 NDF 함량 = 사용자 입력값', 2, 2, 1, TRUE),
('사료 회분 함량', '사료 회분 함량', '사료 회분 함량 = 입력값', '사료 회분 함량 = 사용자 입력값', 3, 2, 1, TRUE),
('사료 칼슘 함량', '사료 칼슘 함량', '사료 칼슘 함량 = 입력값', '사료 칼슘 함량 = 사용자 입력값', 0, 5, 1, TRUE),
('사료 인 함량', '사료 인 함량', '사료 인 함량 = 입력값', '사료 인 함량 = 사용자 입력값', 0, 5, 1, TRUE),
('사료 마그네슘 함량', '사료 마그네슘 함량', '사료 마그네슘 함량 = 입력값', '사료 마그네슘 함량 = 사용자 입력값', 0, 5, 1, TRUE),
('사료 칼륨 함량', '사료 칼륨 함량', '사료 칼륨 함량 = 입력값', '사료 칼륨 함량 = 사용자 입력값', 0, 5, 1, TRUE),
('사료 나트륨 함량', '사료 나트륨 함량', '사료 나트륨 함량 = 입력값', '사료 나트륨 함량 = 사용자 입력값', 0, 5, 1, TRUE),
('사료 염소 함량', '사료 염소 함량', '사료 염소 함량 = 입력값', '사료 염소 함량 = 사용자 입력값', 0, 5, 1, TRUE),
('사료 황 함량', '사료 황 함량', '사료 황 함량 = 입력값', '사료 황 함량 = 사용자 입력값', 0, 5, 1, TRUE),
('사료 비타민 A 함량', '사료 비타민 A 함량', '사료 비타민 A 함량 = 입력값', '사료 비타민 A 함량 = 사용자 입력값', 0, 6, 1, TRUE),
('사료 비타민 D 함량', '사료 비타민 D 함량', '사료 비타민 D 함량 = 입력값', '사료 비타민 D 함량 = 사용자 입력값', 0, 6, 1, TRUE),
('사료 비타민 E 함량', '사료 비타민 E 함량', '사료 비타민 E 함량 = 입력값', '사료 비타민 E 함량 = 사용자 입력값', 0, 6, 1, TRUE),
('사료 비타민 K 함량', '사료 비타민 K 함량', '사료 비타민 K 함량 = 입력값', '사료 비타민 K 함량 = 사용자 입력값', 0, 6, 1, TRUE),
('사료 티아민 함량', '사료 티아민 함량', '사료 티아민 함량 = 입력값', '사료 티아민 함량 = 사용자 입력값', 0, 6, 1, TRUE),
('사료 리보플라빈 함량', '사료 리보플라빈 함량', '사료 리보플라빈 함량 = 입력값', '사료 리보플라빈 함량 = 사용자 입력값', 0, 6, 1, TRUE),
('사료 피리독신 함량', '사료 피리독신 함량', '사료 피리독신 함량 = 입력값', '사료 피리독신 함량 = 사용자 입력값', 0, 6, 1, TRUE),
('사료 코발라민 함량', '사료 코발라민 함량', '사료 코발라민 함량 = 입력값', '사료 코발라민 함량 = 사용자 입력값', 0, 6, 1, TRUE),
('사료 나이아신 함량', '사료 나이아신 함량', '사료 나이아신 함량 = 입력값', '사료 나이아신 함량 = 사용자 입력값', 0, 6, 1, TRUE),
('사료 판토텐산 함량', '사료 판토텐산 함량', '사료 판토텐산 함량 = 입력값', '사료 판토텐산 함량 = 사용자 입력값', 0, 6, 1, TRUE),
('사료 비오틴 함량', '사료 비오틴 함량', '사료 비오틴 함량 = 입력값', '사료 비오틴 함량 = 사용자 입력값', 0, 6, 1, TRUE),
('사료 엽산 함량', '사료 엽산 함량', '사료 엽산 함량 = 입력값', '사료 엽산 함량 = 사용자 입력값', 0, 6, 1, TRUE),
('사료 콜린 함량', '사료 콜린 함량', '사료 콜린 함량 = 입력값', '사료 콜린 함량 = 사용자 입력값', 0, 6, 1, TRUE);

-- 인덱스 생성
CREATE INDEX idx_formula_name ON formulas(formula_name);
CREATE INDEX idx_formula_category ON formulas(category_id);
CREATE INDEX idx_formula_location ON formulas(location_id);
CREATE INDEX idx_formula_level ON formulas(level);
CREATE INDEX idx_formula_input ON formulas(is_input_value);

-- 뷰 생성
CREATE VIEW formula_summary AS
SELECT 
    f.formula_name,
    f.full_name,
    f.expression,
    f.description,
    f.level,
    c.category_name,
    l.location_name,
    f.is_input_value,
    COUNT(fd.dependency_formula_id) as dependency_count
FROM formulas f
LEFT JOIN formula_categories c ON f.category_id = c.id
LEFT JOIN formula_locations l ON f.location_id = l.id
LEFT JOIN formula_dependencies fd ON f.id = fd.formula_id
GROUP BY f.id, f.formula_name, f.full_name, f.expression, f.description, f.level, c.category_name, l.location_name, f.is_input_value;

-- 통계 뷰
CREATE VIEW formula_statistics AS
SELECT 
    c.category_name,
    l.location_name,
    COUNT(*) as formula_count,
    SUM(CASE WHEN f.is_input_value = 1 THEN 1 ELSE 0 END) as input_count,
    SUM(CASE WHEN f.is_input_value = 0 THEN 1 ELSE 0 END) as calculated_count
FROM formulas f
JOIN formula_categories c ON f.category_id = c.id
JOIN formula_locations l ON f.location_id = l.id
GROUP BY c.category_name, l.location_name;

-- 완료 메시지
SELECT 'CNUCNM 데이터베이스 생성 완료!' as message;
SELECT COUNT(*) as total_formulas FROM formulas;
SELECT COUNT(*) as input_values FROM formulas WHERE is_input_value = 1;
SELECT COUNT(*) as calculated_formulas FROM formulas WHERE is_input_value = 0;
