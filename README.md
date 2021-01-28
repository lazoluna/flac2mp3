# flac2mp3
bash script for encoding flac to mp3 and make a .torrent

A script for comfortably encoding flac2mp3 on a linux machine.
You can encode to 320Kbps V0 and V2.
If jp(e)g files are present they will be transfered as well.


!! Remember to first create your input and output folder and edit the script to add your defaults. !!


+ added a menustructure for comfortable use
+ added subfolder depth support
+ added name cleanup to remove "FLAC" in foldernames
+ added batch encode for every folder in Inputfolder to Outputfolder
+ added menu to choose desired output
+ added confirmation to copy and rename original FLAC files as well
+ added supoort to encode specific folder directly from torrent downloadfolder
+ added check if folder exist
+ added check if ffmpeg & mktorrent is present
+ added skipping of empty folders
+ added option to create a torrent for every folder in outputfolder (in case some jpgs are added after encoding)
+ added option to shrink flac to V0 for every folder in Inputfolder without creating torrent (for making music transportable)
+ added option to change announce url


Main Menu:

  (1) Batchencode from INPUT to OUTPUT and make .torrents
  
  (2) Specific folder in downloads, encode and make .torrent
  
  (3) Rebuild .torrent for every folder in OUTPUT
  
  (4) Batchshrink from INPUT to MP3 V0 in OUTPUT (no .torrent)
  
  (5) change default announce url for this session"
