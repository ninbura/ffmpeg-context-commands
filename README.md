# FFmpegContextCommands
FFmpeg Context Commands is a suite of of FFmpeg Commands run by Windows Powershell that allow you to play and modify media files in a 
variety of ways. For example in regards to video - playing, compressing, cutting, changing resolution, changing framerate, converting, and
more.

#Setup
To setup these commands all you need to do is download the files from this repository, whether that be via git clone or simply donwloading 
the zip folder, extract the main folder to a location of your choosing, and run the `Run Me.bat` file as administrator. It doesn't matter 
what you name the folder you store the contents of this project in, but it's worth noting that wherever you choose to store it, each time 
you run the `Run Me.bat` file it will delete the contents of the directory you ran the batch file in. So it's best to store it in folder 
seperate from other files, for example rather than putting the root contents ("Functions", "Other Assets", "Scripts", "Run Me.bat") 
directly in your Documents folder, you'd store it in a folder in the Documents folder (C:\Users\[user]\Documents\FFmpegContextCommands).
That way when you run the `Run Me.bat` it will only delete the "FFmpegContextCommands" folder within your Documents folder, in the case
of the above example. On first running said batch file you will be prompted to install certain packages, these are required for the 
commands to function. But after the first time you install said packages you can opt to skip the install step and simply update the 
commands. And to explain that further, whenever this repo is updated, to pull the new commands or changes as I add them you just have to 
run the `Run Me.bat` file again, so essentially the `Run Me.bat` file is your one stop shop for initial install and continuous updates.

Once you've run the `Run me.bat` file and followed the resulting prompts, assuming there were no errors, the commands will have been added
to your context menu when right clicking a file in Windows Explorer:
![Alt Text](https://i.postimg.cc/RVLpfj9m/MW00-Cropped-Gif.gif)
