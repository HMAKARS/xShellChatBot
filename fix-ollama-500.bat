@echo off
:: Ollama 500 오류 진단 및 해결 스크립트

setlocal enabledelayedexpansion
chcp 65001 >nul
cls

echo.
echo 🔧 Ollama 500 오류 진단 및 해결
echo ===============================
echo.
echo 500 Internal Server Error는 Ollama 서비스 내부 문제입니다.
echo 단계별로 진단하고 해결해보겠습니다.
echo.
pause

:: 1단계: 현재 상태 확인
echo 📋 1단계: 현재 상태 확인
echo =========================

echo Ollama 버전 확인...
ollama --version
echo.

echo 프로세스 확인...
tasklist | findstr ollama
echo.

echo 포트 확인...
netstat -an | findstr 11434
echo.

:: 2단계: Ollama 서비스 완전 재시작
echo 🔄 2단계: Ollama 서비스 완전 재시작
echo ================================

echo 기존 Ollama 프로세스 종료 중...
taskkill /f /im ollama.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 기존 프로세스 종료됨
) else (
    echo ℹ️  실행 중인 프로세스 없음
)

echo 잠시 대기... (3초)
timeout /t 3 /nobreak >nul

echo 새로운 Ollama 서비스 시작...
start /min "Ollama Service" ollama serve

echo 서비스 시작 대기... (10초)
timeout /t 10 /nobreak >nul

:: 3단계: 기본 연결 테스트
echo 🌐 3단계: 기본 연결 테스트
echo ===========================

echo 기본 엔드포인트 테스트...
curl -s -m 5 http://localhost:11434/
if %errorlevel% equ 0 (
    echo ✅ 기본 연결 성공
) else (
    echo ❌ 기본 연결 실패
    goto :restart_solution
)

echo.
echo /api/tags 테스트...
curl -s -m 5 http://localhost:11434/api/tags
if %errorlevel% equ 0 (
    echo ✅ /api/tags 성공
) else (
    echo ❌ /api/tags 실패
    goto :restart_solution
)

echo.

:: 4단계: 모델 상태 확인
echo 📚 4단계: 모델 상태 확인
echo ========================

echo 설치된 모델 확인...
ollama list
if %errorlevel% neq 0 (
    echo ❌ 모델 목록 조회 실패
    goto :model_problem
)

:: 사용 가능한 모델 찾기
for /f "skip=1 tokens=1" %%a in ('ollama list 2^>nul') do (
    set AVAILABLE_MODEL=%%a
    goto :model_found
)

echo ❌ 사용 가능한 모델이 없습니다.
goto :model_problem

:model_found
echo ✅ 사용 가능한 모델: !AVAILABLE_MODEL!

:: 5단계: 모델별 테스트
echo 🧪 5단계: 모델별 테스트
echo =======================

echo 모델 로드 테스트 중...
echo "test" | ollama run !AVAILABLE_MODEL! >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 모델 로드 성공
) else (
    echo ❌ 모델 로드 실패
    goto :model_problem
)

echo.
echo 간단한 API 테스트...
curl -s -m 15 -X POST http://localhost:11434/api/generate ^
  -H "Content-Type: application/json" ^
  -d "{\"model\": \"!AVAILABLE_MODEL!\", \"prompt\": \"Hello\", \"stream\": false, \"options\": {\"num_predict\": 5}}"

if %errorlevel% equ 0 (
    echo.
    echo ✅ API 테스트 성공!
    goto :success
) else (
    echo.
    echo ❌ API 테스트 실패
    goto :api_problem
)

:: 문제 해결 섹션들

:restart_solution
echo.
echo 🔧 해결 방법 1: 완전 재시작
echo ==========================
echo.
echo 1. Ollama 완전 종료:
echo    taskkill /f /im ollama.exe
echo.
echo 2. 시스템 재시작 (권장):
echo    모든 프로세스와 메모리를 정리합니다
echo.
echo 3. 수동 재시작:
echo    ollama serve
echo.
set /p RESTART_SYSTEM="시스템을 재시작하시겠습니까? (y/N): "
if /i "!RESTART_SYSTEM!"=="y" (
    echo 시스템을 재시작합니다...
    shutdown /r /t 10 /c "Ollama 문제 해결을 위한 재시작"
    echo 10초 후 재시작됩니다. 취소하려면 shutdown /a
    pause
    exit /b 0
)
goto :manual_solutions

