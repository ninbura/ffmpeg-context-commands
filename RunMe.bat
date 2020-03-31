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

echo Creating contextual menu items...

set ccPath=%~dp0Scripts\CreateContext.ps1
set relevantPath=%~dp0
set relevantPath=%relevantPath:~0,-1%

PowerShell -NoProfile -ExecutionPolicy Bypass -File "%ccPath%" -relevantPath "%relevantPath%"

echo Compress created.
echo GameOnly Created.
echo Gif Created.
echo.
echo Creation complete.
PAUSE