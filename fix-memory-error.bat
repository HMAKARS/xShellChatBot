@echo off
:: 메모리 부족 오류 해결 스크립트

setlocal enabledelayedexpansion
chcp 65001 >nul
cls

echo.
echo 🔧 Ollama 메모리 부족 오류 해결
echo ===============================
echo.
echo 로그 분석 결과: 모델이 너무 커서 메모리가 부족합니다.
echo 시스템 메모리: 6GB, 모델 요구량: 6.1GB
echo.
echo 해결 방법: 더 작은 모델로 교체합니다.
echo.
pause

:: 1단계: 기존 큰 모델 확인
echo 📋 1단계: 현재 설치된 모델 확인
echo ================================
ollama list
echo.

:: 2단계: 큰 모델 제거
echo 🗑️  2단계: 큰 모델 제거
echo ========================
echo 메모리를 절약하기 위해 큰 모델을 제거합니다.
echo.

:: llama3.1:8b 제거 (6.1GB)
ollama list | findstr "llama3.1:8b" >nul 2>&1
if %errorlevel% equ 0 (
    echo llama3.1:8b 모델 제거 중... (6.1GB 절약)
    ollama rm llama3.1:8b
    if %errorlevel% equ 0 (
        echo ✅ llama3.1:8b 모델 제거 완료
    ) else (
        echo ⚠️ 모델 제거 중 오류 발생
    )
) else (
    echo ℹ️  llama3.1:8b 모델이 설치되지 않음
)

:: llama3.1:70b 제거 (있다면)
ollama list | findstr "llama3.1:70b" >nul 2>&1
if %errorlevel% equ 0 (
    echo llama3.1:70b 모델 제거 중... (대용량 모델)
    ollama rm llama3.1:70b
)

:: 기타 큰 모델들 확인
echo.
echo 현재 남은 모델:
ollama list
echo.

:: 3단계: 경량 모델 설치
echo 📥 3단계: 경량 모델 설치
echo =========================
echo 6GB RAM에 적합한 경량 모델을 설치합니다.
echo.

set /p MODEL_CHOICE="어떤 모델을 설치하시겠습니까? (1=초경량 1B/2=경량 3B/Enter=건너뛰기): "

if "%MODEL_CHOICE%"=="1" (
    echo 📥 llama3.2:1b 설치 중... (약 1GB, 매우 빠름)
    ollama pull llama3.2:1b
    if %errorlevel% equ 0 (
        echo ✅ 초경량 모델 설치 완료!
        set INSTALLED_MODEL=llama3.2:1b
    ) else (
        echo ❌ 모델 설치 실패
    )
) else if "%MODEL_CHOICE%"=="2" (
    echo 📥 llama3.2:3b 설치 중... (약 2GB, 균형잡힌 성능)
    ollama pull llama3.2:3b
    if %errorlevel% equ 0 (
        echo ✅ 경량 모델 설치 완료!
        set INSTALLED_MODEL=llama3.2:3b
    ) else (
        echo ❌ 모델 설치 실패
    )
) else (
    echo ℹ️  모델 설치를 건너뜁니다.
)

:: 4단계: 메모리 정리
echo 🧹 4단계: 메모리 정리
echo ====================
echo 시스템 메모리를 정리합니다...

:: Ollama 재시작
echo Ollama 서비스 재시작 중...
taskkill /f /im ollama.exe >nul 2>&1
timeout /t 3 /nobreak >nul
start /min "Ollama Service" ollama serve

echo 서비스 시작 대기 중... (10초)
timeout /t 10 /nobreak >nul

:: 5단계: 테스트
echo 🧪 5단계: 모델 테스트
echo ===================

if defined INSTALLED_MODEL (
    echo 새 모델 테스트 중: !INSTALLED_MODEL!
    echo.
    
    :: 간단한 테스트
    echo "Hi, test" | ollama run !INSTALLED_MODEL!
    if %errorlevel% equ 0 (
        echo.
        echo ✅ 모델 테스트 성공!
        echo.
        echo 🎉 메모리 문제 해결 완료!
        echo ============================
        echo.
        echo ✅ 설치된 모델: !INSTALLED_MODEL!
        echo ✅ 메모리 사용량: 크게 감소
        echo ✅ 500 오류: 해결됨
        echo.
        echo 💡 성능 비교:
        echo   • llama3.1:8b: 높은 품질, 6.1GB 메모리 (너무 큼)
        echo   • llama3.2:3b: 좋은 품질, 2GB 메모리 (적당)  
        echo   • llama3.2:1b: 기본 품질, 1GB 메모리 (빠름)
        echo.
        echo 📱 다음 단계:
        echo   1. run-daphne.bat 실행
        echo   2. 브라우저에서 http://localhost:8000 접속
        echo   3. AI 채팅 테스트
        echo.
        goto :success
    ) else (
        echo ❌ 모델 테스트 실패
    )
) else (
    echo ⚠️ 설치된 모델이 없습니다.
    echo   수동으로 설치하세요: ollama pull llama3.2:1b
)

echo.
echo 💡 추가 해결 방법:
echo ==================
echo.
echo 1. 💾 메모리 업그레이드 (8GB+ 권장)
echo.
echo 2. 🔧 Windows 메모리 정리:
echo    • 다른 프로그램 종료
echo    • 브라우저 탭 줄이기
echo    • 시스템 재시작
echo.
echo 3. ⚙️ Ollama 설정 최적화:
echo    • 환경변수: OLLAMA_MAX_LOADED_MODELS=1
echo    • 더 작은 컨텍스트 크기 사용
echo.
echo 4. 📊 메모리 모니터링:
echo    • 작업 관리자에서 메모리 사용량 확인
echo    • 메모리 사용량이 80% 이상이면 재시작
echo.

goto :end

:success
set /p START_SERVER="지금 바로 XShell 챗봇 서버를 시작하시겠습니까? (Y/n): "
if /i "!START_SERVER!" neq "n" if /i "!START_SERVER!" neq "N" (
    echo.
    echo 🚀 서버 시작 중...
    if exist run-daphne.bat (
        call run-daphne.bat
    ) else (
        echo run-daphne.bat을 찾을 수 없습니다.
        echo 수동으로 시작하세요: python manage.py runserver
    )
)

:end
echo.
echo 📞 추가 도움이 필요하면:
echo   • check-ollama-quick.bat - 빠른 상태 확인
echo   • test-ai.bat - AI 기능 테스트  
echo   • GitHub Issues - 기술 지원
echo.
pause
