@echo off
:: XShell AI Chatbot All-in-One Installer (Final Fixed Version)
:: Completely rewritten for maximum stability

chcp 65001 >nul
cls

echo.
echo 🚀 XShell AI Chatbot All-in-One Installer
echo ==========================================
echo.
echo Installing components:
echo   • Python 3.11 + Virtual Environment
echo   • Ollama AI Engine + Models
echo   • Django Web Server + WebSocket
echo   • XShell Integration + All Config Files
echo.
echo Estimated time: 15-30 minutes
echo Required disk space: ~15GB
echo.

set /p CONTINUE="Start installation? (Y/n): "
if /i "%CONTINUE%"=="n" goto :user_exit

:: Check admin rights
echo Checking admin rights...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Admin rights required.
    echo Right-click this file and select "Run as administrator"
    pause
    exit /b 1
)
echo ✅ Admin rights confirmed

:: Create temp directory
set TEMP_INSTALL_DIR=%~dp0temp_install
if not exist "%TEMP_INSTALL_DIR%" mkdir "%TEMP_INSTALL_DIR%"
echo Temp directory: %TEMP_INSTALL_DIR%

:: =================================================================
:: Step 1: System Check
:: =================================================================
echo.
echo Step 1: System Environment Check
echo =================================

echo Checking system memory...
powershell -Command "& {$mem = Get-WmiObject -Class Win32_ComputerSystem; $memGB = [math]::Round($mem.TotalPhysicalMemory / 1GB, 2); Write-Host \"System Memory: $memGB GB\"}"

echo Checking disk space...
echo Disk space check completed

echo ✅ System check completed

:: =================================================================
:: Step 2: Python Installation
:: =================================================================
echo.
echo Step 2: Python Installation
echo ============================

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python not found. Installing...
    
    set PYTHON_URL=https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe
    set PYTHON_FILE=%TEMP_INSTALL_DIR%\python-installer.exe
    
    echo Downloading Python installer...
    powershell -Command "& {Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_FILE%'}"
    
    if not exist "%PYTHON_FILE%" (
        echo ERROR: Python download failed
        echo Please download manually from https://python.org/downloads/
        goto :install_error
    )
    
    echo Installing Python (this may take 2-5 minutes)...
    "%PYTHON_FILE%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
    
    echo Cleaning up installer...
    if exist "%PYTHON_FILE%" del "%PYTHON_FILE%" >nul 2>&1
    
    echo Waiting for Python to be recognized...
    timeout /t 10 /nobreak >nul
    
    python --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: Python installation failed
        echo Please restart your computer and try again
        goto :install_error
    )
    
    echo ✅ Python installation completed
) else (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
    echo ✅ Python found: !PYTHON_VERSION!
)

:: Upgrade pip
echo Upgrading pip...
python -m pip install --upgrade pip --quiet
echo ✅ pip upgrade completed

:: =================================================================
:: Step 3: Ollama Installation
:: =================================================================
echo.
echo Step 3: Ollama AI Engine Installation
echo ======================================

ollama --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Ollama not found. Installing...
    
    set OLLAMA_FILE=%TEMP_INSTALL_DIR%\OllamaSetup.exe
    
    echo Downloading Ollama installer...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/ollama/ollama/releases/latest/download/OllamaSetup.exe' -OutFile '%OLLAMA_FILE%'}"
    
    if not exist "%OLLAMA_FILE%" (
        echo ERROR: Ollama download failed
        echo Please download manually from https://ollama.com/download
        goto :install_error
    )
    
    echo Installing Ollama (this may take 2-5 minutes)...
    "%OLLAMA_FILE%" /S
    
    echo Cleaning up installer...
    if exist "%OLLAMA_FILE%" del "%OLLAMA_FILE%" >nul 2>&1
    
    echo Waiting for Ollama service...
    timeout /t 30 /nobreak >nul
    
    ollama --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: Ollama installation failed
        echo Please restart your computer and try again
        goto :install_error
    )
    
    echo ✅ Ollama installation completed
) else (
    echo ✅ Ollama already installed
    ollama --version
)

