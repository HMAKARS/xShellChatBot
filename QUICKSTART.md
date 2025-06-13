@echo off
:: XShell AI 챗봇 Windows 설치 스크립트
setlocal enabledelayedexpansion

:: 색상 및 유니코드 지원
chcp 65001 >nul
cls

echo.
echo 📦 XShell AI 챗봇 Windows 설치 스크립트
echo =============================================
echo.
echo 이 스크립트는 다음을 설치합니다:
echo   • Python 가상환경
echo   • Django 웹 프레임워크
echo   • WebSocket 지원 (실시간 채팅)
echo   • 데이터베이스 설정
echo   • 기본 설정 파일
echo.

set /p CONTINUE="설치를 시작하시겠습니까? (Y/n): "
if /i "%CONTINUE%"=="n" goto :user_exit

:: Python 버전 확인
echo 🔍 Python 확인 중...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python이 설치되지 않았거나 PATH에 없습니다.
    echo.
    echo 📥 Python 설치가 필요합니다:
    echo    1. https://python.org/downloads/ 방문
    echo    2. Python 3.8 이상 다운로드
    echo    3. 설치 시 "Add Python to PATH" 체크 필수
    echo.
    echo 🔗 Python 다운로드 페이지를 열겠습니다...
    start https://python.org/downloads/
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo ✅ Python %PYTHON_VERSION% 확인됨

:: pip 업그레이드
echo 📈 pip 업그레이드 중...
python -m pip install --upgrade pip --quiet
echo ✅ pip 업그레이드 완료

