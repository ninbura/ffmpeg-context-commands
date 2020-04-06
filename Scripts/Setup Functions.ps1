function Quit(){
    write-host('Closing program, press [Enter] to exit...') -NoNewLine
    $Host.UI.ReadLine()

    exit
}

function CheckRequiredPackages(){
    $chocoBool = $true
    $gitBool = $true
    $ffmpegBool = $true
    $boolArray = @($false, $false)

    try{
        choco | Out-Null
    }
    catch{
        $chocoBool = $false
    }

    try{
        git | Out-Null
    }
    catch{
        $gitBool = $false
    }

    if(!(Test-Path "C:\ProgramData\chocolatey\lib\ffmpeg\tools\ffmpeg\bin\ffmpeg.exe") -or 
        !(Test-Path "C:\ProgramData\chocolatey\lib\ffmpeg\tools\ffmpeg\bin\ffplay.exe") -or 
        !(Test-Path "C:\ProgramData\chocolatey\lib\ffmpeg\tools\ffmpeg\bin\ffprobe.exe")){
        $ffmpegBool = $false
    }

    if(!($chocoBool) -or !($gitBool) -or !($ffmpegBool)){
        Write-Host "Required packages are not installed, would you like to install them?"
        $answer = Read-Host "Chocolatey, git, and FFmpeg will be installed / updated [y=yes, n=no]"
        Write-Host ""
        while($true){
            if($answer.ToUpper() -eq "Y"){
                $boolArray[0] = $true
                $boolArray[1] = $true

                break
            }
            elseif($answer.ToUpper() -ne "N"){
                Write-Host "Invalid input answer should be `"y`" (yes) or `"N`" (no)..."
            }
            else{
                Write-Host "Required packages were not installed, process is exiting."

                exit
            }
        }
    }   
    else{
        Write-Host "Required packages are already installed, would you like to update them? (this is optional)"
        $answer = Read-Host "Chocolatey, git, and FFmpeg will be installed / updated [y=yes, n=no]"
        Write-Host ""
        while($true){
            if($answer.ToUpper() -eq "Y"){
                $boolArray[0] = $true
                $boolArray[1] = $true

                break
            }
            elseif($answer.ToUpper() -ne "N"){
                Write-Host "Invalid input answer should be `"y`" (yes) or `"N`" (no)..."
            }
            else{
                $boolArray[1] = $true

                Write-Host "Skipping updates...`n"

                break
            }
        }
    }

    return $boolArray
}


function InstallPackages($installBool){
    if($installBool){
        Write-Host "Installing / updating required packages..."

        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = 
            [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        choco install ffmpeg -y
        choco install git -y

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
    }
}

function UpdateFiles($updateBool, $relativePath){
    if($updateBool){
        $userConfirmation = "d"

        if(Test-Path -path "$relativePath\.git"){
            while($true){
                Write-Host "Would you like to update files, or delete existing files and then redownload them? (note: if update doesn't work opt for deletion and re-download)"
                Read-Host "Enter `"u`" to update files without deletion or `"d`" to first delete files and then redownload them [u/d]"
                Write-Host ""

                if($userConfirmation -match "^d$|^u$"){
                    break
                }
                else{
                    Write-Host "Invalid input, input should be either `"u`" (update) or `"d`" (delete & re-download)..."
                }
            }
        }

        if(!($userConfirmation -eq "d")){
            while($true){
                Write-Host "`nWhen updating files old files are deleted, everything currently in `"$relativePath`"" -ForegroundColor Yellow
                Write-Host "Will be deleted, would you like to continue? [y/n]: " -NoNewline -ForegroundColor Yellow
                $confirmation = $Host.UI.ReadLine()
                Write-Host ""

                if($confirmation -eq "y"){
                    $fileCount = Get-ChildItem -Path $relativePath -Recurse -Depth 5

                    if($fileCount.Count -gt 50){
                        while($true){
                            Write-Host "There are more than 50 files in `"$relativePath`"," -ForegroundColor Red
                            Write-Host "EVERYTHING INSIDE WILL BE DELETED ARE YOU SURE YOU WANT TO CONTINUE? [y/n]: " -ForegroundColor Red
                            $secondConfirmation = $Host.UI.ReadLine()
                            Write-host ""

                            if($secondConfirmation -eq "y"){
                                break
                            }
                            elseif($secondConfirmation -eq "n"){
                                Write-Host "No files were updated or deleted...`n"
                            
                                Quit 
                            }
                            else{
                                Write-Host "Invalid input, valid input is `"y`" (yes) or `"n`" (no)..."
                            }
                        }
                    }
                    else{
                        break
                    }
                }
                elseif($confirmation -eq "n"){
                    Write-Host "No files were updated or deleted...`n"

                    Quit
                }
                else{
                    Write-Host "Invalid input, valid input is `"y`" (yes) or `"n`" (no)..."
                }
            }

            Write-Host "Deleting old files..."
            Remove-Item -LiteralPath $relativePath -Force -Recurse
            Start-Sleep 2

            Write-Host "`nUpdating Files..."
            git clone https://github.com/TheNimble1/FFmpegContextCommands.git $relativePath

            Write-Host ""
        }
        else{
            Write-Host "Updating Files..."
            Set-Location "$relativePath"
            git pull --force

            Write-Host ""
        }
    }
}


function EditRegistry($registryBool, $relativePath){
    if($registryBool){
        Write-Host "Creating contextual menu items..." -NoNewLine

        for($i = 0; $i -lt 3; $i++){
            Write-Host ""
        
            if($i -eq 0){
                $contextType = "*\shell"
                $folder = "File Functions"
                $directoryPass = "%1"
            }
            elseif($i -eq 1){
                $contextType = "Directory\shell"
                $folder = "Folder Functions"
                $directoryPass = "%V"
            }
            else{
                $contextType = "Directory\Background\shell"
                $folder = "Folder Functions"
                $directoryPass = "%V"
            }
        
            [array]$functionArray = Get-ChildItem "$relativePath\$folder" | Select-Object -Property BaseName -ExpandProperty BaseName
        
            $functionString = ""
        
            for($j = 0; $j -lt $functionArray.Count; $j++){
                $function = $functionArray[$j].Replace(' ', '')
        
                if($j -eq $functionArray.Count - 1){
                    $functionString += $function
                }
                else{
                    $functionString += "$function;"
                }
            }

            [microsoft.win32.registry]::SetValue(
                    "HKEY_CLASSES_ROOT\$contextType\FFmpeg",
                    "MUIVerb",
                    "FFmpeg"
            )
            [microsoft.win32.registry]::SetValue(
                    "HKEY_CLASSES_ROOT\$contextType\FFmpeg",
                    "Icon",
                    "$relativePath\Other Assets\FFmpeg.ico"
            )
            [microsoft.win32.registry]::SetValue(
                    "HKEY_CLASSES_ROOT\$contextType\FFmpeg",
                    "SubCommands",
                    "$functionString"
            )

            write-Host "HKCR:\$contextType\FFmpeg"

            foreach($function in $functionArray){
                $functionNoSpaces = $function.Replace(' ', '')
                $functionName = "$($function.SubString(0,1).ToUpper())$($function.SubString(1).ToLower())"
        
                $null = New-Item -Force "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\$functionNoSpaces" |
                    New-ItemProperty -Name '(Default)' -Value "$functionName"
                $null = New-Item -Force "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\$functionNoSpaces\command" | 
                    New-ItemProperty -Name '(Default)' -Value ((
                            "$PSHOME\powershell.exe -WindowStyle Maximized -ExecutionPolicy Bypass -NoProfile",
                            "-File `"$relativePath\$folder\$function.ps1`" -filePath `"$directoryPass`""
                    ) -Join ' ')
        
                write-Host "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\$functionNoSpaces"
                Write-Host "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\$functionNoSpaces\command"
            }
        }

        Write-Host ""
    }
    else{
        Write-Host "`nRequired packages are not installed to add contextual menu items, run this batch file again if you'd like to retry setup."
    }
}