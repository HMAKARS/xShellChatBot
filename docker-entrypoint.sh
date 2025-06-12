#!/bin/bash
set -e

# 환경 변수 기본값 설정
export DJANGO_SETTINGS_MODULE=${DJANGO_SETTINGS_MODULE:-xshell_chatbot.settings}
export OLLAMA_BASE_URL=${OLLAMA_BASE_URL:-http://ollama:11434}

echo "🐳 XShell AI 챗봇 Docker 컨테이너 시작"

# Redis 연결 대기
echo "⏳ Redis 연결 대기 중..."
until redis-cli -h ${REDIS_HOST:-redis} -p ${REDIS_PORT:-6379} ping; do
    echo "Redis를 기다리는 중..."
    sleep 2
done
echo "✅ Redis 연결 완료"

# Ollama 연결 대기 (선택사항)
if [ "${WAIT_FOR_OLLAMA:-true}" = "true" ]; then
    echo "⏳ Ollama 연결 대기 중..."
    for i in {1..30}; do
        if curl -f ${OLLAMA_BASE_URL}/api/tags >/dev/null 2>&1; then
            echo "✅ Ollama 연결 완료"
            break
        fi
        echo "Ollama를 기다리는 중... (시도 $i/30)"
        sleep 5
    done
fi

# 데이터베이스 마이그레이션
echo "🗄️ 데이터베이스 마이그레이션 중..."
python manage.py makemigrations --noinput
python manage.py migrate --noinput

# 슈퍼유저 자동 생성 (환경 변수가 설정된 경우)
if [ -n "$DJANGO_SUPERUSER_USERNAME" ] && [ -n "$DJANGO_SUPERUSER_EMAIL" ] && [ -n "$DJANGO_SUPERUSER_PASSWORD" ]; then
    echo "👤 슈퍼유저 생성 중..."
    python manage.py createsuperuser --noinput || echo "슈퍼유저가 이미 존재합니다."
fi

# 정적 파일 수집
if [ "${COLLECT_STATIC:-true}" = "true" ]; then
    echo "📁 정적 파일 수집 중..."
    python manage.py collectstatic --noinput
fi

# AI 모델 상태 확인
echo "🤖 AI 모델 상태 확인 중..."
python manage.py check_ai_models || echo "⚠️ AI 모델 확인 실패 (서비스는 계속 실행됩니다)"

echo "🚀 서버 시작 중..."

# 전달된 명령어 실행
exec "$@"
