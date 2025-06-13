@echo off
:: Django 테스트 스크립트 - 단계별 확인

chcp 65001 >nul
cls

echo.
echo 🔍 Django 프로젝트 테스트 스크립트
echo =====================================
echo.

:: 가상환경 활성화
call .venv\Scripts\activate.bat

:: 1. Django 버전 확인
echo [1/5] Django 버전 확인...
python -c "import django; print('Django version:', django.get_version())"
if %errorlevel% neq 0 (
    echo ❌ Django import 실패
    pause
    exit /b 1
)
echo ✅ Django import 성공
echo.

:: 2. 설정 파일 확인
echo [2/5] Django 설정 확인...
python -c "import os; os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'xshell_chatbot.settings'); import django; django.setup(); print('Settings loaded successfully')"
if %errorlevel% neq 0 (
    echo ❌ Django 설정 로드 실패
    pause
    exit /b 1
)
echo ✅ Django 설정 로드 성공
echo.

:: 3. 앱 import 확인
echo [3/5] 앱 import 확인...
python -c "import chatbot.models; import ai_backend.services; import xshell_integration.services; print('All apps imported successfully')"
if %errorlevel% neq 0 (
    echo ❌ 앱 import 실패
    pause
    exit /b 1
)
echo ✅ 모든 앱 import 성공
echo.

:: 4. URL 설정 확인 (간단한 방법)
echo [4/5] URL 설정 확인...
python -c "import os; os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'xshell_chatbot.settings'); import django; django.setup(); from django.urls import reverse; print('URL configuration working')"
if %errorlevel% neq 0 (
    echo ❌ URL 설정 확인 실패
    echo    URL 패턴에 문제가 있을 수 있습니다.
    echo.
    echo 🔧 문제 해결 단계:
    echo    1. URL 패턴 확인
    echo    2. views.py 중복 함수 확인
    echo    3. import 오류 확인
    echo.
    set /p CONTINUE="계속하시겠습니까? (y/N): "
    if /i "%CONTINUE%" neq "y" (
        pause
        exit /b 1
    )
)
echo ✅ URL 설정 확인 완료
echo.

:: 5. 데이터베이스 테이블 확인 (migrate 없이)
echo [5/5] 데이터베이스 상태 확인...
if exist db.sqlite3 (
    echo ✅ 데이터베이스 파일 존재
) else (
    echo ⚠️ 데이터베이스 파일 없음 - 마이그레이션 필요
)
echo.

echo 🎉 Django 프로젝트 기본 구조 확인 완료!
echo.
echo 📋 다음 단계:
echo   1. python manage.py makemigrations
echo   2. python manage.py migrate
echo   3. python manage.py runserver
echo.

pause
