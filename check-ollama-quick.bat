@echo off
:: 빠른 Ollama 상태 확인

chcp 65001 >nul
cls

echo.
echo ⚡ Ollama 빠른 상태 확인
echo =======================
echo.

:: 1. 서비스 실행 확인
echo 🔍 서비스 실행 상태...
curl -s -m 3 http://localhost:11434/ >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Ollama 서비스 실행 중
) else (
    echo ❌ Ollama 서비스 중지됨
    echo.
    echo 🚀 해결 방법:
    echo   1. ollama serve
    echo   2. 또는 fix-ollama-500.bat 실행
    echo.
    goto :end
)

:: 2. 모델 확인
echo 📚 모델 상태...
ollama list >nul 2>&1
if %errorlevel% equ 0 (
    for /f "skip=1" %%a in ('ollama list 2^>nul') do (
        echo ✅ 모델 사용 가능: %%a
        set MODEL_FOUND=1
        goto :model_check_done
    )
    echo ❌ 설치된 모델 없음
    echo.
    echo 📥 모델 설치:
    echo   ollama pull llama3.2:3b
    echo.
    goto :end
) else (
    echo ❌ 모델 상태 확인 실패
    goto :end
)

:model_check_done

:: 3. 간단 API 테스트
echo 🧪 API 테스트 중...
curl -s -m 10 -X POST http://localhost:11434/api/generate ^
  -H "Content-Type: application/json" ^
  -d "{\"model\": \"llama3.2:3b\", \"prompt\": \"Hi\", \"stream\": false, \"options\": {\"num_predict\": 3}}" >nul 2>&1

if %errorlevel% equ 0 (
    echo ✅ API 정상 작동
    echo.
    echo 🎉 모든 기능이 정상입니다!
    echo    XShell 챗봇의 AI 기능을 사용할 수 있습니다.
    echo.
    echo 📱 다음 단계:
    echo   • run-daphne.bat 실행
    echo   • 브라우저에서 http://localhost:8000 접속
) else (
    echo ❌ API 오류 (500 Internal Server Error)
    echo.
    echo 🔧 해결 방법:
    echo   1. fix-ollama-500.bat 실행 (자동 수정)
    echo   2. 시스템 재시작
    echo   3. 작은 모델 설치: ollama pull llama3.2:1b
)

:end
echo.
pause
