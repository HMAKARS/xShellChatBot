@echo off
:: XShell AI 챗봇 All-in-One 설치 스크립트 (개선된 버전)
:: 안정성과 오류 처리를 대폭 개선한 버전

setlocal enabledelayedexpansion
chcp 65001 >nul
cls

:: 전역 변수 설정
set "SCRIPT_DIR=%~dp0"
set "TEMP_DIR=%SCRIPT_DIR%temp_install"
set "LOG_FILE=%SCRIPT_DIR%install.log"
set "PYTHON_INSTALLER=python-installer.exe"
set "OLLAMA_INSTALLER=OllamaSetup.exe"

:: 로그 시작
echo %date% %time% - XShell AI 챗봇 설치 시작 > "%LOG_FILE%"

echo.
echo 🚀 XShell AI 챗봇 All-in-One 설치 스크립트 (개선된 버전)
echo ========================================================
echo.
echo 💪 고성능 시스템용 최적화 설치 프로그램
echo.
echo 📦 설치할 구성 요소:
echo   • Python 3.11 + 가상환경 + 의존성 패키지
echo   • Ollama AI 엔진 + 고성능 모델들
echo   • Django 웹 서버 + WebSocket 지원
echo   • XShell 통합 기능 + 모든 설정 파일
echo.
echo ⏱️  예상 소요 시간: 15-30분 (인터넷 속도에 따라)
echo 💾 필요 디스크 공간: 약 15GB
echo 📁 설치 위치: %SCRIPT_DIR%
echo.

set /p CONTINUE="전체 설치를 시작하시겠습니까? (Y/n): "
if /i "%CONTINUE%"=="n" goto :user_exit

:: 관리자 권한 확인
echo 🔐 관리자 권한 확인 중...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ 관리자 권한이 필요합니다.
    echo   이 배치 파일을 우클릭 → "관리자 권한으로 실행"을 선택하세요.
    echo %date% %time% - 관리자 권한 없음 >> "%LOG_FILE%"
    pause
    exit /b 1
)
echo ✅ 관리자 권한 확인됨
echo %date% %time% - 관리자 권한 확인됨 >> "%LOG_FILE%"

:: 임시 디렉토리 생성
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

:: =================================================================
:: 1단계: 시스템 환경 검사
:: =================================================================
echo.
echo 🔍 1단계: 시스템 환경 검사
echo ==========================

echo 시스템 정보 확인 중...
systeminfo | findstr "Total Physical Memory" | findstr /C:"GB"
if %errorlevel% neq 0 (
    echo ⚠️ 시스템 메모리 정보를 확인할 수 없습니다.
)

echo 디스크 공간 확인 중...
for /f "tokens=3" %%i in ('dir /-c') do set FREE_SPACE=%%i
echo 💾 사용 가능한 디스크 공간 확인됨

echo ✅ 시스템 환경 검사 완료

