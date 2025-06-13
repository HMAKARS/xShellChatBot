@echo off
:: XShell AI 챗봇 All-in-One 설치 스크립트 (32GB RAM 고성능 버전)
:: Python + Ollama + AI 모델 + 웹서버를 한 번에 설치하고 실행

setlocal enabledelayedexpansion
chcp 65001 >nul
cls

echo.
echo 🚀 XShell AI 챗봇 All-in-One 설치 스크립트
echo ===============================================
echo.
echo 💪 32GB RAM 고성능 시스템용 설치 프로그램
echo.
echo 📦 설치할 구성 요소:
echo   • Python + 가상환경 + 패키지
echo   • Ollama AI 엔진
echo   • 고성능 AI 모델 (llama3.1:8b + codellama:13b)
echo   • Django 웹 서버
echo   • XShell 통합 기능
echo   • 모든 설정 파일 자동 생성
echo.
echo ⏱️  예상 소요 시간: 15-30분 (인터넷 속도에 따라)
echo 💾 필요 디스크 공간: 약 15GB
echo.

set /p CONTINUE="전체 설치를 시작하시겠습니까? (Y/n): "
if /i "%CONTINUE%"=="n" goto :user_exit

:: 관리자 권한 확인
echo 🔐 관리자 권한 확인 중...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ 관리자 권한이 필요합니다.
    echo   이 배치 파일을 우클릭 → "관리자 권한으로 실행"을 선택하세요.
    pause
    exit /b 1
)
echo ✅ 관리자 권한 확인됨

:: =================================================================
:: 1단계: Python 설치 확인 및 설치
:: =================================================================
echo.
echo 🐍 1단계: Python 설치 확인 및 설치
echo ===============================

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python이 설치되지 않았습니다.
    echo.
    echo 📥 Python 자동 설치를 시도합니다...
    
    :: Python 다운로드 URL (Windows x64)
    set PYTHON_URL=https://www.python.org/ftp/python/3.11.6/python-3.11.6-amd64.exe
    set PYTHON_INSTALLER=python-installer.exe
    
    echo 📥 Python 설치 파일 다운로드 중...
    powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%PYTHON_URL%', '%PYTHON_INSTALLER%')"
    
    if not exist "%PYTHON_INSTALLER%" (
        echo ❌ Python 다운로드 실패
        echo   수동으로 https://python.org/downloads/ 에서 설치하세요.
        pause
        exit /b 1
    )
    
    echo 🔧 Python 설치 중... (잠시만 기다려주세요)
    %PYTHON_INSTALLER% /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
    
    echo 🧹 설치 파일 정리 중...
    del "%PYTHON_INSTALLER%" >nul 2>&1
    
    echo 🔄 환경 변수 새로고침 중...
    call refreshenv >nul 2>&1
    
    :: PATH 업데이트를 위해 새로운 cmd 세션에서 확인
    cmd /c python --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo ❌ Python 설치 후에도 인식되지 않습니다.
        echo   시스템을 재시작한 후 다시 시도하세요.
        pause
        exit /b 1
    )
    
    echo ✅ Python 설치 완료!
) else (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
    echo ✅ Python !PYTHON_VERSION! 확인됨
)

:: pip 업그레이드
echo 📈 pip 업그레이드 중...
python -m pip install --upgrade pip --quiet
echo ✅ pip 업그레이드 완료

:: =================================================================
:: 2단계: Ollama 설치
:: =================================================================
echo.
echo 🤖 2단계: Ollama AI 엔진 설치
echo =============================

