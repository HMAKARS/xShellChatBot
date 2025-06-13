@echo off
:: Ollama 상태 확인 및 테스트 스크립트

setlocal enabledelayedexpansion
chcp 65001 >nul
cls

echo.
echo 🔍 Ollama 상태 확인 및 테스트
echo ===============================
echo.

:: 1. Ollama 설치 확인
echo 📋 1. Ollama 설치 확인
echo =====================
ollama --version
if %errorlevel% neq 0 (
    echo ❌ Ollama가 설치되지 않았습니다.
    echo    install-ollama-simple.bat을 실행해주세요.
    goto :end
)
echo ✅ Ollama 설치 확인됨
echo.

:: 2. 서비스 상태 확인
echo 🔄 2. 서비스 상태 확인  
echo ======================
curl -s -m 5 http://localhost:11434 >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Ollama 서비스가 실행되지 않고 있습니다.
    echo.
    set /p START_SERVICE="서비스를 시작하시겠습니까? (Y/n): "
    if /i "!START_SERVICE!" neq "n" if /i "!START_SERVICE!" neq "N" (
        echo 서비스 시작 중...
        start /min "Ollama Service" ollama serve
        
        echo 서비스 시작 대기 중... (최대 15초)
        for /L %%i in (1,1,15) do (
            timeout /t 1 /nobreak >nul 2>&1
            curl -s -m 2 http://localhost:11434 >nul 2>&1
            if !errorlevel! equ 0 (
                echo ✅ 서비스 시작 완료! (%%i초)
                goto :service_ready
            )
        )
        echo ❌ 서비스 시작 실패
        goto :end
    ) else (
        echo 서비스를 수동으로 시작해주세요: ollama serve
        goto :end
    )
) else (
    echo ✅ Ollama 서비스 실행 중
)

:service_ready

:: 3. API 엔드포인트 테스트
echo.
echo 🌐 3. API 엔드포인트 테스트
echo ==========================

echo 기본 엔드포인트 (/) 테스트...
curl -s -m 5 http://localhost:11434/ 
echo.

echo /api/tags 엔드포인트 테스트...
curl -s -m 5 http://localhost:11434/api/tags | python -m json.tool 2>nul
if %errorlevel% neq 0 (
    echo ❌ /api/tags 엔드포인트 오류
    curl -s -m 5 http://localhost:11434/api/tags
) else (
    echo ✅ /api/tags 엔드포인트 정상
)
echo.

:: 4. 설치된 모델 확인
echo 📚 4. 설치된 모델 확인
echo ===================
ollama list
if %errorlevel% neq 0 (
    echo ❌ 모델 목록 조회 실패
    echo.
) else (
    echo ✅ 모델 목록 조회 성공
    echo.
)

:: 사용 가능한 모델 확인
echo 사용 가능한 모델 확인 중...
ollama list | findstr "llama" >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ llama 모델이 설치되지 않았습니다.
    echo.
    set /p INSTALL_MODEL="기본 모델을 설치하시겠습니까? (1=경량 3B / 2=고성능 8B / n=건너뛰기): "
    if "!INSTALL_MODEL!"=="1" (
        echo 📥 llama3.2:3b 모델 설치 중... (약 2GB)
        ollama pull llama3.2:3b
    ) else if "!INSTALL_MODEL!"=="2" (
        echo 📥 llama3.1:8b 모델 설치 중... (약 4.7GB)
        ollama pull llama3.1:8b
    )
) else (
    echo ✅ llama 모델이 설치되어 있습니다.
)

:: 5. API 호출 테스트
echo.
echo 🧪 5. API 호출 테스트
echo ==================

:: 사용할 모델 선택
for /f "tokens=1" %%a in ('ollama list ^| findstr "llama" ^| head -1') do set TEST_MODEL=%%a
if "!TEST_MODEL!"=="" (
    echo ❌ 테스트할 모델이 없습니다.
    echo    모델을 먼저 설치해주세요: ollama pull llama3.2:3b
    goto :end
)

echo 테스트 모델: !TEST_MODEL!
echo.

:: /api/generate 테스트
echo /api/generate 엔드포인트 테스트...
curl -s -m 10 -X POST http://localhost:11434/api/generate ^
  -H "Content-Type: application/json" ^
  -d "{\"model\": \"!TEST_MODEL!\", \"prompt\": \"Hello, what is 2+2?\", \"stream\": false}" ^
  | python -m json.tool 2>nul

if %errorlevel% equ 0 (
    echo ✅ /api/generate 엔드포인트 정상
) else (
    echo ❌ /api/generate 엔드포인트 오류
    echo 직접 응답:
    curl -s -m 10 -X POST http://localhost:11434/api/generate ^
      -H "Content-Type: application/json" ^
      -d "{\"model\": \"!TEST_MODEL!\", \"prompt\": \"Hello, what is 2+2?\", \"stream\": false}"
)
echo.

:: /api/chat 테스트 (있는 경우)
echo /api/chat 엔드포인트 테스트...
curl -s -m 10 -X POST http://localhost:11434/api/chat ^
  -H "Content-Type: application/json" ^
  -d "{\"model\": \"!TEST_MODEL!\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello, what is 2+2?\"}], \"stream\": false}" ^
  | python -m json.tool 2>nul

if %errorlevel% equ 0 (
    echo ✅ /api/chat 엔드포인트 정상
) else (
    echo ⚠️ /api/chat 엔드포인트 사용 불가 (이전 버전일 수 있음)
    echo   /api/generate 엔드포인트를 사용합니다.
)
echo.

:: 6. 챗봇 연동 테스트
echo 🤖 6. 챗봇 연동 테스트
echo ====================

if exist .venv\Scripts\activate.bat (
    echo 가상환경 활성화 중...
    call .venv\Scripts\activate.bat
    
    echo Python AI 서비스 테스트 중...
    python -c "
import sys
sys.path.append('.')
try:
    from ai_backend.services import AIService
    ai = AIService()
    if ai.ollama_available:
        print('✅ AI 서비스 연결 성공')
        print('사용 가능한 모델:', ai.get_available_models())
    else:
        print('❌ AI 서비스 연결 실패')
except Exception as e:
    print('❌ AI 서비스 테스트 실패:', str(e))
"
) else (
    echo ⚠️ 가상환경이 없습니다. install-minimal.bat을 먼저 실행해주세요.
)

echo.
echo 📋 테스트 완료!
echo ==============
echo.

:: 결과 요약
echo 🔧 문제 해결 방법:
echo.
echo 1. 서비스 시작 안됨:
echo    - 수동 시작: ollama serve
echo    - 백그라운드 시작: start /min ollama serve
echo.
echo 2. 모델 없음:
echo    - 경량 모델: ollama pull llama3.2:3b
echo    - 고성능 모델: ollama pull llama3.1:8b
echo.
echo 3. API 오류:
echo    - 포트 확인: netstat -an | findstr 11434
echo    - 로그 확인: ollama logs
echo    - 재시작: taskkill /f /im ollama.exe ^& ollama serve
echo.
echo 4. 챗봇 연동 오류:
echo    - 서버 재시작: run-daphne.bat
echo    - 브라우저 새로고침: Ctrl+F5
echo.

:end
echo 아무 키나 누르면 종료됩니다...
pause >nul