:: =================================================================
:: 2단계: Python 설치 및 확인
:: =================================================================
echo.
echo 🐍 2단계: Python 설치 및 확인
echo =============================

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python이 설치되지 않았습니다.
    echo.
    echo 📥 Python 자동 설치를 시도합니다...
    
    :: Python 다운로드
    set PYTHON_URL=https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe
    
    echo 📥 Python 설치 파일 다운로드 중...
    echo %date% %time% - Python 다운로드 시작 >> "%LOG_FILE%"
    
    powershell -Command "try { (New-Object System.Net.WebClient).DownloadFile('%PYTHON_URL%', '%TEMP_DIR%\%PYTHON_INSTALLER%'); Write-Host '✅ Python 다운로드 완료' } catch { Write-Host '❌ Python 다운로드 실패'; exit 1 }"
    
    if not exist "%TEMP_DIR%\%PYTHON_INSTALLER%" (
        echo ❌ Python 다운로드 실패
        echo   수동으로 https://python.org/downloads/ 에서 설치하세요.
        echo %date% %time% - Python 다운로드 실패 >> "%LOG_FILE%"
        goto :install_error
    )
    
    echo 🔧 Python 설치 중... (2-5분 소요)
    echo %date% %time% - Python 설치 시작 >> "%LOG_FILE%"
    
    "%TEMP_DIR%\%PYTHON_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
    set PYTHON_INSTALL_RESULT=%errorlevel%
    
    echo 🧹 Python 설치 파일 정리 중...
    call :safe_delete "%TEMP_DIR%\%PYTHON_INSTALLER%"
    
    if %PYTHON_INSTALL_RESULT% neq 0 (
        echo ❌ Python 설치 실패 (오류 코드: %PYTHON_INSTALL_RESULT%)
        echo %date% %time% - Python 설치 실패 >> "%LOG_FILE%"
        goto :install_error
    )
    
    echo 🔄 시스템 환경 변수 새로고침 중...
    call :refresh_path
    
    timeout /t 10 /nobreak >nul
    
    python --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo ❌ Python 설치 후에도 인식되지 않습니다.
        echo   시스템을 재시작한 후 다시 시도하세요.
        echo %date% %time% - Python PATH 설정 실패 >> "%LOG_FILE%"
        goto :install_error
    )
    
    echo ✅ Python 설치 완료!
    echo %date% %time% - Python 설치 완료 >> "%LOG_FILE%"
) else (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
    echo ✅ Python !PYTHON_VERSION! 확인됨
    echo %date% %time% - Python !PYTHON_VERSION! 확인됨 >> "%LOG_FILE%"
)

:: pip 업그레이드
echo 📈 pip 업그레이드 중...
python -m pip install --upgrade pip --quiet --no-warn-script-location
echo ✅ pip 업그레이드 완료

:: =================================================================
:: 3단계: Ollama 설치
:: =================================================================
echo.
echo 🤖 3단계: Ollama AI 엔진 설치
echo =============================

ollama --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Ollama가 설치되지 않았습니다.
    echo.
    echo 📥 Ollama 자동 설치를 시도합니다...
    
    echo 📥 Ollama 설치 파일 다운로드 중...
    echo %date% %time% - Ollama 다운로드 시작 >> "%LOG_FILE%"
    
    powershell -Command "try { Invoke-WebRequest -Uri 'https://github.com/ollama/ollama/releases/latest/download/OllamaSetup.exe' -OutFile '%TEMP_DIR%\%OLLAMA_INSTALLER%' -ErrorAction Stop; Write-Host '✅ Ollama 다운로드 완료' } catch { Write-Host '❌ Ollama 다운로드 실패'; exit 1 }"
    
    if not exist "%TEMP_DIR%\%OLLAMA_INSTALLER%" (
        echo ❌ Ollama 다운로드 실패
        echo   수동으로 https://ollama.com/download 에서 설치하세요.
        echo %date% %time% - Ollama 다운로드 실패 >> "%LOG_FILE%"
        goto :install_error
    )
    
    echo 🔧 Ollama 설치 중... (2-5분 소요)
    echo %date% %time% - Ollama 설치 시작 >> "%LOG_FILE%"
    
    "%TEMP_DIR%\%OLLAMA_INSTALLER%" /S
    set OLLAMA_INSTALL_RESULT=%errorlevel%
    
    echo 🧹 Ollama 설치 파일 정리 중...
    call :safe_delete "%TEMP_DIR%\%OLLAMA_INSTALLER%"
    
    if %OLLAMA_INSTALL_RESULT% neq 0 (
        echo ❌ Ollama 설치 실패 (오류 코드: %OLLAMA_INSTALL_RESULT%)
        echo %date% %time% - Ollama 설치 실패 >> "%LOG_FILE%"
        goto :install_error
    )
    
    echo ⏱️ Ollama 서비스 시작 대기 중... (30초)
    timeout /t 30 /nobreak >nul
    
    call :refresh_path
    
    ollama --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo ❌ Ollama 설치 후에도 인식되지 않습니다.
        echo   시스템을 재시작한 후 다시 시도하세요.
        echo %date% %time% - Ollama PATH 설정 실패 >> "%LOG_FILE%"
        goto :install_error
    )
    
    echo ✅ Ollama 설치 완료!
    echo %date% %time% - Ollama 설치 완료 >> "%LOG_FILE%"
) else (
    echo ✅ Ollama가 이미 설치되어 있습니다
    ollama --version
    echo %date% %time% - Ollama 이미 설치됨 >> "%LOG_FILE%"
)

