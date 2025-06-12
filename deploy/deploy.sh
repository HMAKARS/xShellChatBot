#!/bin/bash

# XShell AI 챗봇 배포 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
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

# 환경 변수 확인
check_env_vars() {
    log_info "환경 변수 확인 중..."
    
    required_vars=("SECRET_KEY" "ALLOWED_HOSTS")
    missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        log_error "다음 환경 변수가 설정되지 않았습니다: ${missing_vars[*]}"
        log_info ".env 파일을 확인하거나 환경 변수를 설정해주세요."
        exit 1
    fi
    
    log_success "환경 변수 확인 완료"
}

# Docker 설치 확인
check_docker() {
    log_info "Docker 설치 확인 중..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker가 설치되지 않았습니다."
        log_info "Docker를 설치해주세요: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose가 설치되지 않았습니다."
        log_info "Docker Compose를 설치해주세요: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    log_success "Docker 및 Docker Compose 확인 완료"
}

# 이전 배포 정리
cleanup() {
    log_info "이전 배포 정리 중..."
    
    # 실행 중인 컨테이너 중지
    docker-compose down --remove-orphans || true
    
    # 미사용 이미지 정리
    docker system prune -f || true
    
    log_success "정리 완료"
}

# 애플리케이션 빌드
build_app() {
    log_info "애플리케이션 빌드 중..."
    
    # Docker 이미지 빌드
    docker-compose build --no-cache
    
    log_success "빌드 완료"
}

# 서비스 시작
start_services() {
    log_info "서비스 시작 중..."
    
    # 인프라 서비스 먼저 시작 (Redis, Ollama)
    docker-compose up -d redis ollama
    
    # 서비스가 준비될 때까지 대기
    log_info "인프라 서비스 준비 대기 중..."
    sleep 30
    
    # 애플리케이션 시작
    docker-compose up -d xshell-chatbot
    
    log_success "서비스 시작 완료"
}

# 헬스체크
health_check() {
    log_info "헬스체크 수행 중..."
    
    max_attempts=30
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:8000/api/ai/health/ >/dev/null 2>&1; then
            log_success "애플리케이션이 정상적으로 실행 중입니다."
            return 0
        fi
        
        log_info "헬스체크 시도 $attempt/$max_attempts..."
        sleep 10
        ((attempt++))
    done
    
    log_error "헬스체크 실패"
    return 1
}

# AI 모델 설치
install_ai_models() {
    log_info "AI 모델 설치 확인 중..."
    
    # Ollama 컨테이너에서 모델 설치
    docker-compose exec ollama ollama pull llama3.1:8b || log_warning "llama3.1:8b 모델 설치 실패"
    docker-compose exec ollama ollama pull codellama:7b || log_warning "codellama:7b 모델 설치 실패"
    
    log_success "AI 모델 설치 완료"
}

# 로그 확인
show_logs() {
    log_info "서비스 로그:"
    docker-compose logs --tail=50 xshell-chatbot
}

# 배포 정보 출력
show_deployment_info() {
    log_success "🎉 배포 완료!"
    echo ""
    echo "📋 서비스 정보:"
    echo "  • 웹 애플리케이션: http://localhost:8000"
    echo "  • 관리자 페이지: http://localhost:8000/admin"
    echo "  • Ollama API: http://localhost:11434"
    echo "  • Redis: localhost:6379"
    echo ""
    echo "🔧 관리 명령어:"
    echo "  • 로그 확인: docker-compose logs -f xshell-chatbot"
    echo "  • 서비스 재시작: docker-compose restart xshell-chatbot"
    echo "  • 서비스 중지: docker-compose down"
    echo "  • 데이터베이스 마이그레이션: docker-compose exec xshell-chatbot python manage.py migrate"
    echo ""
}

# 메인 배포 함수
deploy() {
    log_info "🚀 XShell AI 챗봇 배포 시작"
    
    # 환경 변수 로드
    if [ -f .env ]; then
        export $(cat .env | xargs)
        log_info ".env 파일에서 환경 변수 로드됨"
    fi
    
    check_env_vars
    check_docker
    cleanup
    build_app
    start_services
    
    if health_check; then
        install_ai_models
        show_deployment_info
    else
        log_error "배포 실패"
        show_logs
        exit 1
    fi
}

# 스크립트 옵션
case "${1:-deploy}" in
    "deploy")
        deploy
        ;;
    "start")
        log_info "서비스 시작 중..."
        docker-compose up -d
        health_check
        ;;
    "stop")
        log_info "서비스 중지 중..."
        docker-compose down
        log_success "서비스 중지 완료"
        ;;
    "restart")
        log_info "서비스 재시작 중..."
        docker-compose restart
        health_check
        ;;
    "logs")
        docker-compose logs -f xshell-chatbot
        ;;
    "health")
        health_check
        ;;
    "cleanup")
        cleanup
        ;;
    *)
        echo "사용법: $0 {deploy|start|stop|restart|logs|health|cleanup}"
        echo ""
        echo "명령어:"
        echo "  deploy   - 전체 배포 수행 (기본값)"
        echo "  start    - 서비스 시작"
        echo "  stop     - 서비스 중지"
        echo "  restart  - 서비스 재시작"
        echo "  logs     - 로그 확인"
        echo "  health   - 헬스체크"
        echo "  cleanup  - 정리"
        exit 1
        ;;
esac
