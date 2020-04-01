param(
    [string]$relevantPath
)

$step = Get-Content -Path "$relevantPath\Setup\Step.txt" -TotalCount 1

if($step -eq 0){
    $chocoBool = $true
    $gitBool = $true

    try{
        choco
    }
    catch{
        $chocoBool = $false
    }

    try{
        git
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

        if($answer.ToUpper() = "Y"){
            Set-Content -Path "$relevantPath\Setup\Step.txt" -Value "1" | Out-Null
            Write-Host "Installing required packages..."
        }
        else{
            Write-Host "Required packages were not installed, process is exiting."

            exit
        }
    }
    else{
        Write-Host "Required packages are already installed, would you like to update them?"
        $answer = Read-Host "Chocolatey, git, and FFmpeg will be installed / updated [y=yes, n=no]"
        Write-Host ""

        if($answer.ToUpper() = "Y"){
            Set-Content -Path "$relevantPath\Setup\Step.txt" -Value "1" | Out-Null
            Write-Host "Installing required packages..."
        }
        else{
            Set-Content -Path "$relevantPath\Setup\Step.txt" -Value "3" | Out-Null
            Write-Host "Skipping updates..."
        }
    }
}