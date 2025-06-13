@echo off
:: XShell AI 챗봇 최소 설치 스크립트 (Windows) - 안정성 개선 버전
:: CMD 꺼짐 방지 및 오류 처리 개선

setlocal enabledelayedexpansion
chcp 65001 >nul
cls

echo.
echo ⚡ XShell AI 챗봇 최소 설치 스크립트 (안정성 개선 버전)
echo =======================================================
echo.
echo 💡 안전 기능:
echo   • 오류 발생시 창이 자동으로 닫히지 않습니다
echo   • 각 단계마다 진행 상황을 표시합니다
echo   • 문제 발생시 해결 방법을 안내합니다
echo.
echo 설치할 내용:
echo   • Django 웹 프레임워크
echo   • WebSocket 지원 (Channels)
echo   • AI 백엔드 (Ollama, 선택사항)
echo   • 데이터베이스 설정
echo.
set /p CONTINUE="계속하시겠습니까? (Y/n): "
if /i "!CONTINUE!"=="n" goto :user_exit
if /i "!CONTINUE!"=="N" goto :user_exit

:: 1단계: Python 확인
echo.
echo 🔍 1단계: Python 확인
echo ====================
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python이 설치되지 않았습니다.
    echo.
    echo 📥 해결 방법:
    echo   1. https://python.org/downloads/ 에서 Python 3.8+ 다운로드
    echo   2. 설치시 "Add Python to PATH" 체크 필수
    echo   3. 설치 완료 후 시스템 재시작
    echo   4. 이 스크립트를 다시 실행
    echo.
    echo 🔗 Python 다운로드 페이지를 열겠습니다...
    start https://python.org/downloads/
    goto :install_error
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo ✅ Python !PYTHON_VERSION! 확인됨
echo.

:: 2단계: pip 업그레이드
echo 📈 2단계: pip 업그레이드
echo =======================
echo pip 업그레이드 중...
python -m pip install --upgrade pip --quiet
if %errorlevel% neq 0 (
    echo ⚠️ pip 업그레이드에 경고가 있지만 계속 진행합니다.
)
echo ✅ pip 업그레이드 완료
echo.

:: 3단계: 가상환경 생성
echo 📦 3단계: 가상환경 생성
echo ========================
if not exist .venv (
    echo 가상환경 생성 중...
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

:: 4단계: 가상환경 활성화
echo 🔄 4단계: 가상환경 활성화
echo =========================
echo 가상환경 활성화 중...
call .venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ❌ 가상환경 활성화 실패
    pause
    exit /b 1
)
echo ✅ 가상환경 활성화 완료
echo.

:: 5단계: 핵심 패키지 설치
echo 📚 5단계: 핵심 패키지 설치
echo ===========================
echo 필수 패키지들을 하나씩 설치합니다...
echo.

set INSTALL_COUNT=0
set FAILED_COUNT=0

echo [1/8] Django 웹 프레임워크 설치 중...
pip install Django==4.2.7 --quiet --no-warn-script-location
if %errorlevel% equ 0 (
    echo ✅ Django 설치 성공
    set /a INSTALL_COUNT+=1
) else (
    echo ❌ Django 설치 실패
    set /a FAILED_COUNT+=1
)

echo [2/8] CORS 헤더 지원 설치 중...
pip install django-cors-headers==4.3.1 --quiet --no-warn-script-location
if %errorlevel% equ 0 (
    echo ✅ CORS 헤더 설치 성공
    set /a INSTALL_COUNT+=1
) else (
    echo ❌ CORS 헤더 설치 실패
    set /a FAILED_COUNT+=1
)

echo [3/8] WebSocket 지원 설치 중...
pip install channels==4.0.0 --quiet --no-warn-script-location
if %errorlevel% equ 0 (
    echo ✅ WebSocket 지원 설치 성공
    set /a INSTALL_COUNT+=1
) else (
    echo ❌ WebSocket 지원 설치 실패
    set /a FAILED_COUNT+=1
)

echo [4/8] HTTP 클라이언트 설치 중...
pip install requests==2.31.0 --quiet --no-warn-script-location
if %errorlevel% equ 0 (
    echo ✅ HTTP 클라이언트 설치 성공
    set /a INSTALL_COUNT+=1
) else (
    echo ❌ HTTP 클라이언트 설치 실패
    set /a FAILED_COUNT+=1
)

echo [5/8] 환경 변수 지원 설치 중...
pip install python-dotenv==1.0.0 --quiet --no-warn-script-location
if %errorlevel% equ 0 (
    echo ✅ 환경 변수 지원 설치 성공
    set /a INSTALL_COUNT+=1
) else (
    echo ❌ 환경 변수 지원 설치 실패
    set /a FAILED_COUNT+=1
)

