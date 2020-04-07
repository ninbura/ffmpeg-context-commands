# FFmpegContextCommands
FFmpeg Context Commands is a suite of of FFmpeg Commands run by Windows Powershell that allow you to play and modify media files in a variety of ways. For example in regards to video - playing, compressing, cutting, changing resolution, changing framerate, converting, and more.

# Setup
To setup these commands all you need to do is download the files from this repository, whether that be via git clone or simply downloading the zip folder:
![Alt Text](https://i.postimg.cc/FHVGLMJn/Download-zip.gif)


Extract the main folder to a location of your choosing, feel free to rename the folder to whatever you want if desired (renaming not required):
![Alt Text](https://i.postimg.cc/pTfdWJS8/Extract-zip.gif)


Make sure you store the main guts in their own folder, and not directly in a directory with other files as this could lead to accidental deletion of files you want to keep:
![Alt Text](https://i.postimg.cc/XvzQxwNR/Good-v-Bad.png)


Finally run the `Run Me.bat` file as administrator and follow the prompts, the first step is required on initl install unless you already have Chocolatey, FFmpeg, & Git installed:
![Alt Text](https://i.postimg.cc/HxSH6v8p/Fast-Setup-Start-Gif.gif)


On the second step, the first time you run the `Run Me.bat` file it will inform you that old files will be deleted and then updated. This is especially note worthy because if you extract the guts of this folder directly into a folder with other files those files will also be deleted as noted earlier:
![Alt Text](https://i.postimg.cc/44SstMTP/Fast-Setup-End-Gif.gif)


Once you've run the `Run me.bat` file and followed the resulting prompts, assuming there were no errors, the commands will have been added to your context menu when right clicking a file or folder (depending on the command) in Windows Explorer:
![Alt Text](https://i.postimg.cc/HLqPdwGQ/Show-Commands.gif)


Everytime you run a command it will check for updates, if it finds there are new updates it will prompt you to run through the update process again (optional). However, this time you don't have to delete old files, you can simply update them via the second step:
![Alt Text](https://i.postimg.cc/d3L76y1x/Auto-Update.gif)


If you're experiencing strange issues and want to reload all the files you can run the `Run Me.Bat` again and choose option "d" (delete and re-download) in step 2:
![Alt Text](https://i.postimg.cc/y8PZVBwn/Delete-and-Redownload-Gif.gif)


If all else fails you have the option to completely delete the directory and redownload the zip from this page.

# Errors / Issues
If you run into errors at any point during the setup process or while running a command please head to the issues tab on this github page and detail the problem test:
![Alt Text](https://i.postimg.cc/63T5xNX7/Errors-Issues.gif)