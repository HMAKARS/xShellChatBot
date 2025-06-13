@echo off
:: pexpect 수정 후 최종 테스트

chcp 65001 >nul
echo 🎯 pexpect 수정 후 최종 테스트
echo ================================
echo.

call .venv\Scripts\activate.bat

echo 🔍 Django import 최종 테스트...
python test-pexpect-fix.py
if %errorlevel% equ 0 (
    echo.
    echo ✅ 모든 문제 해결 완료!
    echo.
    echo 🚀 이제 서버를 시작할 수 있습니다:
    echo    python manage.py runserver
    echo.
    set /p START_SERVER="지금 바로 서버를 시작하시겠습니까? (y/N): "
    if /i "%START_SERVER%"=="y" (
        echo.
        echo 🌐 서버 시작 중... http://localhost:8000
        python manage.py runserver
    )
) else (
    echo.
    echo ❌ 아직 문제가 남아있습니다.
    echo    install-minimal.bat을 다시 실행해보세요.
)

pause