echo [6/8] ASGI 서버 설치 중...
pip install daphne==4.0.0 --quiet --no-warn-script-location
if %errorlevel% equ 0 (
    echo ✅ ASGI 서버 설치 성공
    set /a INSTALL_COUNT+=1
) else (
    echo ❌ ASGI 서버 설치 실패
    set /a FAILED_COUNT+=1
)

echo [7/8] Redis 클라이언트 설치 중...
pip install redis==5.0.1 --quiet --no-warn-script-location
if %errorlevel% equ 0 (
    echo ✅ Redis 클라이언트 설치 성공
    set /a INSTALL_COUNT+=1
) else (
    echo ❌ Redis 클라이언트 설치 실패
    set /a FAILED_COUNT+=1
)

echo [8/8] SSH 연결 지원 설치 중...
pip install paramiko==3.3.1 --quiet --no-warn-script-location
if %errorlevel% equ 0 (
    echo ✅ SSH 연결 지원 설치 성공
    set /a INSTALL_COUNT+=1
) else (
    echo ❌ SSH 연결 지원 설치 실패
    set /a FAILED_COUNT+=1
)

echo.
echo 📊 패키지 설치 결과: !INSTALL_COUNT!/8 성공, !FAILED_COUNT!/8 실패

if !FAILED_COUNT! gtr 0 (
    echo.
    echo ⚠️ 일부 패키지 설치에 실패했지만 계속 진행합니다.
    echo   기본 기능은 사용 가능하며, 필요시 나중에 수동 설치할 수 있습니다.
    echo.
    set /p CONTINUE_WITH_ERRORS="계속 진행하시겠습니까? (Y/n): "
    if /i "!CONTINUE_WITH_ERRORS!"=="n" goto :install_error
    if /i "!CONTINUE_WITH_ERRORS!"=="N" goto :install_error
)
echo.

:: 6단계: 환경 파일 설정
echo 📝 6단계: 환경 파일 설정
echo ========================
if not exist .env (
    if exist .env.example (
        copy .env.example .env >nul
        echo ✅ 환경 파일(.env) 생성 완료
    ) else (
        echo ⚠️ .env.example 파일이 없어서 환경 파일을 생성하지 못했습니다.
        echo   수동으로 설정이 필요할 수 있습니다.
    )
) else (
    echo ✅ 환경 파일이 이미 존재합니다
)
echo.

:: 7단계: 데이터베이스 설정
echo 🗄️ 7단계: 데이터베이스 설정
echo ===========================
echo Django 설정 확인 중...
python manage.py check --verbosity=0 >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ Django 설정에 경고가 있지만 계속 진행합니다.
    echo   개발 환경에서는 정상적인 경우가 많습니다.
)

echo 데이터베이스 마이그레이션 생성 중...
python manage.py makemigrations --verbosity=0 >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ 마이그레이션 생성 중 경고 발생 (대부분 정상)
)

echo 데이터베이스 설정 중...
python manage.py migrate --verbosity=0
if %errorlevel% neq 0 (
    echo ❌ 데이터베이스 설정 실패
    echo.
    echo 🔧 해결 방법:
    echo   1. 기존 데이터베이스 삭제: del db.sqlite3
    echo   2. 마이그레이션 재시도: python manage.py migrate
    echo   3. Django 설정 확인: python manage.py check
    echo.
    echo 하지만 기본 기능은 사용 가능할 수 있습니다.
    set /p CONTINUE_DB_ERROR="데이터베이스 오류를 무시하고 계속하시겠습니까? (Y/n): "
    if /i "!CONTINUE_DB_ERROR!"=="n" goto :install_error
    if /i "!CONTINUE_DB_ERROR!"=="N" goto :install_error
) else (
    echo ✅ 데이터베이스 설정 완료
)
echo.

:: 8단계: 로그 디렉토리 생성
echo 📂 8단계: 로그 디렉토리 생성
echo =============================
if not exist logs (
    mkdir logs
    echo ✅ 로그 디렉토리 생성 완료
) else (
    echo ✅ 로그 디렉토리가 이미 존재합니다
)
echo.

:: 9단계: Ollama 설정 (선택사항)
echo 🤖 9단계: Ollama AI 설정 (선택사항)
echo ==================================
echo AI 기능을 사용하려면 Ollama가 필요합니다.
echo Ollama 없이도 기본 XShell 기능은 사용할 수 있습니다.
echo.

set /p INSTALL_OLLAMA="Ollama를 설치하시겠습니까? (Y/n): "
if /i "!INSTALL_OLLAMA!"=="n" goto :skip_ollama
if /i "!INSTALL_OLLAMA!"=="N" goto :skip_ollama