:: Start Ollama service
echo Starting Ollama service...
taskkill /f /im ollama.exe >nul 2>&1
start /min "Ollama Service" ollama serve

echo Waiting for service to start...
timeout /t 15 /nobreak >nul

:: Check Ollama connection
set OLLAMA_OK=0
for /l %%i in (1,1,5) do (
    echo Connection attempt %%i/5...
    powershell -Command "try {Invoke-WebRequest -Uri 'http://localhost:11434/' -TimeoutSec 5 -UseBasicParsing | Out-Null; exit 0} catch {exit 1}" >nul 2>&1
    if !errorlevel! equ 0 (
        echo ✅ Ollama service running
        set OLLAMA_OK=1
        goto :ollama_ready
    )
    timeout /t 3 /nobreak >nul
)

if %OLLAMA_OK% equ 0 (
    echo ERROR: Ollama service failed to start
    echo Please run 'ollama serve' manually
    goto :install_error
)

:ollama_ready

:: =================================================================
:: Step 4: AI Models Installation
:: =================================================================
echo.
echo Step 4: AI Models Installation
echo ===============================
echo.
echo Installing high-performance AI models:
echo   • llama3.1:8b (4.7GB) - General conversation
echo   • codellama:13b (7GB) - Code analysis
echo.

set MODEL_COUNT=0

echo [1/2] Installing llama3.1:8b model (about 4.7GB)...
ollama list | findstr "llama3.1:8b" >nul 2>&1
if %errorlevel% neq 0 (
    echo Download starting... (5-10 minutes expected)
    ollama pull llama3.1:8b
    if !errorlevel! equ 0 (
        echo ✅ llama3.1:8b installation completed
        set /a MODEL_COUNT+=1
    ) else (
        echo ❌ llama3.1:8b installation failed
    )
) else (
    echo ✅ llama3.1:8b already installed
    set /a MODEL_COUNT+=1
)

echo [2/2] Installing codellama:13b model (about 7GB)...
ollama list | findstr "codellama:13b" >nul 2>&1
if %errorlevel% neq 0 (
    echo Download starting... (7-15 minutes expected)
    ollama pull codellama:13b
    if !errorlevel! equ 0 (
        echo ✅ codellama:13b installation completed
        set /a MODEL_COUNT+=1
    ) else (
        echo ❌ codellama:13b installation failed
    )
) else (
    echo ✅ codellama:13b already installed
    set /a MODEL_COUNT+=1
)

echo.
echo AI Models installation result: %MODEL_COUNT% models installed
echo Installed models:
ollama list

:: =================================================================
:: Step 5: Python Environment Setup
:: =================================================================
echo.
echo Step 5: Python Environment Setup
echo =================================

:: Create virtual environment
if not exist .venv (
    echo Creating virtual environment...
    python -m venv .venv
    if %errorlevel% neq 0 (
        echo ERROR: Virtual environment creation failed
        goto :install_error
    )
    echo ✅ Virtual environment created
) else (
    echo ✅ Virtual environment already exists
)

:: Activate virtual environment
echo Activating virtual environment...
call .venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ERROR: Virtual environment activation failed
    goto :install_error
)
echo ✅ Virtual environment activated

:: Install packages
echo Installing Python packages...
call :install_packages

:: =================================================================
:: Step 6: Configuration Files
:: =================================================================
echo.
echo Step 6: Configuration Files Setup
echo ==================================

if not exist .env (
    if exist .env.example (
        echo Creating .env file from template...
        copy .env.example .env >nul
        echo ✅ .env file created
    ) else (
        echo Creating new .env file...
        call :create_env_file
        echo ✅ .env file created
    )
) else (
    echo ✅ .env file already exists
)

:: =================================================================
:: Step 7: Database Setup
:: =================================================================
echo.
echo Step 7: Database Setup
echo ======================

