@echo off
:: Python 캐시 및 임시 파일 정리 스크립트

echo 🧹 Python 캐시 파일 정리 중...

:: __pycache__ 디렉토리 삭제
echo    __pycache__ 디렉토리 삭제 중...
for /d /r . %%d in (__pycache__) do @if exist "%%d" rd /s /q "%%d"

:: .pyc 파일 삭제
echo    .pyc 파일 삭제 중...
for /r . %%f in (*.pyc) do @if exist "%%f" del /q "%%f"

:: .pyo 파일 삭제
echo    .pyo 파일 삭제 중...
for /r . %%f in (*.pyo) do @if exist "%%f" del /q "%%f"

:: Django 마이그레이션 캐시 정리 (선택적)
if exist "chatbot\migrations\__pycache__" (
    echo    Django 마이그레이션 캐시 정리 중...
    rd /s /q "chatbot\migrations\__pycache__" 2>nul
)

if exist "ai_backend\migrations\__pycache__" (
    rd /s /q "ai_backend\migrations\__pycache__" 2>nul
)

if exist "xshell_integration\migrations\__pycache__" (
    rd /s /q "xshell_integration\migrations\__pycache__" 2>nul
)

echo ✅ Python 캐시 정리 완료!
echo.
echo 💡 캐시 정리 후 다음을 실행하세요:
echo    install-minimal.bat 또는 quick-test.py
echo.
