# XShell AI 챗봇 PowerShell 시작 스크립트
param(
    [string]$Action = "start",
    [string]$ShellType = "powershell",
    [switch]$SkipChecks
)

# 유니코드 지원
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 색상 함수
function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Success { param([string]$Text) Write-ColorText "✅ $Text" "Green" }
function Write-Error { param([string]$Text) Write-ColorText "❌ $Text" "Red" }
function Write-Warning { param([string]$Text) Write-ColorText "⚠️  $Text" "Yellow" }
function Write-Info { param([string]$Text) Write-ColorText "🔍 $Text" "Cyan" }

Clear-Host
Write-Host ""
Write-ColorText "🤖 XShell AI 챗봇 PowerShell 시작 스크립트" "Magenta"
Write-Host "================================================"
Write-Host ""

# 관리자 권한 확인
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "관리자 권한으로 실행하는 것을 권장합니다."
    $response = Read-Host "계속하시겠습니까? (Y/n)"
    if ($response -eq "n" -or $response -eq "N") {
        Write-Host "스크립트를 종료합니다."
        exit 1
    }
}

# Python 확인
if (-not $SkipChecks) {
    Write-Info "Python 확인 중..."
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Python $($pythonVersion.Split(' ')[1]) 확인됨"
        } else {
            throw "Python not found"
        }
    }
    catch {
        Write-Error "Python이 설치되지 않았거나 PATH에 없습니다."
        Write-Host "Python 3.8 이상을 설치하고 PATH에 추가해주세요."
        Write-Host "다운로드: https://python.org/downloads/"
        Read-Host "계속하려면 Enter를 누르세요"
        exit 1
    }
}

# 가상환경 확인 및 생성
if (-not (Test-Path ".venv")) {
    Write-Info "가상환경 생성 중..."
    python -m venv .venv
    if ($LASTEXITCODE -eq 0) {
        Write-Success "가상환경 생성 완료"
    } else {
        Write-Error "가상환경 생성 실패"
        Read-Host "계속하려면 Enter를 누르세요"
        exit 1
    }
} else {
    Write-Success "가상환경 확인됨"
}

# 가상환경 활성화
Write-Info "가상환경 활성화 중..."
try {
    & ".venv\Scripts\Activate.ps1"
    Write-Success "가상환경 활성화 완료"
}
catch {
    Write-Error "가상환경 활성화 실패"
    Write-Host "ExecutionPolicy를 변경해야 할 수 있습니다:"
    Write-Host "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
    Read-Host "계속하려면 Enter를 누르세요"
    exit 1
}

# 의존성 설치 확인
if (-not $SkipChecks) {
    Write-Info "의존성 확인 중..."
    $djangoInstalled = pip show django 2>$null
    if (-not $djangoInstalled) {
        Write-Info "의존성 설치 중... (시간이 걸릴 수 있습니다)"
        Write-Info "최소 패키지부터 설치를 시도합니다..."
        
        # 먼저 최소 패키지 설치 시도
        pip install -r requirements-minimal.txt
        if ($LASTEXITCODE -eq 0) {
            Write-Success "최소 의존성 설치 완료"
        } else {
            Write-Warning "최소 패키지 설치 실패, Windows 전용 패키지로 재시도..."
            pip install -r requirements-windows.txt
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Windows 전용 패키지 설치 완료"
            } else {
                Write-Error "패키지 설치 실패"
                Write-Host ""
                Write-Host "🔧 수동 설치를 시도해보세요:"
                Write-Host "   pip install Django==4.2.7"
                Write-Host "   pip install channels==4.0.0"  
                Write-Host "   pip install requests==2.31.0"
                Write-Host "   pip install python-dotenv==1.0.0"
                Write-Host "   pip install daphne==4.0.0"
                Write-Host ""
                Read-Host "계속하려면 Enter를 누르세요"
                exit 1
            }
        }
    } else {
        Write-Success "의존성 확인됨"
    }
}

# 환경설정 파일 확인
if (-not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Write-Info ".env 파일 생성 중..."
        Copy-Item ".env.example" ".env"
        Write-Success ".env 파일 생성 완료"
        Write-Warning ".env 파일을 확인하고 필요한 설정을 수정해주세요."
    } else {
        Write-Warning ".env.example 파일이 없습니다."
    }
}

# 서비스 상태 확인
if (-not $SkipChecks) {
    # Redis 확인
    Write-Info "Redis 연결 확인 중..."
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("localhost", 6379)
        $tcpClient.Close()
        Write-Success "Redis 연결 성공"
    }
    catch {
        Write-Warning "Redis 연결 실패 - WebSocket 기능이 제한될 수 있습니다"
        Write-Host "Redis 설치: https://redis.io/download"
    }

    # Ollama 확인
    Write-Info "Ollama 연결 확인 중..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 5 -ErrorAction Stop
        Write-Success "Ollama 연결 성공"
    }
    catch {
        Write-Warning "Ollama 연결 실패 - AI 기능이 제한될 수 있습니다"
        Write-Host "Ollama 설치: https://ollama.ai"
    }
}

