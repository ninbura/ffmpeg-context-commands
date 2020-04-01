Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic


function Startup(){
    Write-Host "Starting process... Input 'q' at any point to to terminate the program.`n"
}


function checkFileType($filePath){
    $incompatibleFileTypeArray = @(
        "MKV"
    )
    $fileType = $filePath.Substring($filePath.length - 3)

    foreach($incompatibleFileType in $incompatibleFileTypeArray){
        if($fileType.ToUpper() -eq $incompatibleFileType){
            Write-Host "The $fileType file type / container is not compatible with this program as it lacks necessary header information for operation." -ForegroundColor Red
            Write-Host "To fix this issue simply use the `"Convert to mp4`" function to change this files container to something compatible.`n" -ForegroundColor Yellow
            Quit
        }
    }
}


function InformUser(){
    Write-Host "File deletion in this program does not completely remove the file from your system, it is moved to the recycle bin and can be recovered." -ForegroundColor Yellow
    Write-Host "UNLESS " -NoNewLine -ForegroundColor Red
    Write-Host "you are agreeing to deletion of a file on a network drive in-which they will be permanently deleted upon affirmative response." -ForegroundColor Yellow
    Write-Host "This program is not compatible with all file types, such as Matroska (.mkv), as it does not have the necessary header information." -ForegroundColor Yellow
    Write-Host "It is possible that there are other file types incompatible with this program that can be excluded from operation in the future.`n" -ForegroundColor Yellow
}


function Quit(){
    write-host('Closing program...') -ForegroundColor Red
    Write-Host "Process complete, press [Enter] to exit..." -NoNewLine
    $Host.UI.ReadLine()

    exit
}


function ConvertDuration($duration){
    [double]$milliDuration = [double]$duration * 1000
    [int]$hour = [math]::Floor(($milliDuration / (1000 * 60 * 60)) % 24)
    [int]$minute = [math]::Floor(($milliDuration / (1000 * 60)) % 60)
    [int]$second = [math]::Floor(($milliDuration / 1000) % 60)
    [int]$millisecond = [math]::Floor($milliDuration % 1000)

    [String]$timeStamp = ('{0:d2}' -f $hour) + ':' + ('{0:d2}' -f $minute) + ':' + ('{0:d2}' -f $second) + '.' + ('{0:d3}' -f $millisecond)

    return $timeStamp
}


function ConvertTimeStamp($timeStamp){
    [double]$duration = [int]$timeStamp.Substring(0,2) * 3600 + [int]$timeStamp.Substring(3,2) * 60 + [int]$timeStamp.Substring(6,2) + ([int]$timeStamp.Substring(9) / 1000)

    return $duration
}


