@echo off
setlocal
chcp 65001 >nul
cls

echo.
echo 🚀 XShell AI Chatbot All-in-One Installer
echo ==========================================
echo.
echo Installing components:
echo   • Ollama AI Engine + Models
echo   • Django Web Server + WebSocket
echo   • XShell Integration + All Config Files
echo.
echo Prerequisites: Python 3.11+ must be installed
echo Estimated time: 10-20 minutes
echo Required disk space: about 12GB
echo.

set /p CONTINUE="Start installation? (Y/n): "
if /i "%CONTINUE%"=="n" (
    echo Installation cancelled.
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

:: Set variables
set SCRIPT_PATH=%~dp0
set TEMP_DIR=%SCRIPT_PATH%temp_install
echo.
echo Script location: %SCRIPT_PATH%
echo Temp directory: %TEMP_DIR%

:: Create temp directory
if not exist "%TEMP_DIR%" (
    mkdir "%TEMP_DIR%"
    echo ✅ Temp directory created
)

:: =================================================================
:: Step 1: Python Check
:: =================================================================
echo.
echo ========================================
echo Step 1: Python Environment Check
echo ========================================

echo Checking for Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ❌ ERROR: Python is not installed or not in PATH
    echo.
    echo Please install Python 3.11+ first:
    echo   1. See PYTHON-INSTALL-GUIDE.md for detailed instructions
    echo   2. Or download from: https://python.org/downloads/
    echo   3. Make sure to check "Add Python to PATH" during installation
    echo   4. Restart this installer after Python installation
    echo.
    pause
    goto :cleanup_and_exit
)

echo ✅ Python found and working
echo.
echo Python version:
python --version

echo.
echo Checking system memory...
powershell -Command "try { $mem = Get-WmiObject -Class Win32_ComputerSystem; $memGB = [math]::Round($mem.TotalPhysicalMemory / 1GB, 2); Write-Host 'System Memory:' $memGB 'GB' } catch { Write-Host 'Memory check failed' }"

echo ✅ System check completed
pause

:: =================================================================
:: Step 2: Ollama Installation
:: =================================================================
echo.
echo ========================================
echo Step 2: Ollama AI Engine Installation
echo ========================================

echo Checking for Ollama...
ollama --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Ollama not found. Installing Ollama...
    
    set OLLAMA_FILE=%TEMP_DIR%\OllamaSetup.exe
    
    echo.
    echo Downloading Ollama installer...
    powershell -Command "try { Invoke-WebRequest -Uri 'https://github.com/ollama/ollama/releases/latest/download/OllamaSetup.exe' -OutFile '%OLLAMA_FILE%'; Write-Host 'Download completed' } catch { Write-Host 'Download failed:' $_.Exception.Message; exit 1 }"
    
    if not exist "%OLLAMA_FILE%" (
        echo.
        echo ERROR: Ollama download failed
        echo Please download manually from https://ollama.com/download
        echo.
        pause
        goto :cleanup_and_exit
    )
    
    echo.
    echo Installing Ollama... (this may take 2-5 minutes)
    "%OLLAMA_FILE%" /S
    set INSTALL_RESULT=%errorlevel%
    
    echo.
    echo Cleaning up installer...
    if exist "%OLLAMA_FILE%" del "%OLLAMA_FILE%" >nul 2>&1
    
    if %INSTALL_RESULT% neq 0 (
        echo.
        echo ERROR: Ollama installation failed with code %INSTALL_RESULT%
        echo.
        pause
        goto :cleanup_and_exit
    )
    
    echo.
    echo Waiting for Ollama service... (30 seconds)
    timeout /t 30 /nobreak >nul
    
    echo.
    echo Testing Ollama installation...
    ollama --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo.
        echo ERROR: Ollama installation failed
        echo Please restart your computer and try again
        echo.
        pause
        goto :cleanup_and_exit
    )
    
    echo ✅ Ollama installation completed successfully
) else (
    echo ✅ Ollama already installed
)