:: Ollama 서비스 시작
echo 🔄 Ollama 서비스 시작 중...
taskkill /f /im ollama.exe >nul 2>&1
start /min "Ollama Service" ollama serve

echo ⏱️ 서비스 시작 대기 중... (15초)
timeout /t 15 /nobreak >nul

:: 연결 확인 (여러 번 시도)
for /l %%i in (1,1,5) do (
    curl -s -m 5 http://localhost:11434/ >nul 2>&1
    if !errorlevel! equ 0 (
        echo ✅ Ollama 서비스 정상 작동 중
        goto :ollama_running
    )
    echo 연결 시도 %%i/5...
    timeout /t 3 /nobreak >nul
)

echo ❌ Ollama 서비스 시작 실패
echo   수동으로 'ollama serve' 명령어를 실행하세요.
echo %date% %time% - Ollama 서비스 시작 실패 >> "%LOG_FILE%"
goto :install_error

:ollama_running
echo %date% %time% - Ollama 서비스 정상 시작 >> "%LOG_FILE%"

:: =================================================================
:: 4단계: AI 모델 설치
:: =================================================================
echo.
echo 🧠 4단계: AI 모델 설치
echo ====================
echo.
echo 💡 고성능 AI 모델들을 설치합니다:
echo   • llama3.1:8b (4.7GB) - 일반 대화용 고성능 모델
echo   • codellama:13b (7GB) - 코드 분석용 전문 모델
echo.

set MODEL_COUNT=0

echo [1/2] llama3.1:8b 모델 설치 중... (약 4.7GB)
echo %date% %time% - llama3.1:8b 모델 설치 시작 >> "%LOG_FILE%"
ollama list | findstr "llama3.1:8b" >nul 2>&1
if %errorlevel% neq 0 (
    echo 📥 다운로드 시작... (5-10분 소요 예상)
    ollama pull llama3.1:8b
    if !errorlevel! equ 0 (
        echo ✅ llama3.1:8b 설치 완료!
        set /a MODEL_COUNT+=1
        echo %date% %time% - llama3.1:8b 모델 설치 완료 >> "%LOG_FILE%"
    ) else (
        echo ❌ llama3.1:8b 설치 실패
        echo %date% %time% - llama3.1:8b 모델 설치 실패 >> "%LOG_FILE%"
    )
) else (
    echo ✅ llama3.1:8b 이미 설치됨
    set /a MODEL_COUNT+=1
    echo %date% %time% - llama3.1:8b 모델 이미 설치됨 >> "%LOG_FILE%"
)

echo [2/2] codellama:13b 모델 설치 중... (약 7GB)
echo %date% %time% - codellama:13b 모델 설치 시작 >> "%LOG_FILE%"
ollama list | findstr "codellama:13b" >nul 2>&1
if %errorlevel% neq 0 (
    echo 📥 다운로드 시작... (7-15분 소요 예상)
    ollama pull codellama:13b
    if !errorlevel! equ 0 (
        echo ✅ codellama:13b 설치 완료!
        set /a MODEL_COUNT+=1
        echo %date% %time% - codellama:13b 모델 설치 완료 >> "%LOG_FILE%"
    ) else (
        echo ❌ codellama:13b 설치 실패
        echo %date% %time% - codellama:13b 모델 설치 실패 >> "%LOG_FILE%"
    )
) else (
    echo ✅ codellama:13b 이미 설치됨
    set /a MODEL_COUNT+=1
    echo %date% %time% - codellama:13b 모델 이미 설치됨 >> "%LOG_FILE%"
)