function GetOriginalVideoProperties($filePath, $originalVideoProperties){
    [array]$optionArray = @()
    
    Switch($originalVideoProperties){
        {$_.Pixel_Height -eq 'Yes'} {$optionArray += 'height';}
        {$_.FPS -eq 'Yes'} {$optionArray += 'r_frame_rate';}
        {$_.Total_Clip_Duration -eq 'Yes'} {$optionArray += 'duration';}
        {$_.Audio_Track_Number -eq 'Yes'} {$optionArray += 'codec_type';}
    }

    for($i = 0; $i -lt $optionArray.Count; $i++){
        if($i -ge 0 -and $i -lt $optionArray.Count - 1){
            $optionString += "$($optionArray[$i]),"
        }
        else{
            $optionString += $optionArray[$i]
        }
    }

    $ffpinfo = New-Object System.Diagnostics.ProcessStartInfo
    $ffpinfo.FileName = "C:\ProgramData\chocolatey\lib\ffmpeg\tools\ffmpeg\bin\ffprobe.exe"
    $ffpinfo.RedirectStandardError = $true
    $ffpinfo.RedirectStandardOutput = $true
    $ffpinfo.UseShellExecute = $false
    $ffpinfo.Arguments = "-loglevel error -i `"$filePath`" -show_entries stream=$optionString"
    $ffp = New-Object System.Diagnostics.Process
    $ffp.StartInfo = $ffpinfo
    $ffp.Start() | Out-Null
    $ffp.WaitForExit()
    $ffpErrOut = $ffp.StandardError.ReadToEnd()
    $ffpStdOut = $ffp.StandardOutput.ReadToEnd().split([Environment]::NewLine)

    if($ffpErrOut -match '(denied)'){
        Write-Host "Invalid path, make sure you're selecting a video file before running this program. `n" -ForegroundColor Yellow

        Quit
    }

    [array]$videoPropertyArray = $ffpStdOut `
        | select-string -Pattern "(height=)|(r_frame_rate=)|(duration=)" `
        | ForEach-Object {$_.ToString().Split(" ")}

    [array]$AudioTrackArray = $ffpStdOut `
        | select-string -Pattern "(codec_type=audio)" `
        | ForEach-Object {$_.ToString().Split(" ")}

    if($videoPropertyArray.Count -eq 0){
        Write-Host "Invalid file, must contain conventional video stream... `n" -ForegroundColor Red

        Quit
    }

    $originalVideoProperties.Pixel_Height = $videoPropertyArray[0].Substring($videoPropertyArray[0].IndexOf("=") + 1)
    $originalVideoProperties.FPS = $videoPropertyArray[1].Substring($videoPropertyArray[1].IndexOf("=") + 1, $videoPropertyArray[1].Length - $videoPropertyArray[1].IndexOf("/"))
    $originalVideoProperties.Total_Clip_Duration = [double]$videoPropertyArray[2].Substring($videoPropertyArray[2].IndexOf("=")+ 1)
    
    if($AudioTrackArray.Count -gt 0){
        $originalVideoProperties.Audio_Track_Number = "1/$($AudioTrackArray.Count)"
    }
    else{
        $originalVideoProperties.Remove("Audio_Track_Number")
        $originalVideoProperties.Remove("Audio_Level")

        write-host "There are no audio tracks in this file, audio modification has been disabled.`n" -ForegroundColor Yellow
    }

    $originalVideoProperties.End_Time = ConvertDuration $originalVideoProperties.Total_Clip_Duration

    return $originalVideoProperties
}


