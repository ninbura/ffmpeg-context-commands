param (
    [string]$filePath
)


Import-Module -Name "$(Split-Path $PSScriptRoot -Parent)\Scripts\Joint Functions.ps1"


function SetPresetValues($originalVideoProperties){
    $presetVideoProperties = [ordered]@{
        Pixel_Height = $null;
        FPS = $null;
        Start_Time = $null;
        End_Time = $null;
        Total_Clip_Duration = $null
    }

    Switch($originalVideoProperties){
        {[INT]$_.Pixel_Height -gt 480} {$presetVideoProperties.Pixel_Height = 480}
        {[INT]$_.FPS -gt 24} {$presetVideoProperties.FPS = 24}
    }

    return $presetVideoProperties
}


function CreateArgumentLists($filePath, $newFilePath, $videoProperties, $originalVideoProperties){
    $argumentLists = @()
    $arrIndex = 0
    $tempPath = $filePath

    if($null -ne $videoProperties.Start_Time -or $null -ne $videoProperties.End_Time){
        $tempFilePath = "$($filePath.substring(0, $filePath.Length - 4))_Temp.mp4"

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

        $argumentLists += ,("-loglevel", "error", "-stats")
        foreach($value in $firstStartTime){$argumentLists[0] += $value}
        $argumentLists[0] += "-i", "`"$filePath`"", "-map", "0:0"
        foreach($value in $secondStartTime){$argumentLists[0] += $value}
        foreach($value in $duration){$argumentLists[0] += $value}
        $argumentLists[0] += "-c", "copy", "`"$tempFilePath`""

        $tempPath = $tempFilePath
        $arrIndex += 1
    }

    if($null -eq $videoProperties.Pixel_Height -and $null -eq $videoProperties.FPS){
        $videoFilters = "`"scale=-2:$($originalVideoProperties.Pixel_Height):flags=lanczos"
    }
    elseif($null -ne $videoProperties.Pixel_Height -and $null -eq $videoProperties.FPS){
        $videoFilters = "`"scale=-2:$($videoProperties.Pixel_Height):flags=lanczos)"
    }
    elseif($null -eq $videoProperties.Pixel_Height -and $null -ne $videoProperties.FPS){
        $videoFilters = "`"fps=$($videoProperties.FPS)"
    }
    else{
        $videoFilters = "`"scale=-2:$($videoProperties.Pixel_Height):flags=lanczos, fps=$($videoProperties.FPS)"
    }

    $pngFilePath = "$($filePath.substring(0, $filePath.Length - 4))_temp.png"

    $argumentLists += ,("-loglevel", "error", "-stats")
    $argumentLists[$arrIndex] += "-i", "`"$tempPath`""
    $argumentLists[$arrIndex] += "-vf", "$videoFilters, palettegen`""
    $argumentLists[$arrIndex] += "`"$pngFilePath`""

    $argumentLists += ,("-loglevel", "error", "-stats")
    $argumentLists[$arrIndex + 1] += "-i", "`"$tempPath`"", "-i", "`"$pngFilePath`""
    $argumentLists[$arrIndex + 1] += "-filter_complex", "$videoFilters[x];[x][1:v]paletteuse`""
    $argumentLists[$arrIndex + 1] += "`"$newFilePath`""

    return $argumentLists
}


function DeleteTempFiles(){
    foreach($argumentList in $argumentLists){
        foreach($argument in $argumentList){
            if($argument -match "_temp\."){
                $argument = "$($argument.Substring(1,$argument.Length - 2))"

                if(Test-Path $argument){
                    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($argument,'OnlyErrorDialogs','SendToRecycleBin')
                }
            }
        }
    }
}


Startup
Write-Host "The purpose of this program is to convert a video file to a gif file." -ForegroundColor Cyan
Write-Host "There are preset values set by default in this program, you can bypass these if you choose but it's not recommended.`n" -ForegroundColor Cyan
CheckFileType $filePath
InformUser
$originalVideoProperties = [ordered]@{
    Pixel_Height = 'Yes';
    FPS = 'Yes';
    Start_Time = '00:00:00.000';
    End_Time = 'Yes';
    Total_Clip_Duration = 'Yes'
}
$originalVideoProperties = GetOriginalVideoProperties $filePath $originalVideoProperties
$presetVideoProperties = SetPresetValues $originalVideoProperties
$keepTweaking = ""
:outer While($keepTweaking.ToUpper() -ne "N"){
    $videoProperties = GetVideoProperties $originalVideoProperties $videoProperties $presetVideoProperties
    $newFilePath = GetNewFilePath "Gif" $filePath
    $fileModificationDate = GetModificationDate $newFilePath
    $newFilePath = DeleteExistingFiles "Gif" $newFilePath
    $argumentLists = CreateArgumentLists $filePath $newFilePath $videoProperties $originalVideoProperties
    Write-Host "Gif is building..."
    foreach($argumentList IN $argumentLists){runFFCommand $argumentList "ffmpeg"}
    DeleteTempFiles $argumentLists
    TestNewFilePath $newFilePath $fileModificationDate
    $keepTweaking = KeepTweaking
}
EndProcess