@echo off
:: XShell AI 챗봇 서버 간단 실행 스크립트

chcp 65001 >nul
cls

echo.
echo 🚀 XShell AI 챗봇 서버 시작
echo ============================
echo.

:: 가상환경 활성화
if exist .venv\Scripts\activate.bat (
    call .venv\Scripts\activate.bat
    echo ✅ 가상환경 활성화 완료
) else (
    echo ❌ 가상환경이 없습니다. install-minimal.bat을 먼저 실행해주세요.
    pause
    exit /b 1
)

:: 브라우저 열기
echo 🌐 브라우저를 엽니다...
start http://localhost:8000

:: Daphne 서버 실행
echo 🚀 서버 시작 중... (종료: Ctrl+C)
echo.
daphne -b 127.0.0.1 -p 8000 xshell_chatbot.asgi:application

pause