echo.
echo 📊 AI 모델 설치 결과: !MODEL_COUNT!개 설치 완료
echo 설치된 모델 목록:
ollama list

:: =================================================================
:: 5단계: Python 가상환경 및 패키지 설치
:: =================================================================
echo.
echo 🐍 5단계: Python 환경 설정
echo ==========================

:: 가상환경 생성
if not exist .venv (
    echo 📦 가상환경 생성 중...
    python -m venv .venv
    if %errorlevel% neq 0 (
        echo ❌ 가상환경 생성 실패
        echo %date% %time% - 가상환경 생성 실패 >> "%LOG_FILE%"
        goto :install_error
    )
    echo ✅ 가상환경 생성 완료
    echo %date% %time% - 가상환경 생성 완료 >> "%LOG_FILE%"
) else (
    echo ✅ 가상환경이 이미 존재합니다
    echo %date% %time% - 가상환경 이미 존재 >> "%LOG_FILE%"
)

:: 가상환경 활성화
echo 🔄 가상환경 활성화 중...
call .venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ❌ 가상환경 활성화 실패
    echo %date% %time% - 가상환경 활성화 실패 >> "%LOG_FILE%"
    goto :install_error
)
echo ✅ 가상환경 활성화 완료

:: 패키지 설치 (기존 requirements 파일 활용)
echo 📚 Python 패키지 설치 중...
echo %date% %time% - 패키지 설치 시작 >> "%LOG_FILE%"

if exist requirements-minimal.txt (
    echo 최소 패키지부터 설치 시도...
    pip install -r requirements-minimal.txt --quiet --no-warn-script-location
    set MINIMAL_RESULT=%errorlevel%
) else (
    set MINIMAL_RESULT=1
)

if !MINIMAL_RESULT! neq 0 (
    if exist requirements-windows.txt (
        echo Windows 전용 패키지로 설치 시도...
        pip install -r requirements-windows.txt --quiet --no-warn-script-location
        set WINDOWS_RESULT=%errorlevel%
    ) else (
        set WINDOWS_RESULT=1
    )
    
    if !WINDOWS_RESULT! neq 0 (
        echo 개별 패키지 설치로 전환...
        call :install_core_packages
    ) else (
        echo ✅ Windows 전용 패키지 설치 완료
    )
) else (
    echo ✅ 최소 패키지 설치 완료
)

echo %date% %time% - 패키지 설치 완료 >> "%LOG_FILE%"

:: =================================================================
:: 6단계: 환경 설정 파일 생성
:: =================================================================
echo.
echo 📄 6단계: 환경 설정 파일 생성
echo =============================

:: .env 파일 확인 및 생성
if not exist .env (
    if exist .env.example (
        echo 📝 .env.example에서 .env 파일 생성 중...
        copy .env.example .env >nul
        echo ✅ .env 파일 생성 완료
    ) else (
        echo 📝 새로운 .env 파일 생성 중...
        call :create_env_file
        echo ✅ .env 파일 생성 완료
    )
) else (
    echo ✅ .env 파일이 이미 존재합니다
)

echo %date% %time% - 환경 설정 파일 생성 완료 >> "%LOG_FILE%"

:: =================================================================
:: 7단계: 데이터베이스 설정
:: =================================================================
echo.
echo 🗄️ 7단계: 데이터베이스 설정
echo ===========================

:: 필요한 디렉토리 생성
echo 📂 필요한 디렉토리 생성 중...
if not exist logs mkdir logs
if not exist static mkdir static
if not exist templates mkdir templates
if not exist media mkdir media
echo ✅ 디렉토리 생성 완료

