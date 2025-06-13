@echo off
:: 간단한 Ollama 설치 스크립트

chcp 65001 >nul
cls

echo.
echo 🤖 Ollama 간단 설치
echo ==================
echo.

:: 1. 기존 설치 확인
ollama --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Ollama가 이미 설치되어 있습니다!
    ollama --version
    goto :install_model
)

echo ❌ Ollama가 설치되지 않았습니다.
echo.

:: 2. 다운로드 페이지 열기
echo 📥 Ollama 다운로드 페이지를 엽니다...
echo    https://ollama.com/download
echo.
start https://ollama.com/download

echo 💡 설치 방법:
echo   1. 브라우저에서 "Download for Windows" 클릭
echo   2. 다운로드된 OllamaSetup.exe 실행  
echo   3. 설치 완료 후 아무 키나 누르세요
echo.
pause

:: 3. 설치 확인
echo 🔍 설치 확인 중...
ollama --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 설치가 확인되지 않습니다.
    echo    다시 설치하거나 시스템을 재시작해보세요.
    pause
    exit /b 1
)

echo ✅ Ollama 설치 완료!
ollama --version
echo.

:install_model
:: 4. 서비스 시작
echo 🔄 서비스 시작 중...
start /min "Ollama" ollama serve

echo ⏳ 서비스 시작 대기... (10초)
timeout /t 10 /nobreak >nul

:: 5. 모델 설치
echo 📥 AI 모델 설치
echo ================
echo.
echo 추천 모델:
echo   • llama3.2:3b  (경량, 2GB, 빠름)
echo   • llama3.1:8b  (고성능, 4.7GB, 느림)
echo.

set /p MODEL_CHOICE="어떤 모델을 설치하시겠습니까? (1=경량/2=고성능/Enter=건너뛰기): "

if "%MODEL_CHOICE%"=="1" (
    echo 📥 llama3.2:3b 설치 중...
    ollama pull llama3.2:3b
    echo ✅ 경량 모델 설치 완료!
) else if "%MODEL_CHOICE%"=="2" (
    echo 📥 llama3.1:8b 설치 중... (시간이 걸립니다)
    ollama pull llama3.1:8b
    echo ✅ 고성능 모델 설치 완료!
)

echo.
echo 🎉 설치 완료!
echo   • 서비스: http://localhost:11434
echo   • 모델 목록: ollama list
echo   • 챗봇 시작: run-daphne.bat
echo.
pause
