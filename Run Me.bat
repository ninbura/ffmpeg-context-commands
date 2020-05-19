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

%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%relativePath%Scripts\Setup.ps1"

Exit