# XShell AI 챗봇 Dockerfile
FROM python:3.11-slim

# 시스템 의존성 설치
RUN apt-get update && apt-get install -y \
    openssh-client \
    redis-tools \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 작업 디렉토리 설정
WORKDIR /app

# Python 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Ollama CLI 설치 (선택사항)
RUN curl -fsSL https://ollama.ai/install.sh | sh || true

# 애플리케이션 코드 복사
COPY . .

# 로그 디렉토리 생성
RUN mkdir -p logs

# 정적 파일 수집
RUN python manage.py collectstatic --noinput

# 포트 노출
EXPOSE 8000

# 헬스체크
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/ai/health/ || exit 1

# 시작 스크립트
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