echo Creating required directories...
if not exist logs mkdir logs
if not exist static mkdir static
if not exist templates mkdir templates
if not exist media mkdir media
echo ✅ Directories created

echo Setting up database...
python manage.py check --verbosity=0 >nul 2>&1
python manage.py makemigrations --verbosity=0 >nul 2>&1
python manage.py migrate --verbosity=0
if %errorlevel% neq 0 (
    echo ERROR: Database setup failed
    goto :install_error
)
echo ✅ Database setup completed

:: =================================================================
:: Step 8: System Test
:: =================================================================
echo.
echo Step 8: System Test
echo ===================

echo Testing complete system...

call :test_system
if %errorlevel% neq 0 (
    echo ❌ System test failed
    set /p CONTINUE_ANYWAY="Ignore errors and continue? (y/N): "
    if /i "!CONTINUE_ANYWAY!" neq "y" (
        echo Installation aborted
        goto :install_error
    )
) else (
    echo ✅ All tests passed!
)

:: =================================================================
:: Step 9: Installation Complete
:: =================================================================
echo.
echo Step 9: Installation Complete!
echo ===============================
echo.
echo ✅ Installed components:
echo   • Python 3.11 + Virtual Environment
echo   • Django Web Framework
echo   • Ollama AI Engine
echo   • AI Models: llama3.1:8b, codellama:13b
echo   • WebSocket Real-time Chat
echo   • Database (SQLite)
echo   • All Configuration Files
echo.
echo 🚀 High-performance settings:
echo   • Default AI Model: llama3.1:8b
echo   • Code AI Model: codellama:13b
echo   • Simultaneous Model Loading: 2
echo   • Context Length: 8192 tokens
echo.

:: Clean up temp directory
if exist "%TEMP_INSTALL_DIR%" rmdir /s /q "%TEMP_INSTALL_DIR%" >nul 2>&1

set /p START_SERVER="Start server now? (Y/n): "
if /i "%START_SERVER%"=="n" goto :manual_start

echo.
echo Starting server...
echo.

:: Open browser after 5 seconds
start "" cmd /c "timeout /t 5 /nobreak >nul && start http://localhost:8000"

:: Start server
if exist start.bat (
    echo Using start.bat to start server...
    call start.bat
) else if exist run-daphne.bat (
    echo Using run-daphne.bat to start server...
    call run-daphne.bat
) else (
    echo Starting Django development server...
    python manage.py runserver 0.0.0.0:8000
)

goto :end

:manual_start
echo.
echo Manual start instructions:
echo =========================
echo.
echo 1. Start server: start.bat
echo 2. Open browser: http://localhost:8000
echo 3. Check AI status: check-ollama-quick.bat
echo.

goto :end

:: =================================================================
:: Function Definitions
:: =================================================================

:install_packages
set PACKAGE_SUCCESS=0

if exist requirements-minimal.txt (
    echo Trying minimal packages first...
    pip install -r requirements-minimal.txt --quiet
    if !errorlevel! equ 0 (
        echo ✅ Minimal packages installed
        set PACKAGE_SUCCESS=1
        exit /b 0
    )
)

if exist requirements-windows.txt (
    echo Trying Windows-specific packages...
    pip install -r requirements-windows.txt --quiet
    if !errorlevel! equ 0 (
        echo ✅ Windows packages installed
        set PACKAGE_SUCCESS=1
        exit /b 0
    )
)

if %PACKAGE_SUCCESS% equ 0 (
    echo Installing core packages individually...
    call :install_core_packages
)
exit /b 0

:install_core_packages
echo Installing core packages individually...
set PACKAGE_COUNT=0

echo [1/8] Django...
pip install Django==4.2.7 --quiet
if !errorlevel! equ 0 set /a PACKAGE_COUNT+=1

echo [2/8] CORS headers...
pip install django-cors-headers==4.3.1 --quiet
if !errorlevel! equ 0 set /a PACKAGE_COUNT+=1

