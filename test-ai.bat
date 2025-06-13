@echo off
:: AI 연결 테스트 실행 스크립트

setlocal enabledelayedexpansion
chcp 65001 >nul
cls

echo.
echo 🧪 XShell 챗봇 AI 연결 테스트
echo ============================
echo.
echo 이 스크립트는 Ollama와 AI 기능 연결 상태를 확인합니다.
echo.

:: 가상환경 확인
if not exist .venv (
    echo ❌ 가상환경이 없습니다.
    echo    install-minimal.bat을 먼저 실행해주세요.
    pause
    exit /b 1
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
echo.

:: Python 테스트 실행
echo 🚀 AI 연결 테스트 시작...
echo.
python test-ai-connection.py

:: 결과에 따른 추가 안내
echo.
echo 💡 추가 테스트 옵션:
echo   • 상세 Ollama 테스트: test-ollama.bat
echo   • 서버 시작: run-daphne.bat
echo   • Ollama 설치: install-ollama-simple.bat
echo.

pause
