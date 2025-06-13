@echo off
:: All-in-One 설치 후 시스템 검증 스크립트

setlocal enabledelayedexpansion
chcp 65001 >nul
cls

echo.
echo 🧪 XShell AI 챗봇 All-in-One 설치 검증
echo ====================================
echo.
echo 이 스크립트는 all-in-one 설치가 올바르게 완료되었는지 확인합니다.
echo.

set TEST_COUNT=0
set PASSED_COUNT=0

:: 1. Python 환경 확인
echo [1/8] Python 환경 확인...
python --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
    echo ✅ Python !PYTHON_VERSION! 확인됨
    set /a PASSED_COUNT+=1
) else (
    echo ❌ Python 설치 확인 실패
)
set /a TEST_COUNT+=1

:: 2. 가상환경 확인
echo [2/8] 가상환경 확인...
if exist .venv\Scripts\activate.bat (
    echo ✅ 가상환경 존재 확인
    set /a PASSED_COUNT+=1
) else (
    echo ❌ 가상환경 없음
)
set /a TEST_COUNT+=1

:: 3. Ollama 설치 확인
echo [3/8] Ollama 설치 확인...
ollama --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Ollama 설치 확인됨
    set /a PASSED_COUNT+=1
) else (
    echo ❌ Ollama 설치 확인 실패
)
set /a TEST_COUNT+=1

:: 4. Ollama 서비스 확인
echo [4/8] Ollama 서비스 확인...
curl -s -m 5 http://localhost:11434/ >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Ollama 서비스 정상 작동
    set /a PASSED_COUNT+=1
) else (
    echo ❌ Ollama 서비스 중지됨
    echo    해결: ollama serve
)
set /a TEST_COUNT+=1

:: 5. AI 모델 확인
echo [5/8] AI 모델 확인...
ollama list | findstr "llama3.1:8b" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 기본 AI 모델 (llama3.1:8b) 설치됨
    set /a PASSED_COUNT+=1
) else (
    echo ❌ 기본 AI 모델 없음
    echo    해결: ollama pull llama3.1:8b
)
set /a TEST_COUNT+=1

ollama list | findstr "codellama:13b" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 코드 AI 모델 (codellama:13b) 설치됨
) else (
    echo ⚠️ 코드 AI 모델 없음 (선택사항)
)

:: 6. Python 패키지 확인
echo [6/8] Python 패키지 확인...
call .venv\Scripts\activate.bat >nul 2>&1
python -c "import django, channels, requests; print('✅ 핵심 패키지 설치 확인됨')" 2>nul
if %errorlevel% equ 0 (
    set /a PASSED_COUNT+=1
) else (
    echo ❌ Python 패키지 확인 실패
    echo    해결: .venv\Scripts\activate 후 pip install -r requirements.txt
)
set /a TEST_COUNT+=1

:: 7. 설정 파일 확인
echo [7/8] 설정 파일 확인...
if exist .env (
    findstr "llama3.1:8b" .env >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ 고성능 설정 파일 (.env) 확인됨
        set /a PASSED_COUNT+=1
    ) else (
        echo ⚠️ 설정 파일이 구 버전일 수 있음
    )
) else (
    echo ❌ 설정 파일 (.env) 없음
    echo    해결: .env.example을 .env로 복사
)
set /a TEST_COUNT+=1

:: 8. Django 설정 확인
echo [8/8] Django 설정 확인...
python manage.py check --verbosity=0 >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Django 설정 정상
    set /a PASSED_COUNT+=1
) else (
    echo ❌ Django 설정 오류
    echo    해결: python manage.py check
)
set /a TEST_COUNT+=1

:: 결과 요약
echo.
echo 📊 검증 결과 요약
echo ================
echo 통과한 테스트: !PASSED_COUNT!/!TEST_COUNT!

if !PASSED_COUNT! equ !TEST_COUNT! (
    echo.
    echo 🎉 모든 테스트 통과!
    echo ✅ All-in-One 설치가 완벽하게 완료되었습니다.
    echo.
    echo 🚀 바로 사용 가능:
    echo   • 서버 시작: start.bat
    echo   • 웹 접속: http://localhost:8000
    echo   • AI 채팅 테스트 가능
    echo.
    
    set /p START_NOW="지금 바로 서버를 시작하시겠습니까? (Y/n): "
    if /i "!START_NOW!" neq "n" (
        echo.
        echo 🚀 서버 시작 중...
        if exist start.bat (
            call start.bat
        ) else (
            python manage.py runserver
        )
    )
    
) else if !PASSED_COUNT! geq 6 (
    echo.
    echo ⚠️ 부분적으로 성공
    echo ✅ 핵심 기능은 사용 가능하지만 일부 문제가 있습니다.
    echo.
    echo 🔧 권장 해결 방법:
    echo   1. install-all-in-one.bat 재실행
    echo   2. fix-ollama-500.bat 실행
    echo   3. 문제 영역별 개별 해결
    echo.
    
) else (
    echo.
    echo ❌ 설치 불완전
    echo 핵심 구성 요소에 문제가 있습니다.
    echo.
    echo 🔧 해결 방법:
    echo   1. install-all-in-one.bat 재실행 (관리자 권한)
    echo   2. 인터넷 연결 및 방화벽 확인
    echo   3. 바이러스 백신 일시 비활성화 후 재시도
    echo.
)

:: 상세 진단 옵션
echo.
echo 💡 추가 진단 도구:
echo   • 빠른 Ollama 확인: check-ollama-quick.bat
echo   • 완전한 AI 테스트: test-ai.bat
echo   • Ollama 문제 수정: fix-ollama-500.bat
echo   • 상세 설치 가이드: QUICK-START-ALLINONE.md
echo.

pause
