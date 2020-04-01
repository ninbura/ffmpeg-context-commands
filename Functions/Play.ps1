param (
    [string]$filePath
)

Import-Module -Name "$(Split-Path $PSScriptRoot -Parent)\Scripts\Joint Functions.ps1"

function PrintControls(){
    Write-Host "FFplay controls:" -ForegroundColor Yellow
    Write-Host "[q, ESC] = Quit." -ForegroundColor Yellow
    Write-Host "[f] = Toggle full screen." -ForegroundColor Yellow
    Write-Host "[p, SPC] = Pause" -ForegroundColor Yellow
    Write-Host "[m] = Toggle mute." -ForegroundColor Yellow
    Write-Host "[9, 0] = Decrease and increase volume respectively." -ForegroundColor Yellow
    Write-Host "[/, *] = Decrease and increase volume respectively." -ForegroundColor Yellow
    Write-Host "[a] = Cycle audio channel in the current program." -ForegroundColor Yellow
    Write-Host "[v] = Cycle video channel." -ForegroundColor Yellow
    Write-Host "[t] = Cycle subtitle channel in the current program." -ForegroundColor Yellow
    Write-Host "[c] = Cycle program." -ForegroundColor Yellow
    Write-Host "[w] = Cycle video filters or show modes." -ForegroundColor Yellow
    Write-Host "[s] = Step to the next frame." -ForegroundColor Yellow
    Write-Host "[left/right] = Seek backward/forward 10 seconds." -ForegroundColor Yellow
    Write-Host "[down/up] = Seek backward/forward 1 minute." -ForegroundColor Yellow
    Write-Host "[page down/page up] = Seek to the previous/next chapter. or if there are no chapters Seek backward/forward 10 minutes." -ForegroundColor Yellow
    Write-Host "[right mouse click] = Seek to percentage in file corresponding to fraction of width." -ForegroundColor Yellow
    Write-Host "[left mouse double-click] = Toggle full screen.`n" -ForegroundColor Yellow
}

Write-Host "FFplay is starting...`n"
PrintControls
$argumentList = @("-i", "`"$filePath`"")
runFFCommand $argumentList "ffplay"
EndProcess