@echo off
echo.
echo ========================================
echo   CRITICAL SECURITY INCIDENT RESPONSE
echo ========================================
echo.
echo This will help you resolve the 4 HIGH-SEVERITY
echo secrets detected by GitGuardian.
echo.
echo Press any key to start credential rotation...
pause >nul
echo.
echo Starting PowerShell script...
powershell.exe -ExecutionPolicy Bypass -File ".\rotate_credentials.ps1"
echo.
echo ========================================
echo   NEXT STEPS:
echo ========================================
echo.
echo 1. Make repository PRIVATE:
echo    https://github.com/sathvik7137/learnease-community-platform/settings
echo.
echo 2. Update Render environment variables:
echo    https://dashboard.render.com
echo.
echo 3. Read CRITICAL_SECURITY_INCIDENT.md for full details
echo.
pause
