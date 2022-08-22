# MagicMirror-backup-restore
scripts for backing up magicmirror config and module github urls  and using that to restore at a later time

these scripts will  save the config.js , custom.css and the list of installed modules (and where they are loaded from (github urls) 
into a git repo, so they can be versioned and uploaded

the restore script takes the info saved and copies back the config.js, custom.css  and re-installs each module 

it assumes a new MagicMirror install has been completed

both scripts support help with -h

and parms for where the MagicMirror folder is  -s , default $HOME/MagicMirror

and the name of the backup folder, -b , default $HOME/MM-backup
