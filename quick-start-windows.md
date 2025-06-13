# 🚀 Windows 사용자 빠른 시작 가이드

## 💫 가장 빠른 방법 (30초)

### 1. 더블클릭으로 시작
1. `start.bat` 파일을 더블클릭
2. 자동으로 모든 설정이 완료됩니다
3. 브라우저가 자동으로 열립니다

### 2. PowerShell로 시작
```powershell
# PowerShell을 관리자로 실행하고
.\start.ps1
```

## 🛠️ 필요한 프로그램 자동 설치

### 모든 필수 프로그램 한번에 설치
```powershell
# PowerShell을 관리자로 실행하고
.\install.ps1 -All
```

### 개별 설치
```powershell
# Python만 설치
.\install.ps1 -InstallPython

# Redis만 설치  
.\install.ps1 -InstallRedis

# Ollama만 설치
.\install.ps1 -InstallOllama
```

## 📋 Windows에서 지원하는 Shell

### 1. PowerShell (권장)
- 최신 Windows의 기본 셸
- 강력한 객체 지향 명령어
- .NET 기반 스크립팅

```powershell
# PowerShell 명령어 예시
Get-Process          # 프로세스 목록
Get-ChildItem        # 파일/폴더 목록
Get-WmiObject        # 시스템 정보
```

### 2. Command Prompt (cmd)
- 전통적인 Windows 명령어
- 배치 파일 지원
- 레거시 호환성

```cmd
# Command Prompt 명령어 예시
dir                  # 파일/폴더 목록
tasklist            # 프로세스 목록
systeminfo          # 시스템 정보
```

## 🎯 사용 예시

### PowerShell 명령어
```
사용자: "현재 폴더의 파일 목록 보여줘"
AI: Get-ChildItem 명령어를 실행하겠습니다. [실행]

사용자: "실행 중인 프로세스 확인해줘"
AI: Get-Process 명령어를 실행하겠습니다. [실행]

사용자: "시스템 정보 알려줘"
AI: Get-ComputerInfo 명령어를 실행하겠습니다. [실행]
```

### Command Prompt 명령어
```
사용자: "파일 목록 보여줘"
AI: dir 명령어를 실행하겠습니다. [실행]

사용자: "프로세스 목록 확인해줘"
AI: tasklist 명령어를 실행하겠습니다. [실행]

사용자: "네트워크 설정 확인해줘"
AI: ipconfig /all 명령어를 실행하겠습니다. [실행]
```

## 🔧 고급 설정

### PowerShell 실행 정책 설정
```powershell
# 현재 사용자만 적용
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 전체 시스템 적용 (관리자 권한 필요)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

### 환경 변수 설정
```powershell
# 사용자 환경 변수
[Environment]::SetEnvironmentVariable("OLLAMA_BASE_URL", "http://localhost:11434", "User")

# 시스템 환경 변수 (관리자 권한 필요)
[Environment]::SetEnvironmentVariable("XSHELL_PATH", "C:\Program Files\NetSarang\Xshell 8\Xshell.exe", "Machine")
```

## 🚨 문제 해결

### PowerShell 스크립트 실행 오류
```powershell
# 실행 정책 확인
Get-ExecutionPolicy

# 실행 정책 변경
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Python 인식 안됨
```powershell
# Python 버전 확인
python --version

# PATH에 Python 추가
$env:Path += ";C:\Python311;C:\Python311\Scripts"
```

### Redis 연결 실패
```powershell
# Redis 서비스 상태 확인
Get-Service redis

# Redis 서비스 시작
Start-Service redis
```

### Ollama 연결 실패
```powershell
# Ollama 서비스 확인
ollama list

# Ollama 서비스 시작
ollama serve
```

## 💡 유용한 팁

### 1. Windows Terminal 사용
- 최신 Windows에서 제공하는 통합 터미널
- PowerShell, CMD, WSL 모두 지원
- 탭 기능과 멀티 패널 지원

### 2. WSL(Windows Subsystem for Linux) 활용
```powershell
# WSL 설치
wsl --install

# Ubuntu 설치
wsl --install -d Ubuntu
```

### 3. 바로가기 만들기
1. `start.bat`를 마우스 우클릭
2. "바로가기 만들기" 선택
3. 바탕화면이나 시작 메뉴에 배치

### 4. 자동 실행 설정
```powershell
# 시작 프로그램에 추가하려면
# 다음 경로에 배치 파일이나 바로가기 배치:
# %APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
```

## 🎉 완료!

이제 Windows에서 XShell AI 챗봇을 완벽하게 사용할 수 있습니다!

- **웹 인터페이스**: http://localhost:8000
- **관리자 페이지**: http://localhost:8000/admin
- **종료**: Ctrl+C

궁금한 점이 있으면 언제든 채팅으로 물어보세요! 🤖
