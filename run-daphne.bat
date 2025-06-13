@echo off
:: XShell AI 챗봇 Daphne 서버 실행 스크립트
:: WebSocket 안정성을 위해 Daphne ASGI 서버 사용

setlocal enabledelayedexpansion
chcp 65001 >nul
cls

echo.
echo 🚀 XShell AI 챗봇 Daphne 서버 시작
echo ==========================================
echo.
echo Daphne ASGI 서버로 실행합니다.
echo 일반 Django runserver보다 WebSocket 연결이 안정적입니다.
echo.

:: Python 확인
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python이 설치되지 않았거나 PATH에 없습니다.
    echo    Python 3.8 이상을 설치하고 PATH에 추가해주세요.
    pause
    exit /b 1
)

:: 가상환경 확인
if not exist .venv (
    echo ❌ 가상환경이 없습니다.
    echo    먼저 install-minimal.bat을 실행해주세요.
    pause
    exit /b 1
)

:: 가상환경 활성화
echo 🔄 가상환경 활성화 중...
call .venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ❌ 가상환경 활성화 실패
    echo    install-minimal.bat을 다시 실행해주세요.
    pause
    exit /b 1
)
echo ✅ 가상환경 활성화 완료

:: Daphne 설치 확인
echo 🔍 Daphne 확인 중...
python -c "import daphne" >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Daphne가 설치되지 않았습니다. 설치 중...
    pip install daphne --quiet
    if %errorlevel% neq 0 (
        echo ❌ Daphne 설치 실패
        echo    인터넷 연결을 확인하고 다시 시도해주세요.
        pause
        exit /b 1
    )
    echo ✅ Daphne 설치 완료
) else (
    echo ✅ Daphne 확인됨
)

:: Django 설정 확인
echo 🔍 Django 설정 확인 중...
python manage.py check >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Django 설정에 문제가 있을 수 있습니다.
    python manage.py check
)

:: 데이터베이스 마이그레이션 확인
echo 🗄️  데이터베이스 확인 중...
if not exist db.sqlite3 (
    echo ⚠️  데이터베이스가 없습니다. 마이그레이션을 실행합니다.
    python manage.py migrate
    if %errorlevel% neq 0 (
        echo ❌ 마이그레이션 실패
        pause
        exit /b 1
    )
    echo ✅ 데이터베이스 생성 완료
) else (
    echo ✅ 데이터베이스 확인됨
)

:: Ollama 상태 확인 (선택적)
echo 🤖 Ollama 상태 확인 중...
curl -s http://localhost:11434 >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Ollama 서비스 실행 중 - AI 기능 사용 가능
) else (
    echo ⚠️  Ollama 서비스가 실행되지 않음 - AI 기능 제한됨
    echo    Ollama를 시작하려면: ollama serve
)

:: 포트 8000 설정
set SERVER_PORT=8000
set SERVER_URL=http://localhost:8000

:: 포트 사용 확인
netstat -an | findstr "127.0.0.1:8000" >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  포트 8000이 이미 사용 중입니다.
    echo    다른 서버를 먼저 종료하거나 포트 8001을 사용합니다.
    set SERVER_PORT=8001
    set SERVER_URL=http://localhost:8001
)

:: 서버 시작 안내
echo.
echo 🎉 모든 준비가 완료되었습니다!
echo.
echo 📋 서버 정보:
echo   • 서버 주소: !SERVER_URL!
echo   • 서버 타입: Daphne ASGI 서버
echo   • WebSocket: ws://localhost:!SERVER_PORT!/ws/chat/
echo   • 관리자 페이지: !SERVER_URL!/admin
echo.
echo 💡 사용법:
echo   • 브라우저가 자동으로 열립니다
echo   • 서버 종료: Ctrl+C
echo   • 로그는 콘솔에서 실시간 확인 가능
echo.

:: 5초 후 브라우저 자동 열기
echo 🌐 5초 후 브라우저를 자동으로 엽니다...
timeout /t 3 /nobreak >nul 2>&1
start !SERVER_URL! >nul 2>&1

:: Daphne 서버 시작
echo 🚀 Daphne 서버 시작 중...
echo    종료하려면 Ctrl+C를 누르세요.
echo.

daphne -b 127.0.0.1 -p !SERVER_PORT! xshell_chatbot.asgi:application

:: 서버 종료 후 정리
echo.
echo 🛑 서버가 종료되었습니다.
echo.
echo 💡 다시 시작하려면:
echo   • run-daphne.bat 실행
echo   • 또는 수동으로: daphne -b 127.0.0.1 -p 8000 xshell_chatbot.asgi:application
echo.

pause
