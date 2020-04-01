@echo off
echo Administrative permissions required. Detecting permissions...
echo.

net session >nul 2>&1
if %errorLevel% == 0 (
    echo Success: Administrative permissions confirmed.
    echo.
) else (
    echo Failure: Current permissions inadequate.

    PAUSE

    exit
)

set relativePath=%~dp0

PowerShell -NoProfile -ExecutionPolicy Bypass -File "%relativePath%Scripts\Setup.ps1"

Echo Ignore "system cannot find the specified path", error message is by design.

PAUSE
Exit