function PrintProperties($originalVideoProperties, $videoProperties, $type, $colors){
    if($type -eq 'Original'){
        Write-Host "Original properties: " -NoNewline
        for($i = 0; $i -lt $originalVideoProperties.Count; $i++){
            if(($originalVideoProperties.GetEnumerator() | select-object -Index $i).Name -eq "Total_Clip_Duration"){
                $newDuration = ConvertDuration $originalVideoProperties.Total_Clip_Duration
    
                Write-Host "[Total Clip Duraion = $newDuration]" -ForegroundColor $colors[$i]
            }
            else{
                Write-Host "[$(($originalVideoProperties.GetEnumerator() | select-object -Index $i).Name -replace '_',' ') = " -NoNewline -ForegroundColor $colors[$i]
                Write-Host "$(($originalVideoProperties.GetEnumerator() | select-object -Index $i).value)]/$($i + 1) " -NoNewline -ForegroundColor $colors[$i]
            }            
        }
    }
    elseif($type -eq 'Current'){
        Write-Host "Current properties : " -NoNewline
        for($i = 0; $i -lt $originalVideoProperties.Count; $i++){
            if(($originalVideoProperties.GetEnumerator() | select-object -Index $i).Name -eq "Total_Clip_Duration"){
                if($null -eq ($videoProperties.GetEnumerator() | select-object -Index $i).value){
                    $newDuration = ConvertDuration $originalVideoProperties.Total_Clip_Duration
                }
                else{
                    $newDuration = ConvertDuration $videoProperties.Total_Clip_Duration
                }
    
                Write-Host "[Total Clip Duraion = $newDuration]" -ForegroundColor $colors[$i]
            }
            else{
                Write-Host "[$(($originalVideoProperties.GetEnumerator() | select-object -Index $i).Name -replace '_',' ') = " -NoNewline -ForegroundColor $colors[$i]

                if($null -eq ($videoProperties.GetEnumerator() | select-object -Index $i).value){
                    Write-Host "$(($originalVideoProperties.GetEnumerator() | select-object -Index $i).value)]/$($i + 1) " -NoNewline -ForegroundColor $colors[$i]
                }
                else{
                    Write-Host "$(($videoProperties.GetEnumerator() | select-object -Index $i).value)]/$($i + 1) " -NoNewline -ForegroundColor $colors[$i]
                }
            }            
        }
    }
    elseif($type -eq 'Change'){
        Write-Host "$($videoProperties.Name -replace '_',' ') " -NoNewline -ForegroundColor $colors
        write-host "changed to " -NoNewline
        Write-Host "$($videoProperties.value)" -NoNewline -ForegroundColor $colors
        Write-Host ".`n"
    }
    elseif($type -eq 'Cancel'){
        Write-Host "$($originalVideoProperties.Name -replace '_',' ') " -NoNewline -ForegroundColor $colors
        Write-Host  'unchanged (' -NoNewline

        if($null -eq $videoProperties.Value){
            Write-Host "$($originalVideoProperties.Value)" -NoNewLine -ForegroundColor $colors
        }
        else{
            Write-Host "$($videoProperties.Value)" -NoNewLine -ForegroundColor $colors
        }

        Write-Host ")...`n"
    }
    elseif($type -eq 'Revert'){
        write-Host "$($originalVideoProperties.Name -replace '_',' ') " -NoNewline -ForegroundColor $colors
        Write-Host 'reverted to original ' -NoNewLine 
        Write-Host "$($originalVideoProperties.Name -replace '_',' ') " -NoNewline -ForegroundColor $colors

        if($null -eq $videoProperties.Value){
            Write-Host "$($originalVideoProperties.Value)" -NoNewline -ForegroundColor $colors
        }
        else{
            Write-Host "$($videoProperties.Value)" -NoNewline -ForegroundColor $colors
        }

        Write-Host "...`n"
    }
    else{
        Write-Host 'Final settings:'
        for($i = 0; $i -lt $originalVideoProperties.Count; $i++){
            if(($originalVideoProperties.GetEnumerator() | select-object -Index $i).Name -eq "Total_Clip_Duration"){
                if($null -eq ($videoProperties.GetEnumerator() | select-object -Index $i).value){
                    $newDuration = ConvertDuration $originalVideoProperties.Total_Clip_Duration
                }
                else{
                    $newDuration = ConvertDuration $videoProperties.Total_Clip_Duration
                }
    
                Write-Host "Total Clip Duraion = $newDuration" -ForegroundColor $colors[$i]
            }
            else{
                Write-Host "$(($originalVideoProperties.GetEnumerator() | select-object -Index $i).Name -replace '_',' ') = " -NoNewline -ForegroundColor $colors[$i]
                if($null -eq ($videoProperties.GetEnumerator() | select-object -Index $i).value){
                    Write-Host "$(($originalVideoProperties.GetEnumerator() | select-object -Index $i).value)" -ForegroundColor $colors[$i]
                }
                else{
                    Write-Host "$(($videoProperties.GetEnumerator() | select-object -Index $i).value)" -ForegroundColor $colors[$i]
                }
            }
        }
        Write-Host ""
    }
}


