@echo off
:: XShell AI 챗봇 최소 설치 스크립트 (Windows)
:: 컴파일 오류 없이 핵심 기능만 설치

setlocal enabledelayedexpansion
chcp 65001 >nul
cls

echo.
echo ⚡ XShell AI 챗봇 최소 설치 스크립트
echo =============================================
echo.
echo 이 스크립트는 컴파일 오류를 피해 핵심 기능만 설치합니다.
echo psycopg2-binary, Pillow 등의 문제를 해결합니다.
echo.
pause

:: Python 확인
echo 🔍 Python 확인 중...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python이 설치되지 않았습니다.
    echo.
    echo 📥 Python 3.8 이상을 설치해주세요:
    echo    https://python.org/downloads/
    echo.
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo ✅ Python %PYTHON_VERSION% 확인됨

:: pip 업그레이드
echo 📈 pip 업그레이드 중...
python -m pip install --upgrade pip --quiet

:: 가상환경 생성
if not exist .venv (
    echo 📦 가상환경 생성 중...
    python -m venv .venv
    if %errorlevel% neq 0 (
        echo ❌ 가상환경 생성 실패
        pause
        exit /b 1
    )
    echo ✅ 가상환경 생성 완료
) else (
    echo ✅ 가상환경 확인됨
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

:: 핵심 패키지 개별 설치
echo.
echo 📚 핵심 패키지 설치 중...
echo    컴파일이 필요한 패키지는 제외됩니다.
echo.

set INSTALL_COUNT=0
set TOTAL_PACKAGES=8

call :install_package "Django==4.2.7" "웹 프레임워크"
call :install_package "django-cors-headers==4.3.1" "CORS 헤더"
call :install_package "channels==4.0.0" "WebSocket 지원"
call :install_package "requests==2.31.0" "HTTP 클라이언트"
call :install_package "python-dotenv==1.0.0" "환경 변수"
call :install_package "daphne==4.0.0" "ASGI 서버"
call :install_package "redis==5.0.1" "캐싱"
call :install_package "paramiko==3.3.1" "SSH 연결"

echo.
echo ✅ 핵심 패키지 설치 완료! (%INSTALL_COUNT%/%TOTAL_PACKAGES%)
echo.

:: 선택적 패키지 안내
echo 📋 선택적 패키지 ^(필요시 수동 설치^):
echo    pip install channels-redis  ^# Redis WebSocket 지원
echo    pip install whitenoise      ^# 정적 파일 서빙
echo    pip install ollama          ^# AI 백엔드
echo    pip install Pillow          ^# 이미지 처리 ^(컴파일 필요^)
echo.

:: 환경 파일 생성
if not exist .env (
    if exist .env.example (
        copy .env.example .env >nul
        echo ✅ .env 파일 생성 완료
    ) else (
        echo ⚠️ .env.example 파일을 찾을 수 없습니다.
    )
) else (
    echo ✅ .env 파일 확인됨
)

:: 데이터베이스 설정
echo 🗄️ 데이터베이스 설정 중...

:: 먼저 Django import 테스트
echo    Django 모듈 import 테스트 중...
python test-pexpect-fix.py
if %errorlevel% neq 0 (
    echo ❌ Django 모듈 import 테스트 실패
    echo.
    echo 🔧 자동 수정을 시도합니다...
    python fix-django.py
    if %errorlevel% neq 0 (
        echo ❌ 자동 수정 실패
        echo.
        echo 💡 수동 해결 방법:
        echo    1. pexpect 문제: xshell_integration/services.py 확인
        echo    2. 모델 파일 문제: chatbot/models.py 확인
        echo    3. 서비스 파일 문제: ai_backend/services.py 확인
        echo    4. 의존성 문제: pip list 확인
        echo.
        goto :django_error
    ) else (
        echo ✅ 자동 수정 완료, import 재테스트...
        python test-pexpect-fix.py
        if %errorlevel% neq 0 (
            echo ❌ 수정 후에도 import 실패
            goto :django_error
        )
    )
)

echo    ✅ Django 모듈 import 성공

echo    마이그레이션 생성 중...
python manage.py makemigrations --verbosity=1
if %errorlevel% neq 0 (
    echo ⚠️ 마이그레이션 생성 중 경고 발생 (정상적일 수 있음)
)

echo    데이터베이스 마이그레이션 실행 중...
python manage.py migrate --verbosity=1
if %errorlevel% neq 0 (
    echo ❌ 데이터베이스 마이그레이션 실패
    echo.
    echo 🔧 해결 방법:
    echo    1. 데이터베이스 파일 삭제 후 재시도: del db.sqlite3
    echo    2. 마이그레이션 파일 삭제 후 재시도
    echo    3. python manage.py check 로 문제 확인
    echo.
    goto :django_error
)
echo ✅ 데이터베이스 설정 완료

:: 로그 디렉토리 생성
if not exist logs (
    mkdir logs
    echo ✅ 로그 디렉토리 생성 완료
)

:: Ollama 확인 및 모델 다운로드
echo.
echo 🤖 Ollama AI 설정 중...
echo    AI 기능을 위해 Ollama와 모델을 설정합니다.

:: Ollama 설치 확인
ollama --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Ollama가 설치되지 않았습니다.
    echo.
    echo 📥 Ollama 설치 방법:
    echo    1. https://ollama.ai/download 방문
    echo    2. Windows용 Ollama 다운로드 및 설치
    echo    3. 설치 완료 후 이 스크립트를 다시 실행
    echo.
    echo 💡 Ollama 없이도 XShell 기능은 사용 가능합니다.
    set /p CONTINUE_WITHOUT_OLLAMA="Ollama 없이 계속하시겠습니까? (y/N): "
    if /i "!CONTINUE_WITHOUT_OLLAMA!"=="y" (
        echo ✅ Ollama 없이 설치를 계속합니다.
        goto :skip_ollama
    ) else (
        echo.
        echo 🔗 Ollama 다운로드 페이지를 열어드립니다...
        start https://ollama.ai/download
        echo.
        echo 설치 완료 후 이 스크립트를 다시 실행해주세요.
        pause
        exit /b 0
    )
) else (
    echo ✅ Ollama 확인됨
    
    :: Ollama 서비스 확인
    echo    Ollama 서비스 상태 확인 중...
    curl -s http://localhost:11434 >nul 2>&1
    if %errorlevel% neq 0 (
        echo ⚠️  Ollama 서비스가 실행되지 않습니다.
        echo    서비스를 시작합니다...
        
        :: Ollama 서비스 시작 시도
        start /min ollama serve >nul 2>&1
        
        :: 서비스 시작 대기 (최대 10초)
        echo    서비스 시작 대기 중...
        for /L %%i in (1,1,10) do (
            timeout /t 1 /nobreak >nul 2>&1
            curl -s http://localhost:11434 >nul 2>&1
            if !errorlevel! equ 0 (
                echo ✅ Ollama 서비스 시작됨
                goto :ollama_ready
            )
        )
        
        echo ⚠️  Ollama 서비스 자동 시작 실패
        echo    수동으로 Ollama를 시작해주세요: ollama serve
        goto :skip_ollama
    ) else (
        echo ✅ Ollama 서비스 실행 중
    )
    
    :ollama_ready
    :: 모델 확인 및 다운로드
    echo    설치된 모델 확인 중...
    ollama list | findstr "llama3.1:8b" >nul 2>&1
    if %errorlevel% neq 0 (
        echo 📥 llama3.1:8b 모델 다운로드 중... (약 4.7GB, 시간이 걸릴 수 있습니다)
        echo    네트워크 상태에 따라 5-20분 소요될 수 있습니다.
        echo.
        
        ollama pull llama3.1:8b
        if %errorlevel% equ 0 (
            echo ✅ llama3.1:8b 모델 다운로드 완료!
        ) else (
            echo ❌ 모델 다운로드 실패
            echo    인터넷 연결을 확인하고 나중에 다시 시도해주세요:
            echo    ollama pull llama3.1:8b
        )
    ) else (
        echo ✅ llama3.1:8b 모델 이미 설치됨
    )
    
    :: 추가 경량 모델 제안
    echo.
    set /p INSTALL_LIGHT_MODEL="경량 모델(llama3.2:3b, 약 2GB)도 설치하시겠습니까? (y/N): "
    if /i "!INSTALL_LIGHT_MODEL!"=="y" (
        echo 📥 llama3.2:3b 모델 다운로드 중...
        ollama pull llama3.2:3b
        if %errorlevel% equ 0 (
            echo ✅ llama3.2:3b 모델 다운로드 완료!
        ) else (
            echo ❌ 경량 모델 다운로드 실패
        )
    )
)

