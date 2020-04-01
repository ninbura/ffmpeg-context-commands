param (
    [string]$filePath
)


Import-Module -Name "$(Split-Path $PSScriptRoot -Parent)\Scripts\Joint Functions.ps1"


function CreateArgumentList($filePath, $newFilePath, $videoProperties){
    switch($videoProperties.Compression_Level){
        {$null -eq $_} {$compressionLevel = 1; Break}
        default {$compressionLevel = $videoProperties.Compression_Level; Break}
    }
    
    if($null -eq $videoProperties.Pixel_Height -and $null -eq $videoProperties.FPS){
        $videoFilters = $null
    }
    elseif($null -ne $videoProperties.Pixel_Height -and $null -eq $videoProperties.FPS){
        $videoFilters = @("-vf", "`"scale=-2:$($videoProperties.Pixel_Height):flags=lanczos`"")
    }
    elseif($null -eq $videoProperties.Pixel_Height -and $null -ne $videoProperties.FPS){
        $videoFilters = @("-vf", "`"fps=$($videoProperties.FPS)`"")
    }
    else{
        $videoFilters = @("-vf", "`"scale=-2:$($videoProperties.Pixel_Height):flags=lanczos, fps=$($videoProperties.FPS)`"")
    }

    if($videoProperties.Contains("Audio_Track_Number")){
        if($null -eq $videoProperties.Audio_Track_Number){
            $audioTrackMap = @("-map", "0:1")
        }
        else{
            $audioTrackMap = @("-map", "0:$([Regex]::Match($videoProperties.Audio_Track_Number, "^([0-9])*(?=\/)").Value)")
        }
    }
    else{
        $audioTrackMap = $null
    }

    if(($videoProperties.Contains("Audio_Level")) -and $null -ne $videoProperties.Audio_Level -and $videoProperties.Audio_Level -ne "0"){
        $audioFilters = @("-af", "`"volume=$($videoProperties.Audio_Level)dB`"")
    }
    else{
        $audioFilters = $null
    }

    if($null -eq $audioFilters){
        $audioCodec = @("-c:a", "copy")
    }
    else{
        $audioCodec = @("-c:a", "aac", "-ar", "44100", "-b:a", "320k")
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
    $argumentList += "-i", "`"$filePath`"", "-map", "0:0"  
    foreach($value in $audioTrackMap){$argumentList += $value}
    $argumentList +=  "-movflags", "+faststart"
    foreach($value in $secondStartTime){$argumentList += $value}
    foreach($value in $duration){$argumentList += $value}
    $argumentList += "-c:v", "libx264", "-preset", "slow", "-crf", (16 + $compressionLevel)
    foreach($value in $videoFilters){$argumentList += $value}
    foreach($value in $audioFilters){$argumentList += $value}
    foreach($value in $audioCodec){$argumentList += $value}
    $argumentList += "`"$newFilePath`""

    return $argumentList
}


Startup
Write-Host "The purpose of this program is to allow simple modification of a video file for easy sharing online or elsewhere.`n" -ForegroundColor Cyan
CheckFileType $filePath
InformUser
$originalVideoProperties = [ordered]@{
    Compression_Level = '1';
    Pixel_Height = 'Yes';
    FPS = 'Yes';
    Audio_Track_Number = 'Yes';
    Audio_Level = '0'
    Start_Time = '00:00:00.000';
    End_Time = 'Yes';
    Total_Clip_Duration = 'Yes'
}
$originalVideoProperties = GetOriginalVideoProperties $filePath $originalVideoProperties
$videoProperties = GetVideoProperties $originalVideoProperties
$newFilePath = GetNewFilePath "Compressed" $filePath
$fileModificationDate = GetModificationDate $newFilePath
DeleteExistingFiles $newFilePath
$argumentList = CreateArgumentList $filePath $newFilePath $videoProperties
Write-Host "Video is building..."
runFFCommand $argumentList "ffmpeg"
TestNewFilePath $newFilePath $fileModificationDate
EndProcess