function FormatTimeStamp($timeStamp){
    switch($timeStamp){
        {$_ -match '^([0-9][0-9]:[0-5][0-9]:[0-5][0-9][.][0-9][0-9])$'} {$timeStamp =              "$($timeStamp)0"    ; Break}
        {$_ -match '^([0-9][0-9]:[0-5][0-9]:[0-5][0-9][.][0-9])$'     } {$timeStamp =              "$($timeStamp)00"   ; Break}
        {$_ -match '^([0-9][0-9]:[0-5][0-9]:[0-5][0-9])$'             } {$timeStamp =              "$($timeStamp).000" ; Break}
        {$_ -match '^([0-9]:[0-5][0-9]:[0-5][0-9][.][0-9][0-9][0-9])$'} {$timeStamp = '0'        +   "$timeStamp"      ; Break}
        {$_ -match '^([0-5][0-9]:[0-5][0-9][.][0-9][0-9][0-9])$'      } {$timeStamp = '00:'      +   "$timeStamp"      ; Break}
        {$_ -match '^([0-9]:[0-5][0-9][.][0-9][0-9][0-9])$'           } {$timeStamp = '00:0'     +   "$timeStamp"      ; Break}
        {$_ -match '^([0-5][0-9][.][0-9][0-9][0-9])$'                 } {$timeStamp = '00:00:'   +   "$timeStamp"      ; Break}
        {$_ -match '^([0-9][.][0-9][0-9][0-9])$'                      } {$timeStamp = '00:00:0'  +   "$timeStamp"      ; Break}
        {$_ -match '^([0-9]:[0-5][0-9]:[0-5][0-9][.][0-9][0-9])$'     } {$timeStamp = '0'        + "$($timeStamp)0"    ; Break}
        {$_ -match '^([0-5][0-9]:[0-5][0-9][.][0-9][0-9])$'           } {$timeStamp = '00:'      + "$($timeStamp)0"    ; Break}
        {$_ -match '^([0-9]:[0-5][0-9][.][0-9][0-9])$'                } {$timeStamp = '00:0'     + "$($timeStamp)0"    ; Break}
        {$_ -match '^([0-5][0-9][.][0-9][0-9])$'                      } {$timeStamp = '00:00:'   + "$($timeStamp)0"    ; Break}
        {$_ -match '^([0-9][.][0-9][0-9])$'                           } {$timeStamp = '00:00:0'  + "$($timeStamp)0"    ; Break}
        {$_ -match '^([0-9]:[0-5][0-9]:[0-5][0-9][.][0-9])$'          } {$timeStamp = '0'        + "$($timeStamp)00"   ; Break}
        {$_ -match '^([0-5][0-9]:[0-5][0-9][.][0-9])$'                } {$timeStamp = '00:'      + "$($timeStamp)00"   ; Break}
        {$_ -match '^([0-9]:[0-5][0-9][.][0-9])$'                     } {$timeStamp = '00:0'     + "$($timeStamp)00"   ; Break}
        {$_ -match '^([0-5][0-9][.][0-9])$'                           } {$timeStamp = '00:00:'   + "$($timeStamp)00"   ; Break}
        {$_ -match '^([0-9][.][0-9])$'                                } {$timeStamp = '00:00:0'  + "$($timeStamp)00"   ; Break}
        {$_ -match '^([0-9]:[0-5][0-9]:[0-5][0-9])$'                  } {$timeStamp = '0'        +   "$timeStamp.000"  ; Break}
        {$_ -match '^([0-5][0-9]:[0-5][0-9])$'                        } {$timeStamp = '00:'      +   "$timeStamp.000"  ; Break}
        {$_ -match '^([0-9]:[0-5][0-9])$'                             } {$timeStamp = '00:0'     +   "$timeStamp.000"  ; Break}
        {$_ -match '^([0-5][0-9])$'                                   } {$timeStamp = '00:00:'   +   "$timeStamp.000"  ; Break}
        {$_ -match '^([0-9])$'                                        } {$timeStamp = '00:00:0'  +   "$timeStamp.000"  ; Break}
        {$_ -match '^([.][0-9][0-9][0-9])$'                           } {$timeStamp = '00:00:00' +   "$timeStamp"      ; Break}
        {$_ -match '^([.][0-9][0-9])$'                                } {$timeStamp = '00:00:00' + "$($timeStamp)0"    ; Break}
        {$_ -match '^([.][0-9])$'                                     } {$timeStamp = '00:00:00' + "$($timeStamp)00"   ; Break}
    }

    return $timeStamp
}


