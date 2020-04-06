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

    if($null -eq $videoProperties.Start_Time){
        $firstStartTime = $null
        $secondStartTime = $null
    }
    elseif((ConvertTimeStamp $videoProperties.Start_Time) -lt 10){
        $firstStartTime = $null
        $secondStartTime = @("-ss", "$($videoProperties.Start_Time)")
    }
    else{
        $firstStartTime = @("-ss", "$(ConvertDuration ((ConvertTimeStamp $videoProperties.Start_Time) - 10))")
        $secondStartTime = @("-ss", "00:00:10.000")
    }

    switch($videoProperties.Total_Clip_Duration){
        {$null -eq $_} {$duration = $null; Break}
        default {$duration = @("-t", "$($videoProperties.Total_Clip_Duration)"); Break}
    }

    $argumentList = @("-loglevel", "error", "-stats")
    foreach($value in $firstStartTime){$argumentList += $value}
    $argumentList += "-i", "`"$filePath`"", "-map", "0:0", "-map", "0:a", "-movflags", "+faststart"
    foreach($value in $secondStartTime){$argumentList += $value}
    foreach($value in $duration){$argumentList += $value}
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
    Start_Time = '00:00:00.000';
    End_Time = 'Yes';
    Resolution = 'Yes';
    Total_Clip_Duration = 'Yes'
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