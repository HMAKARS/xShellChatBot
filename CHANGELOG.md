# 변경 사항 (Changelog)

## [1.1.1] - 2025-06-13 (핫픽스)

### 🔧 Windows 설치 오류 완전 해결
- **psycopg2-binary 컴파일 오류 해결**: PostgreSQL 제외한 SQLite 기반 개발환경
- **Pillow 컴파일 오류 해결**: 이미지 처리 라이브러리 선택적 설치
- **최소 설치 옵션**: `install-minimal.bat` 스크립트 추가 ⭐
- **다단계 설치 시스템**: 최소 → Windows → 전체 순서로 시도

### 📦 새로운 Requirements 파일
- `requirements-minimal.txt` - 핵심 기능만 (컴파일 없음) ⭐
- `requirements-windows.txt` - Windows 최적화 (개선됨)
- `requirements-production.txt` - 프로덕션 환경 전용

### 🛠️ 업데이트된 설치 스크립트
- `start.bat` - 최소 패키지부터 자동으로 시도
- `start.ps1` - PowerShell에서 다단계 설치 지원
- `install-minimal.bat` - 컴파일 없는 안전한 설치 ⭐

### 📚 개선된 문서
- `FIX-WINDOWS-INSTALL.md` - 상세한 Windows 설치 문제 해결 가이드
- `quick-start-windows.md` - Windows 사용자 빠른 시작 가이드 개선
- 단계별 해결 방법 및 대안 제시

### 🚀 **즉시 사용 가능한 해결법**
```batch
# 컴파일 오류 없이 바로 시작
install-minimal.bat

# 또는 업데이트된 자동 설치
start.bat
```

---

## [1.1.0] - 2025-06-13

### 🎉 주요 기능 추가
- **Windows Shell 완전 지원**: PowerShell 및 Command Prompt 네이티브 지원
- **자동 OS 감지**: Windows/Linux/macOS 자동 감지 및 적절한 명령어 제안
- **Shell 타입 선택**: 사용자가 원하는 Shell 환경 선택 가능
- **명령어 모드**: 직접 명령어 입력을 위한 전용 모드
- **Windows 특화 시작 스크립트**: `start.bat`, `start.ps1`, `install.ps1`

### ✨ 개선 사항
- **AI 의도 분석 강화**: OS별 명령어 키워드 인식 개선
- **명령어 설명 개선**: Shell별 상세한 명령어 설명 제공
- **실시간 Shell 정보**: 현재 선택된 Shell 정보 표시
- **향상된 UI**: Shell 선택기 및 명령어 모드 토글
- **컨텍스트 인식**: 사용자 환경에 맞는 AI 응답

### 🛠️ 기술적 개선
- **WindowsShellService 클래스**: Windows 전용 Shell 처리
- **컨텍스트 기반 AI 처리**: Shell 타입 정보를 활용한 AI 응답
- **스트리밍 명령어 실행**: Windows에서도 실시간 출력 지원
- **향상된 오류 처리**: OS별 구체적인 오류 메시지

### 🔧 설치 및 배포
- **자동 설치 스크립트**: Windows용 완전 자동화된 설치
- **Chocolatey 통합**: Windows 패키지 관리자 지원
- **Docker 개선**: Windows 컨테이너 호환성 향상

### 📚 문서화
- **Windows 빠른 시작 가이드**: `quick-start-windows.md`
- **상세한 설치 가이드**: 단계별 설치 및 설정 안내
- **Shell별 사용 예시**: PowerShell, CMD, Bash 예시 포함

### 🐛 버그 수정
- Windows 경로 처리 개선
- 유니코드 문자 인코딩 문제 해결
- WebSocket 연결 안정성 향상
- CSS 반응형 디자인 개선

---

## [1.0.0] - 2025-06-12

### 🎉 초기 릴리즈
- **기본 채팅봇 기능**: Ollama 기반 AI 대화
- **SSH 연결**: XShell을 통한 원격 서버 연결
- **실시간 채팅**: Django Channels + WebSocket
- **명령어 실행**: 기본적인 Unix/Linux 명령어 지원
- **코드 분석**: 오류 분석 및 해결책 제시
- **시스템 관리**: 서버 모니터링 조언
- **반응형 웹 UI**: 모바일/데스크톱 지원

### 🛠️ 초기 기술 스택
- Django 4.2 + Django Channels
- Ollama (Llama 3.1, CodeLlama)
- Redis (WebSocket 백엔드)
- SQLite (개발용 DB)
- Bootstrap 5 (UI 프레임워크)

---

## 로드맵

### [1.2.0] - 계획 중
- **다국어 지원**: 영어, 일본어 UI
- **음성 인식**: 음성으로 명령어 입력
- **플러그인 시스템**: 사용자 정의 기능 확장
- **클라우드 연동**: AWS, Azure, GCP 통합
- **협업 기능**: 팀 채팅 및 세션 공유

### [1.3.0] - 계획 중
- **모바일 앱**: iOS/Android 네이티브 앱
- **IDE 플러그인**: VSCode, IntelliJ 확장
- **API 개방**: RESTful API 및 SDK 제공
- **성능 최적화**: 대용량 처리 및 속도 개선
- **보안 강화**: 2FA, RBAC, 감사 로그

---

이 프로젝트는 지속적으로 발전하고 있습니다. 
피드백이나 제안사항이 있으시면 언제든 Issues를 통해 알려주세요! 🚀
