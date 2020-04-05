param (
    [string]$filePath
)


Import-Module -Name "$(Split-Path $PSScriptRoot -Parent)\Scripts\Joint Functions.ps1"


function CreateArgumentList($filePath, $newFilePath, $videoProperties){
    if($null -eq $videoProperties.Resolution){
        $cropFilter = $null
    }
    else{
        $width = $videoProperties.Resolution.Substring(0, $videoProperties.Resolution.IndexOf("x"))
        $height = $videoProperties.Resolution.Substring($videoProperties.Resolution.IndexOf("x") + 1)
        
        if($null -eq $videoProperties.Left_Crop){
            $x = 0
        }
        else{
            $x = $videoProperties.Left_Crop
        }

        if($null -eq $videoProperties.Top_Crop){
            $y = 0
        }
        else{
            $y = $videoProperties.Top_Crop
        }

        $cropFilter = @("-vf", "`"crop=$($width):$($height):$($x):$($y)`"")
    }

    $argumentList = @("-loglevel", "error", "-stats", "-i", "`"$filePath`"", "-map", "0:0", "-map", "0:a")
    foreach($value in $cropFilter){$argumentList += $value}
    $argumentList += "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-c:a copy", "`"$newFilePath`""

    return $argumentList
}


Startup
Write-Host "The purpose of this program is to allow cropping of a video.`n" -ForegroundColor Cyan
InformUser
$originalVideoProperties = $originalVideoProperties = [ordered]@{
    Left_Crop = '0';
    Right_Crop = '0';
    Top_Crop = '0';
    Bottom_Crop = '0';
    Resolution = 'Yes'
}
$originalVideoProperties = GetOriginalVideoProperties $filePath $originalVideoProperties
$keepTweaking = ""
:outer While($keepTweaking.ToUpper() -ne "N"){
    $videoProperties = GetVideoProperties $originalVideoProperties $videoProperties
    $newFilePath = GetNewFilePath "Cropped" $filePath
    $fileModificationDate = GetModificationDate $newFilePath
    $newFilePath = DeleteExistingFiles "Cropped" $newFilePath
    $argumentList = CreateArgumentList $filePath $newFilePath $videoProperties
    Write-Host "Video is building..."
    runFFCommand $argumentList "ffmpeg"
    TestNewFilePath $newFilePath $fileModificationDate
    $keepTweaking = KeepTweaking
}
EndProcess