echo.
echo Ollama version:
ollama --version

echo.
echo Starting Ollama service...
taskkill /f /im ollama.exe >nul 2>&1
start /min "Ollama Service" ollama serve

echo.
echo Waiting for service to start... (15 seconds)
timeout /t 15 /nobreak >nul

echo.
echo Testing Ollama connection...
set OLLAMA_OK=0
for /l %%i in (1,1,5) do (
    echo Connection attempt %%i/5...
    powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:11434/' -TimeoutSec 5 -UseBasicParsing | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ Ollama service is running properly
        set OLLAMA_OK=1
        goto :ollama_ready
    )
    timeout /t 3 /nobreak >nul
)

if %OLLAMA_OK% equ 0 (
    echo.
    echo ERROR: Ollama service failed to start
    echo Please run 'ollama serve' manually in another terminal
    echo.
    pause
    goto :cleanup_and_exit
)

:ollama_ready
echo.
echo Ollama setup completed successfully
pause

:: =================================================================
:: Step 3: AI Models Installation
:: =================================================================
echo.
echo ========================================
echo Step 3: AI Models Installation
echo ========================================
echo.
echo Installing high-performance AI models:
echo   • llama3.1:8b (4.7GB) - General conversation
echo   • codellama:13b (7GB) - Code analysis
echo.

set MODEL_COUNT=0

echo [1/2] Installing llama3.1:8b model (about 4.7GB)...
ollama list 2>nul | findstr "llama3.1:8b" >nul 2>&1
if %errorlevel% neq 0 (
    echo Download starting... (5-10 minutes expected)
    ollama pull llama3.1:8b
    if %errorlevel% equ 0 (
        echo ✅ llama3.1:8b installation completed
        set /a MODEL_COUNT+=1
    ) else (
        echo ❌ llama3.1:8b installation failed
    )
) else (
    echo ✅ llama3.1:8b already installed
    set /a MODEL_COUNT+=1
)

