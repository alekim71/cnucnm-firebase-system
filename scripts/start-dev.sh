#!/bin/bash

# CNUCNM 마이크로서비스 개발 환경 시작 스크립트

set -e

echo "🚀 CNUCNM 마이크로서비스 개발 환경 시작 중..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수 정의
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Docker 및 Docker Compose 확인
check_dependencies() {
    log_info "의존성 확인 중..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker가 설치되지 않았습니다."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose가 설치되지 않았습니다."
        exit 1
    fi
    
    log_success "의존성 확인 완료"
}

# 기존 컨테이너 정리
cleanup_existing() {
    log_info "기존 컨테이너 정리 중..."
    
    # 기존 컨테이너 중지 및 제거
    docker-compose -f docker-compose.dev.yml down --remove-orphans 2>/dev/null || true
    
    log_success "기존 컨테이너 정리 완료"
}

# 환경 변수 파일 생성
create_env_file() {
    log_info "환경 변수 파일 생성 중..."
    
    if [ ! -f .env ]; then
        cat > .env << EOF
# CNUCNM 마이크로서비스 개발 환경 설정

# 기본 설정
ENVIRONMENT=development
DEBUG=true
LOG_LEVEL=INFO

# 서버 설정
HOST=0.0.0.0
PORT=8000

# 데이터베이스 설정
DATABASE_URL=postgresql://cnucnm_user:cnucnm_password@localhost:5432/cnucnm
REDIS_URL=redis://localhost:6379
MONGO_URL=mongodb://cnucnm_admin:cnucnm_password@localhost:27017/cnucnm
ELASTICSEARCH_URL=http://localhost:9200

# JWT 설정
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS 설정
CORS_ORIGINS=["http://localhost:3000","http://localhost:8080"]
CORS_ALLOW_CREDENTIALS=true
CORS_ALLOW_METHODS=["GET","POST","PUT","DELETE","OPTIONS"]
CORS_ALLOW_HEADERS=["*"]

# 캐시 설정
CACHE_TTL=3600
CACHE_PREFIX=cnucnm:

# 파일 업로드 설정
MAX_FILE_SIZE=10485760
ALLOWED_FILE_TYPES=["jpg","jpeg","png","gif","pdf","xlsx","xls"]

# MinIO 설정
MINIO_URL=localhost:9000
MINIO_ACCESS_KEY=cnucnm_admin
MINIO_SECRET_KEY=cnucnm_password
MINIO_BUCKET=cnucnm-files
MINIO_SECURE=false

# RabbitMQ 설정
RABBITMQ_URL=amqp://cnucnm_user:cnucnm_password@localhost:5672/

# 모니터링 설정
ENABLE_METRICS=true
METRICS_PORT=9090

# 보안 설정
RATE_LIMIT_PER_MINUTE=100
PASSWORD_MIN_LENGTH=8
PASSWORD_REQUIRE_UPPERCASE=true
PASSWORD_REQUIRE_LOWERCASE=true
PASSWORD_REQUIRE_DIGIT=true
PASSWORD_REQUIRE_SPECIAL=true

# 비즈니스 로직 설정
DEFAULT_PAGE_SIZE=20
MAX_PAGE_SIZE=100

# NASEM 설정
NASEM_VERSION=2024
EOF
        log_success ".env 파일 생성 완료"
    else
        log_info ".env 파일이 이미 존재합니다."
    fi
}

# 개발 환경 시작
start_development() {
    log_info "개발 환경 시작 중..."
    
    # Docker Compose로 서비스 시작
    docker-compose -f docker-compose.dev.yml up -d
    
    log_success "개발 환경 시작 완료"
}

# 서비스 상태 확인
check_services() {
    log_info "서비스 상태 확인 중..."
    
    # 잠시 대기
    sleep 10
    
    # 각 서비스 상태 확인
    services=(
        "postgres:5432"
        "redis:6379"
        "mongodb:27017"
        "rabbitmq:5672"
        "elasticsearch:9200"
        "prometheus:9090"
        "grafana:3000"
        "kibana:5601"
        "jaeger:16686"
        "minio:9000"
    )
    
    for service in "${services[@]}"; do
        host_port=(${service//:/ })
        host=${host_port[0]}
        port=${host_port[1]}
        
        if nc -z localhost $port 2>/dev/null; then
            log_success "$host 서비스가 정상적으로 실행 중입니다 (포트: $port)"
        else
            log_warning "$host 서비스가 아직 시작되지 않았습니다 (포트: $port)"
        fi
    done
}

# 사용법 출력
show_usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -h, --help     이 도움말을 표시합니다"
    echo "  -c, --cleanup  기존 컨테이너를 정리합니다"
    echo "  -s, --status   서비스 상태를 확인합니다"
    echo ""
    echo "예시:"
    echo "  $0              # 개발 환경 시작"
    echo "  $0 -c           # 기존 컨테이너 정리 후 시작"
    echo "  $0 -s           # 서비스 상태만 확인"
}

# 메인 실행
main() {
    case "${1:-}" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -c|--cleanup)
            check_dependencies
            cleanup_existing
            create_env_file
            start_development
            check_services
            ;;
        -s|--status)
            check_services
            ;;
        "")
            check_dependencies
            cleanup_existing
            create_env_file
            start_development
            check_services
            ;;
        *)
            log_error "알 수 없는 옵션: $1"
            show_usage
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@"

echo ""
echo "🎉 CNUCNM 마이크로서비스 개발 환경이 시작되었습니다!"
echo ""
echo "📊 서비스 접속 정보:"
echo "  - API Gateway: http://localhost:8000"
echo "  - Kong Admin: http://localhost:8001"
echo "  - Grafana: http://localhost:3000 (admin/cnucnm_password)"
echo "  - Prometheus: http://localhost:9090"
echo "  - Kibana: http://localhost:5601"
echo "  - Jaeger: http://localhost:16686"
echo "  - MinIO Console: http://localhost:9001 (cnucnm_admin/cnucnm_password)"
echo "  - RabbitMQ Management: http://localhost:15672 (cnucnm_user/cnucnm_password)"
echo ""
echo "🔧 개발 도구:"
echo "  - PostgreSQL: localhost:5432 (cnucnm_user/cnucnm_password)"
echo "  - Redis: localhost:6379"
echo "  - MongoDB: localhost:27017 (cnucnm_admin/cnucnm_password)"
echo "  - Elasticsearch: http://localhost:9200"
echo ""
echo "📝 로그 확인:"
echo "  docker-compose -f docker-compose.dev.yml logs -f [서비스명]"
echo ""
echo "🛑 서비스 중지:"
echo "  docker-compose -f docker-compose.dev.yml down"
