# ⚡ Windows 설치 오류 해결 가이드

Windows에서 `psycopg2-binary` 설치 오류가 발생했을 때의 해결 방법입니다.

## 🔧 즉시 해결 방법

### 방법 1: Windows 전용 패키지 사용 (권장)
```batch
# 기존 설치 중단 후 Windows 전용 패키지로 설치
pip install -r requirements-windows.txt
```

### 방법 2: 업데이트된 시작 스크립트 사용
```batch
# 새로운 start.bat 실행 (자동으로 Windows용 패키지 사용)
start.bat
```

### 방법 3: PowerShell로 실행
```powershell
# PowerShell에서 실행 (권장)
.\start.ps1
```

## 🔍 오류 원인

- **psycopg2-binary**: PostgreSQL 데이터베이스 라이브러리
- **Windows 환경**: PostgreSQL 헤더 파일이 없어 컴파일 실패
- **SQLite 사용**: 개발환경에서는 PostgreSQL 불필요

## 📋 Requirements 파일별 용도

### 1. `requirements-windows.txt` 
✅ **Windows 개발용 (권장)**
- SQLite 데이터베이스 사용
- PostgreSQL 라이브러리 제외
- Windows 특화 패키지 포함

### 2. `requirements.txt`
⚠️ **전체 기능 (PostgreSQL 포함)**
- 모든 기능 포함
- PostgreSQL 필요
- Linux/macOS 환경 권장

### 3. `requirements-production.txt`
🚀 **프로덕션 환경용**
- PostgreSQL 데이터베이스
- 모니터링 도구 포함
- 배포 최적화

## 🛠️ 수동 해결 방법

만약 위 방법들이 작동하지 않으면:

### 1. 최소 패키지 설치
```batch
pip install Django==4.2.7
pip install channels==4.0.0
pip install django-cors-headers==4.3.1
pip install requests==2.31.0
pip install python-dotenv==1.0.0
```

### 2. 개별 패키지 설치
```batch
pip install daphne==4.0.0
pip install redis==5.0.1
pip install paramiko==3.3.1
```

### 3. 데이터베이스 설정 확인
```python
# settings.py에서 SQLite 사용 확인
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}
```

## 🚀 정상 설치 확인

설치가 완료되면:

```batch
# 서버 시작
python manage.py runserver

# 또는
python start_server.py
```

브라우저에서 `http://localhost:8000` 접속하여 확인

## 🔄 추가 오류 발생시

### Redis 연결 오류
```batch
# Redis 설치 (Windows)
# https://github.com/microsoftarchive/redis/releases
# 또는 Docker 사용
docker run -d -p 6379:6379 redis:alpine
```

### Ollama 연결 오류
```batch
# Ollama 설치
# https://ollama.ai/download
# 모델 다운로드
ollama pull llama3.1:8b
```

## 📞 추가 도움

문제가 지속되면:
1. Python 버전 확인: `python --version` (3.8+ 필요)
2. pip 업데이트: `python -m pip install --upgrade pip`
3. 가상환경 재생성: `rmdir /s .venv` → `python -m venv .venv`

---

이 가이드로 문제가 해결되지 않으면 GitHub Issues에 문의해주세요! 🤝