echo.
echo [2/2] Installing codellama:13b model (about 7GB)...
ollama list 2>nul | findstr "codellama:13b" >nul 2>&1
if %errorlevel% neq 0 (
    echo Download starting... (7-15 minutes expected)
    ollama pull codellama:13b
    if %errorlevel% equ 0 (
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
echo AI Models installation result: %MODEL_COUNT% models installed successfully
echo.
echo Current installed models:
ollama list

echo.
echo AI models setup completed
pause

:: =================================================================
:: Step 4: Python Environment Setup
:: =================================================================
echo.
echo ========================================
echo Step 4: Python Environment Setup
echo ========================================

:: Upgrade pip first
echo.
echo Upgrading pip...
python -m pip install --upgrade pip --quiet
if %errorlevel% neq 0 (
    echo Warning: pip upgrade failed, continuing anyway...
) else (
    echo ✅ pip upgrade completed
)

:: Create virtual environment
if not exist .venv (
    echo Creating virtual environment...
    python -m venv .venv
    if %errorlevel% neq 0 (
        echo.
        echo ERROR: Virtual environment creation failed
        echo.
        pause
        goto :cleanup_and_exit
    )
    echo ✅ Virtual environment created successfully
) else (
    echo ✅ Virtual environment already exists
)

:: Activate virtual environment
echo.
echo Activating virtual environment...
call .venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Virtual environment activation failed
    echo.
    pause
    goto :cleanup_and_exit
)
echo ✅ Virtual environment activated successfully

:: Install packages
echo.
echo Installing Python packages...

if exist requirements-minimal.txt (
    echo Trying minimal packages first...
    pip install -r requirements-minimal.txt --quiet
    if %errorlevel% equ 0 (
        echo ✅ Minimal packages installed successfully
        goto :packages_done
    )
)

if exist requirements-windows.txt (
    echo Trying Windows-specific packages...
    pip install -r requirements-windows.txt --quiet
    if %errorlevel% equ 0 (
        echo ✅ Windows packages installed successfully
        goto :packages_done
    )
)

echo Installing core packages individually...
set PACKAGE_COUNT=0

echo [1/8] Installing Django...
pip install Django==4.2.7 --quiet
if %errorlevel% equ 0 (
    set /a PACKAGE_COUNT+=1
    echo ✅ Django installed
) else (
    echo ❌ Django installation failed
)

echo [2/8] Installing CORS headers...
pip install django-cors-headers==4.3.1 --quiet
if %errorlevel% equ 0 (
    set /a PACKAGE_COUNT+=1
    echo ✅ CORS headers installed
) else (
    echo ❌ CORS headers installation failed
)

echo [3/8] Installing WebSocket support...
pip install channels==4.0.0 --quiet
if %errorlevel% equ 0 (
    set /a PACKAGE_COUNT+=1
    echo ✅ WebSocket support installed
) else (
    echo ❌ WebSocket support installation failed
)

echo [4/8] Installing HTTP client...
pip install requests==2.31.0 --quiet
if %errorlevel% equ 0 (
    set /a PACKAGE_COUNT+=1
    echo ✅ HTTP client installed
) else (
    echo ❌ HTTP client installation failed
)

echo [5/8] Installing environment variables support...
pip install python-dotenv==1.0.0 --quiet
if %errorlevel% equ 0 (
    set /a PACKAGE_COUNT+=1
    echo ✅ Environment variables support installed
) else (
    echo ❌ Environment variables support installation failed
)

echo [6/8] Installing ASGI server...
pip install daphne==4.0.0 --quiet
if %errorlevel% equ 0 (
    set /a PACKAGE_COUNT+=1
    echo ✅ ASGI server installed
) else (
    echo ❌ ASGI server installation failed
)

echo [7/8] Installing SSH support...
pip install paramiko==3.3.1 --quiet
if %errorlevel% equ 0 (
    set /a PACKAGE_COUNT+=1
    echo ✅ SSH support installed
) else (
    echo ❌ SSH support installation failed
)

echo [8/8] Installing Redis client...
pip install redis==5.0.1 --quiet
if %errorlevel% equ 0 (
    set /a PACKAGE_COUNT+=1
    echo ✅ Redis client installed
) else (
    echo ❌ Redis client installation failed
)

echo.
echo Individual package installation result: %PACKAGE_COUNT%/8 successful

:packages_done
echo.
echo Python environment setup completed
pause

:: =================================================================
:: Step 5: Configuration Files
:: =================================================================
echo.
echo ========================================
echo Step 5: Configuration Files Setup
echo ========================================

if not exist .env (
    if exist .env.example (
        echo Creating .env file from template...
        copy .env.example .env >nul
        echo ✅ .env file created from template
    ) else (
        echo Creating new .env file...
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
        echo ✅ New .env file created
    )
) else (
    echo ✅ .env file already exists
)

echo.
echo Configuration files setup completed
pause

:: =================================================================
:: Step 6: Database Setup
:: =================================================================
echo.
echo ========================================
echo Step 6: Database Setup
echo ========================================

echo Creating required directories...
if not exist logs mkdir logs
if not exist static mkdir static
if not exist templates mkdir templates
if not exist media mkdir media
echo ✅ Required directories created

echo.
echo Setting up database...
python manage.py check --verbosity=0 >nul 2>&1
python manage.py makemigrations --verbosity=0 >nul 2>&1
python manage.py migrate --verbosity=0
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Database setup failed
    echo.
    pause
    goto :cleanup_and_exit
)
echo ✅ Database setup completed successfully

echo.
echo Database setup completed
pause

:: =================================================================
:: Step 7: System Test
:: =================================================================
echo.
echo ========================================
echo Step 7: System Test
echo ========================================

