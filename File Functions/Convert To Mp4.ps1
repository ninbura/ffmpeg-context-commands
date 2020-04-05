param (
    [string]$filePath
)

Import-Module -Name "$(Split-Path $PSScriptRoot -Parent)\Scripts\Joint Functions.ps1"

function GetUserConfirmation{
    while($true){
        $userConfirmation = Read-Host "Are you sure you'd like to convert `"$filepath`" to an MP4 file? [y/n]"
        Write-Host ""

        if($userConfirmation.ToUpper() -eq "Y"){
            break
        }
        elseif($userConfirmation.ToUpper() -eq "N"){
            Quit
        }
        else{
            Write-Host "Invalid input, answer should be `"y`" (Yes) or `"N`" (No)..." -ForegroundColor Yellow
        }
    }

    return $userConfirmation
}

Startup
$userConfirmation = GetUserConfirmation $filePath
$newFilePath = GetNewFilePath "Converted" $filePath
$fileModificationDate = GetModificationDate $newFilePath
DeleteExistingFiles $newFilePath
$argumentList = @("-loglevel", "error", "-stats", "-i", "`"$filePath`"", "-map", "0", "-c", "copy", "`"$newFilePath`"")
Write-Host "Video is Building..."
runFFCommand $argumentList "ffmpeg"
TestNewFilePath $newFilePath $fileModificationDate
EndProcess