:model_problem
echo.
echo 🔧 해결 방법 2: 모델 문제
echo =========================
echo.
echo 모델이 없거나 손상된 것 같습니다.
echo.
set /p FIX_MODEL="모델을 다시 설치하시겠습니까? (Y/n): "
if /i "!FIX_MODEL!" neq "n" if /i "!FIX_MODEL!" neq "N" (
    echo.
    echo 🗑️  기존 모델 제거 중...
    for /f "skip=1 tokens=1" %%a in ('ollama list 2^>nul') do (
        echo    %%a 제거 중...
        ollama rm %%a >nul 2>&1
    )
    
    echo.
    echo 📥 새 모델 설치 중...
    echo    경량 모델 (llama3.2:3b) 설치 중... (약 2GB)
    ollama pull llama3.2:3b
    
    if %errorlevel% equ 0 (
        echo ✅ 모델 설치 완료!
        echo.
        echo 🧪 새 모델 테스트...
        echo "Hello" | ollama run llama3.2:3b
        if %errorlevel% equ 0 (
            echo ✅ 새 모델 작동 확인!
            goto :success
        )
    ) else (
        echo ❌ 모델 설치 실패
    )
)
goto :manual_solutions

:api_problem
echo.
echo 🔧 해결 방법 3: API 문제
echo =======================
echo.
echo API는 연결되지만 요청 처리에 실패합니다.
echo 가능한 원인: 메모리 부족, 모델 손상, 설정 문제
echo.

echo 💾 시스템 메모리 확인...
for /f "skip=1 tokens=4" %%a in ('wmic OS get TotalVisibleMemorySize /format:table') do (
    if "%%a" neq "" set TOTAL_MEM=%%a
)
set /a TOTAL_GB=!TOTAL_MEM!/1024/1024
echo 총 메모리: !TOTAL_GB!GB

if !TOTAL_GB! lss 8 (
    echo ⚠️ 메모리가 부족할 수 있습니다. (8GB 이상 권장)
    echo.
    echo 해결 방법:
    echo 1. 다른 프로그램 종료
    echo 2. 더 작은 모델 사용 (llama3.2:1b)
    echo 3. 메모리 증설
)

echo.
set /p TRY_SMALL_MODEL="더 작은 모델(1B)을 시도해보시겠습니까? (Y/n): "
if /i "!TRY_SMALL_MODEL!" neq "n" if /i "!TRY_SMALL_MODEL!" neq "N" (
    echo 📥 초경량 모델 설치 중...
    ollama pull llama3.2:1b
    
    if %errorlevel% equ 0 (
        echo ✅ 초경량 모델 설치 완료!
        echo.
        echo 🧪 테스트 중...
        echo "Hi" | ollama run llama3.2:1b
        if %errorlevel% equ 0 (
            echo ✅ 초경량 모델 작동 확인!
            goto :success
        )
    )
)

goto :manual_solutions

:success
echo.
echo 🎉 문제 해결 완료!
echo ==================
echo.
echo ✅ Ollama가 정상적으로 작동합니다.
echo.
echo 다음 단계:
echo 1. XShell 챗봇 서버 시작: run-daphne.bat
echo 2. 브라우저에서 http://localhost:8000 접속
echo 3. AI 기능 테스트
echo.
echo 💡 팁: 향후 문제 방지를 위해
echo   • 충분한 메모리 확보 (8GB+ 권장)
echo   • 정기적인 시스템 재시작
echo   • 작은 모델부터 시작
echo.
goto :end

:manual_solutions
echo.
echo 🛠️  수동 해결 방법
echo ==================
echo.
echo 자동 해결이 실패했습니다. 다음 방법을 시도해주세요:
echo.
echo 1. 💻 시스템 재시작 (가장 효과적)
echo    - Windows 재시작 후 다시 시도
echo.
echo 2. 🗑️  Ollama 완전 제거 후 재설치
echo    - 제어판에서 Ollama 제거
echo    - %%USERPROFILE%%\.ollama 폴더 삭제
echo    - install-ollama-simple.bat으로 재설치
echo.
echo 3. 🔧 환경 변수 설정
echo    - OLLAMA_HOST=127.0.0.1:11434
echo    - OLLAMA_MAX_LOADED_MODELS=1
echo.
echo 4. 🩺 상세 진단
echo    - test-ollama.bat 실행
echo    - 로그 파일 확인: %%TEMP%%\ollama.log
echo.
echo 5. 💬 커뮤니티 도움
echo    - GitHub Issues에 문의
echo    - 오류 메시지와 시스템 정보 포함
echo.

:end
echo 📞 추가 도움이 필요하면:
echo   • test-ollama.bat - 상세 진단
echo   • install-ollama-simple.bat - 재설치
echo   • GitHub Issues - 문제 신고
echo.
pause