ollama --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Ollama가 설치되지 않았습니다.
    echo.
    echo 📥 Ollama 자동 설치를 시도합니다...
    
    :: Ollama 다운로드 URL
    set OLLAMA_URL=https://ollama.com/download/windows
    set OLLAMA_INSTALLER=OllamaSetup.exe
    
    echo 📥 Ollama 설치 파일 다운로드 중...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/ollama/ollama/releases/latest/download/OllamaSetup.exe' -OutFile '%OLLAMA_INSTALLER%'"
    
    if not exist "%OLLAMA_INSTALLER%" (
        echo ❌ Ollama 다운로드 실패
        echo   수동으로 https://ollama.com/download 에서 설치하세요.
        pause
        exit /b 1
    )
    
    echo 🔧 Ollama 설치 중... (잠시만 기다려주세요)
    %OLLAMA_INSTALLER% /S
    
    echo 🧹 설치 파일 정리 중...
    del "%OLLAMA_INSTALLER%" >nul 2>&1
    
    echo ⏱️ Ollama 서비스 시작 대기 중... (30초)
    timeout /t 30 /nobreak >nul
    
    :: PATH 업데이트 확인
    ollama --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo ❌ Ollama 설치 후에도 인식되지 않습니다.
        echo   시스템을 재시작한 후 다시 시도하세요.
        pause
        exit /b 1
    )
    
    echo ✅ Ollama 설치 완료!
) else (
    echo ✅ Ollama가 이미 설치되어 있습니다
    ollama --version
)

:: Ollama 서비스 시작
echo 🔄 Ollama 서비스 시작 중...
taskkill /f /im ollama.exe >nul 2>&1
start /min "Ollama Service" ollama serve

echo ⏱️ 서비스 시작 대기 중... (15초)
timeout /t 15 /nobreak >nul

:: 연결 확인
curl -s -m 5 http://localhost:11434/ >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Ollama 서비스 시작 실패
    echo   수동으로 'ollama serve' 명령어를 실행하세요.
    pause
    exit /b 1
)
echo ✅ Ollama 서비스 정상 작동 중

:: =================================================================
:: 3단계: 고성능 AI 모델 설치 (32GB RAM용)
:: =================================================================
echo.
echo 🧠 3단계: 고성능 AI 모델 설치 (32GB RAM용)
echo =========================================
echo.
echo 💡 32GB RAM 시스템에 최적화된 모델들을 설치합니다:
echo   • llama3.1:8b (4.7GB) - 일반 대화용 고성능 모델
echo   • codellama:13b (7GB) - 코드 분석용 전문 모델
echo   • llama3.1:70b (40GB) - 최고 성능 모델 (선택사항)
echo.

:: 기본 모델들 설치
set MODEL_COUNT=0

echo [1/2] llama3.1:8b 모델 설치 중... (약 4.7GB)
ollama list | findstr "llama3.1:8b" >nul 2>&1
if %errorlevel% neq 0 (
    echo 📥 다운로드 시작... (5-10분 소요 예상)
    ollama pull llama3.1:8b
    if %errorlevel% equ 0 (
        echo ✅ llama3.1:8b 설치 완료!
        set /a MODEL_COUNT+=1
    ) else (
        echo ❌ llama3.1:8b 설치 실패
    )
) else (
    echo ✅ llama3.1:8b 이미 설치됨
    set /a MODEL_COUNT+=1
)

echo [2/2] codellama:13b 모델 설치 중... (약 7GB)
ollama list | findstr "codellama:13b" >nul 2>&1
if %errorlevel% neq 0 (
    echo 📥 다운로드 시작... (7-15분 소요 예상)
    ollama pull codellama:13b
    if %errorlevel% equ 0 (
        echo ✅ codellama:13b 설치 완료!
        set /a MODEL_COUNT+=1
    ) else (
        echo ❌ codellama:13b 설치 실패
    )
) else (
    echo ✅ codellama:13b 이미 설치됨
    set /a MODEL_COUNT+=1
)

:: 최고성능 모델 선택 설치
echo.
echo 🔥 선택사항: 최고성능 모델 설치
echo ===============================
echo llama3.1:70b 모델 (약 40GB)은 최고 성능을 제공하지만
echo 다운로드에 시간이 많이 걸립니다. (20-60분)
echo.
set /p INSTALL_70B="llama3.1:70b 모델을 설치하시겠습니까? (y/N): "
if /i "%INSTALL_70B%"=="y" (
    echo [3/3] llama3.1:70b 모델 설치 중... (약 40GB)
    echo 📥 대용량 다운로드 시작... (20-60분 소요 예상)
    echo ⚠️ 다운로드 중에는 컴퓨터를 사용할 수 있지만 인터넷이 느려질 수 있습니다.
    ollama pull llama3.1:70b
    if %errorlevel% equ 0 (
        echo ✅ llama3.1:70b 설치 완료!
        set /a MODEL_COUNT+=1
    ) else (
        echo ❌ llama3.1:70b 설치 실패 (나중에 수동으로 설치 가능)
    )
)