:skip_ollama

:: 완료 메시지
echo.
echo 🎉 XShell AI 챗봇 최소 설치 완료!
echo.
echo ✅ 해결된 문제들:
echo   • psycopg2-binary 컴파일 오류
echo   • Pillow 컴파일 오류  
echo   • pexpect 모듈 오류 (Windows 호환성)
echo   • Django import 오류
echo.
echo 📋 다음 단계:
echo   1. final-test.bat 실행하여 최종 확인
echo   2. start.bat 실행하여 서버 시작
echo   3. 또는 수동으로: python manage.py runserver
echo.
echo 🌐 브라우저에서 http://localhost:8000 접속
echo.
echo 📚 추가 기능이 필요하면:
echo   • FIX-WINDOWS-INSTALL.md 파일 참조
echo   • 선택적 패키지 개별 설치
echo.

goto :success

:install_package
set /a INSTALL_COUNT+=1
echo [%INSTALL_COUNT%/%TOTAL_PACKAGES%] %~2 설치 중...
pip install %~1 --quiet --no-warn-script-location
if %errorlevel% neq 0 (
    echo ❌ %~1 설치 실패  
    set /a INSTALL_COUNT-=1
    echo    인터넷 연결을 확인하고 다시 시도해주세요.
    goto :install_error
)
echo ✅ %~2 설치 완료
goto :eof

