@echo off
:: Ollama 자동 설치 및 설정 스크립트 (Windows)
:: 여러 방법으로 Ollama 설치를 시도합니다

setlocal enabledelayedexpansion
chcp 65001 >nul
cls

echo.
echo 🤖 Ollama AI 자동 설치 및 설정
echo ================================
echo.
echo 이 스크립트는 Windows에서 Ollama를 자동으로 설치하고 설정합니다.
echo 여러 방법을 시도하여 가장 적합한 방법을 찾습니다.
echo.
pause

:: 관리자 권한 확인
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  관리자 권한이 필요할 수 있습니다.
    echo    설치 실패 시 '관리자 권한으로 실행'을 시도해주세요.
    echo.
)

:: 1단계: 기존 Ollama 설치 확인
echo 🔍 1단계: 기존 Ollama 설치 확인
echo ================================
ollama --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Ollama가 이미 설치되어 있습니다!
    ollama --version
    echo.
    goto :check_service
) else (
    echo ❌ Ollama가 설치되지 않았습니다.
    echo.
)

:: 2단계: PowerShell 설치 확인
echo 🔍 2단계: PowerShell 설치 확인
echo ==============================
powershell -Command "Write-Host 'PowerShell 사용 가능'" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ PowerShell을 사용할 수 없습니다.
    echo    수동 설치를 진행합니다.
    goto :manual_install
) else (
    echo ✅ PowerShell 사용 가능
    echo.
)

:: 3단계: 인터넷 연결 확인
echo 🌐 3단계: 인터넷 연결 확인
echo ==========================
ping -n 1 8.8.8.8 >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 인터넷 연결을 확인할 수 없습니다.
    echo    인터넷 연결을 확인하고 다시 시도해주세요.
    goto :manual_install
) else (
    echo ✅ 인터넷 연결 확인됨
    echo.
)

:: 4단계: Winget 설치 시도
echo 📦 4단계: Winget으로 Ollama 설치 시도
echo ====================================
winget --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Winget 사용 가능
    echo    Ollama 설치 중...
    
    winget install ollama
    if %errorlevel% equ 0 (
        echo ✅ Winget으로 Ollama 설치 성공!
        echo.
        goto :check_service
    ) else (
        echo ❌ Winget 설치 실패. 다른 방법을 시도합니다.
        echo.
    )
) else (
    echo ❌ Winget을 사용할 수 없습니다.
    echo.
)

:: 5단계: Chocolatey 설치 시도
echo 🍫 5단계: Chocolatey로 Ollama 설치 시도
echo =====================================
choco --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Chocolatey 사용 가능
    echo    Ollama 설치 중...
    
    choco install ollama -y
    if %errorlevel% equ 0 (
        echo ✅ Chocolatey로 Ollama 설치 성공!
        echo.
        goto :check_service
    ) else (
        echo ❌ Chocolatey 설치 실패. 다른 방법을 시도합니다.
        echo.
    )
) else (
    echo ❌ Chocolatey가 설치되지 않았습니다.
    echo.
)

:: 6단계: PowerShell 스크립트로 설치 시도
echo 💻 6단계: PowerShell 스크립트로 설치 시도
echo ========================================
echo    PowerShell로 Ollama 설치를 시도합니다...
echo.

powershell -ExecutionPolicy Bypass -Command "& { try { Invoke-RestMethod -Uri 'https://ollama.com/install.ps1' | Invoke-Expression; Write-Host 'PowerShell 설치 성공' } catch { Write-Host 'PowerShell 설치 실패: ' + $_.Exception.Message; exit 1 } }"

if %errorlevel% equ 0 (
    echo ✅ PowerShell 스크립트로 Ollama 설치 성공!
    echo.
    goto :check_service
) else (
    echo ❌ PowerShell 스크립트 설치 실패.
    echo.
)

:: 7단계: 수동 다운로드 설치
:manual_install
echo 📥 7단계: 수동 다운로드 설치
echo ===========================
echo    자동 설치가 모두 실패했습니다.
echo    수동 설치를 진행합니다.
echo.

set OLLAMA_URL=https://ollama.com/download/windows
set OLLAMA_EXE=ollama-windows-amd64.exe
set TEMP_DIR=%TEMP%\ollama-install

