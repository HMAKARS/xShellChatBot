# XShell AI 챗봇 자동 설치 스크립트
param(
    [switch]$InstallPython,
    [switch]$InstallRedis,
    [switch]$InstallOllama,
    [switch]$All
)

# 관리자 권한 확인
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "이 스크립트는 관리자 권한이 필요합니다." -ForegroundColor Red
    Write-Host "PowerShell을 관리자로 실행하고 다시 시도해주세요." -ForegroundColor Yellow
    Read-Host "계속하려면 Enter를 누르세요"
    exit 1
}

function Write-Step {
    param([string]$Message)
    Write-Host "🔧 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

Clear-Host
Write-Host "🚀 XShell AI 챗봇 자동 설치 스크립트" -ForegroundColor Magenta
Write-Host "==========================================" -ForegroundColor Magenta
Write-Host ""

# Chocolatey 설치 확인
Write-Step "Chocolatey 패키지 관리자 확인 중..."
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Success "Chocolatey가 이미 설치되어 있습니다."
} else {
    Write-Step "Chocolatey 설치 중..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # PATH 새로고침
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Success "Chocolatey 설치 완료"
    } else {
        Write-Error "Chocolatey 설치 실패"
        exit 1
    }
}

# Python 설치
if ($InstallPython -or $All) {
    Write-Step "Python 설치 확인 중..."
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $pythonVersion = python --version
        Write-Success "Python이 이미 설치되어 있습니다: $pythonVersion"
    } else {
        Write-Step "Python 설치 중..."
        choco install python -y
        
        # PATH 새로고침
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        if (Get-Command python -ErrorAction SilentlyContinue) {
            Write-Success "Python 설치 완료"
        } else {
            Write-Error "Python 설치 실패"
        }
    }
}

# Redis 설치
if ($InstallRedis -or $All) {
    Write-Step "Redis 설치 확인 중..."
    if (Get-Command redis-server -ErrorAction SilentlyContinue) {
        Write-Success "Redis가 이미 설치되어 있습니다."
    } else {
        Write-Step "Redis 설치 중..."
        choco install redis-64 -y
        
        # Redis 서비스 시작
        Start-Service redis
        Write-Success "Redis 설치 및 시작 완료"
    }
}

# Ollama 설치
if ($InstallOllama -or $All) {
    Write-Step "Ollama 설치 확인 중..."
    if (Get-Command ollama -ErrorAction SilentlyContinue) {
        Write-Success "Ollama가 이미 설치되어 있습니다."
    } else {
        Write-Step "Ollama 설치 중..."
        
        # Ollama 다운로드 및 설치
        $ollamaUrl = "https://ollama.ai/download/windows"
        $ollamaInstaller = "$env:TEMP\OllamaSetup.exe"
        
        try {
            Invoke-WebRequest -Uri $ollamaUrl -OutFile $ollamaInstaller
            Start-Process -FilePath $ollamaInstaller -Wait
            Remove-Item $ollamaInstaller
            
            # PATH 새로고침
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            if (Get-Command ollama -ErrorAction SilentlyContinue) {
                Write-Success "Ollama 설치 완료"
                
                # 기본 모델 설치
                Write-Step "기본 AI 모델 설치 중..."
                ollama pull llama3.1:8b
                ollama pull codellama:7b
                Write-Success "AI 모델 설치 완료"
            } else {
                Write-Error "Ollama 설치 실패"
            }
        }
        catch {
            Write-Error "Ollama 다운로드 실패: $_"
        }
    }
}

# Git 설치 (선택사항)
Write-Step "Git 설치 확인 중..."
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Success "Git이 이미 설치되어 있습니다."
} else {
    $installGit = Read-Host "Git을 설치하시겠습니까? (y/N)"
    if ($installGit -eq "y" -or $installGit -eq "Y") {
        choco install git -y
        Write-Success "Git 설치 완료"
    }
}

# Visual Studio Code 설치 (선택사항)
Write-Step "Visual Studio Code 설치 확인 중..."
if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Success "Visual Studio Code가 이미 설치되어 있습니다."
} else {
    $installVSCode = Read-Host "Visual Studio Code를 설치하시겠습니까? (y/N)"
    if ($installVSCode -eq "y" -or $installVSCode -eq "Y") {
        choco install vscode -y
        Write-Success "Visual Studio Code 설치 완료"
    }
}

Write-Host ""
Write-Success "🎉 설치가 완료되었습니다!"
Write-Host ""
Write-Host "📋 다음 단계:"
Write-Host "  1. PowerShell을 재시작하세요 (PATH 갱신을 위해)"
Write-Host "  2. 프로젝트 디렉토리로 이동하세요"
Write-Host "  3. .\start.ps1을 실행하세요"
Write-Host ""
Write-Host "🔧 설치된 구성 요소:"
if (Get-Command python -ErrorAction SilentlyContinue) { Write-Host "  ✅ Python" -ForegroundColor Green }
if (Get-Command redis-server -ErrorAction SilentlyContinue) { Write-Host "  ✅ Redis" -ForegroundColor Green }
if (Get-Command ollama -ErrorAction SilentlyContinue) { Write-Host "  ✅ Ollama" -ForegroundColor Green }
if (Get-Command git -ErrorAction SilentlyContinue) { Write-Host "  ✅ Git" -ForegroundColor Green }
if (Get-Command code -ErrorAction SilentlyContinue) { Write-Host "  ✅ Visual Studio Code" -ForegroundColor Green }

Write-Host ""
Read-Host "계속하려면 Enter를 누르세요"