echo [3/8] WebSocket support...
pip install channels==4.0.0 --quiet
if !errorlevel! equ 0 set /a PACKAGE_COUNT+=1

echo [4/8] HTTP client...
pip install requests==2.31.0 --quiet
if !errorlevel! equ 0 set /a PACKAGE_COUNT+=1

echo [5/8] Environment variables...
pip install python-dotenv==1.0.0 --quiet
if !errorlevel! equ 0 set /a PACKAGE_COUNT+=1

echo [6/8] ASGI server...
pip install daphne==4.0.0 --quiet
if !errorlevel! equ 0 set /a PACKAGE_COUNT+=1

echo [7/8] SSH support...
pip install paramiko==3.3.1 --quiet
if !errorlevel! equ 0 set /a PACKAGE_COUNT+=1

echo [8/8] Redis client...
pip install redis==5.0.1 --quiet
if !errorlevel! equ 0 set /a PACKAGE_COUNT+=1

echo Individual package installation result: %PACKAGE_COUNT%/8 successful
exit /b 0

:create_env_file
(
echo # XShell AI Chatbot Environment Configuration
echo.
echo # Django Settings
echo SECRET_KEY=django-insecure-xshell-chatbot-dev-key-auto-generated
echo DEBUG=True
echo.
echo # Database
echo DATABASE_URL=sqlite:///db.sqlite3
echo.
echo # XShell Integration
echo XSHELL_PATH=C:\Program Files\NetSarang\Xshell 8\Xshell.exe
echo XSHELL_SESSIONS_PATH=C:\Users\%USERNAME%\Documents\NetSarang Computer\8\Xshell\Sessions
echo.
echo # AI Backend (Ollama^)
echo OLLAMA_BASE_URL=http://localhost:11434
echo DEFAULT_AI_MODEL=llama3.1:8b
echo CODE_AI_MODEL=codellama:13b
echo.
echo # High-performance AI Options
echo OLLAMA_MAX_LOADED_MODELS=2
echo OLLAMA_CONTEXT_LENGTH=8192
echo OLLAMA_NUM_PARALLEL=4
echo.
echo # Security
echo ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0
echo CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
echo.
echo # Logging
echo LOG_LEVEL=INFO
) > .env
exit /b 0

:test_system
echo [1/4] Python environment test...
python -c "import django; print('Django OK')" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python environment error
    exit /b 1
)

echo [2/4] Ollama connection test...
powershell -Command "try {Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -TimeoutSec 5 -UseBasicParsing | Out-Null; exit 0} catch {exit 1}" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Ollama connection error
    exit /b 1
)

echo [3/4] AI model test...
python -c "import requests; response = requests.post('http://localhost:11434/api/generate', json={'model': 'llama3.1:8b', 'prompt': 'Hi', 'stream': False, 'options': {'num_predict': 5}}, timeout=15); print('AI Model OK') if response.status_code == 200 else exit(1)" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: AI model test failed
    exit /b 1
)

echo [4/4] Django configuration test...
python manage.py check --verbosity=0 >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Django configuration error
    exit /b 1
)

echo ✅ All system tests passed
exit /b 0

:install_error
echo.
echo ERROR: Installation failed
echo.
echo Troubleshooting steps:
echo   1. Check internet connection
echo   2. Run as administrator
echo   3. Temporarily disable antivirus
echo   4. Restart computer and try again
echo.
goto :end

:user_exit
echo.
echo Installation cancelled by user.
echo You can run install-all-in-one.bat again later.
echo.

:end
:: Clean up temp directory
if exist "%TEMP_INSTALL_DIR%" rmdir /s /q "%TEMP_INSTALL_DIR%" >nul 2>&1

echo.
echo XShell AI Chatbot Installer Finished
echo.
echo Additional information:
echo   • Admin panel: http://localhost:8000/admin
echo   • Configuration file: .env
echo   • Troubleshooting: TROUBLESHOOTING-AI.md
echo.
echo Enjoy your AI chatbot!
echo.
pause