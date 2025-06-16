@echo off
setlocal
chcp 65001 >nul
cls

:: Setup logging
set LOG_FILE=%~dp0install.log
echo ================================================== > "%LOG_FILE%"
echo XShell AI Chatbot Environment Setup Log >> "%LOG_FILE%"
echo Started: %date% %time% >> "%LOG_FILE%"
echo ================================================== >> "%LOG_FILE%"

echo.
echo 🚀 XShell AI Chatbot Environment Setup
echo =====================================
echo.
echo This script will setup:
echo   • Python Virtual Environment
echo   • Required Python Packages
echo   • Environment Configuration Files
echo   • Database Setup
echo   • System Testing
echo.
echo Prerequisites (must be installed first):
echo   • Python 3.11+ with PATH configured
echo   • Ollama AI Engine running
echo.
echo 📝 Installation log: %LOG_FILE%
echo.

echo [%date% %time%] Setup started >> "%LOG_FILE%"

set /p CONTINUE="Start environment setup? (Y/n): "
if /i "%CONTINUE%"=="n" (
    echo Setup cancelled.
    echo [%date% %time%] Setup cancelled by user >> "%LOG_FILE%"
    pause
    exit /b 0
)

:: Check admin rights
echo.
echo Checking admin rights...
echo [%date% %time%] Checking admin rights... >> "%LOG_FILE%"
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Admin rights required.
    echo Right-click this file and select "Run as administrator"
    echo.
    echo [%date% %time%] ERROR: Admin rights required >> "%LOG_FILE%"
    pause
    exit /b 1
)
echo ✅ Admin rights confirmed
echo [%date% %time%] Admin rights confirmed >> "%LOG_FILE%"

:: =================================================================
:: Step 1: Prerequisites Check
:: =================================================================
echo.
echo ========================================
echo Step 1: Prerequisites Check
echo ========================================
echo [%date% %time%] Step 1: Prerequisites Check started >> "%LOG_FILE%"

echo Checking Python installation...
echo [%date% %time%] Checking Python installation... >> "%LOG_FILE%"
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ❌ ERROR: Python is not installed or not in PATH
    echo.
    echo Please install Python 3.11+ first:
    echo   1. Download from: https://python.org/downloads/
    echo   2. Make sure to check "Add Python to PATH" during installation
    echo   3. Restart this script after Python installation
    echo.
    echo [%date% %time%] ERROR: Python not found >> "%LOG_FILE%"
    pause
    exit /b 1
)

echo ✅ Python found
for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo %PYTHON_VERSION%
echo [%date% %time%] Python found: %PYTHON_VERSION% >> "%LOG_FILE%"

echo.
echo Checking Ollama installation...
echo [%date% %time%] Checking Ollama installation... >> "%LOG_FILE%"
ollama --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ❌ ERROR: Ollama is not installed or not in PATH
    echo.
    echo Please install Ollama first:
    echo   1. Download from: https://ollama.com/download
    echo   2. Install and make sure it's in PATH
    echo   3. Restart this script after Ollama installation
    echo.
    echo [%date% %time%] ERROR: Ollama not found >> "%LOG_FILE%"
    pause
    exit /b 1
)

echo ✅ Ollama found
for /f "tokens=*" %%i in ('ollama --version 2^>^&1') do set OLLAMA_VERSION=%%i
echo %OLLAMA_VERSION%
echo [%date% %time%] Ollama found: %OLLAMA_VERSION% >> "%LOG_FILE%"

echo.
echo Checking Ollama service...
echo [%date% %time%] Checking Ollama service... >> "%LOG_FILE%"
powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:11434/' -TimeoutSec 3 -UseBasicParsing | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ⚠️ WARNING: Ollama service is not running
    echo Starting Ollama service...
    echo [%date% %time%] WARNING: Ollama service not running, attempting to start... >> "%LOG_FILE%"
    start /min "Ollama Service" ollama serve
    
    echo Waiting for service to start... (10 seconds)
    timeout /t 10 /nobreak >nul
    
    powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:11434/' -TimeoutSec 5 -UseBasicParsing | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if %errorlevel% neq 0 (
        echo.
        echo ❌ ERROR: Could not start Ollama service
        echo Please run 'ollama serve' manually in another terminal
        echo.
        echo [%date% %time%] ERROR: Could not start Ollama service >> "%LOG_FILE%"
        pause
        exit /b 1
    )
    echo [%date% %time%] Ollama service started successfully >> "%LOG_FILE%"
)

