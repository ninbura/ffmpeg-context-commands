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

set /p step=<"G:\My Drive\Programming\Powershell\FFmpeg\FFmpeg Powershell Scripts\Setup\Step.txt"
set relativePath=%~dp0
set relevantPath=%relativePath:~0,-1%

if %step% == 0 (
    (echo 1) > "%relativePath%Setup\Step.txt"

    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%relativePath%Setup\GetChocolatey.ps1"

    start "" "G:\My Drive\Programming\Powershell\FFmpeg\FFmpeg Powershell Scripts\RunMe.bat"

    exit
) 

if %step% == 1 (
    (echo 2) > "%relativePath%Setup\Step.txt"

    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%relativePath%Setup\GetGit.ps1"

    start "" "G:\My Drive\Programming\Powershell\FFmpeg\FFmpeg Powershell Scripts\RunMe.bat"

    exit
) 

if %step% == 2 (
    (echo 0) > "%relativePath%Setup\Step.txt"

    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%relativePath%Setup\Update.ps1" -relevantPath "%relevantPath%"
) 

PAUSE