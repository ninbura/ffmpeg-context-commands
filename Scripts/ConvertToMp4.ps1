param (
    [string]$relevantPath,
    [string]$filePath
)


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic
Import-Module -Name "$PSScriptRoot\JointFunctions.ps1"

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
$newFilePath = "$($filePath.substring(0, $filePath.Length - 4))_Converted.mp4"
$fileModificationDate = GetModificationDate $newFilePath
DeleteExistingFiles $newFilePath
$argumentList = @("-loglevel", "error", "-stats", "-i", "`"$filePath`"", "-map", "0", "-c", "copy", "`"$newFilePath`"")
Write-Host "Video is Building..."
runFFmpegCommand $relevantPath $argumentList
TestNewFilePath $newFilePath $fileModificationDate
EndProcess