# FFmpegContextCommands
FFmpeg Context Commands is a suite of of FFmpeg Commands run by Windows Powershell that allow you to play and modify media files in a variety of ways. For example in regards to video - playing, compressing, cutting, changing resolution, changing framerate, converting, and more.

# Setup
To setup these commands all you need to do is download the files from this repository, whether that be via git clone or simply downloading the zip folder:

Extract the main folder to a location of your choosing, feel free to rename the folder to whatever you want if desired (not required):

Make sure you store the main guts in their own folder, and not directly in a directory with other files as this could lead to accidental deletion of files you want to keep:

Finally run the `Run Me.bat` file as administrator and follow the prompts, the first prompt is required on initail install unless you already have Chocolatey, FFmpeg, & Git installed:

The second prompt will inform you that old files will be deleted to update commands each time you run the `Run me.bat` file, this is especially note worthy because if you extract the guts of this folder directly into a folder with other files those files will also be deleted (as noted earlier): 

If more than 50 files are going to be deleted it will double prompt you:

Once you've run the `Run me.bat` file and followed the resulting prompts, assuming there were no errors, the commands will have been added to your context menu when right clicking a file or folder (depending on the command) in Windows Explorer:
![Alt Text](https://i.postimg.cc/RVLpfj9m/MW00-Cropped-Gif.gif)

Whenever this repo is updated, to pull the new commands or changes as I add them you can run the `Run Me.bat` file again. You'll notice that the first prompt is now optional but it would be good to update these packages every once in a while:

Additionally, if there are new updates availble you will be prompted to update each time you run a command, you can always defer if wanted:

# Errors
If you run into errors at any point during the setup process or while running a command please head to the issues tab on this github page and detail the problem test:
