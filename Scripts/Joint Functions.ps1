Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic


function Startup(){
    Write-Host "Starting process and checking for updates...`n"

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    $gitBool = $true

    try{
        git | Out-Null
    }
    catch{
        $gitBool = $false
    }

    if($gitBool){
        $updateBool = $false
        $parentDirectory = $(Split-Path $PSScriptRoot -Parent)

        Set-Location $parentDirectory

        Write-Host "Before"
        git fetch | Out-Null
        Write-Host "After"
        [Array]$checkForUpdates = git status

        foreach($line in $checkForUpdates){
            if($line -match "Your branch is behind"){
                $updateBool = $true
            }
        }

        if($updateBool){
            while($true){
                Write-Host "Updates are available which could fix existing problems and or add new commands, would you like to update right now? [y/n]: " -NoNewLine -ForegroundColor Cyan
                $updateConfirmation = $Host.UI.ReadLine()
                Write-host ""

                if($updateConfirmation -eq 'y'){
                    Write-Host "Starting update process, this process will exit...`n"

                    Start-Sleep 2

                    Start-Process powershell -Verb runAs -WindowStyle Maximized -ArgumentList "-File `"$parentDirectory\Scripts\Setup.ps1`""

                    exit
                }
                elseif($updateConfirmation -eq 'n'){
                    break
                }
                else{
                    Write-Host "Invalid input, please input `"y`" (yes) or `"n`" (no)..."
                }
            }
        }
        else{
            "All files are up to date...`n"
        }
    }
    else{
        Write-Host "Git is not currently installed on this machine, please re-run the `"$parentDirectory\Run me.bat`"" -ForegroundColor Yellow
        Write-Host "file again and say yes to the first prompt.`n" -ForegroundColor Yellow
    }
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
    Write-Host "Input 'q' at any point to to terminate the program."
    Write-Host "File deletion in this program does not completely remove the file from your system, it is moved to the recycle bin and can be recovered." -ForegroundColor Yellow
    Write-Host "UNLESS" -NoNewLine -BackgroundColor DarkRed
    Write-Host " you are agreeing to deletion of a file on a network drive in-which they will be permanently deleted upon affirmative response." -ForegroundColor Yellow
    Write-Host "This program is not compatible with all file types, such as Matroska (.mkv), as it does not have the necessary header information." -ForegroundColor Yellow
    Write-Host "It is possible that there are other file types incompatible with this program that can be excluded from operation in the future.`n" -ForegroundColor Yellow
}


function Quit(){
    write-host('Closing program, press [Enter] to exit...') -NoNewLine
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
        {$_.Pixel_Width -eq 'Yes' -or $_.Resolution -eq 'Yes'} {$optionArray += 'width';}
        {$_.Pixel_Height -eq 'Yes' -or $_.Resolution -eq 'Yes'} {$optionArray += 'height';}
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

    $noPropertyFlag = 0

    foreach($property in $ffpStdOut){
        if($property -eq "[/PROGRAM]"){
            $noPropertyFlag = 1
        }
    }

    $videoPropertyArray = @()
    $programFlag = 0

    foreach($property in $ffpStdOut){
        if($property -eq "[/PROGRAM]"){
            $programFlag = 1
        }
        
        if(
            $noPropertyFlag -eq 0 -or
            ($programFlag -gt 0 -and $property -match "width=|height=|r_frame_rate=|duration=|codec_type=")
        ){
            $videoPropertyArray += $property
        }
    }

    [string]$pixelWidth = $videoPropertyArray | select-string -Pattern "width=" | select-object -First 1
    [string]$pixelHeight = $videoPropertyArray | select-string -Pattern "height=" | select-object -First 1
    [string]$fps = $videoPropertyArray | select-string -Pattern "r_frame_rate=" | select-object -First 1
    [string]$duration = $videoPropertyArray | select-string -Pattern "duration=" | select-object -First 1

    if($videoPropertyArray.Count -eq 0){
        Write-Host "Invalid file, must contain conventional video stream... `n" -ForegroundColor Red

        Quit
    }

    if($originalVideoProperties.Resolution -eq 'Yes' -and $null -ne $pixelWidth -and $null -ne $pixelHeight){
        $originalVideoProperties.Resolution = "$($pixelWidth.Substring($pixelWidth.IndexOf("=") + 1))x$($pixelHeight.Substring($pixelHeight.IndexOf("=") + 1))"
    }

    if($originalVideoProperties.Pixel_Width -eq 'Yes' -and $null -ne $pixelWidth){
        $originalVideoProperties.Pixel_Width = $pixelWidth.Substring($pixelWidth.IndexOf("=") + 1)
    }
    
    if($originalVideoProperties.Pixel_Height -eq 'Yes' -and $null -ne $pixelHeight){
        $originalVideoProperties.Pixel_Height = $pixelHeight.Substring($pixelHeight.IndexOf("=") + 1)
    }
    
    if($null -ne $fps){
        $originalVideoProperties.FPS = [regex]::match($fps,"(?<=\=).*(?=\/)").Value
    }
    
    if($null -ne $duration){
        $originalVideoProperties.Total_Clip_Duration = [double]$duration.Substring($duration.IndexOf("=")+ 1)
    }

    if($originalVideoProperties.End_Time -eq 'Yes' -and $null -ne $duration){
        $originalVideoProperties.End_Time = ConvertDuration $originalVideoProperties.Total_Clip_Duration
    }

    [array]$AudioTrackArray = $videoPropertyArray `
        | select-string -Pattern "(codec_type=audio)" `
        | ForEach-Object {$_.ToString().Split(" ")}

    if($AudioTrackArray.Count -gt 0){
        $originalVideoProperties.Audio_Track_Number = "1/$($AudioTrackArray.Count)"
    }
    elseif($AudioTrackArray.Count -eq 0 -and $originalVideoProperties.Audio_Track_Number -eq 'Yes'){
        $originalVideoProperties.Remove("Audio_Track_Number")
        $originalVideoProperties.Remove("Audio_Level")

        write-host "There are no audio tracks in this file, audio modification has been disabled.`n" -ForegroundColor Yellow
    }

    return $originalVideoProperties
}


