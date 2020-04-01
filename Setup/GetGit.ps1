function InstallAndUpdateGit(){
    $answer = Read-Host "Would you like to install / update git? This is required for automated updates... [y/n]"
    Write-Host ""

    if($answer.ToUpper() -eq "Y"){
            choco install git
    }
    elseif($answer.ToUpper() -NE "N"){
            Write-Host "Invalid input, answer must be `"y`" (Yes) or `"n`" (No)...`n"
    }
}

InstallAndUpdateGit