echo Testing complete system...

echo [1/4] Testing Python environment...
python -c "import django; print('Django OK')" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python environment test failed
    goto :test_failed
) else (
    echo ✅ Python environment test passed
)

echo [2/4] Testing Ollama connection...
powershell -Command "try { Invoke-WebRequest -Uri 'http://localhost:11434/api/tags' -TimeoutSec 5 -UseBasicParsing | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Ollama connection test failed
    goto :test_failed
) else (
    echo ✅ Ollama connection test passed
)

echo [3/4] Testing AI model...
python -c "import requests; response = requests.post('http://localhost:11434/api/generate', json={'model': 'llama3.1:8b', 'prompt': 'Hi', 'stream': False, 'options': {'num_predict': 5}}, timeout=15); print('AI Model OK') if response.status_code == 200 else exit(1)" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AI model test failed
    goto :test_failed
) else (
    echo ✅ AI model test passed
)

echo [4/4] Testing Django configuration...
python manage.py check --verbosity=0 >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Django configuration test failed
    goto :test_failed
) else (
    echo ✅ Django configuration test passed
)

echo.
echo ✅ All system tests passed successfully!
goto :test_passed

:test_failed
echo.
echo ❌ Some system tests failed
set /p CONTINUE_ANYWAY="Do you want to continue anyway? (y/N): "
if /i "%CONTINUE_ANYWAY%" neq "y" (
    echo.
    echo Installation aborted by user
    echo.
    pause
    goto :cleanup_and_exit
)

:test_passed
echo.
echo System test completed
pause

:: =================================================================
:: Step 8: Installation Complete
:: =================================================================
echo.
echo ========================================
echo Step 8: Installation Complete!
echo ========================================
echo.
echo ✅ Successfully installed components:
echo   • Django Web Framework
echo   • Ollama AI Engine
echo   • AI Models: llama3.1:8b, codellama:13b
echo   • WebSocket Real-time Chat
echo   • Database (SQLite)
echo   • All Configuration Files
echo.
echo 🚀 High-performance settings configured:
echo   • Default AI Model: llama3.1:8b
echo   • Code AI Model: codellama:13b
echo   • Simultaneous Model Loading: 2
echo   • Context Length: 8192 tokens
echo.

echo Cleaning up temporary files...
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" >nul 2>&1

echo.
set /p START_SERVER="Do you want to start the server now? (Y/n): "
if /i "%START_SERVER%"=="n" goto :manual_start

echo.
echo Starting server...
echo.

:: Open browser after 5 seconds
start "" cmd /c "timeout /t 5 /nobreak >nul && start http://localhost:8000"

:: Start server
if exist start.bat (
    echo Using start.bat to start the server...
    call start.bat
) else if exist run-daphne.bat (
    echo Using run-daphne.bat to start the server...
    call run-daphne.bat
) else (
    echo Starting Django development server...
    python manage.py runserver 0.0.0.0:8000
)

goto :final_end

:manual_start
echo.
echo Manual start instructions:
echo =========================
echo.
echo 1. To start server: run start.bat
echo 2. Open browser to: http://localhost:8000
echo 3. Check AI status: run check-ollama-quick.bat
echo.
goto :final_end

:cleanup_and_exit
echo.
echo Cleaning up and exiting...
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" >nul 2>&1
echo.
echo Installation was not completed successfully.
echo Please check the error messages above and try again.
echo.
pause
exit /b 1

:final_end
echo.
echo ==========================================
echo XShell AI Chatbot Installation Finished
echo ==========================================
echo.
echo Additional information:
echo   • Admin panel: http://localhost:8000/admin
echo   • Configuration file: .env
echo   • Python install guide: PYTHON-INSTALL-GUIDE.md
echo   • Troubleshooting: TROUBLESHOOTING-AI.md
echo.
echo Thank you for using XShell AI Chatbot!
echo.
pause