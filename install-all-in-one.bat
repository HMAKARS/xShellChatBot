@echo off
setlocal
chcp 65001 >nul
cls

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

set /p CONTINUE="Start environment setup? (Y/n): "
if /i "%CONTINUE%"=="n" (
    echo Setup cancelled.
    pause
    exit /b 0
)

:: Check admin rights
echo.
echo Checking admin rights...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Admin rights required.
    echo Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)
echo ✅ Admin rights confirmed

:: =================================================================
:: Step 1: Prerequisites Check
:: =================================================================
echo.
echo ========================================
echo Step 1: Prerequisites Check
echo ========================================

echo Checking Python installation...
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
    pause
    exit /b 1
)

echo ✅ Python found
python --version

echo.
echo Checking Ollama installation...
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
    pause
    exit /b 1
)

echo ✅ Ollama found
ollama --version

echo.
echo Checking Ollama service...
powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:11434/' -TimeoutSec 3 -UseBasicParsing | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ⚠️ WARNING: Ollama service is not running
    echo Starting Ollama service...
    start /min "Ollama Service" ollama serve
    
    echo Waiting for service to start... (10 seconds)
    timeout /t 10 /nobreak >nul
    
    powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:11434/' -TimeoutSec 5 -UseBasicParsing | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if %errorlevel% neq 0 (
        echo.
        echo ❌ ERROR: Could not start Ollama service
        echo Please run 'ollama serve' manually in another terminal
        echo.
        pause
        exit /b 1
    )
)

echo ✅ Ollama service is running

echo.
echo ✅ All prerequisites check passed
pause

:: =================================================================
:: Step 2: Python Virtual Environment Setup
:: =================================================================
echo.
echo ========================================
echo Step 2: Python Virtual Environment Setup
echo ========================================

if not exist .venv (
    echo Creating virtual environment...
    python -m venv .venv
    if %errorlevel% neq 0 (
        echo.
        echo ERROR: Virtual environment creation failed
        echo.
        pause
        exit /b 1
    )
    echo ✅ Virtual environment created
) else (
    echo ✅ Virtual environment already exists
)

echo.
echo Activating virtual environment...
call .venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Virtual environment activation failed
    echo.
    pause
    exit /b 1
)
echo ✅ Virtual environment activated

echo.
echo Upgrading pip...
python -m pip install --upgrade pip --quiet
echo ✅ pip upgraded

echo.
echo Python environment setup completed
pause

:: =================================================================
:: Step 3: Python Packages Installation
:: =================================================================
echo.
echo ========================================
echo Step 3: Python Packages Installation
echo ========================================

echo Installing required packages...

echo [1/8] Installing Django...
pip install Django==4.2.7 --quiet
if %errorlevel% equ 0 (
    echo ✅ Django installed
) else (
    echo ❌ Django installation failed
    set PACKAGE_ERRORS=1
)

echo [2/8] Installing CORS headers...
pip install django-cors-headers==4.3.1 --quiet
if %errorlevel% equ 0 (
    echo ✅ CORS headers installed
) else (
    echo ❌ CORS headers installation failed
    set PACKAGE_ERRORS=1
)

echo [3/8] Installing WebSocket support...
pip install channels==4.0.0 --quiet
if %errorlevel% equ 0 (
    echo ✅ WebSocket support installed
) else (
    echo ❌ WebSocket support installation failed
    set PACKAGE_ERRORS=1
)

echo [4/8] Installing HTTP client...
pip install requests==2.31.0 --quiet
if %errorlevel% equ 0 (
    echo ✅ HTTP client installed
) else (
    echo ❌ HTTP client installation failed
    set PACKAGE_ERRORS=1
)

echo [5/8] Installing environment variables support...
pip install python-dotenv==1.0.0 --quiet
if %errorlevel% equ 0 (
    echo ✅ Environment variables support installed
) else (
    echo ❌ Environment variables support installation failed
    set PACKAGE_ERRORS=1
)

echo [6/8] Installing ASGI server...
pip install daphne==4.0.0 --quiet
if %errorlevel% equ 0 (
    echo ✅ ASGI server installed
) else (
    echo ❌ ASGI server installation failed
    set PACKAGE_ERRORS=1
)

echo [7/8] Installing SSH support...
pip install paramiko==3.3.1 --quiet
if %errorlevel% equ 0 (
    echo ✅ SSH support installed
) else (
    echo ❌ SSH support installation failed
    set PACKAGE_ERRORS=1
)

echo [8/8] Installing Redis client...
pip install redis==5.0.1 --quiet
if %errorlevel% equ 0 (
    echo ✅ Redis client installed
) else (
    echo ❌ Redis client installation failed
    set PACKAGE_ERRORS=1
)

if defined PACKAGE_ERRORS (
    echo.
    echo ⚠️ Some packages failed to install
    set /p CONTINUE_ANYWAY="Continue anyway? (y/N): "
    if /i "%CONTINUE_ANYWAY%" neq "y" (
        echo Setup aborted
        pause
        exit /b 1
    )
)

