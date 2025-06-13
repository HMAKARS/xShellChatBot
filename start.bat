@echo off
:: XShell AI 챗봇 Windows 시작 스크립트
setlocal enabledelayedexpansion

:: 색상 및 유니코드 지원
chcp 65001 >nul
cls

echo.
echo 🤖 XShell AI 챗봇 Windows 시작 스크립트
echo ================================================
echo.

:: Python 버전 확인
echo 🔍 Python 확인 중...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python이 설치되지 않았거나 PATH에 없습니다.
    echo    Python 3.8 이상을 설치하고 PATH에 추가해주세요.
    echo    다운로드: https://python.org/downloads/
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo ✅ Python %PYTHON_VERSION% 확인됨

:: 가상환경 확인 및 생성
if not exist .venv (
    echo 📦 가상환경 생성 중...
    python -m venv .venv
    if %errorlevel% neq 0 (
        echo ❌ 가상환경 생성 실패
        pause
        exit /b 1
    )
    echo ✅ 가상환경 생성 완료
) else (
    echo ✅ 가상환경 확인됨
)

:: 가상환경 활성화
echo 🔄 가상환경 활성화 중...
call .venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ❌ 가상환경 활성화 실패
    pause
    exit /b 1
)
echo ✅ 가상환경 활성화 완료

:: 의존성 설치 확인
echo 📚 의존성 확인 중...
pip show django >nul 2>&1
if %errorlevel% neq 0 (
    echo 📥 의존성 설치 중... (시간이 걸릴 수 있습니다)
    echo    최소 패키지부터 설치를 시도합니다...
    
    REM 먼저 최소 패키지 설치 시도
    pip install -r requirements-minimal.txt
    if %errorlevel% equ 0 (
        echo ✅ 최소 의존성 설치 완료
    ) else (
        echo ⚠️ 최소 패키지 설치 실패, Windows 전용 패키지로 재시도...
        pip install -r requirements-windows.txt
        if %errorlevel% equ 0 (
            echo ✅ Windows 전용 패키지 설치 완료
        ) else (
            echo ❌ 패키지 설치 실패
            echo.
            echo 🔧 수동 설치를 시도해보세요:
            echo    pip install Django==4.2.7
            echo    pip install channels==4.0.0
            echo    pip install requests==2.31.0
            echo    pip install python-dotenv==1.0.0
            echo    pip install daphne==4.0.0
            echo.
            pause
            exit /b 1
        )
    )
) else (
    echo ✅ 의존성 확인됨
)

:: 환경설정 파일 확인
if not exist .env (
    if exist .env.example (
        echo 📄 .env 파일 생성 중...
        copy .env.example .env >nul
        echo ✅ .env 파일 생성 완료
        echo ⚠️  .env 파일을 확인하고 필요한 설정을 수정해주세요.
    ) else (
        echo ⚠️  .env.example 파일이 없습니다.
    )
)

:: Redis 확인 (선택사항)
echo 🔍 Redis 연결 확인 중...
powershell -Command "try { $client = New-Object System.Net.Sockets.TcpClient('localhost', 6379); $client.Close(); Write-Host '✅ Redis 연결 성공' } catch { Write-Host '⚠️  Redis 연결 실패 - WebSocket 기능이 제한될 수 있습니다' }"

:: Ollama 확인 (선택사항)
echo 🔍 Ollama 연결 확인 중...
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -TimeoutSec 5; Write-Host '✅ Ollama 연결 성공' } catch { Write-Host '⚠️  Ollama 연결 실패 - AI 기능이 제한될 수 있습니다' }"

:: 데이터베이스 마이그레이션
echo 🗄️  데이터베이스 확인 중...
if not exist db.sqlite3 (
    echo 📊 데이터베이스 초기화 중...
    python manage.py makemigrations
    python manage.py migrate
    echo ✅ 데이터베이스 초기화 완료
    
    :: 슈퍼유저 생성 여부 묻기
    set /p CREATE_SUPERUSER="👤 관리자 계정을 생성하시겠습니까? (y/N): "
    if /i "!CREATE_SUPERUSER!"=="y" (
        python manage.py createsuperuser
    )
) else (
    echo ✅ 데이터베이스 확인됨
    echo 🔄 마이그레이션 확인 중...
    python manage.py migrate --check >nul 2>&1
    if %errorlevel% neq 0 (
        echo 📊 데이터베이스 업데이트 중...
        python manage.py makemigrations
        python manage.py migrate
    )
)

:: AI 모델 확인
echo 🤖 AI 모델 상태 확인 중...
python manage.py check_ai_models >nul 2>&1

:: 로그 디렉토리 생성
if not exist logs (
    mkdir logs
    echo ✅ 로그 디렉토리 생성 완료
)

:: 서버 시작 방식 선택
echo.
echo 🚀 서버 시작 방식을 선택하세요:
echo   1. 개발 서버 (Django runserver) - 권장
echo   2. 프로덕션 서버 (Daphne)
echo   3. Python 시작 스크립트 사용
echo.
set /p SERVER_TYPE="선택 (1-3, 기본값: 1): "
if "!SERVER_TYPE!"=="" set SERVER_TYPE=1

echo.
echo 🎉 모든 준비가 완료되었습니다!
echo.
echo 📋 서비스 정보:
echo   • 웹 애플리케이션: http://localhost:8000
echo   • 관리자 페이지: http://localhost:8000/admin
echo   • 종료하려면 Ctrl+C를 누르세요
echo.

:: 브라우저 자동 열기 (5초 후)
start "" timeout /t 5 /nobreak >nul 2>&1 && start http://localhost:8000

if "!SERVER_TYPE!"=="1" (
    echo 🚀 Django 개발 서버 시작 중...
    python manage.py runserver 0.0.0.0:8000
) else if "!SERVER_TYPE!"=="2" (
    echo 🚀 Daphne 프로덕션 서버 시작 중...
    pip show daphne >nul 2>&1 || pip install daphne
    daphne -b 0.0.0.0 -p 8000 xshell_chatbot.asgi:application
) else if "!SERVER_TYPE!"=="3" (
    echo 🚀 Python 시작 스크립트 실행 중...
    python start_server.py
) else (
    echo ❌ 잘못된 선택입니다. 기본 서버로 시작합니다.
    python manage.py runserver 0.0.0.0:8000
)

pause