function GetVideoProperties($originalVideoProperties, $presetVideoProperties){
    $colorArray = @('Magenta', 'Yellow', 'Cyan', 'DarkCyan', 'DarkGray', 'Green', 'Blue', 'White', 'Red')
    $videoProperties = [ordered]@{}
    
    if($null -eq $presetVideoProperties){
        for($i = 0; $i -lt $originalVideoProperties.Count; $i++){
            $videoProperties.Add(($originalVideoProperties.GetEnumerator() | select-object -Index $i).Name, $null)
        }
    }
    else{
        for($i = 0; $i -lt $presetVideoProperties.Count; $i++){
            $videoProperties.Add((
                $originalVideoProperties.GetEnumerator() | select-object -Index $i).Name, 
                ($presetVideoProperties.GetEnumerator() | select-object -Index $i).Value
            )
        }
    }

    Write-Host "Changing the same setting more than once will overwrite the last change.`n"

    while($true){
        while($true){
            PrintProperties $originalVideoProperties $videoProperties 'Original' $colorArray
            PrintProperties $originalVideoProperties $videoProperties 'Current' $colorArray

            [string]$videoOption = Read-Host -Prompt "Would you like to change settings, if so which one? [n=No, ra=revert all, q=quit]"
            Write-Host ""

            if($videoOption.ToUpper() -match "^([1-$($videoProperties.Count - 1)]|N|NO)$"){
                Break
            }
            elseif($videoOption.ToUpper() -eq 'RA'){
                Write-Host "All settings have been restored to their default value...`n" -ForegroundColor Yellow

                if($null -eq $presetVideoProperties){
                    for($i = 0; $i -lt $videoProperties.Count; $i++){
                        $videoProperties.(($videoProperties.GetEnumerator() | select-object -Index $i).Name) = $null
                    }
                }
                else{
                    for($i = 0; $i -lt $presetVideoProperties.Count; $i++){
                        $videoProperties.(($videoProperties.GetEnumerator() | select-object -Index $i).Name) = 
                            ($presetVideoProperties.GetEnumerator() | select-object -Index $i).Value
                    }
                }
            }
            elseif($videoOption.ToUpper() -eq 'Q'){
                Quit
            }
            else{
                Write-Host "Invalid input, must be 1-$($videoProperties.Count - 1) or [n, q]...`n"
            }
        }

        if($videoOption.ToUpper() -eq 'N'){
            PrintProperties $originalVideoProperties $videoProperties 'All' $colorArray

            [string]$userAcknowledgment = Read-Host -Prompt "Would you like to continue with these settings? [y/n]"
            Write-Host ""

            if($userAcknowledgment.ToUpper() -eq 'Y' -or $userAcknowledgment.ToUpper() -eq 'YES'){
                write-host "Settings finalized...`n"
                break
            }
            elseIf($userAcknowledgment.ToUpper() -eq 'Q'){
                Quit
            }
        }
        elseif(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "Compression_Level"){
            while($true){
                [string]$compressionLevel = Read-Host -Prompt (("Input desired compression level from 1-10 (10 being highest compression), 'c' to cancel, or 'r'",
                    "to revert to the original compression level") -join " ")
                    Write-Host ""

                if($compressionLevel -match '^([1-9]|10)$'){
                    $videoProperties.Compression_Level = $compressionLevel

                    PrintProperties ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    'Change' `
                    $colorArray[$videoOption - 1]

                    Break
                }
                elseif($compressionLevel.ToUpper() -match '^(C|R|Q)$'){
                    switch($compressionLevel.ToUpper()){
                        'C' {$option = "Cancel"; break}
                        'R' {$option = "Revert"; break}
                        'Q' {Quit; break}
                    }

                    if($compressionLevel.ToUpper() -eq "R"){
                        if($null -ne $presetVideoProperties){
                            $videoProperties.Compression_Level = $presetVideoProperties.Compression_Level
                        }
                        else{
                            $videoProperties.Compression_Level = $originalVideoProperties.Compression_Level
                        }
                    }
                    
                    PrintProperties `
                    ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    $option `
                    $colorArray[$videoOption - 1]

                    break
                }
                else{
                    Write-Host "Invalid compression level, input must be numbers 1-10 (" -NoNewline
                    Write-Host "1" -NoNewline -ForegroundColor Magenta
                    Write-Host " is default)...`n"
                }
            }
        }
        elseif(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "Pixel_Height"){
            Write-Host 'Pixel width will automatically scale based on aspect ratio.' -ForegroundColor Yellow

            while($true){
                [string]$pixelHeight = Read-Host -Prompt "Input new pixel height (example: 1080), 'c' to cancel, or 'r' to revert to the original pixel height"
                Write-Host ""

                if($pixelHeight -match '^([0-9])*$' -and [int]$pixelHeight -le $originalVideoProperties.Pixel_Height -and [int]$pixelHeight -ge 1){
                    $videoProperties.Pixel_Height = $pixelHeight

                    PrintProperties ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    'Change' `
                    $colorArray[$videoOption - 1]

                    Break
                }
                elseif($pixelHeight.ToUpper() -match '^(C|R|Q)$'){
                    switch($pixelHeight.ToUpper()){
                        'C' {$option = "Cancel"; break}
                        'R' {$option = "Revert"; break}
                        'Q' {Quit; break}
                    }

                    if($pixelHeight.ToUpper() -eq "R"){
                        if($null -ne $presetVideoProperties){
                            $videoProperties.Pixel_Height = $presetVideoProperties.Pixel_Height
                        }
                        else{
                            $videoProperties.Pixel_Height = $originalVideoProperties.Pixel_Height
                        }
                    }
                    
                    PrintProperties `
                    ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    $option `
                    $colorArray[$videoOption - 1]

                    break
                }
                else{
                    Write-Host "Invalid pixel height, pixel height can only contain numbers and cannot be larger than the orginal pixel height (" -NoNewline
                    Write-Host "$($originalVideoProperties.Pixel_Height)" -NoNewline -ForegroundColor Yellow
                    Write-Host "). `n"
                }
            }
        }
        elseif(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "FPS"){
            while($true){
                [string]$fps = Read-Host -Prompt "Input new FPS (example: 60), 'c' to cancel, or 'r' to revert to the original FPS"
                Write-Host ""

                if($fps -match '^([0-9])*$' -and [int]$fps -le $originalVideoProperties.FPS -and [int]$fps -ge 1){
                    $videoProperties.FPS = $fps

                    PrintProperties ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    'Change' `
                    $colorArray[$videoOption - 1]

                    Break
                }
                elseif($fps.ToUpper() -match '^(C|R|Q)$'){
                    switch($fps.ToUpper()){
                        'C' {$option = "Cancel"; break}
                        'R' {$option = "Revert"; break}
                        'Q' {Quit; break}
                    }

                    if($fps.ToUpper() -eq "R"){
                        if($null -ne $presetVideoProperties){
                            $videoProperties.FPS = $presetVideoProperties.FPS
                        }
                        else{
                            $videoProperties.FPS = $originalVideoProperties.FPS
                        }
                    }
                    
                    PrintProperties `
                    ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    $option `
                    $colorArray[$videoOption - 1]

                    break
                }
                else{
                    Write-Host "Invalid FPS, FPS can only contain numbers and cannot be larger than the orginal FPS (" -NoNewline
                    Write-Host "$($originalVideoProperties.FPS)" -NoNewline -ForegroundColor Cyan 
                    Write-Host ").`n"
                }
            }
        }
        elseif(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "Audio_Track_Number"){
            while($true){
                [string]$audioTrackNumber = Read-Host -Prompt "Input which audio track you'd like from the old video in the new video (example: 2), 'c' to cancel, or 'r' to revert to the first audio track"
                Write-Host ""

                $audioTrackCount = [Regex]::Match($originalVideoProperties.Audio_Track_Number, "(?<=\/).*").Value

                if($audioTrackNumber -match "^[1-$audioTrackCount]$"){
                    $videoProperties.Audio_Track_Number = "$audioTrackNumber/$audioTrackCount"

                    PrintProperties ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    'Change' `
                    $colorArray[$videoOption - 1]

                    Break
                }
                elseif($audioTrackNumber.ToUpper() -match '^(C|R|Q)$'){
                    switch($audioTrackNumber.ToUpper()){
                        'C' {$option = "Cancel"; break}
                        'R' {$option = "Revert"; break}
                        'Q' {Quit; break}
                    }
                    
                    if($audioTrackNumber.ToUpper() -eq "R"){
                        if($null -ne $presetVideoProperties){
                            $videoProperties.Audio_Track_Number = $presetVideoProperties.Audio_Track_Number
                        }
                        else{
                            $videoProperties.Audio_Track_Number = $originalVideoProperties.Audio_Track_Number
                        }
                    }

                    PrintProperties `
                    ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    $option `
                    $colorArray[$videoOption - 1]

                    break
                }
                else{
                    Write-Host "Invalid audio track number, audio track number cannot be greater than the total number of tracks in a video file (" -NoNewline
                    Write-Host "$audioTrackCount" -NoNewline -ForegroundColor Yellow
                    Write-Host "). `n"
                }
            }
        }
        elseif(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "Audio_Level"){
            Write-Host "Audio level is a desired increase or decrease of audio volume in decibels (examples: 22dB, -6dB)." -ForegroundColor Yellow
            
            while($true){
                [string]$audioTrackLevel = Read-Host -Prompt "Input which audio track you'd like in the new video (example: 2), 'c' to cancel, or 'r' to revert to the first audio track"
                Write-Host ""

                if($audioTrackLevel -match '^-?([0-9]*)$'){
                    $videoProperties.Audio_Level = $audioTrackLevel

                    PrintProperties ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    'Change' `
                    $colorArray[$videoOption - 1]

                    Break
                }
                elseif($audioTrackLevel.ToUpper() -match '^(C|R|Q)$'){
                    switch($audioTrackLevel.ToUpper()){
                        'C' {$option = "Cancel"; break}
                        'R' {$option = "Revert"; break}
                        'Q' {Quit; break}
                    }

                    if($audioTrackLevel.ToUpper() -eq "R"){
                        if($null -ne $presetVideoProperties){
                            $videoProperties.Audio_Level = $presetVideoProperties.Audio_Level
                        }
                        else{
                            $videoProperties.Audio_Level = $originalVideoProperties.Audio_Level
                        }
                    }
                    
                    PrintProperties `
                    ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    $option `
                    $colorArray[$videoOption - 1]

                    break
                }
                else{
                    Write-Host "Invalid audio level, audio level must be a positive or negative number.`n"
                }
            }
        }
        elseif(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "Start_Time"){
            if($null -eq $videoProperties.End_Time){
                [double]$endTimeDuration = [double]$originalVideoProperties.Total_Clip_Duration
            }
            else{
                $endTimeDuration = ConvertTimeStamp $endTime
            }

            while($true){
                [string]$startTime = Read-Host -Prompt (("Input a new start time (example: 00:01:49, 20:56, 20 ([h][h]:[m][m]:[s][s].[ms][ms][ms])), 'c' to cancel, or 'r'",
                    "to revert to the original start time") -join " ")
                    Write-Host ""

                $startTime = FormatTimeStamp $startTime

                if($startTime -match '^([0-9][0-9]:[0-5][0-9]:[0-5][0-9][.][0-9][0-9][0-9])$' -and `
                (ConvertTimeStamp $startTime) -lt $originalVideoProperties.Total_Clip_Duration){
                    $videoProperties.Start_Time = $startTime
                    $startTimeDuration = ConvertTimeStamp $startTime
                    $videoProperties.Total_Clip_Duration = [double]$endTimeDuration - [double]$startTimeDuration

                    PrintProperties ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    'Change' `
                    $colorArray[$videoOption - 1]

                    Break
                }
                elseif($startTime.ToUpper() -match '^(C|R|Q)$'){
                    switch($startTime.ToUpper()){
                        'C' {$option = "Cancel"; break}
                        'R' {$option = "Revert"; break}
                        'Q' {Quit; break}
                    }

                    if($startTime.ToUpper() -eq "R"){
                        if($null -ne $presetVideoProperties){
                            $videoProperties.Start_Time = $presetVideoProperties.Start_Time
                        }
                        else{
                            $videoProperties.Start_Time = $originalVideoProperties.Start_Time
                        }
                    }
                    
                    PrintProperties `
                    ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    $option `
                    $colorArray[$videoOption - 1]

                    break
                }
                else{
                    Write-Host "Invalid start time, make sure that format is correct, and that it doesn't exceed the original clips end time (" -NoNewline
                    Write-Host "$($originalVideoProperties.End_Time)" -NoNewline -ForegroundColor Blue
                    Write-Host "), or preceed a newly enstated start time...`n"
                }
            }
        }
        elseif(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "End_Time"){
            if($null -eq $videoProperties.Start_Time){
                [double]$startTimeDuration = 0
            }
            else{
                $startTimeDuration = ConvertTimeStamp $startTime
            }

            while($true){
                [string]$endTime = Read-Host -Prompt (("Input a new end time (example: 00:01:49, 20:56, 20 ([h][h]:[m][m]:[s][s].[ms][ms][ms])), 'c' to cancel, or 'r'",
                "to revert to the original start time") -join " ")
                Write-Host ""

                $endTime = FormatTimeStamp $endTime

                if($endTime -match '^([0-9][0-9]:[0-5][0-9]:[0-5][0-9][.][0-9][0-9][0-9])$' -and `
                (ConvertTimeStamp $endTime) -le $originalVideoProperties.Total_Clip_Duration -and `
                (ConvertTimeStamp $endTime) -gt $startTimeDuration){
                    $videoProperties.End_Time = $endTime
                    $endTimeDuration = ConvertTimeStamp $endTime
                    $videoProperties.Total_Clip_Duration = [double]$endTimeDuration - [double]$startTimeDuration

                    PrintProperties ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    'Change' `
                    $colorArray[$videoOption - 1]

                    Break
                }
                elseif($endTime.ToUpper() -match '^(C|R|Q)$'){
                    switch($endTime.ToUpper()){
                        'C' {$option = "Cancel"; break}
                        'R' {$option = "Revert"; break}
                        'Q' {Quit; break}
                    }

                    if($endTime.ToUpper() -eq "R"){
                        if($null -ne $presetVideoProperties){
                            $videoProperties.End_Time = $presetVideoProperties.End_Time
                        }
                        else{
                            $videoProperties.End_Time = $originalVideoProperties.End_Time
                        }
                    }
                    
                    PrintProperties `
                    ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    $option `
                    $colorArray[$videoOption - 1]

                    break
                }
                else{
                    Write-Host "Invalid end time, make sure that format is correct, and that it doesn't exceed the original clips end time (" -NoNewline
                    Write-Host "$($originalVideoProperties.End_Time)" -NoNewline -ForegroundColor Blue
                    Write-Host "), or preceed a newly enstated start time...`n"
                }
            }
        }
    }

    return $videoProperties
}