echo 📁 임시 디렉토리 생성: %TEMP_DIR%
mkdir "%TEMP_DIR%" 2>nul

echo 📥 Ollama 다운로드 중...
echo    URL: %OLLAMA_URL%
echo    대상: %TEMP_DIR%\%OLLAMA_EXE%
echo.

:: PowerShell로 다운로드 시도
powershell -Command "try { Invoke-WebRequest -Uri '%OLLAMA_URL%' -OutFile '%TEMP_DIR%\%OLLAMA_EXE%' -UseBasicParsing; Write-Host 'PowerShell 다운로드 성공' } catch { Write-Host 'PowerShell 다운로드 실패: ' + $_.Exception.Message; exit 1 }"

if %errorlevel% equ 0 (
    echo ✅ 다운로드 성공!
    echo.
    
    echo 🔧 Ollama 설치 중...
    echo    실행 파일: %TEMP_DIR%\%OLLAMA_EXE%
    
    :: 설치 프로그램 실행
    "%TEMP_DIR%\%OLLAMA_EXE%" /S
    
    :: 설치 완료 대기
    echo    설치 완료 대기 중... (30초)
    timeout /t 30 /nobreak >nul 2>&1
    
    :: 설치 확인
    ollama --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ 수동 설치 성공!
        echo.
        
        :: 임시 파일 정리
        del "%TEMP_DIR%\%OLLAMA_EXE%" 2>nul
        rmdir "%TEMP_DIR%" 2>nul
        
        goto :check_service
    ) else (
        echo ❌ 설치 후에도 Ollama를 찾을 수 없습니다.
        echo    PATH 환경변수를 확인하고 시스템을 재시작해보세요.
        echo.
        goto :manual_guide
    )
) else (
    echo ❌ 다운로드 실패
    echo.
    goto :manual_guide
)

:: 서비스 확인 및 시작
:check_service
echo 🔄 서비스 확인 및 시작
echo =====================

:: Ollama 버전 확인
echo 📋 설치된 Ollama 정보:
ollama --version
echo.

:: 서비스 상태 확인
echo 🔍 서비스 상태 확인 중...
curl -s -m 5 http://localhost:11434 >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Ollama 서비스가 이미 실행 중입니다.
) else (
    echo ⚠️  Ollama 서비스가 실행되지 않고 있습니다.
    echo    서비스를 시작합니다...
    
    :: 백그라운드에서 서비스 시작
    start /min "Ollama Service" ollama serve
    
    :: 서비스 시작 대기
    echo    서비스 시작 대기 중... (최대 30초)
    for /L %%i in (1,1,30) do (
        timeout /t 1 /nobreak >nul 2>&1
        curl -s -m 2 http://localhost:11434 >nul 2>&1
        if !errorlevel! equ 0 (
            echo ✅ Ollama 서비스 시작 완료! (%%i초)
            goto :download_models
        )
        if %%i equ 30 (
            echo ❌ 서비스 시작 시간 초과
            echo    수동으로 시작해보세요: ollama serve
            goto :manual_guide
        )
    )
)

:: 모델 다운로드
:download_models
echo.
echo 📥 AI 모델 다운로드
echo ==================

:: 기존 모델 확인
echo 🔍 설치된 모델 확인 중...
ollama list > "%TEMP%\ollama_models.txt" 2>&1
if %errorlevel% equ 0 (
    echo ✅ 모델 목록 조회 성공
    type "%TEMP%\ollama_models.txt"
    echo.
    
    :: llama3.1:8b 모델 확인
    findstr /C:"llama3.1:8b" "%TEMP%\ollama_models.txt" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ llama3.1:8b 모델이 이미 설치되어 있습니다.
        goto :test_models
    )
    
    del "%TEMP%\ollama_models.txt" 2>nul
) else (
    echo ❌ 모델 목록 조회 실패
    echo    서비스가 완전히 시작되지 않았을 수 있습니다.
)

