param (
    [string]$filePath
)

Import-Module -Name "$(Split-Path $PSScriptRoot -Parent)\Scripts\Joint Functions.ps1"

function PrintControls(){
    Write-Host "FFplay controls:"
    Write-Host "[q, ESC] = Quit."
    Write-Host "[f] = Toggle full screen."
    Write-Host "[p, SPC] = Pause"
    Write-Host "[m] = Toggle mute."
    Write-Host "[9, 0] = Decrease and increase volume respectively."
    Write-Host "[/, *] = Decrease and increase volume respectively."
    Write-Host "[a] = Cycle audio channel in the current program."
    Write-Host "[v] = Cycle video channel."
    Write-Host "[t] = Cycle subtitle channel in the current program."
    Write-Host "[c] = Cycle program."
    Write-Host "[w] = Cycle video filters or show modes."
    Write-Host "[s] = Step to the next frame."
    Write-Host "[left/right] = Seek backward/forward 10 seconds."
    Write-Host "[down/up] = Seek backward/forward 1 minute."
    Write-Host "[page down/page up] = Seek to the previous/next chapter. or if there are no chapters Seek backward/forward 10 minutes."
    Write-Host "[right mouse click] = Seek to percentage in file corresponding to fraction of width."
    Write-Host "[left mouse double-click] = Toggle full screen.`n"
}

Write-Host "FFplay is starting...`n"
PrintControls
$argumentList = @("-i", "`"$filePath`"")
runFFCommand $argumentList "ffplay"
EndProcess