function GetNewFilePath($tag, $filePath){
    $answer = Read-Host "Enter new file name, if left blank name with be autmoatically generate and tagged with `"_$tag`""

    if($null -eq $answer -or $answer -eq ""){
        $newFilePath = "$($filePath.substring(0, $filePath.Length - 4))_$tag.mp4"
    }
    else{
        $newFilepath = "$(Split-Path $filePath -Parent)\$answer.mp4"
    }

    return $newFilePath
}

function GetModificationDate($newFilePath){
    
    if(Test-Path -path $newfilePath){
            $modificationDate = (Get-Item $filePath).LastWriteTime
    }
    else{
        $modificationDate += $false
    }

    return $modificationDate
}


function DeleteExistingFiles($newFilePath){
    if(Test-Path -Path $newFilePath){
        Write-Host "This file already exist:" -ForegroundColor Yellow

        if(Test-Path -Path $newFilePath){
            Write-Host $newFilePath
        }

        $response = Read-Host "`nWould you like to overwrite them? (Deletion will occur upon affirmative response) [y/n]"

        if($response.ToUpper() -eq 'Y' -or $response.ToUpper() -eq 'YES'){
            Write-Host ""

            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile("$newFilePath",'OnlyErrorDialogs','SendToRecycleBin')
            Write-Host "$filePath was deleted..." -ForegroundColor Red
        }
        else{
            Write-Host "`nNo files were deleted..."

            Quit
        }

        Write-Host ""
    }
}