:: 모델 다운로드 확인
echo.
set /p DOWNLOAD_MODEL="llama3.1:8b 모델을 다운로드하시겠습니까? (약 4.7GB) (y/N): "
if /i "!DOWNLOAD_MODEL!"=="y" (
    echo.
    echo 📥 llama3.1:8b 모델 다운로드 중...
    echo    크기: 약 4.7GB
    echo    시간: 인터넷 속도에 따라 5-30분 소요
    echo    진행 상황이 표시됩니다.
    echo.
    
    ollama pull llama3.1:8b
    if %errorlevel% equ 0 (
        echo ✅ llama3.1:8b 모델 다운로드 완료!
    ) else (
        echo ❌ 모델 다운로드 실패
        echo    네트워크 연결을 확인하고 나중에 다시 시도해주세요.
    )
    echo.
    
    :: 경량 모델 제안
    set /p DOWNLOAD_LIGHT="경량 모델(llama3.2:3b, 약 2GB)도 다운로드하시겠습니까? (y/N): "
    if /i "!DOWNLOAD_LIGHT!"=="y" (
        echo.
        echo 📥 llama3.2:3b 모델 다운로드 중...
        ollama pull llama3.2:3b
        if %errorlevel% equ 0 (
            echo ✅ llama3.2:3b 모델 다운로드 완료!
        ) else (
            echo ❌ 경량 모델 다운로드 실패
        )
    )
)

:: 모델 테스트
:test_models
echo.
echo 🧪 모델 테스트
echo ==============

:: 설치된 모델 최종 확인
echo 📋 최종 설치된 모델 목록:
ollama list
echo.

:: 간단한 테스트
echo 🤖 AI 모델 테스트 중...
echo    질문: "Hello, what is 2+2?"
echo.

ollama run llama3.1:8b --version >nul 2>&1
if %errorlevel% equ 0 (
    echo "    답변:"
    echo "Hello, what is 2+2?" | ollama run llama3.1:8b
    echo.
    echo ✅ 모델 테스트 성공!
) else (
    echo ❌ 모델 테스트 실패
    echo    모델이 제대로 설치되지 않았을 수 있습니다.
)

echo.
echo 🎉 Ollama 설치 및 설정 완료!
echo ============================
echo.
echo ✅ 설치 완료 정보:
echo   • Ollama 서비스: http://localhost:11434
echo   • 모델 관리: ollama list
echo   • 새 모델 설치: ollama pull [model-name]
echo   • 모델 실행: ollama run [model-name]
echo.
echo 💡 다음 단계:
echo   1. XShell 챗봇에서 AI 기능을 사용할 수 있습니다
echo   2. 서버 시작: run-daphne.bat 또는 start-server.bat
echo   3. 브라우저에서 http://localhost:8000 접속
echo.
echo 🔧 유용한 명령어:
echo   • 서비스 시작: ollama serve
echo   • 모델 목록: ollama list
echo   • 모델 삭제: ollama rm [model-name]
echo   • 서비스 상태: curl http://localhost:11434
echo.

goto :end

:: 수동 설치 안내
:manual_guide
echo.
echo 📖 수동 설치 안내
echo =================
echo.
echo 자동 설치가 실패했습니다. 다음 방법으로 수동 설치해주세요:
echo.
echo 🌐 방법 1: 웹 다운로드
echo   1. 브라우저에서 https://ollama.com/download 접속
echo   2. "Download for Windows" 클릭
echo   3. 다운로드된 파일 실행
echo   4. 설치 완료 후 이 스크립트를 다시 실행
echo.
echo 💻 방법 2: 명령어 설치
echo   관리자 권한 CMD에서 다음 중 하나 실행:
echo   • winget install ollama
echo   • choco install ollama
echo.
echo 🔧 방법 3: 수동 설정
echo   1. PATH 환경변수에 Ollama 경로 추가
echo   2. 시스템 재시작
echo   3. CMD에서 "ollama --version" 확인
echo.
echo 브라우저를 열어 다운로드 페이지로 이동합니다...
start https://ollama.com/download
echo.

:end
echo 📞 추가 도움이 필요하면:
echo   • 공식 문서: https://ollama.com/docs
echo   • GitHub: https://github.com/ollama/ollama
echo   • 커뮤니티: https://discord.gg/ollama
echo.
pause