echo Ollama 설치 확인 중...
ollama --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Ollama가 설치되지 않았습니다.
    echo.
    echo 📥 Ollama 설치 방법:
    echo   1. 자동 설치: install-ollama-simple.bat 실행
    echo   2. 수동 설치: https://ollama.com/download 방문
    echo.
    set /p AUTO_INSTALL_OLLAMA="자동 설치를 시도하시겠습니까? (Y/n): "
    if /i "!AUTO_INSTALL_OLLAMA!"=="n" goto :manual_ollama
    if /i "!AUTO_INSTALL_OLLAMA!"=="N" goto :manual_ollama
    
    echo 자동 설치 스크립트를 실행합니다...
    if exist install-ollama-simple.bat (
        call install-ollama-simple.bat
    ) else (
        echo ❌ 자동 설치 스크립트를 찾을 수 없습니다.
        goto :manual_ollama
    )
) else (
    echo ✅ Ollama가 이미 설치되어 있습니다
    ollama --version
    echo.
    
    echo AI 모델 확인 중...
    ollama list | findstr "llama" >nul 2>&1
    if %errorlevel% neq 0 (
        echo ⚠️ AI 모델이 설치되지 않았습니다.
        set /p INSTALL_MODEL="기본 모델(llama3.1:8b)을 설치하시겠습니까? (Y/n): "
        if /i "!INSTALL_MODEL!" neq "n" if /i "!INSTALL_MODEL!" neq "N" (
            echo 📥 AI 모델 다운로드 중... (약 4.7GB, 시간이 걸릴 수 있습니다)
            ollama pull llama3.1:8b
            if %errorlevel% equ 0 (
                echo ✅ AI 모델 설치 완료!
            ) else (
                echo ❌ AI 모델 설치 실패 (나중에 수동으로 설치 가능)
            )
        )
    ) else (
        echo ✅ AI 모델이 이미 설치되어 있습니다
    )
)

goto :ollama_complete

:manual_ollama
echo.
echo 🔗 Ollama 다운로드 페이지를 열겠습니다...
start https://ollama.com/download
echo.
echo 💡 설치 후 다음 명령어로 모델을 다운로드하세요:
echo   ollama pull llama3.1:8b
echo.

:skip_ollama
echo ✅ Ollama 설정을 건너뜁니다.
echo   나중에 install-ollama-simple.bat으로 설치할 수 있습니다.

:ollama_complete
echo.

:: 설치 완료
echo 🎉 설치 완료!
echo ==============
echo.
echo ✅ 설치된 구성 요소:
echo   • Django 웹 프레임워크
echo   • WebSocket 지원 (실시간 채팅)
echo   • 데이터베이스 (SQLite)
echo   • ASGI 서버 (Daphne)
echo   • XShell 통합 기능
if !INSTALL_OLLAMA! neq n if !INSTALL_OLLAMA! neq N (
    echo   • AI 기능 (Ollama)
)
echo.
echo 🚀 다음 단계:
echo   1. 서버 시작: run-daphne.bat (권장)
echo   2. 또는 간단 시작: start-server.bat
echo   3. 브라우저에서 http://localhost:8000 접속
echo.
echo 💡 추가 명령어:
echo   • Ollama 설치: install-ollama-simple.bat
echo   • 서버 상태 확인: python manage.py check
echo.

set /p START_NOW="지금 바로 서버를 시작하시겠습니까? (Y/n): "
if /i "!START_NOW!" neq "n" if /i "!START_NOW!" neq "N" (
    echo.
    echo 🚀 서버를 시작합니다...
    echo.
    if exist run-daphne.bat (
        call run-daphne.bat
    ) else (
        echo Daphne 실행 파일이 없어서 기본 서버로 시작합니다...
        python manage.py runserver
    )
)

goto :end

:install_error
echo.
echo ❌ 설치 중 오류가 발생했습니다.
echo.
echo 🔧 해결 방법:
echo   1. 인터넷 연결 확인
echo   2. 관리자 권한으로 실행
echo   3. 바이러스 백신 소프트웨어 일시 비활성화
echo   4. Python 재설치 (PATH 설정 포함)
echo   5. 폴더 권한 확인
echo.
echo 💡 추가 도움:
echo   • 오류 메시지를 복사해서 GitHub Issues에 문의
echo   • FIX-WINDOWS-INSTALL.md 문서 참조
echo.
goto :end

:user_exit
echo.
echo 👋 설치를 취소했습니다.
echo    나중에 다시 실행하시려면 install-minimal.bat을 실행하세요.
echo.

:end
echo.
echo 아무 키나 누르면 종료됩니다...
pause >nul
exit /b 0
