# 🚀 XShell AI 챗봇 빠른 시작 가이드

## 📋 사전 준비사항

- Python 3.8+
- Redis Server (WebSocket 기능용, 선택사항)
- Ollama (AI 기능용)

## ⚡ Windows에서 30초 만에 시작하기

### 방법 1: 배치 파일 (가장 간단) ⭐
```batch
# start.bat 더블클릭하거나 명령어로 실행
start.bat
```

### 방법 2: PowerShell
```powershell
# PowerShell 관리자 모드로 실행
.\start.ps1

# 또는 특정 옵션과 함께
.\start.ps1 -Action start -ShellType powershell
```

### 방법 3: 수동 설정
```batch
# 1. 가상환경 생성
python -m venv .venv
.venv\Scripts\activate

# 2. 의존성 설치
pip install -r requirements.txt

# 3. 데이터베이스 설정
python manage.py makemigrations
python manage.py migrate

# 4. 서버 실행
python manage.py runserver
```

## ⚡ Linux/macOS에서 시작하기

### 1. 자동 설정 실행

```bash
python setup.py
```

### 2. 가상환경 활성화

```bash
source .venv/bin/activate
```

### 3. 의존성 설치

```bash
pip install -r requirements.txt
```

### 4. 데이터베이스 설정

```bash
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser
```

### 5. AI 모델 설치

```bash
# Ollama 모델 설치
ollama pull llama3.1:8b
ollama pull codellama:7b

# 모델 상태 확인
python manage.py check_ai_models
```

### 6. 서버 실행

```bash
# 간편 실행
python start_server.py

# 또는 수동 실행
python manage.py runserver
```

### 7. 접속

브라우저에서 `http://localhost:8000`에 접속하세요.

## 🐳 Docker로 실행하기

```bash
# 실행 권한 부여 (Linux/macOS)
chmod +x deploy/deploy.sh

# 배포 실행
./deploy/deploy.sh
```

## 🔧 주요 관리 명령어

### AI 모델 관리
```bash
# 모델 상태 확인
python manage.py check_ai_models

# 권장 모델 자동 설치
python manage.py check_ai_models --install
```

### XShell 세션 관리
```bash
# 세션 목록 조회
python manage.py manage_xshell_sessions --list

# 새 세션 추가
python manage.py manage_xshell_sessions --add

# 세션 연결 테스트
python manage.py manage_xshell_sessions --test "세션이름"
```

### 테스트 실행
```bash
python manage.py test
```

## 📖 기본 사용법

### 1. 새 채팅 세션 생성
- 사이드바에서 "새 채팅" 버튼 클릭

### 2. 명령어 실행 (OS별 자동 감지)

#### Windows 예시
```
사용자: "현재 폴더의 파일 목록을 보여줘"
AI: dir 명령어를 실행하겠습니다. [실행 버튼]

사용자: "실행 중인 프로세스 확인해줘"  
AI: Get-Process 명령어를 실행하겠습니다. [실행 버튼]

사용자: "시스템 정보 알려줘"
AI: systeminfo 명령어를 실행하겠습니다. [실행 버튼]
```

#### Linux/macOS 예시
```
사용자: "현재 디렉토리의 파일 목록을 보여줘"
AI: ls -la 명령어를 실행하겠습니다. [실행 버튼]

사용자: "실행 중인 프로세스 확인해줘"
AI: ps aux 명령어를 실행하겠습니다. [실행 버튼]

사용자: "디스크 사용량 확인해줘"
AI: df -h 명령어를 실행하겠습니다. [실행 버튼]
```

### 3. 코드 분석
```
사용자: "이 오류를 분석해줘: ImportError: No module named 'django'"
AI: Django가 설치되지 않은 것 같습니다...
```

### 4. 시스템 관리
```
사용자: "메모리 사용량 확인하는 방법은?"
AI: Windows: Get-WmiObject Win32_OperatingSystem | Select TotalVirtualMemorySize
    Linux: free -h 명령어로 메모리 사용량을 확인할 수 있습니다...
```

## ⚙️ 설정 변경

### .env 파일 수정
```env
# AI 모델 변경
DEFAULT_AI_MODEL=llama3.1:8b
CODE_AI_MODEL=codellama:7b

# XShell 경로 설정
XSHELL_PATH=C:\Program Files\NetSarang\Xshell 8\Xshell.exe

# Ollama 서버 주소
OLLAMA_BASE_URL=http://localhost:11434
```

### XShell 세션 추가
1. 관리자 페이지 (`/admin`) 접속
2. "XShell Sessions" 메뉴 선택
3. "Add" 버튼으로 새 세션 추가

## 🚨 문제 해결

### Ollama 연결 실패
```bash
# Ollama 서비스 확인
curl http://localhost:11434/api/tags

# Ollama 재시작
ollama serve
```

### Redis 연결 실패
```bash
# Redis 서비스 확인
redis-cli ping

# Redis 재시작 (Ubuntu)
sudo systemctl restart redis
```

### 권한 오류
```bash
# 로그 디렉토리 권한 설정
chmod 755 logs/

# SQLite 파일 권한 설정
chmod 664 db.sqlite3
```

## 📚 더 자세한 정보

- [전체 README](README.md)
- [API 문서](docs/api.md)
- [배포 가이드](docs/deployment.md)
- [문제 해결](docs/troubleshooting.md)

## 🆘 도움이 필요하신가요?

- GitHub Issues: 버그 신고 및 기능 요청
- Discord: 실시간 커뮤니티 지원
- 이메일: support@example.com

---

**🎉 이제 XShell AI 챗봇을 사용할 준비가 되었습니다!**