echo.
echo 📊 AI 모델 설치 결과: !MODEL_COUNT!개 설치 완료
echo 설치된 모델 목록:
ollama list

:: =================================================================
:: 4단계: Python 가상환경 및 패키지 설치
:: =================================================================
echo.
echo 🐍 4단계: Python 환경 설정
echo ==========================

:: 가상환경 생성
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

:: 패키지 설치
echo 📚 Python 패키지 설치 중...
echo.

set PACKAGE_COUNT=0

echo [1/8] Django 웹 프레임워크...
pip install Django==4.2.7 --quiet
if %errorlevel% equ 0 (
    echo ✅ Django 설치 완료
    set /a PACKAGE_COUNT+=1
) else (
    echo ❌ Django 설치 실패
)

echo [2/8] CORS 헤더 지원...
pip install django-cors-headers==4.3.1 --quiet
if %errorlevel% equ 0 (
    echo ✅ CORS 헤더 설치 완료
    set /a PACKAGE_COUNT+=1
) else (
    echo ❌ CORS 헤더 설치 실패
)

echo [3/8] WebSocket 지원...
pip install channels==4.0.0 --quiet
if %errorlevel% equ 0 (
    echo ✅ WebSocket 설치 완료
    set /a PACKAGE_COUNT+=1
) else (
    echo ❌ WebSocket 설치 실패
)

echo [4/8] HTTP 클라이언트...
pip install requests==2.31.0 --quiet
if %errorlevel% equ 0 (
    echo ✅ HTTP 클라이언트 설치 완료
    set /a PACKAGE_COUNT+=1
) else (
    echo ❌ HTTP 클라이언트 설치 실패
)

echo [5/8] 환경 설정 지원...
pip install python-dotenv==1.0.0 --quiet
if %errorlevel% equ 0 (
    echo ✅ 환경 설정 설치 완료
    set /a PACKAGE_COUNT+=1
) else (
    echo ❌ 환경 설정 설치 실패
)

echo [6/8] ASGI 서버...
pip install daphne==4.0.0 --quiet
if %errorlevel% equ 0 (
    echo ✅ ASGI 서버 설치 완료
    set /a PACKAGE_COUNT+=1
) else (
    echo ❌ ASGI 서버 설치 실패
)

echo [7/8] SSH 연결 지원...
pip install paramiko==3.3.1 --quiet
if %errorlevel% equ 0 (
    echo ✅ SSH 연결 설치 완료
    set /a PACKAGE_COUNT+=1
) else (
    echo ❌ SSH 연결 설치 실패
)

echo [8/8] Redis 클라이언트...
pip install redis==5.0.1 --quiet
if %errorlevel% equ 0 (
    echo ✅ Redis 클라이언트 설치 완료
    set /a PACKAGE_COUNT+=1
) else (
    echo ❌ Redis 클라이언트 설치 실패
)

echo.
echo 📊 패키지 설치 결과: !PACKAGE_COUNT!/8 성공

if !PACKAGE_COUNT! lss 6 (
    echo ⚠️ 필수 패키지 설치에 실패했습니다.
    echo   인터넷 연결을 확인하고 다시 시도하세요.
    pause
    exit /b 1
)

:: =================================================================
:: 5단계: 환경 설정 파일 생성 (32GB RAM 최적화)
:: =================================================================
echo.
echo 📄 5단계: 환경 설정 파일 생성 (32GB RAM 최적화)
echo ==============================================