echo ✅ Ollama service is running
echo [%date% %time%] Ollama service confirmed running >> "%LOG_FILE%"

echo.
echo ✅ All prerequisites check passed
echo [%date% %time%] All prerequisites check passed >> "%LOG_FILE%"
pause

:: =================================================================
:: Step 2: Python Virtual Environment Setup
:: =================================================================
echo.
echo ========================================
echo Step 2: Python Virtual Environment Setup
echo ========================================
echo [%date% %time%] Step 2: Python Virtual Environment Setup started >> "%LOG_FILE%"

if not exist .venv (
    echo Creating virtual environment...
    echo [%date% %time%] Creating virtual environment... >> "%LOG_FILE%"
    python -m venv .venv >> "%LOG_FILE%" 2>&1
    if %errorlevel% neq 0 (
        echo.
        echo ERROR: Virtual environment creation failed
        echo.
        echo [%date% %time%] ERROR: Virtual environment creation failed >> "%LOG_FILE%"
        pause
        exit /b 1
    )
    echo ✅ Virtual environment created
    echo [%date% %time%] Virtual environment created successfully >> "%LOG_FILE%"
) else (
    echo ✅ Virtual environment already exists
    echo [%date% %time%] Virtual environment already exists >> "%LOG_FILE%"
)

echo.
echo Activating virtual environment...
echo [%date% %time%] Activating virtual environment... >> "%LOG_FILE%"
call .venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Virtual environment activation failed
    echo.
    echo [%date% %time%] ERROR: Virtual environment activation failed >> "%LOG_FILE%"
    pause
    exit /b 1
)
echo ✅ Virtual environment activated
echo [%date% %time%] Virtual environment activated successfully >> "%LOG_FILE%"

echo.
echo Upgrading pip...
echo [%date% %time%] Upgrading pip... >> "%LOG_FILE%"
python -m pip install --upgrade pip --quiet >> "%LOG_FILE%" 2>&1
echo ✅ pip upgraded
echo [%date% %time%] pip upgraded successfully >> "%LOG_FILE%"

echo.
echo Python environment setup completed
echo [%date% %time%] Python environment setup completed >> "%LOG_FILE%"
pause

:: =================================================================
:: Step 3: Python Packages Installation
:: =================================================================
echo.
echo ========================================
echo Step 3: Python Packages Installation
echo ========================================
echo [%date% %time%] Step 3: Python Packages Installation started >> "%LOG_FILE%"

echo Installing required packages...

echo [1/8] Installing Django...
echo [%date% %time%] Installing Django... >> "%LOG_FILE%"
pip install Django==4.2.7 --quiet >> "%LOG_FILE%" 2>&1
if %errorlevel% equ 0 (
    echo ✅ Django installed
    echo [%date% %time%] Django installed successfully >> "%LOG_FILE%"
) else (
    echo ❌ Django installation failed
    echo [%date% %time%] ERROR: Django installation failed >> "%LOG_FILE%"
    set PACKAGE_ERRORS=1
)

echo [2/8] Installing CORS headers...
echo [%date% %time%] Installing CORS headers... >> "%LOG_FILE%"
pip install django-cors-headers==4.3.1 --quiet >> "%LOG_FILE%" 2>&1
if %errorlevel% equ 0 (
    echo ✅ CORS headers installed
    echo [%date% %time%] CORS headers installed successfully >> "%LOG_FILE%"
) else (
    echo ❌ CORS headers installation failed
    echo [%date% %time%] ERROR: CORS headers installation failed >> "%LOG_FILE%"
    set PACKAGE_ERRORS=1
)