function PrintProperties($originalVideoProperties, $videoProperties, $type, $colors){
    if($type -eq 'Original'){
        Write-Host "Original properties: " -NoNewline
        for($i = 0; $i -lt $originalVideoProperties.Count; $i++){
            if($i -eq 6){
                Write-Host ""
            }

            Write-Host "[$(($originalVideoProperties.GetEnumerator() | select-object -Index $i).Name -replace '_',' ') = " -NoNewline -ForegroundColor $colors[$i]
            Write-Host "$(($originalVideoProperties.GetEnumerator() | select-object -Index $i).value)]" -NoNewline -ForegroundColor $colors[$i]
            
            if($i -eq $originalVideoProperties.Count -1){
                Write-Host ""
            }
            elseif(($originalVideoProperties.GetEnumerator() | select-object -Index $i).Name -match "^Total_Clip_Duration$|^Resolution$"){
                Write-Host " " -NoNewLine
            }
            else{
                Write-Host "/$($i + 1) " -NoNewline -ForegroundColor $colors[$i]
            }         
        }
    }
    elseif($type -eq 'Current'){
        Write-Host "Current properties : " -NoNewline
        for($i = 0; $i -lt $originalVideoProperties.Count; $i++){
            if($i -eq 6){
                Write-Host ""
            }

            Write-Host "[$(($originalVideoProperties.GetEnumerator() | select-object -Index $i).Name -replace '_',' ') = " -NoNewline -ForegroundColor $colors[$i]

            if($null -eq ($videoProperties.GetEnumerator() | select-object -Index $i).value){
                Write-Host "$(($originalVideoProperties.GetEnumerator() | select-object -Index $i).value)]" -NoNewline -ForegroundColor $colors[$i]
                
                if($i -eq $originalVideoProperties.Count -1){
                    Write-Host ""
                }
                elseif(($originalVideoProperties.GetEnumerator() | select-object -Index $i).Name -match "^Total_Clip_Duration$|^Resolution$"){
                    Write-Host " " -NoNewLine
                }
                else{
                    Write-Host "/$($i + 1) " -NoNewline -ForegroundColor $colors[$i]
                }
            }
            else{
                Write-Host "$(($videoProperties.GetEnumerator() | select-object -Index $i).value)]" -NoNewline -ForegroundColor $colors[$i]
                
                if($i -eq $originalVideoProperties.Count -1){
                    Write-Host ""
                }
                elseif(($videoProperties.GetEnumerator() | select-object -Index $i).Name -match "^Total_Clip_Duration$|^Resolution$"){
                    Write-Host " " -NoNewLine
                }
                else{
                    Write-Host "/$($i + 1) " -NoNewline -ForegroundColor $colors[$i]
                }
            }        
        }
    }
    elseif($type -eq 'Change'){
        Write-Host "$($videoProperties.Name -replace '_',' ') " -NoNewline -ForegroundColor $colors
        write-host "changed to " -NoNewline
        if($null -eq $videoProperties.Value){
            Write-Host "$($originalVideoProperties.value)" -NoNewline -ForegroundColor $colors
        }
        else{
            Write-Host "$($videoProperties.value)" -NoNewline -ForegroundColor $colors
        }
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
    elseif($type -eq 'Test'){
        for($i = 0; $i -lt $originalVideoProperties.Count; $i++){
            Write-Host "$(($originalVideoProperties.GetEnumerator() | select-object -Index $i).Name -replace '_',' ') = " -NoNewline
            Write-Host "$(($originalVideoProperties.GetEnumerator() | select-object -Index $i).value)"
        }

        Write-Host ""
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


function GetVideoProperties($originalVideoProperties, $videoProperties, $presetVideoProperties){
    $colorArray = @('Magenta', 'DarkGray', 'Yellow', 'White', 'Cyan', 'DarkCyan', 'Green', 'DarkGreen', 'Blue', 'Gray')
    
    if($null -eq $videoProperties){
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
    }

    Write-Host "Changing the same setting more than once will overwrite the last change.`n"

    :outer while($true){
        while($true){
            PrintProperties $originalVideoProperties $videoProperties 'Original' $colorArray
            PrintProperties $originalVideoProperties $videoProperties 'Current' $colorArray

            $nonOptionCount = 0

            for($i = 0; $i -lt $videoProperties.Count; $i++){
                if(($videoProperties.GetEnumerator() | select-object -Index $i).Name -eq "Total_Clip_Duration" -or
                ($videoProperties.GetEnumerator() | select-object -Index $i).Name -eq "Resolution"){
                    $nonOptionCount += 1
                }
            }

            [string]$videoOption = Read-Host -Prompt "Would you like to change settings, if so which one? [n=No, ra=revert all, q=quit]"
            Write-Host ""

            if($videoOption.ToUpper() -match "^([1-$($videoProperties.Count - $nonOptionCount)]|N)$"){
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
                Write-Host "Invalid input, must be 1-$($videoProperties.Count - $nonOptionCount) or [n, q]...`n"
            }
        }

        if($videoOption.ToUpper() -eq 'N'){
            PrintProperties $originalVideoProperties $videoProperties 'All' $colorArray

            while($true){
                [string]$userAcknowledgment = Read-Host -Prompt "Would you like to continue with these settings? [y/n]"
                Write-Host ""

                if($userAcknowledgment.ToUpper() -eq 'Y' -or $userAcknowledgment.ToUpper() -eq 'YES'){
                    write-host "Settings finalized...`n"
                    break outer
                }
                elseIf($userAcknowledgment.ToUpper() -eq 'Q'){
                    Quit
                }
                elseif($userAcknowledgment.ToUpper() -eq 'N'){
                    break
                }
                else{
                    Write-Host "Invalid input, please input `"y`" (yes) or `"n`" (no)..."
                }
            }
        }
        elseif(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "Compression_Level"){
            Write-Host "Comrpession level can be set from 0-51, with 0 being the lowest level of compression but largest file size,"
            Write-Host "and 51 being the highest level of compression with lowest file size."
            Write-Host "However, it's worth noting that values below 15 can actually result in an output file larger than the original,"
            Write-Host "and that values from 15-18 are typically considered `"visually losses`" while still decreasing file size.`n"

            while($true){
                [string]$compressionLevel = Read-Host "Input desired compression level"
                    Write-Host ""

                if($compressionLevel -match '^([0-9]|[1-4][0-9]|[5][0-1])$'){
                    if($compressionLevel -eq $originalVideoProperties.Compression_Level){
                        $videoProperties.Compression_Level = $null
                    }
                    else{
                        $videoProperties.Compression_Level = $compressionLevel
                    }

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
                            $videoProperties.Compression_Level = $null
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
        elseif(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "Pixel_Width"){
            if($videoProperties.Pixel_Height -match "^$|^Auto$" -and $null -eq $videoProperties.Pad){
                Write-Host "Pixel Height will automatically scale based on Pixel width and aspect ratio if Pixel Height has not been changed from its original value." -ForegroundColor Yellow
                Write-Host "Auto can be set manually on pixel width or pixel height if needed by entering `"Auto`" (case insensitive)." -ForegroundColor Yellow
                Write-Host "Setting pixel width or height to its original value manually will count as changing its original value.`n" -ForegroundColor Yellow
            }
            elseif($null -eq $videoProperties.Pad -and ($videoProperties.Pixel_Width -match "^$|^Auto$" -or $videoProperties.Pixel_Height -match "^$|^Auto$")){
                Write-Host "Auto can be set manually on pixel width or pixel height if needed by entering `"Auto`" (case insensitive)." -ForegroundColor Yellow
                Write-Host "Warning:" -BackgroundColor DarkRed -NoNewline
                Write-Host " If both pixel width and pixel height are changed and Pad is not enabled output video could be distorted.`n" -ForegroundColor Yellow
            }
            else{
                Write-Host "Auto can be set manually on pixel width or pixel height if needed by entering `"Auto`" (case insensitive).`n" -ForegroundColor Yellow
            }

            while($true){
                [string]$pixelWidth = Read-Host -Prompt "Input new pixel width (example: 1920), 'c' to cancel, or 'r' to revert to the original pixel width"
                Write-Host ""

                if(($pixelWidth -eq "Auto") -or ($pixelWidth -match '^([0-9])*$' -and [int]$pixelWidth -ge 1)){
                    $videoProperties.Pixel_Width = $pixelWidth

                    if($null -eq $videoProperties.Pixel_Height  -and $pixelWidth -ne "Auto"){
                        $videoProperties.Pixel_Height = "Auto"
                    }

                    PrintProperties ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    'Change' `
                    $colorArray[$videoOption - 1]

                    Break
                }
                elseif($pixelWidth.ToUpper() -match '^(C|R|Q)$'){
                    switch($pixelWidth.ToUpper()){
                        'C' {$option = "Cancel"; break}
                        'R' {$option = "Revert"; break}
                        'Q' {Quit; break}
                    }

                    if($pixelWidth.ToUpper() -eq "R"){
                        if($null -ne $presetVideoProperties){
                            $videoProperties.Pixel_Width = $presetVideoProperties.Pixel_Width
                        }
                        else{
                            if(!($videoProperties.Pixel_Height -match "^$|^Auto$")){
                                $videoProperties.Pixel_Width = "Auto"
                            }
                            else{
                                $videoProperties.Pixel_Width = $null
                            }
                        }

                        if($videoProperties.Pixel_Height -eq "Auto"){
                            if($null -ne $presetVideoProperties){
                                $videoProperties.Pixel_Height = $presetVideoProperties.Pixel_Height
                            }
                            else{
                                $videoProperties.Pixel_Height = $null
                            }
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
                    Write-Host "Invalid pixel width, pixel width can only contain numbers.`n"
                }
            }
        }
        elseif(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "Pixel_Height"){
            if($videoProperties.Pixel_Width -match "^$|^Auto$" -and $null -eq $videoProperties.Pad){
                Write-Host "Pixel width will automatically scale based on Pixel Height and aspect ratio if Pixel Width has not been changed from its original value." -ForegroundColor Yellow
                Write-Host "Auto can be set manually on pixel width or pixel height if needed by entering `"Auto`" (case insensitive)." -ForegroundColor Yellow
                Write-Host "Setting pixel width or height to its original value manually will count as changing its original value.`n" -ForegroundColor Yellow
            }
            elseif($null -eq $videoProperties.Pad -and ($videoProperties.Pixel_Width -match "^$|^Auto$" -or $videoProperties.Pixel_Height -match "^$|^Auto$")){
                Write-Host "Auto can be set manually on pixel width or pixel height if needed by entering `"Auto`" (case insensitive)." -ForegroundColor Yellow
                Write-Host "Warning:" -BackgroundColor DarkRed -NoNewline
                Write-Host " If both pixel width and pixel height are changed and Pad is not enabled output video could be distorted.`n" -ForegroundColor Yellow
            }
            else{
                Write-Host "Auto can be set manually on pixel width or pixel height if needed by entering `"Auto`" (case insensitive).`n" -ForegroundColor Yellow
            }

            while($true){
                [string]$pixelHeight = Read-Host -Prompt "Input new pixel height (example: 1080), 'c' to cancel, or 'r' to revert to the original pixel height"
                Write-Host ""

                if(($pixelHeight -eq "Auto") -or ($pixelHeight -match '^([0-9])*$' -and [int]$pixelHeight -ge 1)){
                    $videoProperties.Pixel_Height = $pixelHeight

                    if($null -eq $videoProperties.Pixel_Width -and $pixelHeight -ne "Auto"){
                        $videoProperties.Pixel_Width = "Auto"
                    }

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
                            if(!($videoProperties.Pixel_Width -match "^$|^Auto$")){
                                $videoProperties.Pixel_Height = "Auto"
                            }
                            else{
                                $videoProperties.Pixel_Height = $null
                            }
                        }

                        if($videoProperties.Pixel_Width -eq "Auto"){
                            if($null -ne $presetVideoProperties){
                                $videoProperties.Pixel_Width = $presetVideoProperties.Pixel_Width
                            }
                            else{
                                $videoProperties.Pixel_Width = $null
                            }
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
                    Write-Host "Invalid pixel height, pixel height can only contain numbers.`n"
                }
            }
        }
        elseif(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "Pad"){
            Write-Host "When pad is enabled the original aspect ratio of the video will be preserved regardless of what you change pixel width and pixel height to." -ForegroundColor Yellow

            if($videoProperties.Pixel_Width -match "^$|^Auto$" -or $videoProperties.Pixel_Height -match "^$|^Auto$"){
                Write-Host "Enabling Pad without changing both pixel width and pixel Height will have no effect on the output video.`n" -ForegroundColor Yellow
            }
            elseif(!($videoProperties.Pixel_Width -match "^$|^Auto$") -and !($videoProperties.Pixel_Height -match "^$|^Auto$") -and $null -ne $videoProperties.Pad){
                Write-Host "Warning:" -BackgroundColor DarkRed -NoNewline
                Write-Host " Disabling pad when both pixel width and pixel height have been changed could result in distortion of the output video.`n" -ForegroundColor Yellow
            }
            else{
                Write-Host ""
            }

            while($true){
                [string]$pad = Read-Host -Prompt "Would you like to pad the new video? [y/n]"
                Write-Host ""

                if($pad.ToUpper() -match "^(Y|N)$"){
                    if($pad -eq $originalVideoProperties.Pad){
                        $videoProperties.Pad = $null
                    }
                    else{
                        $videoProperties.Pad = $pad
                    }

                    PrintProperties ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    'Change' `
                    $colorArray[$videoOption - 1]

                    Break
                }
                elseif($pad.ToUpper() -match '^(C|R|Q)$'){
                    switch($pad.ToUpper()){
                        'C' {$option = "Cancel"; break}
                        'R' {$option = "Revert"; break}
                        'Q' {Quit; break}
                    }

                    if($pad.ToUpper() -eq "R"){
                        if($null -ne $presetVideoProperties){
                            $videoProperties.Pad = $presetVideoProperties.Pad
                        }
                        else{
                            $videoProperties.Pad = $null
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
                    Write-Host "Invalid input, pad must be set to `"y`" (yes) or `"n`" (no).`n"
                }
            }
        }
        elseif(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "FPS"){
            while($true){
                [string]$fps = Read-Host -Prompt "Input new FPS (example: 60), 'c' to cancel, or 'r' to revert to the original FPS"
                Write-Host ""

                if($fps -match '^([0-9])*$' -and [int]$fps -le $originalVideoProperties.FPS -and [int]$fps -ge 1){
                    if($fps -eq $originalVideoProperties.FPS){
                        $videoProperties.FPS = $null
                    }
                    else{
                        $videoProperties.FPS = $fps
                    }

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
                            $videoProperties.FPS = $null
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
                    if($audioTrackNumber -eq $originalVideoProperties.Audio_Track_Number){
                        $videoProperties.Audio_Track_Number = $null
                    }
                    else{
                        $videoProperties.Audio_Track_Number = $audioTrackNumber
                    }

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
                            $videoProperties.Audio_Track_Number = $null
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
                [string]$audioLevel = Read-Host -Prompt "Input which audio track you'd like in the new video (example: 2), 'c' to cancel, or 'r' to revert to the first audio track"
                Write-Host ""

                if($audioLevel -match '^-?([0-9]*)$'){
                    if($audioLevel -eq $originalVideoProperties.Audio_Level){
                        $videoProperties.Audio_Level = $null
                    }
                    else{
                        $videoProperties.Audio_Level = $audioLevel
                    }

                    PrintProperties ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    'Change' `
                    $colorArray[$videoOption - 1]

                    Break
                }
                elseif($audioLevel.ToUpper() -match '^(C|R|Q)$'){
                    switch($audioLevel.ToUpper()){
                        'C' {$option = "Cancel"; break}
                        'R' {$option = "Revert"; break}
                        'Q' {Quit; break}
                    }

                    if($audioLevel.ToUpper() -eq "R"){
                        if($null -ne $presetVideoProperties){
                            $videoProperties.Audio_Level = $presetVideoProperties.Audio_Level
                        }
                        else{
                            $videoProperties.Audio_Level = $null
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
        elseIf(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "Left_Crop"){
            $width = $originalVideoProperties.Resolution.Substring(0, $originalVideoProperties.Resolution.IndexOf("x"))

            if($null -eq $videoProperties.Resolution){
                if($null -eq $presetVideoProperties){
                    $height = $originalVideoProperties.Resolution.Substring($originalVideoProperties.Resolution.IndexOf("x") + 1)
                }
                else{
                    $height = $presetVideoProperties.Resolution.Substring($originalVideoProperties.Resolution.IndexOf("x") + 1)
                }
            }
            else{
                $height = $videoProperties.Resolution.Substring($videoProperties.Resolution.IndexOf("x") + 1)
            }
            
            if($null -eq $videoProperties.Right_Crop){
                if($null -eq $presetVideoProperties){
                    $rightCrop = $originalVideoProperties.Right_Crop
                }
                else{
                    $rightCrop = $presetVideoProperties.Right_Crop
                }
            }
            else{
                $rightCrop = $videoProperties.Right_Crop
            }

            while($true){
                [string]$leftCrop = Read-Host -Prompt "Input how much you'd like to crop the left side of the video (example: 480), 'c' to cancel, or 'r' to revert to the first audio track"
                Write-Host ""

                if($leftCrop.ToUpper() -match '^(C|R|Q)$'){
                    switch($leftCrop.ToUpper()){
                        'C' {$option = "Cancel"; break}
                        'R' {$option = "Revert"; break}
                        'Q' {Quit; break}
                    }

                    if($leftCrop.ToUpper() -eq "R"){
                        if($null -ne $presetVideoProperties){
                            $videoProperties.Left_Crop = $presetVideoProperties.Left_Crop

                            $resolution = "$([int]$width - [int]$presetVideoProperties.LeftCrop - [int]$rightCrop)x$($height)"

                            if($resolution -eq $originalVideoProperties.Resolution){
                                $videoProperties.Resolution = $null
                            }
                            else{
                                $videoProperties.Resolution = $resolution
                            }
                        }
                        else{
                            $videoProperties.Left_Crop = $null

                            $resolution = "$([int]$width - [int]$rightCrop)x$($height)"

                            if($resolution -eq $originalVideoProperties.Resolution){
                                $videoProperties.Resolution = $null
                            }
                            else{
                                $videoProperties.Resolution = $resolution
                            }
                        }
                    }
                    
                    PrintProperties `
                    ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    $option `
                    $colorArray[$videoOption - 1]

                    break
                }
                elseif([int]$width -gt [int]$leftCrop + [int]$rightCrop -and $leftCrop -match '^([0-9])*$'){
                    if($leftCrop -eq $originalVideoProperties.Left_Crop){
                        $videoProperties.Left_Crop = $null
                    }
                    else{
                        $videoProperties.Left_Crop = $leftCrop
                    }

                    if($leftCrop -eq "0" -and $rightCrop -eq "0"){
                        $resolution = "$($width)x$($height)"
                    }
                    else{
                        $resolution = "$([int]$width - [int]$leftCrop - [int]$rightCrop)x$($height)"
                    }

                    if($resolution -eq $originalVideoProperties.Resolution){
                        $videoProperties.Resolution = $null
                    }
                    else{
                        $videoProperties.Resolution = $resolution
                    }

                    PrintProperties ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    'Change' `
                    $colorArray[$videoOption - 1]

                    Break
                }
                else{
                    Write-Host "Invalid left crop, left crop must be a number and less than total pixel width,"
                    Write-Host "right crop must also be taken into account (Width > (Left + Right))...`n"
                }
            }
        }
        elseIf(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "Right_Crop"){
            $width = $originalVideoProperties.Resolution.Substring(0, $originalVideoProperties.Resolution.IndexOf("x"))

            if($null -eq $videoProperties.Resolution){
                if($null -eq $presetVideoProperties){
                    $height = $originalVideoProperties.Resolution.Substring($originalVideoProperties.Resolution.IndexOf("x") + 1)
                }
                else{
                    $height = $presetVideoProperties.Resolution.Substring($originalVideoProperties.Resolution.IndexOf("x") + 1)
                }
            }
            else{
                $height = $videoProperties.Resolution.Substring($videoProperties.Resolution.IndexOf("x") + 1)
            }
            
            if($null -eq $videoProperties.Left_Crop){
                if($null -eq $presetVideoProperties){
                    $leftCrop = $originalVideoProperties.Left_Crop
                }
                else{
                    $leftCrop = $presetVideoProperties.Left_Crop
                }
            }
            else{
                $leftCrop = $videoProperties.Left_Crop
            }

            while($true){
                [string]$rightCrop = Read-Host -Prompt "Input how much you'd like to crop the right side of the video (example: 480), 'c' to cancel, or 'r' to revert to the first audio track"
                Write-Host ""

                if($rightCrop.ToUpper() -match '^(C|R|Q)$'){
                    switch($rightCrop.ToUpper()){
                        'C' {$option = "Cancel"; break}
                        'R' {$option = "Revert"; break}
                        'Q' {Quit; break}
                    }

                    if($rightCrop.ToUpper() -eq "R"){
                        if($null -ne $presetVideoProperties){
                            $videoProperties.Right_Crop = $presetVideoProperties.Right_Crop

                            $resolution = "$([int]$width - [int]$leftCrop - [int]$presetVideoProperties.Right_Crop)x$($height)"

                            if($resolution -eq $originalVideoProperties.Resolution){
                                $videoProperties.Resolution = $null
                            }
                            else{
                                $videoProperties.Resolution = $resolution
                            }
                        }
                        else{
                            $videoProperties.Right_Crop = $null

                            $resolution = "$([int]$width - [int]$leftCrop)x$($height)"

                            if($resolution -eq $originalVideoProperties.Resolution){
                                $videoProperties.Resolution = $null
                            }
                            else{
                                $videoProperties.Resolution = $resolution
                            }
                        }
                    }
                    
                    PrintProperties `
                    ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    $option `
                    $colorArray[$videoOption - 1]

                    break
                }
                elseif([int]$width -gt [int]$leftCrop + [int]$rightCrop -and $rightCrop -match '^([0-9])*$'){
                    if($rightCrop -eq $originalVideoProperties.Right_Crop){
                        $videoProperties.Right_Crop = $null
                    }
                    else{
                        $videoProperties.Right_Crop = $rightCrop
                    }

                    if($leftCrop -eq 0 -and $rightCrop -eq 0){
                        $resolution = "$($width)x$($height)"
                    }
                    else{
                        $resolution = "$([int]$width - [int]$leftCrop - [int]$rightCrop)x$($height)"
                    }

                    if($resolution -eq $originalVideoProperties.Resolution){
                        $videoProperties.Resolution = $null
                    }
                    else{
                        $videoProperties.Resolution = $resolution
                    }

                    PrintProperties ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    'Change' `
                    $colorArray[$videoOption - 1]

                    Break
                }
                else{
                    Write-Host "Invalid right crop, right crop must be a number and less than total pixel width,"
                    Write-Host "left crop must also be taken into account (Width > (Left + Right))...`n"
                }
            }
        }
        elseIf(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "Top_Crop"){
            if($null -eq $videoProperties.Resolution){
                if($null -eq $presetVideoProperties){
                    $width = $originalVideoProperties.Resolution.Substring(0, $originalVideoProperties.Resolution.IndexOf("x"))
                }
                else{
                    $width = $presetVideoProperties.Resolution.Substring(0, $originalVideoProperties.Resolution.IndexOf("x"))
                }
            }
            else{
                $width = $videoProperties.Resolution.Substring(0, $videoProperties.Resolution.IndexOf("x"))
            }

            $height = $originalVideoProperties.Resolution.Substring($originalVideoProperties.Resolution.IndexOf("x") + 1)
            
            if($null -eq $videoProperties.Bottom_Crop){
                if($null -eq $presetVideoProperties){
                    $bottomCrop = $originalVideoProperties.Bottom_Crop
                }
                else{
                    $bottomCrop = $presetVideoProperties.Bottom_Crop
                }
            }
            else{
                $bottomCrop = $videoProperties.Bottom_Crop
            }

            while($true){
                [string]$topCrop = Read-Host -Prompt "Input how much you'd like to crop the top of the video (example: 480), 'c' to cancel, or 'r' to revert to the first audio track"
                Write-Host ""

                if($topCrop.ToUpper() -match '^(C|R|Q)$'){
                    switch($topCrop.ToUpper()){
                        'C' {$option = "Cancel"; break}
                        'R' {$option = "Revert"; break}
                        'Q' {Quit; break}
                    }

                    if($topCrop.ToUpper() -eq "R"){
                        if($null -ne $presetVideoProperties){
                            $videoProperties.Top_Crop = $presetVideoProperties.Top_Crop

                            $resolution = "$($width)x$([int]$height - [int]$presetVideoProperties.Top_Crop - [int]$bottomCrop)"

                            if($resolution -eq $originalVideoProperties.Resolution){
                                $videoProperties.Resolution = $null
                            }
                            else{
                                $videoProperties.Resolution = $resolution
                            }
                        }
                        else{
                            $videoProperties.Top_Crop = $null

                            $resolution = "$($width)x$([int]$height - [int]$bottomCrop)"

                            if($resolution -eq $originalVideoProperties.Resolution){
                                $videoProperties.Resolution = $null
                            }
                            else{
                                $videoProperties.Resolution = $resolution
                            }
                        }
                    }
                    
                    PrintProperties `
                    ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    $option `
                    $colorArray[$videoOption - 1]

                    break
                }
                elseif([int]$height -gt [int]$topCrop + [int]$bottomCrop -and $topCrop -match '^([0-9])*$'){
                    if($topCrop -eq $originalVideoProperties.Top_Crop){
                        $videoProperties.Top_Crop = $null
                    }
                    else{
                        $videoProperties.Top_Crop = $topCrop
                    }

                    if($topCrop -eq 0 -and $bottomCrop -eq 0){
                        $resolution = "$($width)x$($height)"
                    }
                    else{
                        $resolution = "$($width)x$([int]$height - [int]$topCrop - [int]$bottomCrop)"
                    }

                    if($resolution -eq $originalVideoProperties.Resolution){
                        $videoProperties.Resolution = $null
                    }
                    else{
                        $videoProperties.Resolution = $resolution
                    }

                    PrintProperties ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    'Change' `
                    $colorArray[$videoOption - 1]

                    Break
                }
                else{
                    Write-Host "Invalid top crop, top crop must be a number and less than total pixel height,"
                    Write-Host "bottom crop must also be taken into account (Height > (Top + Bottom))...`n"
                }
            }
        }
        elseIf(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "Bottom_Crop"){
            if($null -eq $videoProperties.Resolution){
                if($null -eq $presetVideoProperties){
                    $width = $originalVideoProperties.Resolution.Substring(0, $originalVideoProperties.Resolution.IndexOf("x"))
                }
                else{
                    $width = $presetVideoProperties.Resolution.Substring(0, $originalVideoProperties.Resolution.IndexOf("x"))
                }
            }
            else{
                $width = $videoProperties.Resolution.Substring(0, $videoProperties.Resolution.IndexOf("x"))
            }

            $height = $originalVideoProperties.Resolution.Substring($originalVideoProperties.Resolution.IndexOf("x") + 1)
            
            if($null -eq $videoProperties.Top_Crop){
                if($null -eq $presetVideoProperties){
                    $topCrop = $originalVideoProperties.Top_Crop
                }
                else{
                    $topCrop = $presetVideoProperties.Top_Crop
                }
            }
            else{
                $topCrop = $videoProperties.Top_Crop
            }

            while($true){
                [string]$bottomCrop = Read-Host -Prompt "Input how much you'd like to crop the top of the video (example: 480), 'c' to cancel, or 'r' to revert to the first audio track"
                Write-Host ""

                if($bottomCrop.ToUpper() -match '^(C|R|Q)$'){
                    switch($bottomCrop.ToUpper()){
                        'C' {$option = "Cancel"; break}
                        'R' {$option = "Revert"; break}
                        'Q' {Quit; break}
                    }

                    if($bottomCrop.ToUpper() -eq "R"){
                        if($null -ne $presetVideoProperties){
                            $videoProperties.Bottom_Crop = $presetVideoProperties.Bottom_Crop

                            $resolution = "$($width)x$([int]$height - [int]$topCrop - [int]$presetVideoProperties.Bottom_Crop)"

                            if($resolution -eq $originalVideoProperties.Resolution){
                                $videoProperties.Resolution = $null
                            }
                            else{
                                $videoProperties.Resolution = $resolution
                            }
                        }
                        else{
                            $videoProperties.Bottom_Crop = $null

                            $resolution = "$($width)x$([int]$height - [int]$topCrop)"

                            if($resolution -eq $originalVideoProperties.Resolution){
                                $videoProperties.Resolution = $null
                            }
                            else{
                                $videoProperties.Resolution = $resolution
                            }
                        }
                    }
                    
                    PrintProperties `
                    ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    $option `
                    $colorArray[$videoOption - 1]

                    break
                }
                elseif([int]$height -gt [int]$topCrop + [int]$bottomCrop -and $bottomCrop -match '^([0-9])*$'){
                    if($bottomCrop -eq $originalVideoProperties.Bottom_Crop){
                        $videoProperties.Bottom_Crop = $null
                    }
                    else{
                        $videoProperties.Bottom_Crop = $bottomCrop
                    }

                    if($topCrop -eq 0 -and $bottomCrop -eq 0){
                        $resolution = "$($width)x$($height)"
                    }
                    else{
                        $resolution = "$($width)x$([int]$height - [int]$topCrop - [int]$bottomCrop)"
                    }

                    if($resolution -eq $originalVideoProperties.Resolution){
                        $videoProperties.Resolution = $null
                    }
                    else{
                        $videoProperties.Resolution = $resolution
                    }

                    PrintProperties ($originalVideoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    ($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)) `
                    'Change' `
                    $colorArray[$videoOption - 1]

                    Break
                }
                else{
                    Write-Host "Invalid bottom crop, bottom crop must be a number and less than total pixel height,"
                    Write-Host "top crop must also be taken into account (Height > (Top + Bottom))...`n"
                }
            }
        }
        elseif(($videoProperties.GetEnumerator() | select-object -Index ($videoOption - 1)).Name -eq "Start_Time"){
            if($null -eq $videoProperties.End_Time){
                [double]$endTimeDuration = [double]$originalVideoProperties.Total_Clip_Duration
            }
            else{
                $endTimeDuration = ConvertTimeStamp $videoProperties.End_Time
            }

            while($true){
                [string]$startTime = Read-Host -Prompt (("Input a new start time (example: 00:01:49, 20:56, 20 ([h][h]:[m][m]:[s][s].[ms][ms][ms])), 'c' to cancel, or 'r'",
                    "to revert to the original start time") -join " ")
                    Write-Host ""

                $startTime = FormatTimeStamp $startTime

                if($startTime -match '^([0-9][0-9]:[0-5][0-9]:[0-5][0-9][.][0-9][0-9][0-9])$' -and `
                (ConvertTimeStamp $startTime) -lt $originalVideoProperties.Total_Clip_Duration){
                    if($startTime -eq $originalVideoProperties.Start_Time){
                        $videoProperties.Start_Time = $null
                    }
                    else{
                        $videoProperties.Start_Time = $startTime
                    }

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

                            if($null -eq $videoProperties.End_Time){
                                $videoProperties.Duraion = $originalVideoProperties.Total_Clip_Duration - (ConvertTimeStamp $presetVideoProperties.Start_Time)
                            }
                            else{
                                $videoProperties.Duraion = (ConvertTimeStamp $videoProperties.End_Time) - (ConvertTimeStamp $presetVideoProperties.Start_Time)
                            }
                        }
                        else{
                            $videoProperties.Start_Time = $null

                            if($null -eq $videoProperties.End_Time){
                                $videoProperties.Total_Clip_Duration = $null
                            }
                            else{
                                $videoProperties.Total_Clip_Duration = (ConvertTimeStamp $videoProperties.End_Time) - (ConvertTimeStamp $originalVideoProperties.Start_Time)
                            }
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
                $startTimeDuration = ConvertTimeStamp $videoProperties.Start_Time
            }

            while($true){
                [string]$endTime = Read-Host -Prompt (("Input a new end time (example: 00:01:49, 20:56, 20 ([h][h]:[m][m]:[s][s].[ms][ms][ms])), 'c' to cancel, or 'r'",
                "to revert to the original start time") -join " ")
                Write-Host ""

                $endTime = FormatTimeStamp $endTime

                if($endTime -match '^([0-9][0-9]:[0-5][0-9]:[0-5][0-9][.][0-9][0-9][0-9])$' -and `
                (ConvertTimeStamp $endTime) -le $originalVideoProperties.Total_Clip_Duration -and `
                (ConvertTimeStamp $endTime) -gt $startTimeDuration){
                    if($endTime -eq $originalVideoProperties.End_Time){
                        $videoProperties.End_Time = $null
                    }
                    else{
                        $videoProperties.End_Time = $endTime
                    }

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

                            if($null -eq $videoProperties.Start_Time){
                                $videoProperties.Total_Clip_Duration = (ConvertTimeStamp $presetVideoProperties.End_Time) - (ConvertTimeStamp $originalVideoProperties.Start_Time)
                            }
                            else{
                                $videoProperties.Total_Clip_Duration = (ConvertTimeStamp $presetVideoProperties.End_Time) - (ConvertTimeStamp $videoProperties.Start_Time)
                            }
                        }
                        else{
                            $videoProperties.End_Time = $null

                            if($null -eq $videoProperties.Start_Time){
                                $videoProperties.Total_Clip_Duration = $null
                            }
                            else{
                                $videoProperties.Total_Clip_Duration = (ConvertTimeStamp $originalVideoProperties.End_Time) - (ConvertTimeStamp $videoProperties.Start_Time)
                            }
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
    $answer = Read-Host "Enter new file name, if left blank name will be autmoatically generate and tagged with `"_$tag`""
    Write-host ""

    if($tag -eq "Gif"){
        $extension = "gif"
    }
    elseif($tag -eq "Concatenated"){
        $extension = $filePath.Substring($filePath.LastIndexOf(".") + 1)
    }
    else{
        $extension = "mp4"
    }

    if($null -eq $answer -or $answer -eq ""){
        $newFilePath = "$($filePath.Substring(0, $filePath.LastIndexOf(".")))_$tag.$extension"
    }
    else{
        $newFilepath = "$(Split-Path $filePath -Parent)\$answer.$extension"
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


function DeleteExistingFiles($tag, $newFilePath){
    if(Test-Path -Path $newFilePath){
        Write-Host "This file already exist:" -ForegroundColor Yellow

        if(Test-Path -Path $newFilePath){
            Write-Host $newFilePath
        }

        $response = Read-Host "`nWould you like to overwrite them? (Deletion will occur upon affirmative response) [y/n]"
        Write-Host ""

        :outer while($true){
            if($response.ToUpper() -eq 'Y' -or $response.ToUpper() -eq 'YES'){
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile("$newFilePath",'OnlyErrorDialogs','SendToRecycleBin')
                Write-Host "$filePath was deleted...`n" -ForegroundColor Red

                break
            }
            elseif($response.ToUpper() -eq 'N'){
                while($true){
                    $newestFilePath = GetNewFilePath $tag $filePath 

                    if($newestFilePath.ToUpper() -eq "Q"){
                        Quit
                    }
                    elseif($newestFilePath.ToUpper() -eq $newFilePath.ToUpper()){
                        Write-Host "You said you wanted to change the output file name to avoid deletion of an existing file but then you didn't actually change the name, try again..."
                    }
                    else{
                        $newFilePath = $newestFilePath

                        break outer
                    }
                }
            }
            else{
                Write-Host "Invalid input, answer must be `"y`" (Yes), `"n`" (No), or `"q`" (quit)..."
            }
        }
    }

    return $newFilePath
}


function runFFCommand($argumentList, $program){
    Start-Process -FilePath "C:\ProgramData\chocolatey\lib\ffmpeg\tools\ffmpeg\bin\$program.exe" -Wait -NoNewWindow -ArgumentList $argumentList
}


function DeleteTempFiles($filePath){
    if(Test-Path $filePath){
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($filePath,'OnlyErrorDialogs','SendToRecycleBin')
    }
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


function KeepTweaking(){
    while($true){
        $keepTweaking = Read-Host "Would you like to continue tweaking settings and output again? [y=Yes, n=No]"
        Write-Host ""

        if($keepTweaking.ToUpper() -eq "Q"){
            Quit
        }
        elseif($keepTweaking.ToUpper() -match "^(Y|N)$"){
            break
        }
        else{
            Write-Host "Invalid input, answer must be `"y`" (Yes), `"n`" (No), or `"q`" (quit)..."
        }
    }

    return $keepTweaking
}


function EndProcess(){
    Write-Host "Process complete, press [Enter] to exit..." -NoNewLine
    $Host.UI.ReadLine()
}