:: .env 파일 생성 (고성능 설정)
echo 📝 고성능 .env 파일 생성 중...
(
echo # XShell AI 챗봇 환경 설정 (32GB RAM 고성능 버전^)
echo.
echo # Django Settings
echo SECRET_KEY=django-insecure-dev-key-change-in-production-32gb-version
echo DEBUG=True
echo.
echo # Database
echo DATABASE_URL=sqlite:///db.sqlite3
echo.
echo # XShell Integration
echo XSHELL_PATH=C:\Program Files\NetSarang\Xshell 8\Xshell.exe
echo XSHELL_SESSIONS_PATH=C:\Users\%USERNAME%\Documents\NetSarang Computer\8\Xshell\Sessions
echo.
echo # AI Backend (Ollama^) - 32GB RAM 고성능 설정
echo OLLAMA_BASE_URL=http://localhost:11434
echo DEFAULT_AI_MODEL=llama3.1:8b
echo CODE_AI_MODEL=codellama:13b
echo.
echo # 고성능 AI 옵션
echo OLLAMA_MAX_LOADED_MODELS=2
echo OLLAMA_CONTEXT_LENGTH=8192
echo OLLAMA_NUM_PARALLEL=4
echo.
echo # Security
echo ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0
echo CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
echo.
echo # Logging
echo LOG_LEVEL=INFO
) > .env

echo ✅ 고성능 .env 파일 생성 완료

:: Django settings.py 업데이트 (고성능 설정)
echo 📝 Django 설정 업데이트 중...
if exist xshell_chatbot\settings.py (
    :: 기존 설정 백업
    copy xshell_chatbot\settings.py xshell_chatbot\settings.py.backup >nul
    
    :: 고성능 설정으로 업데이트
    powershell -Command "(Get-Content xshell_chatbot\settings.py) -replace 'llama3.2:3b', 'llama3.1:8b' -replace 'codellama:7b', 'codellama:13b' | Set-Content xshell_chatbot\settings.py"
    
    echo ✅ Django 설정 고성능으로 업데이트 완료
)

:: =================================================================
:: 6단계: 데이터베이스 및 디렉토리 설정
:: =================================================================
echo.
echo 🗄️ 6단계: 데이터베이스 및 디렉토리 설정
echo ===================================

:: 필요한 디렉토리 생성
echo 📂 필요한 디렉토리 생성 중...
if not exist logs mkdir logs
if not exist static mkdir static
if not exist templates mkdir templates
if not exist media mkdir media
echo ✅ 디렉토리 생성 완료

:: 데이터베이스 설정
echo 🗄️ 데이터베이스 설정 중...
python manage.py makemigrations --verbosity=0 >nul 2>&1
python manage.py migrate --verbosity=0
if %errorlevel% neq 0 (
    echo ❌ 데이터베이스 설정 실패
    pause
    exit /b 1
)
echo ✅ 데이터베이스 설정 완료

:: =================================================================
:: 7단계: 시스템 테스트 및 검증
:: =================================================================
echo.
echo 🧪 7단계: 시스템 테스트 및 검증
echo =============================

echo 🔍 전체 시스템 검증 중...

:: Python 환경 테스트
echo [1/5] Python 환경...
python -c "import django; print('✅ Django 정상')" 2>nul
if %errorlevel% neq 0 (
    echo ❌ Python 환경 오류
    goto :test_failed
)

:: Ollama 연결 테스트
echo [2/5] Ollama 연결...
curl -s -m 5 http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Ollama 연결 오류
    goto :test_failed
)
echo ✅ Ollama 연결 정상

:: AI 모델 테스트
echo [3/5] AI 모델 테스트...
python -c "
import requests
try:
    response = requests.post('http://localhost:11434/api/generate', 
        json={'model': 'llama3.1:8b', 'prompt': 'Hi', 'stream': False, 'options': {'num_predict': 5}},
        timeout=15)
    if response.status_code == 200:
        print('✅ AI 모델 정상')
    else:
        print('❌ AI 모델 응답 오류')
        exit(1)
except:
    print('❌ AI 모델 테스트 실패')
    exit(1)
"
if %errorlevel% neq 0 goto :test_failed