echo [3/8] Installing WebSocket support...
echo [%date% %time%] Installing WebSocket support... >> "%LOG_FILE%"
pip install channels==4.0.0 --quiet >> "%LOG_FILE%" 2>&1
if %errorlevel% equ 0 (
    echo ✅ WebSocket support installed
    echo [%date% %time%] WebSocket support installed successfully >> "%LOG_FILE%"
) else (
    echo ❌ WebSocket support installation failed
    echo [%date% %time%] ERROR: WebSocket support installation failed >> "%LOG_FILE%"
    set PACKAGE_ERRORS=1
)

echo [4/8] Installing HTTP client...
echo [%date% %time%] Installing HTTP client... >> "%LOG_FILE%"
pip install requests==2.31.0 --quiet >> "%LOG_FILE%" 2>&1
if %errorlevel% equ 0 (
    echo ✅ HTTP client installed
    echo [%date% %time%] HTTP client installed successfully >> "%LOG_FILE%"
) else (
    echo ❌ HTTP client installation failed
    echo [%date% %time%] ERROR: HTTP client installation failed >> "%LOG_FILE%"
    set PACKAGE_ERRORS=1
)

echo [5/8] Installing environment variables support...
echo [%date% %time%] Installing environment variables support... >> "%LOG_FILE%"
pip install python-dotenv==1.0.0 --quiet >> "%LOG_FILE%" 2>&1
if %errorlevel% equ 0 (
    echo ✅ Environment variables support installed
    echo [%date% %time%] Environment variables support installed successfully >> "%LOG_FILE%"
) else (
    echo ❌ Environment variables support installation failed
    echo [%date% %time%] ERROR: Environment variables support installation failed >> "%LOG_FILE%"
    set PACKAGE_ERRORS=1
)

echo [6/8] Installing ASGI server...
echo [%date% %time%] Installing ASGI server... >> "%LOG_FILE%"
pip install daphne==4.0.0 --quiet >> "%LOG_FILE%" 2>&1
if %errorlevel% equ 0 (
    echo ✅ ASGI server installed
    echo [%date% %time%] ASGI server installed successfully >> "%LOG_FILE%"
) else (
    echo ❌ ASGI server installation failed
    echo [%date% %time%] ERROR: ASGI server installation failed >> "%LOG_FILE%"
    set PACKAGE_ERRORS=1
)

echo [7/8] Installing SSH support...
echo [%date% %time%] Installing SSH support... >> "%LOG_FILE%"
pip install paramiko==3.3.1 --quiet >> "%LOG_FILE%" 2>&1
if %errorlevel% equ 0 (
    echo ✅ SSH support installed
    echo [%date% %time%] SSH support installed successfully >> "%LOG_FILE%"
) else (
    echo ❌ SSH support installation failed
    echo [%date% %time%] ERROR: SSH support installation failed >> "%LOG_FILE%"
    set PACKAGE_ERRORS=1
)

echo [8/8] Installing Redis client...
echo [%date% %time%] Installing Redis client... >> "%LOG_FILE%"
pip install redis==5.0.1 --quiet >> "%LOG_FILE%" 2>&1
if %errorlevel% equ 0 (
    echo ✅ Redis client installed
    echo [%date% %time%] Redis client installed successfully >> "%LOG_FILE%"
) else (
    echo ❌ Redis client installation failed
    echo [%date% %time%] ERROR: Redis client installation failed >> "%LOG_FILE%"
    set PACKAGE_ERRORS=1
)

if defined PACKAGE_ERRORS (
    echo.
    echo ⚠️ Some packages failed to install
    echo [%date% %time%] WARNING: Some packages failed to install >> "%LOG_FILE%"
    set /p CONTINUE_ANYWAY="Continue anyway? (y/N): "
    if /i "%CONTINUE_ANYWAY%" neq "y" (
        echo Setup aborted
        echo [%date% %time%] Setup aborted by user due to package errors >> "%LOG_FILE%"
        pause
        exit /b 1
    )
    echo [%date% %time%] User chose to continue despite package errors >> "%LOG_FILE%"
)