echo.
echo ✅ Package installation completed
pause

:: =================================================================
:: Step 4: Environment Configuration
:: =================================================================
echo.
echo ========================================
echo Step 4: Environment Configuration
echo ========================================

if not exist .env (
    echo Creating .env configuration file...
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
) else (
    echo ✅ .env file already exists
)

echo.
echo Creating required directories...
if not exist logs mkdir logs
if not exist static mkdir static
if not exist templates mkdir templates
if not exist media mkdir media
echo ✅ Required directories created

echo.
echo Environment configuration completed
pause

:: =================================================================
:: Step 5: Database Setup
:: =================================================================
echo.
echo ========================================
echo Step 5: Database Setup
echo ========================================

echo Checking Django configuration...
python manage.py check --verbosity=0 >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Django configuration check failed
    echo Please check your Django settings
    echo.
    pause
    exit /b 1
)
echo ✅ Django configuration is valid

echo.
echo Creating database migrations...
python manage.py makemigrations --verbosity=0 >nul 2>&1
echo ✅ Migrations created

echo.
echo Applying database migrations...
python manage.py migrate --verbosity=0
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Database migration failed
    echo.
    pause
    exit /b 1
)
echo ✅ Database setup completed

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

echo Checking installed AI models...
ollama list

echo.
echo Checking for llama3.1:8b model...
ollama list | findstr "llama3.1:8b" >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ llama3.1:8b model not found
    set /p INSTALL_LLAMA="Install llama3.1:8b model now? (Y/n): "
    if /i "%INSTALL_LLAMA%" neq "n" (
        echo Installing llama3.1:8b model... (this may take 5-10 minutes)
        ollama pull llama3.1:8b
        if %errorlevel% equ 0 (
            echo ✅ llama3.1:8b model installed
        ) else (
            echo ❌ llama3.1:8b model installation failed
        )
    )
) else (
    echo ✅ llama3.1:8b model found
)

echo.
echo Checking for codellama:13b model...
ollama list | findstr "codellama:13b" >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ codellama:13b model not found
    set /p INSTALL_CODELLAMA="Install codellama:13b model now? (Y/n): "
    if /i "%INSTALL_CODELLAMA%" neq "n" (
        echo Installing codellama:13b model... (this may take 7-15 minutes)
        ollama pull codellama:13b
        if %errorlevel% equ 0 (
            echo ✅ codellama:13b model installed
        ) else (
            echo ❌ codellama:13b model installation failed
        )
    )
) else (
    echo ✅ codellama:13b model found
)

echo.
echo AI models check completed
pause

:: =================================================================
:: Step 7: System Testing
:: =================================================================
echo.
echo ========================================
echo Step 7: System Testing
echo ========================================

echo Testing system components...

echo [1/4] Testing Python environment...
python -c "import django; print('Django OK')" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python environment test failed
    set TEST_ERRORS=1
) else (
    echo ✅ Python environment test passed
)

echo [2/4] Testing Ollama connection...
powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -TimeoutSec 5 -UseBasicParsing | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Ollama connection test failed
    set TEST_ERRORS=1
) else (
    echo ✅ Ollama connection test passed
)

echo [3/4] Testing AI model...
python -c "import requests; response = requests.post('http://localhost:11434/api/generate', json={'model': 'llama3.1:8b', 'prompt': 'Hi', 'stream': False, 'options': {'num_predict': 5}}, timeout=15); print('AI Model OK') if response.status_code == 200 else exit(1)" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AI model test failed (model may not be installed)
    set TEST_ERRORS=1
) else (
    echo ✅ AI model test passed
)

echo [4/4] Testing Django configuration...
python manage.py check --verbosity=0 >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Django configuration test failed
    set TEST_ERRORS=1
) else (
    echo ✅ Django configuration test passed
)

if defined TEST_ERRORS (
    echo.
    echo ⚠️ Some tests failed, but you can still try to run the application
) else (
    echo.
    echo ✅ All system tests passed successfully!
)

echo.
echo System testing completed
pause

:: =================================================================
:: Step 8: Setup Complete
:: =================================================================
echo.
echo ========================================
echo Step 8: Setup Complete!
echo ========================================
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

set /p START_SERVER="Start the Django server now? (Y/n): "
if /i "%START_SERVER%"=="n" (
    echo.
    echo To start the server manually:
    echo   1. Activate virtual environment: .venv\Scripts\activate
    echo   2. Start server: python manage.py runserver 0.0.0.0:8000
    echo   3. Open browser: http://localhost:8000
    echo.
    goto :end
)

echo.
echo Starting Django development server...
echo.
echo The server will start in 3 seconds...
echo You can access the application at: http://localhost:8000
echo Press Ctrl+C to stop the server
echo.

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
echo.
echo Configuration files:
echo   • Environment: .env
echo   • Database: db.sqlite3
echo.
echo Thank you for using XShell AI Chatbot!
echo.
pause