function runFFCommand($argumentList, $program){
    Start-Process -FilePath "C:\ProgramData\chocolatey\lib\ffmpeg\tools\ffmpeg\bin\$program.exe" -Wait -NoNewWindow -ArgumentList $argumentList
}


function TestNewFilePath($newFilePath, $fileModificationDate){
    $errorCounter = 0

    Write-host ""

    if(((Test-Path -path $newFilePath) -and !($fileModificationDate)) -or
    ((Test-Path -path $newFilePath) -and $fileModificationDate -lt (Get-Item $newFilePath).LastWriteTime)){
        Write-Host "File generated succesfully, location: $newFilePath" -ForegroundColor Green
    }
    else{
        $newFileName = $newFilePath.Substring($newFilePath.LastIndexOf("\") + 1)
        Write-Host "File `"$newFileName`" was not generated due to a programmatic or FFmpeg error (see above for FFmpeg errors)..." -ForegroundColor Red
        $errorCounter += 1
    }

    if($errorCounter -ge 1){
        Write-Host "If no FFmpeg errors were generated it is likely a problem with the program and you should report it to the developer." -ForegroundColor Yellow
    }

    Write-Host ""
}


function EndProcess(){
    Write-Host "Process complete, press [Enter] to exit..." -NoNewLine
    $Host.UI.ReadLine()
}