echo.
echo ✅ Package installation completed
echo [%date% %time%] Package installation completed >> "%LOG_FILE%"
pause

:: =================================================================
:: Step 4: Environment Configuration
:: =================================================================
echo.
echo ========================================
echo Step 4: Environment Configuration
echo ========================================
echo [%date% %time%] Step 4: Environment Configuration started >> "%LOG_FILE%"

if not exist .env (
    echo Creating .env configuration file...
    echo [%date% %time%] Creating .env configuration file... >> "%LOG_FILE%"
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
    echo ✅ .env file created
    echo [%date% %time%] .env file created successfully >> "%LOG_FILE%"
) else (
    echo ✅ .env file already exists
    echo [%date% %time%] .env file already exists >> "%LOG_FILE%"
)

echo.
echo Creating required directories...
echo [%date% %time%] Creating required directories... >> "%LOG_FILE%"
if not exist logs mkdir logs
if not exist static mkdir static
if not exist templates mkdir templates
if not exist media mkdir media
echo ✅ Required directories created
echo [%date% %time%] Required directories created successfully >> "%LOG_FILE%"

echo.
echo Environment configuration completed
echo [%date% %time%] Environment configuration completed >> "%LOG_FILE%"
pause

:: =================================================================
:: Step 5: Database Setup
:: =================================================================
echo.
echo ========================================
echo Step 5: Database Setup
echo ========================================
echo [%date% %time%] Step 5: Database Setup started >> "%LOG_FILE%"

echo Checking Django configuration...
echo [%date% %time%] Checking Django configuration... >> "%LOG_FILE%"
python manage.py check --verbosity=0 >> "%LOG_FILE%" 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Django configuration check failed
    echo Please check your Django settings
    echo.
    echo [%date% %time%] ERROR: Django configuration check failed >> "%LOG_FILE%"
    pause
    exit /b 1
)
echo ✅ Django configuration is valid
echo [%date% %time%] Django configuration is valid >> "%LOG_FILE%"

echo.
echo Creating database migrations...
echo [%date% %time%] Creating database migrations... >> "%LOG_FILE%"
python manage.py makemigrations --verbosity=0 >> "%LOG_FILE%" 2>&1
echo ✅ Migrations created
echo [%date% %time%] Migrations created successfully >> "%LOG_FILE%"

echo.
echo Applying database migrations...
echo [%date% %time%] Applying database migrations... >> "%LOG_FILE%"
python manage.py migrate --verbosity=0 >> "%LOG_FILE%" 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Database migration failed
    echo.
    echo [%date% %time%] ERROR: Database migration failed >> "%LOG_FILE%"
    pause
    exit /b 1
)
echo ✅ Database setup completed
echo [%date% %time%] Database setup completed successfully >> "%LOG_FILE%"

echo.
echo Database setup completed
pause

:: =================================================================
:: Step 6: AI Models Check
:: =================================================================
echo.
echo ========================================
echo Step 6: AI Models Check
echo ========================================
echo [%date% %time%] Step 6: AI Models Check started >> "%LOG_FILE%"

echo Checking installed AI models...
echo [%date% %time%] Checking installed AI models... >> "%LOG_FILE%"
ollama list >> "%LOG_FILE%" 2>&1
ollama list

