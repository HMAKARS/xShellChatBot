# ⚡ Windows 설치 오류 해결 가이드

Windows에서 `psycopg2-binary`, `Pillow` 등의 컴파일 오류가 발생했을 때의 해결 방법입니다.

## 🔧 즉시 해결 방법 (우선순위 순)

### 방법 1: 최소 설치 스크립트 (가장 안전)
```batch
# 컴파일 없이 핵심 기능만 설치
install-minimal.bat
```

### 방법 2: 업데이트된 시작 스크립트
```batch
# 자동으로 최소 패키지부터 시도
start.bat
```

### 방법 3: PowerShell 실행
```powershell
# PowerShell에서 실행
.\start.ps1
```

### 방법 4: 수동 최소 패키지 설치
```batch
# 최소 패키지만 설치
pip install -r requirements-minimal.txt
```

## 🔍 오류 원인별 해결책

### 1. psycopg2-binary 오류
**원인**: PostgreSQL 헤더 파일 부족
**해결**: SQLite 사용 (PostgreSQL 제외)

### 2. Pillow 오류  
**원인**: 이미지 라이브러리 컴파일 환경 부족
**해결**: Pillow 없이 실행 (필요시 나중에 설치)

### 3. 기타 컴파일 오류
**원인**: Visual Studio Build Tools 부족
**해결**: 바이너리 휠 버전 사용 또는 제외

## 📋 Requirements 파일 가이드

### 1. `requirements-minimal.txt` ⭐
✅ **최소 설치 (가장 안전)**
- 핵심 기능만 포함
- 컴파일 오류 없음
- 즉시 실행 가능

### 2. `requirements-windows.txt`
⚠️ **Windows 전용 (일부 고급 기능)**
- Windows 최적화
- 일부 패키지 선택적 설치

### 3. `requirements.txt`
❌ **전체 기능 (오류 가능)**
- 모든 기능 포함
- Windows에서 컴파일 오류 가능성

## 🛠️ 단계별 해결 방법

### 1단계: 최소 설치 시도
```batch
# 가장 안전한 방법
install-minimal.bat
```

### 2단계: 수동 핵심 패키지 설치
```batch
pip install Django==4.2.7
pip install channels==4.0.0
pip install requests==2.31.0
pip install python-dotenv==1.0.0
pip install daphne==4.0.0
```

### 3단계: 데이터베이스 설정
```batch
python manage.py makemigrations
python manage.py migrate
```

### 4단계: 서버 실행
```batch
python manage.py runserver
```

## 🔧 고급 해결 방법

### Visual Studio Build Tools 설치 (선택사항)
컴파일이 필요한 패키지를 설치하려면:
1. [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) 다운로드
2. "C++ build tools" 워크로드 설치
3. Windows 10/11 SDK 포함 설치

### 개별 패키지 수동 설치
```batch
# 필요한 패키지만 개별 설치
pip install --only-binary=all Pillow      # 바이너리만 설치
pip install --no-deps some-package        # 의존성 제외 설치
```

## 🚀 설치 확인 및 테스트

### 1. 설치 확인
```batch
python -c "import django; print('Django:', django.get_version())"
python -c "import channels; print('Channels: OK')"
python -c "import requests; print('Requests: OK')"
```

### 2. 서버 시작 테스트
```batch
python manage.py check
python manage.py runserver
```

### 3. 브라우저 접속
- `http://localhost:8000` 접속
- 챗봇 인터페이스 확인

## 📞 추가 도움

### 환경 정보 확인
```batch
python --version
pip --version
pip list
```

### 가상환경 재생성
```batch
rmdir /s .venv
python -m venv .venv
.venv\Scripts\activate
install-minimal.bat
```

### 캐시 정리
```batch
pip cache purge
pip install --no-cache-dir -r requirements-minimal.txt
```

## 🎯 권장 설치 순서

1. **`install-minimal.bat`** 실행 (가장 안전)
2. 정상 작동 확인
3. 필요한 추가 기능 개별 설치:
   ```batch
   pip install Pillow          # 이미지 처리 필요시
   pip install wmi             # Windows 시스템 정보 필요시
   pip install django-redis    # Redis 세션 필요시
   ```

---

이 가이드로 99% 이상의 Windows 설치 문제가 해결됩니다! 🚀
추가 문제가 있으면 GitHub Issues에 문의해주세요.