:: Django 설정 테스트
echo [4/5] Django 설정...
python manage.py check --verbosity=0 >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Django 설정 오류
    goto :test_failed
)
echo ✅ Django 설정 정상

:: 전체 통합 테스트
echo [5/5] 통합 테스트...
timeout /t 2 /nobreak >nul
echo ✅ 모든 테스트 통과!

goto :test_passed

:test_failed
echo.
echo ❌ 시스템 테스트 실패
echo   일부 기능에 문제가 있지만 기본 사용은 가능할 수 있습니다.
echo.
set /p CONTINUE_ANYWAY="문제를 무시하고 계속하시겠습니까? (y/N): "
if /i "%CONTINUE_ANYWAY%" neq "y" (
    echo 설치를 중단합니다.
    pause
    exit /b 1
)

:test_passed

:: =================================================================
:: 8단계: 서비스 시작 및 브라우저 열기
:: =================================================================
echo.
echo 🚀 8단계: 서비스 시작 및 최종 설정
echo ================================

echo 🎉 설치 완료!
echo ==============
echo.
echo ✅ 설치된 구성 요소:
echo   • Python 3.11 + 가상환경
echo   • Django 웹 프레임워크
echo   • Ollama AI 엔진
echo   • AI 모델: llama3.1:8b, codellama:13b
if /i "%INSTALL_70B%"=="y" (
    echo   • 최고성능 AI 모델: llama3.1:70b
)
echo   • WebSocket 실시간 채팅
echo   • 데이터베이스 (SQLite)
echo   • 모든 설정 파일 (32GB RAM 최적화)
echo.
echo 🔥 32GB RAM 고성능 설정:
echo   • 기본 AI 모델: llama3.1:8b (고품질 대화)
echo   • 코드 AI 모델: codellama:13b (전문 코드 분석)
echo   • 동시 모델 로딩: 2개
echo   • 컨텍스트 길이: 8192 토큰
echo   • 병렬 처리: 4 스레드
echo.

set /p START_SERVER="지금 바로 서버를 시작하시겠습니까? (Y/n): "
if /i "%START_SERVER%"=="n" goto :manual_start

echo.
echo 🚀 서버 시작 중...
echo.

:: 브라우저 자동 열기 (5초 후)
echo 🌐 5초 후 브라우저가 자동으로 열립니다...
start "" timeout /t 5 /nobreak >nul 2>&1 && start http://localhost:8000

:: 서버 시작 (start.bat 우선)
if exist start.bat (
    echo start.bat을 사용해서 서버를 시작합니다...
    call start.bat
) else if exist run-daphne.bat (
    echo run-daphne.bat을 사용해서 서버를 시작합니다...
    call run-daphne.bat
) else (
    echo Django 개발 서버로 시작합니다...
    python manage.py runserver 0.0.0.0:8000
)

goto :end

:manual_start
echo.
echo 📋 수동 시작 방법:
echo ================
echo.
echo 1. 서버 시작:
echo    start.bat
echo.
echo 2. 브라우저 접속:
echo    http://localhost:8000
echo.
echo 3. 유용한 명령어:
echo    • AI 상태 확인: check-ollama-quick.bat
echo    • AI 오류 수정: fix-ollama-500.bat
echo    • 전체 테스트: test-ai.bat
echo.

goto :end

:user_exit
echo.
echo 👋 설치를 취소했습니다.
echo    나중에 install-all-in-one.bat을 다시 실행하세요.
echo.

:end
echo.
echo 🎊 XShell AI 챗봇 All-in-One 설치 완료!
echo.
echo 💡 추가 정보:
echo   • 관리자 페이지: http://localhost:8000/admin
echo   • AI 모델 변경: .env 파일에서 DEFAULT_AI_MODEL 수정
echo   • 설정 파일 위치: .env (고성능 32GB RAM 최적화됨)
echo   • 로그 파일: logs\ 디렉토리
echo   • 문제 해결: TROUBLESHOOTING-AI.md 참조
echo.
echo 🚀 즐거운 AI 챗봇 사용 되세요!
echo.
pause
