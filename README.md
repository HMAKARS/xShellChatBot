# XShell AI 챗봇

Django + Channels + Ollama를 기반으로 한 XShell 통합 AI 챗봇입니다.

## ✨ 주요 기능

- **🤖 오픈소스 AI 지원**: Ollama 기반으로 완전 로컬에서 동작
- **💬 실시간 채팅**: WebSocket을 통한 실시간 대화
- **🔧 명령어 실행**: SSH를 통한 원격 터미널 명령어 실행
- **💻 코드 분석**: 오류 분석 및 해결책 제시
- **⚙️ 시스템 관리**: 서버 모니터링 및 관리 조언
- **📱 반응형 UI**: 모바일과 데스크톱 모두 지원

## 🛠️ 기술 스택

- **Backend**: Django 4.2, Django Channels
- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **AI**: Ollama (Llama 3.1, CodeLlama)
- **Database**: SQLite (개발용), PostgreSQL (프로덕션 권장)
- **WebSocket**: Django Channels + Redis
- **SSH**: Paramiko, Pexpect

## 📋 시스템 요구사항

- Python 3.8+
- Redis Server
- Ollama
- XShell 8 (Windows)

## 🚀 설치 및 실행

### 1. 프로젝트 클론 및 의존성 설치

```bash
# 프로젝트 클론
git clone <repository-url>
cd xShellChatBot

# 가상환경 생성 및 활성화
python -m venv .venv
# Windows
.venv\Scripts\activate
# macOS/Linux
source .venv/bin/activate

# 의존성 설치
pip install -r requirements.txt
```

### 2. Ollama 설치 및 모델 다운로드

```bash
# Ollama 설치 (https://ollama.ai)
# Windows: 설치 프로그램 다운로드 후 실행
# macOS: brew install ollama
# Linux: curl -fsSL https://ollama.ai/install.sh | sh

# 권장 모델 설치
ollama pull llama3.1:8b
ollama pull codellama:7b

# 모델 확인
ollama list
```

### 3. Redis 설치 및 실행

```bash
# Windows (Chocolatey)
choco install redis-64

# macOS
brew install redis
brew services start redis

# Linux (Ubuntu)
sudo apt install redis-server
sudo systemctl start redis
```

### 4. 환경 설정

```bash
# .env 파일 생성
cp .env.example .env

# .env 파일 편집 (필요에 따라)
# SECRET_KEY, XSHELL_PATH 등 설정
```

### 5. 데이터베이스 설정

```bash
# 마이그레이션 생성 및 적용
python manage.py makemigrations
python manage.py migrate

# 관리자 계정 생성 (선택사항)
python manage.py createsuperuser
```

### 6. 서버 실행

#### 간편 실행 (권장)
```bash
python start_server.py
```

#### 수동 실행
```bash
# 개발 서버
python manage.py runserver 0.0.0.0:8000

# 또는 프로덕션 서버 (Daphne)
daphne -b 0.0.0.0 -p 8000 xshell_chatbot.asgi:application
```

### 7. 접속

브라우저에서 `http://localhost:8000`에 접속하세요.

## 🔧 관리 명령어

### AI 모델 상태 확인
```bash
# 모델 상태 확인
python manage.py check_ai_models

# 권장 모델 자동 설치
python manage.py check_ai_models --install

# 특정 모델 설치
python manage.py check_ai_models --model llama3.1:8b
```

### XShell 세션 관리
```bash
# 세션 목록 조회
python manage.py manage_xshell_sessions --list

# 새 세션 추가
python manage.py manage_xshell_sessions --add

# 세션 연결 테스트
python manage.py manage_xshell_sessions --test "세션이름"

# 세션 삭제
python manage.py manage_xshell_sessions --delete "세션이름"
```

## 📖 사용법

### 1. 기본 대화
- 자연어로 질문하면 AI가 적절한 답변을 제공합니다.
- 명령어 관련 질문 시 자동으로 실행 가능한 명령어를 제안합니다.

### 2. 명령어 실행
```
사용자: "현재 디렉토리의 파일 목록을 보여줘"
AI: ls -la 명령어를 실행하겠습니다. [실행 버튼]
```

### 3. 코드 분석
```
사용자: "이 오류를 분석해줘: ImportError: No module named 'django'"
AI: Django가 설치되지 않은 것 같습니다. pip install django로 설치하세요.
```

### 4. 시스템 관리
```
사용자: "서버 메모리 사용량이 높은데 어떻게 확인하지?"
AI: free -h 명령어로 메모리 사용량을 확인할 수 있습니다...
```

## 🏗️ 프로젝트 구조

```
xShellChatBot/
├── chatbot/                # 메인 챗봇 앱
│   ├── consumers.py        # WebSocket 컨슈머
│   ├── models.py          # 데이터 모델
│   ├── routing.py         # WebSocket 라우팅
│   └── views.py           # API 뷰
├── ai_backend/            # AI 백엔드 서비스
│   └── services.py        # Ollama 클라이언트
├── xshell_integration/    # XShell 통합 서비스
│   └── services.py        # SSH 연결 및 명령어 실행
├── templates/             # HTML 템플릿
├── static/               # 정적 파일 (CSS, JS)
├── xshell_chatbot/       # Django 프로젝트 설정
└── requirements.txt      # Python 의존성
```

## 🔐 보안 고려사항

- SSH 비밀번호는 암호화되어 저장됩니다
- 위험한 명령어는 실행이 차단됩니다
- CSRF 보호가 활성화되어 있습니다
- WebSocket 연결에 Origin 검증이 적용됩니다

## 🚨 주의사항

- 이 챗봇은 SSH를 통해 실제 서버에 명령어를 실행할 수 있습니다
- 프로덕션 환경에서는 추가적인 보안 조치가 필요합니다
- 중요한 서버에서는 제한된 권한의 사용자로만 접속하세요

## 🛠️ 개발 환경 설정

### 개발 서버 실행
```bash
# Django 개발 서버
python manage.py runserver

# Redis 실행 (별도 터미널)
redis-server

# Ollama 실행 (별도 터미널)
ollama serve
```

### 테스트 실행
```bash
python manage.py test
```

### 코드 포맷팅
```bash
# Black 사용 (권장)
black .

# isort 사용
isort .
```

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 🤝 기여하기

1. 이 저장소를 포크하세요
2. 새로운 기능 브랜치를 만드세요 (`git checkout -b feature/AmazingFeature`)
3. 변경사항을 커밋하세요 (`git commit -m 'Add some AmazingFeature'`)
4. 브랜치에 푸시하세요 (`git push origin feature/AmazingFeature`)
5. Pull Request를 생성하세요

## 📞 지원

이슈가 있으시면 GitHub Issues를 통해 보고해주세요.

## 🔄 업데이트 로그

### v1.0.0
- 기본 챗봇 기능 구현
- Ollama AI 통합
- XShell SSH 연동
- 실시간 WebSocket 채팅
- 반응형 웹 인터페이스

---

**즐거운 개발 되세요! 🚀**