echo.
echo Checking for llama3.1:8b model...
echo [%date% %time%] Checking for llama3.1:8b model... >> "%LOG_FILE%"
ollama list | findstr "llama3.1:8b" >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ llama3.1:8b model not found
    echo [%date% %time%] llama3.1:8b model not found >> "%LOG_FILE%"
    set /p INSTALL_LLAMA="Install llama3.1:8b model now? (Y/n): "
    if /i "%INSTALL_LLAMA%" neq "n" (
        echo Installing llama3.1:8b model... (this may take 5-10 minutes)
        echo [%date% %time%] Installing llama3.1:8b model... >> "%LOG_FILE%"
        ollama pull llama3.1:8b >> "%LOG_FILE%" 2>&1
        if %errorlevel% equ 0 (
            echo ✅ llama3.1:8b model installed
            echo [%date% %time%] llama3.1:8b model installed successfully >> "%LOG_FILE%"
        ) else (
            echo ❌ llama3.1:8b model installation failed
            echo [%date% %time%] ERROR: llama3.1:8b model installation failed >> "%LOG_FILE%"
        )
    ) else (
        echo [%date% %time%] User skipped llama3.1:8b model installation >> "%LOG_FILE%"
    )
) else (
    echo ✅ llama3.1:8b model found
    echo [%date% %time%] llama3.1:8b model found >> "%LOG_FILE%"
)

echo.
echo Checking for codellama:13b model...
echo [%date% %time%] Checking for codellama:13b model... >> "%LOG_FILE%"
ollama list | findstr "codellama:13b" >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ codellama:13b model not found
    echo [%date% %time%] codellama:13b model not found >> "%LOG_FILE%"
    set /p INSTALL_CODELLAMA="Install codellama:13b model now? (Y/n): "
    if /i "%INSTALL_CODELLAMA%" neq "n" (
        echo Installing codellama:13b model... (this may take 7-15 minutes)
        echo [%date% %time%] Installing codellama:13b model... >> "%LOG_FILE%"
        ollama pull codellama:13b >> "%LOG_FILE%" 2>&1
        if %errorlevel% equ 0 (
            echo ✅ codellama:13b model installed
            echo [%date% %time%] codellama:13b model installed successfully >> "%LOG_FILE%"
        ) else (
            echo ❌ codellama:13b model installation failed
            echo [%date% %time%] ERROR: codellama:13b model installation failed >> "%LOG_FILE%"
        )
    ) else (
        echo [%date% %time%] User skipped codellama:13b model installation >> "%LOG_FILE%"
    )
) else (
    echo ✅ codellama:13b model found
    echo [%date% %time%] codellama:13b model found >> "%LOG_FILE%"
)

echo.
echo AI models check completed
echo [%date% %time%] AI models check completed >> "%LOG_FILE%"
pause

:: =================================================================
:: Step 7: System Testing
:: =================================================================
echo.
echo ========================================
echo Step 7: System Testing
echo ========================================
echo [%date% %time%] Step 7: System Testing started >> "%LOG_FILE%"

echo Testing system components...

echo [1/4] Testing Python environment...
echo [%date% %time%] Testing Python environment... >> "%LOG_FILE%"
python -c "import django; print('Django OK')" >> "%LOG_FILE%" 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python environment test failed
    echo [%date% %time%] ERROR: Python environment test failed >> "%LOG_FILE%"
    set TEST_ERRORS=1
) else (
    echo ✅ Python environment test passed
    echo [%date% %time%] Python environment test passed >> "%LOG_FILE%"
)

echo [2/4] Testing Ollama connection...
echo [%date% %time%] Testing Ollama connection... >> "%LOG_FILE%"
powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -TimeoutSec 5 -UseBasicParsing | Out-Null; exit 0 } catch { exit 1 }" >> "%LOG_FILE%" 2>&1
if %errorlevel% neq 0 (
    echo ❌ Ollama connection test failed
    echo [%date% %time%] ERROR: Ollama connection test failed >> "%LOG_FILE%"
    set TEST_ERRORS=1
) else (
    echo ✅ Ollama connection test passed
    echo [%date% %time%] Ollama connection test passed >> "%LOG_FILE%"
)

echo [3/4] Testing AI model...
echo [%date% %time%] Testing AI model... >> "%LOG_FILE%"
python -c "import requests; response = requests.post('http://localhost:11434/api/generate', json={'model': 'llama3.1:8b', 'prompt': 'Hi', 'stream': False, 'options': {'num_predict': 5}}, timeout=15); print('AI Model OK') if response.status_code == 200 else exit(1)" >> "%LOG_FILE%" 2>&1
if %errorlevel% neq 0 (
    echo ❌ AI model test failed (model may not be installed)
    echo [%date% %time%] ERROR: AI model test failed >> "%LOG_FILE%"
    set TEST_ERRORS=1
) else (
    echo ✅ AI model test passed
    echo [%date% %time%] AI model test passed >> "%LOG_FILE%"
)

