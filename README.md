# CNUCNM Microservices System

## 🎯 프로젝트 개요

CNUCNM (Chungnam National University Cattle Nutrition Model)은 소의 영양 요구량 계산 및 사료 배합 최적화를 위한 마이크로서비스 시스템입니다.

### 핵심 기능
- **NASEM(2024) 기준** 영양 요구량 계산
- **선형계획법**을 활용한 사료 배합 최적화
- **품종별 특성** 반영 (한우, 홀스타인)
- **생리적 단계별** 지원 (송아지~건유기)

## 🏗️ 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client Layer                             │
├─────────────────────────────────────────────────────────────────┤
│  Web UI  │  Mobile App  │  API Client  │  3rd Party Integration │
└─────────────────────────────────────────────────────────────────┘
                                    │
┌─────────────────────────────────────────────────────────────────┐
│                      API Gateway Layer                          │
├─────────────────────────────────────────────────────────────────┤
│  Kong/Envoy  │  Rate Limiting  │  Authentication  │  Load Balancer │
└─────────────────────────────────────────────────────────────────┘
                                    │
┌─────────────────────────────────────────────────────────────────┐
│                    Microservices Layer                          │
├─────────────────────────────────────────────────────────────────┤
│ User Mgmt │ Animal Mgmt │ Feed Library │ Nutrition Calc │ Formulation │
│ Analytics │ Reports     │ Notifications │ Intake Pred   │ Analysis    │
└─────────────────────────────────────────────────────────────────┘
                                    │
┌─────────────────────────────────────────────────────────────────┐
│                     Data Layer                                  │
├─────────────────────────────────────────────────────────────────┤
│ PostgreSQL │ MongoDB │ Redis │ Elasticsearch │ MinIO (S3) │ RabbitMQ │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 빠른 시작

### 개발 환경 요구사항
- Docker & Docker Compose
- Python 3.11+
- Node.js 18+
- Kubernetes (Minikube/Docker Desktop)

### 로컬 개발 환경 실행
```bash
# 1. 저장소 클론
git clone <repository-url>
cd cnucnm-microservices

# 2. 개발 환경 시작
docker-compose -f docker-compose.dev.yml up -d

# 3. 서비스 확인
curl http://localhost:8000/health
```

## 📁 프로젝트 구조

```
cnucnm-microservices/
├── infrastructure/          # 인프라 설정
│   ├── docker/             # Docker 설정
│   ├── kubernetes/         # Kubernetes 매니페스트
│   ├── terraform/          # 인프라 자동화
│   └── monitoring/         # 모니터링 설정
├── services/               # 마이크로서비스
│   ├── user-service/       # 사용자 관리
│   ├── animal-service/     # 동물 정보 관리
│   ├── feed-library-service/ # 사료 라이브러리
│   ├── nutrition-service/  # 영양 요구량 계산
│   ├── formulation-service/ # 사료 배합 최적화
│   ├── analysis-service/   # 영양 분석
│   ├── intake-service/     # 섭취량 예측
│   ├── report-service/     # 보고서 생성
│   ├── notification-service/ # 알림 서비스
│   └── analytics-service/  # 데이터 분석
├── shared/                 # 공통 모듈
│   ├── common/            # 공통 유틸리티
│   ├── models/            # 공통 데이터 모델
│   └── utils/             # 공통 함수
├── clients/               # 클라이언트 애플리케이션
│   ├── web-ui/           # React 웹 UI
│   └── mobile-app/       # React Native 모바일 앱
├── docs/                 # 문서
├── tests/                # 테스트
└── scripts/              # 스크립트
```

## 🔧 기술 스택

### 백엔드
- **Python 3.11+** + **FastAPI**
- **PostgreSQL** + **MongoDB** + **Redis**
- **Celery** (비동기 작업)
- **NumPy/SciPy** (수치 계산)
- **PuLP** (선형계획법)

### 프론트엔드
- **React 18** + **TypeScript**
- **Material-UI**
- **Redux Toolkit**
- **React Query**

### 인프라
- **Docker** + **Kubernetes**
- **Kong** (API Gateway)
- **Prometheus** + **Grafana**
- **ELK Stack**

## 📊 API 문서

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **API Gateway**: http://localhost:8001

## 🧪 테스트

```bash
# 단위 테스트
pytest tests/unit/

# 통합 테스트
pytest tests/integration/

# E2E 테스트
pytest tests/e2e/

# 테스트 커버리지
pytest --cov=services/ --cov-report=html
```

## 📈 모니터링

- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9090
- **Kibana**: http://localhost:5601

## 🚀 배포

### 개발 환경
```bash
docker-compose -f docker-compose.dev.yml up -d
```

### 스테이징 환경
```bash
kubectl apply -f infrastructure/kubernetes/staging/
```

### 프로덕션 환경
```bash
kubectl apply -f infrastructure/kubernetes/production/
```

## 📚 문서

- [시스템 아키텍처](./docs/architecture.md)
- [API 명세](./docs/api-specification.md)
- [개발 가이드](./docs/development-guide.md)
- [배포 가이드](./docs/deployment-guide.md)

## 🤝 기여하기

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 📞 지원

- **이슈 리포트**: [GitHub Issues](https://github.com/your-repo/issues)
- **문서**: [Wiki](https://github.com/your-repo/wiki)
- **이메일**: support@cnucnm.com

---

**CNUCNM Microservices System** - 축산 영양 관리의 디지털 전환
