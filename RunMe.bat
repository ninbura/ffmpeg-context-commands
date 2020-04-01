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

set GetChocolateyPath=%~dp0Setup\GetChocolatey.ps1
set UpdatePath=%~dp0Setup\Update.ps1
set relevantPath=%~dp0
set relevantPath=%relevantPath:~0,-1%

PowerShell -NoProfile -ExecutionPolicy Bypass -File "%GetChocolateyPath%"
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%UpdatePath%" -relevantPath "%relevantPath%"

PAUSE