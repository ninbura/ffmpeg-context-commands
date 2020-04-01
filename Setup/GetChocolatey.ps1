$answer = Read-Host "Would you like to install / update Chocolatey? This is required for automated updates... [y/n]"
Write-Host ""

if($answer.ToUpper() -eq "Y"){
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = 
        [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}
elseif($answer.ToUpper() -NE "N"){
    Write-Host "Invalid input, answer must be `"y`" (Yes) or `"n`" (No)...`n"
}
else{
    Write-Host "Chocolatey was not installed / updated...`n"
}