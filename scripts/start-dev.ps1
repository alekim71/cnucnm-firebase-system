# CNUCNM 마이크로서비스 개발 환경 시작 스크립트 (PowerShell)

param(
    [switch]$Cleanup,
    [switch]$Status,
    [switch]$Help
)

# 색상 정의
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"

# 함수 정의
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Red
}

# 의존성 확인
function Test-Dependencies {
    Write-Info "의존성 확인 중..."
    
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker가 설치되지 않았습니다."
        exit 1
    }
    
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        Write-Error "Docker Compose가 설치되지 않았습니다."
        exit 1
    }
    
    Write-Success "의존성 확인 완료"
}

# 기존 컨테이너 정리
function Remove-ExistingContainers {
    Write-Info "기존 컨테이너 정리 중..."
    
    try {
        docker-compose -f docker-compose.dev.yml down --remove-orphans
        Write-Success "기존 컨테이너 정리 완료"
    }
    catch {
        Write-Warning "기존 컨테이너가 없거나 정리 중 오류가 발생했습니다."
    }
}

# 환경 변수 파일 생성
function New-EnvFile {
    Write-Info "환경 변수 파일 생성 중..."
    
    if (-not (Test-Path ".env")) {
        $envContent = @"
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
"@
        
        $envContent | Out-File -FilePath ".env" -Encoding UTF8
        Write-Success ".env 파일 생성 완료"
    }
    else {
        Write-Info ".env 파일이 이미 존재합니다."
    }
}

# 개발 환경 시작
function Start-Development {
    Write-Info "개발 환경 시작 중..."
    
    try {
        docker-compose -f docker-compose.dev.yml up -d
        Write-Success "개발 환경 시작 완료"
    }
    catch {
        Write-Error "개발 환경 시작 중 오류가 발생했습니다: $_"
        exit 1
    }
}

# 서비스 상태 확인
function Test-Services {
    Write-Info "서비스 상태 확인 중..."
    
    Start-Sleep -Seconds 10
    
    $services = @(
        @{Name="postgres"; Port=5432},
        @{Name="redis"; Port=6379},
        @{Name="mongodb"; Port=27017},
        @{Name="rabbitmq"; Port=5672},
        @{Name="elasticsearch"; Port=9200},
        @{Name="prometheus"; Port=9090},
        @{Name="grafana"; Port=3000},
        @{Name="kibana"; Port=5601},
        @{Name="jaeger"; Port=16686},
        @{Name="minio"; Port=9000}
    )
    
    foreach ($service in $services) {
        try {
            $connection = Test-NetConnection -ComputerName localhost -Port $service.Port -InformationLevel Quiet
            if ($connection) {
                Write-Success "$($service.Name) 서비스가 정상적으로 실행 중입니다 (포트: $($service.Port))"
            }
            else {
                Write-Warning "$($service.Name) 서비스가 아직 시작되지 않았습니다 (포트: $($service.Port))"
            }
        }
        catch {
            Write-Warning "$($service.Name) 서비스 상태 확인 실패 (포트: $($service.Port))"
        }
    }
}

# 사용법 출력
function Show-Usage {
    Write-Host "사용법: $($MyInvocation.MyCommand.Name) [옵션]"
    Write-Host ""
    Write-Host "옵션:"
    Write-Host "  -Help     이 도움말을 표시합니다"
    Write-Host "  -Cleanup  기존 컨테이너를 정리합니다"
    Write-Host "  -Status   서비스 상태를 확인합니다"
    Write-Host ""
    Write-Host "예시:"
    Write-Host "  $($MyInvocation.MyCommand.Name)              # 개발 환경 시작"
    Write-Host "  $($MyInvocation.MyCommand.Name) -Cleanup     # 기존 컨테이너 정리 후 시작"
    Write-Host "  $($MyInvocation.MyCommand.Name) -Status      # 서비스 상태만 확인"
}

# 메인 실행
function Main {
    if ($Help) {
        Show-Usage
        return
    }
    
    if ($Status) {
        Test-Services
        return
    }
    
    if ($Cleanup) {
        Test-Dependencies
        Remove-ExistingContainers
        New-EnvFile
        Start-Development
        Test-Services
    }
    else {
        Test-Dependencies
        Remove-ExistingContainers
        New-EnvFile
        Start-Development
        Test-Services
    }
}

# 스크립트 실행
Main

Write-Host ""
Write-Host "🎉 CNUCNM 마이크로서비스 개발 환경이 시작되었습니다!" -ForegroundColor $Green
Write-Host ""
Write-Host "📊 서비스 접속 정보:" -ForegroundColor $Blue
Write-Host "  - API Gateway: http://localhost:8000"
Write-Host "  - Kong Admin: http://localhost:8001"
Write-Host "  - Grafana: http://localhost:3000 (admin/cnucnm_password)"
Write-Host "  - Prometheus: http://localhost:9090"
Write-Host "  - Kibana: http://localhost:5601"
Write-Host "  - Jaeger: http://localhost:16686"
Write-Host "  - MinIO Console: http://localhost:9001 (cnucnm_admin/cnucnm_password)"
Write-Host "  - RabbitMQ Management: http://localhost:15672 (cnucnm_user/cnucnm_password)"
Write-Host ""
Write-Host "🔧 개발 도구:" -ForegroundColor $Blue
Write-Host "  - PostgreSQL: localhost:5432 (cnucnm_user/cnucnm_password)"
Write-Host "  - Redis: localhost:6379"
Write-Host "  - MongoDB: localhost:27017 (cnucnm_admin/cnucnm_password)"
Write-Host "  - Elasticsearch: http://localhost:9200"
Write-Host ""
Write-Host "📝 로그 확인:" -ForegroundColor $Blue
Write-Host "  docker-compose -f docker-compose.dev.yml logs -f [서비스명]"
Write-Host ""
Write-Host "🛑 서비스 중지:" -ForegroundColor $Blue
Write-Host "  docker-compose -f docker-compose.dev.yml down"
