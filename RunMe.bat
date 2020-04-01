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
set relevantPath=%relativePath:~0,-1%
set /p step=<"%relativePath%Setup\Step.txt"

PowerShell -NoProfile -ExecutionPolicy Bypass -File "%relativePath%Setup\CheckChoco.ps1" -relevantPath "%relevantPath%"

if %step% == 1 (
    (echo 1) > "%relativePath%Setup\Step.txt"

    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%relativePath%Setup\GetChocolatey.ps1"

    start "" "%relativePath%RunMe.bat"

    exit
) 

if %step% == 2 (
    (echo 2) > "%relativePath%Setup\Step.txt"

    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%relativePath%Setup\GetRequiredPackages.ps1"

    start "" "%relativePath%RunMe.bat"

    exit
) 

if %step% == 3 (
    (echo 0) > "%relativePath%Setup\Step.txt"

    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%relativePath%Setup\Update.ps1" -relevantPath "%relevantPath%"
) 

PAUSE
Exit