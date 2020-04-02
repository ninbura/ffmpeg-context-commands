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
        Write-Host "Required packages are already installed, would you like to update them?"
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

function cloneGit($cloneBool, $relativePath){
    if($cloneBool){
        Write-Host "Deleting old files..."
        Remove-Item -LiteralPath $relativePath -Force -Recurse
        Start-Sleep 2

        Write-Host "`nUpdating Files..."
        git clone https://github.com/TheNimble1/FFmpegContextCommands.git $relativePath
    }
}


function EditRegistry($registryBool, $relativePath){
    if($registryBool){
        Write-Host "`nCreating contextual menu items..."

        [array]$functionArray = Get-ChildItem "$relativePath\Functions" | Select-Object -Property BaseName -ExpandProperty BaseName
        $functionString = ""

        for($i = 0; $i -lt $functionArray.Count; $i++){
            $function = $functionArray[$i].Replace(' ', '')

            if($i -eq $functionArray.Count - 1){
                $functionString += $function
            }
            else{
                $functionString += "$function;"
            }
        }

        $null = New-Item -Force "HKLM:\Software\Classes\*\shell\FFmpeg" |
                New-ItemProperty -Name 'MUIVerb' -Value "FFmpeg"
        [microsoft.win32.registry]::SetValue(
                "HKEY_LOCAL_MACHINE\Software\Classes\*\shell\FFmpeg",
                "Icon",
                "$relativePath\Other Assets\FFmpeg.ico"
        )
        [microsoft.win32.registry]::SetValue(
                "HKEY_LOCAL_MACHINE\Software\Classes\*\shell\FFmpeg",
                "SubCommands",
                "$functionString"
        )

        write-Host "HKLM:\Software\Classes\*\shell\FFmpeg"

        foreach($function in $functionArray){
            $functionNoSpaces = $function.Replace(' ', '')

            $null = New-Item -Force "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\$functionNoSpaces" |
                New-ItemProperty -Name '(Default)' -Value "$function"
            $null = New-Item -Force "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\$functionNoSpaces\command" | 
                New-ItemProperty -Name '(Default)' -Value ((
                        "$PSHOME\powershell.exe -WindowStyle Maximized -ExecutionPolicy Bypass -NoProfile",
                        "-File `"$relativePath\Functions\$function.ps1`" -filePath `"%1`""
                ) -Join ' ')

            write-Host "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\$functionNoSpaces"
            Write-Host "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\$functionNoSpaces\command"
        }
        
        Write-Host ""
    }
    else{
        Write-Host "`nRequired packages are not installed to add contextual menu items, run this batch file again if you'd like to retry setup."
    }
}


$boolArray = CheckRequiredPackages
InstallPackages $boolArray[0]
$relativePath = $(Split-Path $PSScriptRoot -Parent)
cloneGit $boolArray[1] $relativePath
Start-Sleep 2
EditRegistry $boolArray[1] $relativePath