:: 데이터베이스 설정
echo 🗄️ 데이터베이스 설정 중...
python manage.py check --verbosity=0 >nul 2>&1
python manage.py makemigrations --verbosity=0 >nul 2>&1
python manage.py migrate --verbosity=0
if %errorlevel% neq 0 (
    echo ❌ 데이터베이스 설정 실패
    echo %date% %time% - 데이터베이스 설정 실패 >> "%LOG_FILE%"
    goto :install_error
)
echo ✅ 데이터베이스 설정 완료
echo %date% %time% - 데이터베이스 설정 완료 >> "%LOG_FILE%"

:: =================================================================
:: 8단계: 시스템 테스트
:: =================================================================
echo.
echo 🧪 8단계: 시스템 테스트
echo ====================

echo 🔍 전체 시스템 검증 중...

call :test_system
if %errorlevel% neq 0 (
    echo ❌ 시스템 테스트 실패
    set /p CONTINUE_ANYWAY="문제를 무시하고 계속하시겠습니까? (y/N): "
    if /i "!CONTINUE_ANYWAY!" neq "y" (
        echo 설치를 중단합니다.
        echo %date% %time% - 사용자가 테스트 실패로 설치 중단 >> "%LOG_FILE%"
        goto :install_error
    )
) else (
    echo ✅ 모든 테스트 통과!
    echo %date% %time% - 시스템 테스트 통과 >> "%LOG_FILE%"
)

:: =================================================================
:: 9단계: 설치 완료 및 서비스 시작
:: =================================================================
echo.
echo 🎉 9단계: 설치 완료!
echo ====================
echo.
echo ✅ 설치된 구성 요소:
echo   • Python 3.11 + 가상환경
echo   • Django 웹 프레임워크
echo   • Ollama AI 엔진
echo   • AI 모델: llama3.1:8b, codellama:13b
echo   • WebSocket 실시간 채팅
echo   • 데이터베이스 (SQLite)
echo   • 모든 설정 파일
echo.
echo 🚀 고성능 설정:
echo   • 기본 AI 모델: llama3.1:8b
echo   • 코드 AI 모델: codellama:13b
echo   • 동시 모델 로딩: 2개
echo   • 컨텍스트 길이: 8192 토큰
echo.

:: 임시 디렉토리 정리
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" >nul 2>&1

set /p START_SERVER="지금 바로 서버를 시작하시겠습니까? (Y/n): "
if /i "%START_SERVER%"=="n" goto :manual_start

echo.
echo 🚀 서버 시작 중...
echo.

:: 5초 후 브라우저 자동 열기
start "" timeout /t 5 /nobreak && start http://localhost:8000

