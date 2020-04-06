Import-Module -Name "$PSScriptRoot\Setup Functions.Ps1"

$boolArray = CheckRequiredPackages
InstallPackages $boolArray[0]
$relativePath = $(Split-Path $PSScriptRoot -Parent)
UpdateFiles $boolArray[1] $relativePath
Start-Sleep 2
EditRegistry $boolArray[1] $relativePath
Write-Host "Ignore `"system cannot find the specified path`", error message is by design."
Quit