# 데이터베이스 설정
Write-Info "데이터베이스 확인 중..."
if (-not (Test-Path "db.sqlite3")) {
    Write-Info "데이터베이스 초기화 중..."
    python manage.py makemigrations
    python manage.py migrate
    Write-Success "데이터베이스 초기화 완료"
    
    $createSuperuser = Read-Host "👤 관리자 계정을 생성하시겠습니까? (y/N)"
    if ($createSuperuser -eq "y" -or $createSuperuser -eq "Y") {
        python manage.py createsuperuser
    }
} else {
    Write-Success "데이터베이스 확인됨"
    Write-Info "마이그레이션 확인 중..."
    python manage.py migrate --check 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Info "데이터베이스 업데이트 중..."
        python manage.py makemigrations
        python manage.py migrate
    }
}

# AI 모델 확인
if (-not $SkipChecks) {
    Write-Info "AI 모델 상태 확인 중..."
    python manage.py check_ai_models 2>$null
}

# 로그 디렉토리 생성
if (-not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
    Write-Success "로그 디렉토리 생성 완료"
}

# 액션에 따른 실행
switch ($Action.ToLower()) {
    "start" {
        Write-Host ""
        Write-ColorText "🚀 서버 시작 방식을 선택하세요:" "Yellow"
        Write-Host "  1. Django 개발 서버 (기본값)"
        Write-Host "  2. Daphne 프로덕션 서버"
        Write-Host "  3. Python 시작 스크립트"
        Write-Host ""
        
        $serverType = Read-Host "선택 (1-3, 기본값: 1)"
        if (-not $serverType) { $serverType = "1" }
        
        Write-Host ""
        Write-ColorText "🎉 모든 준비가 완료되었습니다!" "Green"
        Write-Host ""
        Write-Host "📋 서비스 정보:"
        Write-Host "  • 웹 애플리케이션: http://localhost:8000"
        Write-Host "  • 관리자 페이지: http://localhost:8000/admin"
        Write-Host "  • 종료하려면 Ctrl+C를 누르세요"
        Write-Host ""
        
        # 브라우저 자동 열기 (5초 후)
        Start-Job -ScriptBlock {
            Start-Sleep 5
            Start-Process "http://localhost:8000"
        } | Out-Null
        
        switch ($serverType) {
            "1" {
                Write-ColorText "🚀 Django 개발 서버 시작 중..." "Green"
                python manage.py runserver 0.0.0.0:8000
            }
            "2" {
                Write-ColorText "🚀 Daphne 프로덕션 서버 시작 중..." "Green"
                $daphneInstalled = pip show daphne 2>$null
                if (-not $daphneInstalled) {
                    pip install daphne
                }
                daphne -b 0.0.0.0 -p 8000 xshell_chatbot.asgi:application
            }
            "3" {
                Write-ColorText "🚀 Python 시작 스크립트 실행 중..." "Green"
                python start_server.py
            }
            default {
                Write-Warning "잘못된 선택입니다. 기본 서버로 시작합니다."
                python manage.py runserver 0.0.0.0:8000
            }
        }
    }
    
    "setup" {
        Write-Success "설정이 완료되었습니다!"
        Write-Host "다음 명령어로 서버를 시작하세요:"
        Write-Host "  .\start.ps1"
    }
    
    "install" {
        Write-Info "AI 모델 설치 중..."
        python manage.py check_ai_models --install
    }
    
    "test" {
        Write-Info "테스트 실행 중..."
        python manage.py test
    }
    
    "shell" {
        Write-Info "Django Shell 시작 중..."
        python manage.py shell
    }
    
    default {
        Write-Host "사용법: .\start.ps1 [-Action <action>] [-ShellType <type>] [-SkipChecks]"
        Write-Host ""
        Write-Host "액션:"
        Write-Host "  start   - 서버 시작 (기본값)"
        Write-Host "  setup   - 초기 설정만 수행"
        Write-Host "  install - AI 모델 설치"
        Write-Host "  test    - 테스트 실행"
        Write-Host "  shell   - Django Shell 시작"
        Write-Host ""
        Write-Host "셸 타입 (기본값: powershell):"
        Write-Host "  powershell - PowerShell 사용"
        Write-Host "  cmd        - Command Prompt 사용"
        Write-Host ""
        Write-Host "예시:"
        Write-Host "  .\start.ps1"
        Write-Host "  .\start.ps1 -Action setup"
        Write-Host "  .\start.ps1 -Action start -ShellType cmd"
        Write-Host "  .\start.ps1 -SkipChecks"
    }
}

Write-Host ""
Read-Host "계속하려면 Enter를 누르세요"