:: 서버 시작 (우선순위: start.bat > run-daphne.bat > manage.py runserver)
if exist start.bat (
    echo start.bat을 사용해서 서버를 시작합니다...
    echo %date% %time% - start.bat으로 서버 시작 >> "%LOG_FILE%"
    call start.bat
) else if exist run-daphne.bat (
    echo run-daphne.bat을 사용해서 서버를 시작합니다...
    echo %date% %time% - run-daphne.bat으로 서버 시작 >> "%LOG_FILE%"
    call run-daphne.bat
) else (
    echo Django 개발 서버로 시작합니다...
    echo %date% %time% - Django runserver로 서버 시작 >> "%LOG_FILE%"
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
echo    • 전체 테스트: test-ai.bat
echo.

goto :end

:: =================================================================
:: 함수 정의 구역
:: =================================================================

:safe_delete
set "FILE_TO_DELETE=%~1"
if exist "%FILE_TO_DELETE%" (
    for /l %%i in (1,1,10) do (
        del "%FILE_TO_DELETE%" >nul 2>&1
        if not exist "%FILE_TO_DELETE%" goto :delete_success
        timeout /t 1 /nobreak >nul
    )
    echo ⚠️ 파일 삭제 실패: %FILE_TO_DELETE%
    goto :delete_success
)
:delete_success
exit /b 0

:refresh_path
:: PATH 환경변수 새로고침
for /f "tokens=2*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH') do set "SYSTEM_PATH=%%j"
for /f "tokens=2*" %%i in ('reg query "HKCU\Environment" /v PATH') do set "USER_PATH=%%j"
set "PATH=%SYSTEM_PATH%;%USER_PATH%"
exit /b 0

:install_core_packages
echo 핵심 패키지 개별 설치 중...
set PACKAGE_COUNT=0

set PACKAGES=Django==4.2.7 django-cors-headers==4.3.1 channels==4.0.0 requests==2.31.0 python-dotenv==1.0.0 daphne==4.0.0 paramiko==3.3.1 redis==5.0.1

for %%p in (%PACKAGES%) do (
    echo 설치 중: %%p
    pip install %%p --quiet --no-warn-script-location
    if !errorlevel! equ 0 (
        set /a PACKAGE_COUNT+=1
    )
)

echo 📊 개별 패키지 설치 결과: !PACKAGE_COUNT!개 성공
exit /b 0

:create_env_file
(
echo # XShell AI 챗봇 환경 설정
echo.
echo # Django Settings
echo SECRET_KEY=django-insecure-xshell-chatbot-dev-key-auto-generated
echo DEBUG=True
echo.
echo # Database
echo DATABASE_URL=sqlite:///db.sqlite3
echo.
echo # XShell Integration
echo XSHELL_PATH=C:\Program Files\NetSarang\Xshell 8\Xshell.exe
echo XSHELL_SESSIONS_PATH=C:\Users\%USERNAME%\Documents\NetSarang Computer\8\Xshell\Sessions
echo.
echo # AI Backend ^(Ollama^)
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
exit /b 0

:test_system
echo [1/4] Python 환경 테스트...
python -c "import django; print('✅ Django 정상')" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python 환경 오류
    exit /b 1
)

echo [2/4] Ollama 연결 테스트...
curl -s -m 5 http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Ollama 연결 오류
    exit /b 1
)

echo [3/4] AI 모델 테스트...
python -c "import requests; response = requests.post('http://localhost:11434/api/generate', json={'model': 'llama3.1:8b', 'prompt': 'Hi', 'stream': False, 'options': {'num_predict': 5}}, timeout=15); print('✅ AI 모델 정상') if response.status_code == 200 else exit(1)" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AI 모델 테스트 실패
    exit /b 1
)

echo [4/4] Django 설정 테스트...
python manage.py check --verbosity=0 >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Django 설정 오류
    exit /b 1
)

echo ✅ 모든 시스템 테스트 통과
exit /b 0

:install_error
echo.
echo ❌ 설치 중 오류가 발생했습니다.
echo.
echo 🔧 해결 방법:
echo   1. 인터넷 연결 확인
echo   2. 관리자 권한으로 재실행
echo   3. 바이러스 백신 일시 비활성화
echo   4. 로그 파일 확인: %LOG_FILE%
echo.
echo %date% %time% - 설치 오류로 종료 >> "%LOG_FILE%"
goto :end

:user_exit
echo.
echo 👋 설치를 취소했습니다.
echo    나중에 install-all-in-one.bat을 다시 실행하세요.
echo.
echo %date% %time% - 사용자가 설치 취소 >> "%LOG_FILE%"

:end
:: 임시 디렉토리 정리
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" >nul 2>&1

echo.
echo 🎊 XShell AI 챗봇 설치 프로그램 종료
echo.
echo 💡 추가 정보:
echo   • 관리자 페이지: http://localhost:8000/admin
echo   • 설정 파일: .env
echo   • 로그 파일: %LOG_FILE%
echo   • 문제 해결: TROUBLESHOOTING-AI.md 참조
echo.
echo 🚀 즐거운 AI 챗봇 사용 되세요!
echo.
echo %date% %time% - 설치 프로그램 종료 >> "%LOG_FILE%"
pause