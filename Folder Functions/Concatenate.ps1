param (
    [string]$filePath
)


Import-Module -Name "$(Split-Path $PSScriptRoot -Parent)\Scripts\Joint Functions.ps1"


function CheckFiles($fileArray){
    if($fileArray.Count -gt 1){
        $mismatchingFileCounter = 0

        ForEach($file in $fileArray){
            if($file.SubString($file.LastIndexOf(".")) -ne $fileArray[0].SubString($fileArray[0].LastIndexOf("."))){
                $mismatchingFileCounter += 1
            }
        }
    }
    else{
        Write-Host "There is 1 or no files in this directory, " -NoNewLine -ForegroundColor Red
        Write-Host "please verify you're attempting to use this command in the correct directory and that it contains multiple video Files.`n" -ForegroundColor Red

        Quit
    }

    if($mismatchingFileCounter -gt 0){
        Write-Host "There are files of mulitple types in this directory which is not permitted, review details at the beggining of this console and try again.`n" -ForegroundColor Red

        Quit
    }
}

function VerifyDesire($fileArray){
    while($true){
        Write-Host $fileArray
        $userConfirmation = Read-Host "Are you sure you want to concatenate the above files?"\
        Write-Host ""
        
        if($userConfirmation -eq "y"){
            break
        }
        elseif($userConfirmation -eq "n"){
            Write-Host "No files were concatenated or generated...`n"
            
            Quit
        }
        else{
            Write-Host "Invalid input, please input `"y`" (yes) or `"n`" (no)..."
        }
    }
}


StartUp
Write-Host "The purpose of this program is to concatenate like videos in a given directory." -ForegroundColor Cyan
Write-Host "Video files to be concatenated must be placed into a directory with no other file and must have the same file extension, " -NoNewline -ForegroundColor Cyan
Write-Host "audio / video codecs, count of streams, resolution, and FPS." -ForegroundColor Cyan
Write-Host "If the video files you'd like to concatenate have differing specifications simply use the `"Compress and edit`" command to match them up." -ForegroundColor Cyan
Write-Host "Lastly, video files will be concatenated in alphabetical order, so prepare for such.`n" -ForegroundColor Cyan
InformUser
$fileArray = Get-ChildItem -Path $filePath -File -Recurse | Select-Object -ExpandProperty FullName | ForEach-Object {$_.ToString()}
CheckFiles $fileArray
VerifyDesire $fileArray
$newFilePath = GetNewFilePath "Concatenated" $fileArray[0]
$fileModificationDate = GetModificationDate $newFilePath
$newFilePath = DeleteExistingFiles "Concatenated" $newFilePath
$formattedFileArray = $fileArray | ForEach-Object {"file `'$($_.Replace("'", "'\''"))`'"}
$formattedFileArray | Out-File -FilePath "$filePath\Concat.txt" -Force -Encoding ASCII
$argumentList = @("-loglevel", "error", "-stats", "-f", "concat", "-safe", "0", "-i", "`"$filePath\Concat.txt`"", "-c", "copy", "`"$newFilePath`"")
Write-Host "Video is building..."
runFFCommand $argumentList "ffmpeg"
DeleteTempFiles "$filePath\Concat.txt"
TestNewFilePath $newFilePath $fileModificationDate
EndProcess