echo [4/4] Testing Django configuration...
echo [%date% %time%] Testing Django configuration... >> "%LOG_FILE%"
python manage.py check --verbosity=0 >> "%LOG_FILE%" 2>&1
if %errorlevel% neq 0 (
    echo ❌ Django configuration test failed
    echo [%date% %time%] ERROR: Django configuration test failed >> "%LOG_FILE%"
    set TEST_ERRORS=1
) else (
    echo ✅ Django configuration test passed
    echo [%date% %time%] Django configuration test passed >> "%LOG_FILE%"
)

if defined TEST_ERRORS (
    echo.
    echo ⚠️ Some tests failed, but you can still try to run the application
    echo [%date% %time%] WARNING: Some tests failed >> "%LOG_FILE%"
) else (
    echo.
    echo ✅ All system tests passed successfully!
    echo [%date% %time%] All system tests passed successfully >> "%LOG_FILE%"
)

echo.
echo System testing completed
echo [%date% %time%] System testing completed >> "%LOG_FILE%"
pause

:: =================================================================
:: Step 8: Setup Complete
:: =================================================================
echo.
echo ========================================
echo Step 8: Setup Complete!
echo ========================================
echo [%date% %time%] Step 8: Setup Complete >> "%LOG_FILE%"

echo.
echo ✅ Environment setup completed successfully!
echo.
echo Installed components:
echo   • Python Virtual Environment
echo   • Django Web Framework
echo   • All Required Python Packages
echo   • Environment Configuration Files
echo   • Database (SQLite)
echo.
echo Next steps:
echo   1. Make sure Ollama service is running: ollama serve
echo   2. Install AI models if not done yet:
echo      - ollama pull llama3.1:8b
echo      - ollama pull codellama:13b
echo   3. Start the application: python manage.py runserver
echo.
echo 📝 Installation log saved to: %LOG_FILE%
echo 📋 To view log: type "view-log.bat" or "notepad %LOG_FILE%"
echo.

echo [%date% %time%] Setup completed successfully >> "%LOG_FILE%"

set /p START_SERVER="Start the Django server now? (Y/n): "
if /i "%START_SERVER%"=="n" (
    echo.
    echo To start the server manually:
    echo   1. Activate virtual environment: .venv\Scripts\activate
    echo   2. Start server: python manage.py runserver 0.0.0.0:8000
    echo   3. Open browser: http://localhost:8000
    echo.
    echo [%date% %time%] User chose manual server start >> "%LOG_FILE%"
    goto :end
)

echo.
echo Starting Django development server...
echo.
echo The server will start in 3 seconds...
echo You can access the application at: http://localhost:8000
echo Press Ctrl+C to stop the server
echo.

echo [%date% %time%] Starting Django development server >> "%LOG_FILE%"
timeout /t 3 /nobreak >nul

:: Open browser after 3 seconds
start "" cmd /c "timeout /t 3 /nobreak >nul && start http://localhost:8000"

:: Start Django server
python manage.py runserver 0.0.0.0:8000

:end
echo.
echo ==========================================
echo XShell AI Chatbot Setup Finished
echo ==========================================
echo.
echo Useful commands:
echo   • Start server: python manage.py runserver 0.0.0.0:8000
echo   • Activate virtual env: .venv\Scripts\activate
echo   • Check Ollama: ollama list
echo   • Start Ollama: ollama serve
echo   • View installation log: view-log.bat
echo.
echo Configuration files:
echo   • Environment: .env
echo   • Database: db.sqlite3
echo   • Installation log: %LOG_FILE%
echo.
echo Thank you for using XShell AI Chatbot!
echo.

echo [%date% %time%] Setup script finished >> "%LOG_FILE%"
pause