@echo off
:: XShell AI 챗봇 설치 디버깅 스크립트
:: 어디서 문제가 발생하는지 단계별로 확인

chcp 65001 >nul
cls

echo.
echo 🔍 XShell AI 챗봇 설치 디버깅
echo ==============================
echo.
echo 각 단계별로 확인하여 문제를 찾습니다.
echo.

:: 1단계: Python 확인
echo [1/8] Python 확인 중...
python --version
if %errorlevel% neq 0 (
    echo ❌ Python 설치 필요
    pause
    exit /b 1
) else (
    echo ✅ Python 확인됨
)
echo.
pause

:: 2단계: pip 확인
echo [2/8] pip 확인 중...
python -m pip --version
if %errorlevel% neq 0 (
    echo ❌ pip 문제 발생
    pause
    exit /b 1
) else (
    echo ✅ pip 확인됨
)
echo.
pause

:: 3단계: 가상환경 생성 테스트
echo [3/8] 가상환경 생성 테스트 중...
if exist .venv (
    echo ✅ 가상환경 이미 존재
) else (
    echo 가상환경 생성 중...
    python -m venv .venv
    if %errorlevel% neq 0 (
        echo ❌ 가상환경 생성 실패
        pause
        exit /b 1
    ) else (
        echo ✅ 가상환경 생성 성공
    )
)
echo.
pause

:: 4단계: 가상환경 활성화 테스트
echo [4/8] 가상환경 활성화 테스트 중...
call .venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ❌ 가상환경 활성화 실패
    pause
    exit /b 1
) else (
    echo ✅ 가상환경 활성화 성공
    python -c "import sys; print('Python 경로:', sys.executable)"
)
echo.
pause

:: 5단계: Django 설치 테스트
echo [5/8] Django 설치 테스트 중...
pip install Django==4.2.7 --quiet
if %errorlevel% neq 0 (
    echo ❌ Django 설치 실패
    pause
    exit /b 1
) else (
    echo ✅ Django 설치 성공
    python -c "import django; print('Django 버전:', django.get_version())"
)
echo.
pause

:: 6단계: 기본 패키지 설치 테스트
echo [6/8] 기본 패키지 설치 테스트 중...
pip install channels daphne requests python-dotenv --quiet
if %errorlevel% neq 0 (
    echo ❌ 기본 패키지 설치 실패
    pause
    exit /b 1
) else (
    echo ✅ 기본 패키지 설치 성공
)
echo.
pause

:: 7단계: Django 프로젝트 체크
echo [7/8] Django 프로젝트 체크 중...
python manage.py check
if %errorlevel% neq 0 (
    echo ❌ Django 프로젝트 체크 실패
    echo 설정 파일을 확인해주세요.
) else (
    echo ✅ Django 프로젝트 체크 성공
)
echo.
pause

:: 8단계: 마이그레이션 테스트
echo [8/8] 마이그레이션 테스트 중...
python manage.py makemigrations
python manage.py migrate
if %errorlevel% neq 0 (
    echo ❌ 마이그레이션 실패
    echo 데이터베이스 설정을 확인해주세요.
) else (
    echo ✅ 마이그레이션 성공
)
echo.

echo 🎉 모든 테스트 완료!
echo.
echo 이제 서버를 시작할 수 있습니다:
echo   run-daphne.bat 또는 start-server.bat
echo.
pause