:: 가상환경 생성
echo 📦 가상환경 확인 중...
if not exist .venv (
    echo 🔨 가상환경 생성 중...
    python -m venv .venv
    if %errorlevel% neq 0 (
        echo ❌ 가상환경 생성 실패
        pause
        exit /b 1
    )
    echo ✅ 가상환경 생성 완료
) else (
    echo ✅ 가상환경이 이미 존재합니다
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

:: 핵심 패키지 설치
echo 📚 핵심 패키지 설치 중...
echo.

echo [1/7] Django 웹 프레임워크...
pip install Django==4.2.7 --quiet
if %errorlevel% neq 0 (
    echo ❌ Django 설치 실패
    goto :install_error
)
echo ✅ Django 설치 완료

echo [2/7] CORS 헤더 지원...
pip install django-cors-headers==4.3.1 --quiet
if %errorlevel% neq 0 (
    echo ❌ CORS 헤더 설치 실패
    goto :install_error
)
echo ✅ CORS 헤더 설치 완료

echo [3/7] WebSocket 지원...
pip install channels==4.0.0 --quiet
if %errorlevel% neq 0 (
    echo ❌ WebSocket 설치 실패
    goto :install_error
)
echo ✅ WebSocket 설치 완료

echo [4/7] HTTP 클라이언트...
pip install requests==2.31.0 --quiet
if %errorlevel% neq 0 (
    echo ❌ HTTP 클라이언트 설치 실패
    goto :install_error
)
echo ✅ HTTP 클라이언트 설치 완료

echo [5/7] 환경 설정 지원...
pip install python-dotenv==1.0.0 --quiet
if %errorlevel% neq 0 (
    echo ❌ 환경 설정 설치 실패
    goto :install_error
)
echo ✅ 환경 설정 설치 완료

echo [6/7] ASGI 서버...
pip install daphne==4.0.0 --quiet
if %errorlevel% neq 0 (
    echo ❌ ASGI 서버 설치 실패
    goto :install_error
)
echo ✅ ASGI 서버 설치 완료

echo [7/7] SSH 연결 지원...
pip install paramiko==3.3.1 --quiet
if %errorlevel% neq 0 (
    echo ❌ SSH 연결 설치 실패
    goto :install_error
)
echo ✅ SSH 연결 설치 완료

echo.
echo 📄 환경 설정 파일 생성 중...
if not exist .env (
    if exist .env.example (
        copy .env.example .env >nul
        echo ✅ .env 파일 생성 완료
    ) else (
        echo ⚠️ .env.example이 없어서 기본 .env 파일을 생성합니다
        echo SECRET_KEY=django-insecure-dev-key-change-in-production > .env
        echo DEBUG=True >> .env
        echo OLLAMA_BASE_URL=http://localhost:11434 >> .env
        echo DEFAULT_AI_MODEL=llama3.2:3b >> .env
        echo ✅ 기본 .env 파일 생성 완료
    )
) else (
    echo ✅ .env 파일이 이미 존재합니다
)

:: 데이터베이스 설정
echo 🗄️ 데이터베이스 설정 중...
python manage.py makemigrations --verbosity=0 >nul 2>&1
python manage.py migrate --verbosity=0
if %errorlevel% neq 0 (
    echo ❌ 데이터베이스 설정 실패
    goto :install_error
)
echo ✅ 데이터베이스 설정 완료

:: 로그 디렉토리 생성
echo 📂 로그 디렉토리 생성 중...
if not exist logs (
    mkdir logs
)
echo ✅ 로그 디렉토리 준비 완료

:: 정적 파일 디렉토리 생성
echo 📁 정적 파일 디렉토리 확인 중...
if not exist static (
    mkdir static
)
if not exist templates (
    mkdir templates
)
echo ✅ 필요한 디렉토리 준비 완료

:: AI 기능 설정 (선택사항)
echo.
echo 🤖 AI 기능 설정 (선택사항)
echo ==============================
echo AI 기능을 위해 Ollama가 필요합니다.
echo Ollama 없이도 기본 XShell 기능은 사용할 수 있습니다.
echo.

set /p SETUP_AI="AI 기능을 설정하시겠습니까? (Y/n): "
if /i "%SETUP_AI%"=="n" goto :skip_ai

:: Ollama 확인
echo 🔍 Ollama 확인 중...
ollama --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Ollama가 설치되지 않았습니다.
    echo.
    echo 📥 Ollama 설치 옵션:
    echo   1. 자동 설치 (install-ollama-simple.bat)
    echo   2. 수동 설치 (https://ollama.com/download)
    echo   3. 나중에 설치
    echo.
    set /p OLLAMA_CHOICE="선택하세요 (1-3): "
    
    if "%OLLAMA_CHOICE%"=="1" (
        if exist install-ollama-simple.bat (
            echo 🚀 자동 설치 시작...
            call install-ollama-simple.bat
        ) else (
            echo ❌ 설치 스크립트를 찾을 수 없습니다
            goto :manual_ollama
        )
    ) else if "%OLLAMA_CHOICE%"=="2" (
        goto :manual_ollama
    ) else (
        goto :skip_ai
    )
) else (
    echo ✅ Ollama 확인됨
    
    :: 모델 확인
    echo 🔍 AI 모델 확인 중...
    ollama list | findstr "llama" >nul 2>&1
    if %errorlevel% neq 0 (
        echo ⚠️ AI 모델이 설치되지 않았습니다.
        echo.
        echo 📥 권장 모델 (6GB RAM 시스템 최적화):
        echo   1. llama3.2:3b (2GB, 균형잡힌 성능)
        echo   2. llama3.2:1b (1GB, 빠른 속도)
        echo   3. 건너뛰기
        echo.
        set /p MODEL_CHOICE="선택하세요 (1-3): "
        
        if "%MODEL_CHOICE%"=="1" (
            echo 📥 llama3.2:3b 설치 중... (약 2GB)
            ollama pull llama3.2:3b
            echo ✅ AI 모델 설치 완료
        ) else if "%MODEL_CHOICE%"=="2" (
            echo 📥 llama3.2:1b 설치 중... (약 1GB)
            ollama pull llama3.2:1b
            echo ✅ AI 모델 설치 완료
        )
    ) else (
        echo ✅ AI 모델이 이미 설치되어 있습니다
    )
)

goto :ai_complete

:manual_ollama
echo 🔗 Ollama 다운로드 페이지를 열겠습니다...
start https://ollama.com/download
echo.
echo 💡 설치 후 다음 명령어로 모델을 설치하세요:
echo    ollama pull llama3.2:3b
echo.

goto :ai_complete

:skip_ai
echo ✅ AI 기능 설정을 건너뜁니다
echo   나중에 install-ollama-simple.bat으로 설치할 수 있습니다

:ai_complete

:: 설치 완료
echo.
echo 🎉 설치 완료!
echo =================
echo.
echo ✅ 설치된 구성 요소:
echo   • Python 가상환경
echo   • Django 웹 프레임워크
echo   • WebSocket 지원 (실시간 채팅)
echo   • 데이터베이스 (SQLite)
echo   • ASGI 서버 (Daphne)
echo   • 환경 설정 (.env)
echo   • 로그 시스템
if /i "%SETUP_AI%" neq "n" (
    echo   • AI 기능 (Ollama)
)
echo.
echo 🚀 다음 단계:
echo   • 서버 시작: start.bat 또는 run-daphne.bat
echo   • 브라우저에서 http://localhost:8000 접속
echo.
echo 💡 유용한 명령어:
echo   • 서버 시작: start.bat
echo   • AI 기능 설치: install-ollama-simple.bat
echo   • AI 상태 확인: check-ollama-quick.bat
echo.

set /p START_NOW="지금 바로 서버를 시작하시겠습니까? (Y/n): "
if /i "%START_NOW%" neq "n" (
    echo.
    echo 🚀 서버를 시작합니다...
    if exist start.bat (
        call start.bat
    ) else if exist run-daphne.bat (
        call run-daphne.bat
    ) else (
        echo 기본 서버로 시작합니다...
        python manage.py runserver
    )
)

goto :end

:install_error
echo.
echo ❌ 설치 중 오류가 발생했습니다.
echo.
echo 🔧 해결 방법:
echo   1. 인터넷 연결 상태 확인
echo   2. 관리자 권한으로 실행
echo   3. 바이러스 백신 일시 비활성화
echo   4. Python PATH 설정 확인
echo.
echo 💡 수동 설치:
echo   pip install Django channels requests python-dotenv daphne
echo.
goto :end

:user_exit
echo.
echo 👋 설치를 취소했습니다.
echo    나중에 install-minimal.bat을 다시 실행하세요.
echo.

:end
echo.
echo 아무 키나 누르면 종료됩니다...
pause >nul
exit /b 0
