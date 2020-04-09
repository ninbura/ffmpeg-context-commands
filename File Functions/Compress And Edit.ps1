param (
    [string]$filePath
)


Import-Module -Name "$(Split-Path $PSScriptRoot -Parent)\Scripts\Joint Functions.ps1"


function CreateArgumentList($filePath, $newFilePath, $videoProperties, $originalVideoProperties){
    switch($videoProperties.Compression_Level){
        {$null -eq $_} {$compressionLevel = 17; Break}
        default {$compressionLevel = $videoProperties.Compression_Level; Break}
    }

    if($null -ne $videoProperties.Pixel_Width -or $null -ne $videoProperties.Pixel_Height -or $null -ne $videoProperties.FPS){
        [array]$videoFilters = @()

        if($null -ne $videoProperties.FPS){
            $videoFilters += "fps=$($videoProperties.FPS)"
        }

        if(!($videoProperties.Pixel_Width -match "^$|^Auto$") -and $videoProperties.Pixel_Height -eq "Auto"){
            $videoFilters += "scale=$($videoProperties.Pixel_Width):-2:flags=lanczos, setsar=sar=1/1"
        }
        elseif($videoProperties.Pixel_Width -eq "Auto" -and !($videoProperties.Pixel_Height -match "^$|^Auto$")){
            $videoFilters += "scale=-2:$($videoProperties.Pixel_Height):flags=lanczos, setsar=sar=1/1"
        }
        elseif(!($videoProperties.Pixel_Width -match "^$|^Auto$") -and !($videoProperties.Pixel_Height -match "^$|^Auto$") -and $null -eq $videoProperties.Pad){
            $videoFilters += "scale=$($videoProperties.Pixel_Width):$($videoProperties.Pixel_Height):flags=lanczos, setsar=sar=1/1"
        }
        elseif(!($videoProperties.Pixel_Width -match "^$|^Auto$") -and !($videoProperties.Pixel_Height -match "^$|^Auto$") -and $null -ne $videoProperties.Pad){
            if($originalVideoProperties.Pixel_Width / $originalVideoProperties.Pixel_Height -gt $videoProperties.Pixel_Width / $videoProperties.Pixel_Height){
                $videoFilters += "scale=$($videoProperties.Pixel_Width):-2:flags=lanczos, pad=iw:$($videoProperties.Pixel_Height):0:$($videoProperties.Pixel_Height)-ih/2, setsar=sar=1/1"
            }
            else{
                $videoFilters += "scale=-2:$($videoProperties.Pixel_Height):flags=lanczos, pad=$($videoProperties.Pixel_Width):ih:$($videoProperties.Pixel_Width)-iw/2:0, setsar=sar=1/1"
            }
        }

        $videoFilterString = ""
        
        for($i = 0; $i -lt $videoFilters.Count; $i++){
            if($videoFilters.Count -eq 1){
                $videoFilterString = "`"$($videoFilters[$i])`""
            }
            elseif($i -eq 0){
                $videoFilterString += "`"$($videoFilters[$i]), "
            }
            elseif($i -eq $videoFilters.Count - 1){
                $videoFilterString += "$($videoFilters[$i])`""
            }
            else{
                $videoFilterString += "$($videoFilters[$i]), "
            }
        }

        $videoFilters = @("-vf", "$videoFilterString")
    }
    else{
        $videoFilters = $null
    }

    if($videoProperties.Contains("Audio_Track_Number")){
        if($null -eq $videoProperties.Audio_Track_Number){
            $audioTrackMap = @("-map", "0:a")
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
    $argumentList += "-c:v", "libx264", "-preset", "slow", "-crf", $compressionLevel
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
    Compression_Level = '17';
    Pixel_width = 'Yes';
    Pixel_Height = 'Yes';
    Pad = 'n';
    FPS = 'Yes';
    Audio_Track_Number = 'Yes';
    Audio_Level = '0'
    Start_Time = '00:00:00.000';
    End_Time = 'Yes';
    Total_Clip_Duration = 'Yes'
}
$originalVideoProperties = GetOriginalVideoProperties $filePath $originalVideoProperties
$keepTweaking = ""
While($keepTweaking.ToUpper() -ne "N"){
    $videoProperties = GetVideoProperties $originalVideoProperties $videoProperties
    $newFilePath = GetNewFilePath "Compressed" $filePath
    $fileModificationDate = GetModificationDate $newFilePath
    $newFilePath = DeleteExistingFiles "Compressed" $newFilePath
    $argumentList = CreateArgumentList $filePath $newFilePath $videoProperties $originalVideoProperties
    Write-Host "Video is building..."
    runFFCommand $argumentList "ffmpeg"
    TestNewFilePath $newFilePath $fileModificationDate
    $keepTweaking = KeepTweaking
}
EndProcess