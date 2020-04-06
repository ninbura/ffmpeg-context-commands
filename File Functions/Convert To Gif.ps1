param (
    [string]$filePath
)


Import-Module -Name "$(Split-Path $PSScriptRoot -Parent)\Scripts\Joint Functions.ps1"


function SetPresetValues($originalVideoProperties){
    $presetVideoProperties = [ordered]@{
        Pixel_Width = "Auto";
        Pixel_Height = $null;
        Pad = $null;
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
        $tempFilePath = "$($filePath.Substring(0, $filePath.LastIndexOf(".")))_Temp.$($filePath.Substring($filePath.LastIndexOf(".") + 1))"

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
        if(($videoFilters.Count -eq 1) -or ($i -eq $videoFilters.Count - 1)){
            $videoFilterString += "$($videoFilters[$i])"
        }
        else{
            $videoFilterString += "$($videoFilters[$i]), "
        }
    }

    $pngFilePath = "$($filePath.Substring(0, $filePath.LastIndexOf(".")))_temp.png"

    $argumentLists += ,("-loglevel", "error", "-stats")
    $argumentLists[$arrIndex] += "-i", "`"$tempPath`""
    $argumentLists[$arrIndex] += "-vf", "`"$videoFilterString, palettegen`""
    $argumentLists[$arrIndex] += "`"$pngFilePath`""

    $argumentLists += ,("-loglevel", "error", "-stats")
    $argumentLists[$arrIndex + 1] += "-i", "`"$tempPath`"", "-i", "`"$pngFilePath`""
    $argumentLists[$arrIndex + 1] += "-filter_complex", "`"$videoFilterString[x];[x][1:v]paletteuse`""
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
    Pixel_Width = 'Yes';
    Pixel_Height = 'Yes';
    Pad = 'n';
    FPS = 'Yes';
    Start_Time = '00:00:00.000';
    End_Time = 'Yes';
    Total_Clip_Duration = 'Yes'
}
$originalVideoProperties = GetOriginalVideoProperties $filePath $originalVideoProperties
$presetVideoProperties = SetPresetValues $originalVideoProperties
$keepTweaking = ""
While($keepTweaking.ToUpper() -ne "N"){
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