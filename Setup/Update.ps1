param(
    [string]$relevantPath
)


function InstallAndUpdateGit($relevantPath){
        $answer = Read-Host "Would you like to install / update git? This is required for automated updates... [y/n]"
        Write-Host ""

        if($answer.ToUpper() -eq "Y"){
                choco install git

                git clone https://github.com/TheNimble1/FFmpegPowershellScripts.git $relevantPath
        }
        elseif($answer.ToUpper() -NE "N"){
                Write-Host "Invalid input, answer must be `"y`" (Yes) or `"n`" (No)...`n"
        }
}


function EditRegistry($relevantPath){
        Write-Host "Creating contextual menu items...`n"

        $null = New-Item -Force "HKLM:\Software\Classes\*\shell\FFmpeg" |
                New-ItemProperty -Name 'MUIVerb' -Value "FFmpeg"
        [microsoft.win32.registry]::SetValue(
                "HKEY_LOCAL_MACHINE\Software\Classes\*\shell\FFmpeg",
                "Icon",
                "$relevantPath\Other Assets\FFmpeg.ico"
        )
        [microsoft.win32.registry]::SetValue(
                "HKEY_LOCAL_MACHINE\Software\Classes\*\shell\FFmpeg",
                "SubCommands",
                "Compress;ConvertToGif;ConvertToMp4"
        )

        $null = New-Item -Force "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Compress" |
                New-ItemProperty -Name '(Default)' -Value "Compress"
        $null = New-Item -Force "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Compress\command" | 
                New-ItemProperty -Name '(Default)' -Value ((
                        "$PSHOME\powershell.exe -WindowStyle Maximized -ExecutionPolicy Bypass -NoProfile",
                        "-File `"$relevantPath\Scripts\Compress.ps1`" -relevantPath `"$relevantPath`" -filePath `"%1`""
                ) -Join ' ')

        $null = New-Item -Force "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\ConvertToMp4" |
                New-ItemProperty -Name '(Default)' -Value "Convert to mp4"
        $null = New-Item -Force "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\ConvertToMp4\command" | 
                New-ItemProperty -Name '(Default)' -Value ((
                        "$PSHOME\powershell.exe -WindowStyle Maximized -ExecutionPolicy Bypass -NoProfile",
                        "-File `"$relevantPath\Scripts\ConvertToMp4.ps1`" -relevantPath `"$relevantPath`" -filePath `"%1`""
                ) -Join ' ')

        $null = New-Item -Force "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\ConvertToGif" |
                New-ItemProperty -Name '(Default)' -Value "Convert to gif"
        $null = New-Item -Force "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\ConvertToGif\command" | 
                New-ItemProperty -Name '(Default)' -Value ((
                        "$PSHOME\powershell.exe -WindowStyle Maximized -ExecutionPolicy Bypass -NoProfile",
                        "-File `"$relevantPath\Scripts\ConvertToGif.ps1`" -relevantPath `"$relevantPath`" -filePath `"%1`""
                ) -Join ' ')
        
        Write-Host "Context menu options have been generated..."
}


InstallAndUpdateGit $relevantPath
EditRegistry $relevantPath