:install_error
echo.
echo ❌ 패키지 설치 중 오류 발생
echo.
echo 🔧 해결 방법:
echo   1. 인터넷 연결 확인
echo   2. 방화벽/백신 소프트웨어 확인
echo   3. 관리자 권한으로 실행
echo   4. Python 버전 확인 (3.8+ 필요)
echo.
pause
exit /b 1

:django_error
echo.
echo ❌ Django 설정 오류 발생
echo.
echo 🛠️ 단계별 해결 방법:
echo.
echo   1. 캐시 정리:     clear-cache.bat
echo   2. 빠른 테스트:   python quick-test.py
echo   3. 자세한 진단:   python test-imports.py
echo   4. 자동 수정:     python fix-django.py  
echo   5. 수동 체크:     python manage.py check
echo.
echo 💡 일반적인 해결 방법:
echo   • pexpect 오류: Windows 환경에서 정상 (자동 수정됨)
echo   • Import 오류: Python 캐시 정리 후 재시도
echo   • 모델 오류: 마이그레이션 파일 확인 및 재생성
echo   • 의존성 오류: pip install -r requirements-minimal.txt
echo.
set /p TRY_AUTO_FIX="자동 수정을 시도하시겠습니까? (y/N): "
if /i "%TRY_AUTO_FIX%"=="y" (
    echo.
    echo 🧹 먼저 캐시를 정리합니다...
    call clear-cache.bat
    echo.
    echo 🔧 자동 수정 시도 중...
    python fix-django.py
    if %errorlevel% equ 0 (
        echo.
        echo 📋 재테스트 중...
        python test-pexpect-fix.py
        if %errorlevel% equ 0 (
            echo ✅ 수정 완료! 설치를 계속합니다.
            goto :continue_install
        ) else (
            echo ❌ 재테스트 실패
            echo.
            echo 💡 final-test.bat을 실행해서 다시 확인해보세요.
        )
    ) else (
        echo ❌ 자동 수정 실패
    )
)

echo.
echo 📞 추가 도움이 필요하면:
echo   • FIX-WINDOWS-INSTALL.md 문서 참조
echo   • GitHub Issues에 문의
echo.
pause
exit /b 1

:continue_install
echo ✅ Django 설정 확인됨
echo    마이그레이션 재시도 중...
python manage.py makemigrations --verbosity=1
python manage.py migrate --verbosity=1
if %errorlevel% neq 0 (
    echo ⚠️ 마이그레이션 재시도 실패 - 수동으로 실행해주세요
)
goto :success

:success
echo 🚀 설치 완료! 이제 챗봇을 시작할 수 있습니다.
echo.
set /p START_NOW="지금 바로 서버를 시작하시겠습니까? (y/N): "
if /i "%START_NOW%"=="y" (
    echo.
    echo 🚀 서버 시작 중...
    python manage.py runserver
) else (
    echo.
    echo 나중에 다음 명령어로 서버를 시작하세요:
    echo    start.bat 또는 python manage.py runserver
)

pause
