# MagicMirror-backup-restore
scripts for backing up magicmirror config and module github urls  and using that to restore at a later time

# DO NOT CLONE this repo, execute by copy/pasting one of the command lines below
# that way you always use the most up to date script(s)
# DO NOT CLONE this repo

these scripts will  save the config.js , custom.css and the list of installed modules (and where they are loaded from (github urls)
into a git repo, so they can be versioned and uploaded to a ===>**private**<===  github repository
  if you wish to use github and never have, see below for how to get the required access token

the restore script takes the info saved and copies back the config.js, custom.css  and re-installs each module

it assumes a new MagicMirror install has been completed

both scripts support help with -h

and parms for where the MagicMirror folder is  -s , default $HOME/MagicMirror

and the name of the backup folder, -b , default $HOME/MM_backup

one can execute the scripts directly from here

# to execute Backup
```bash
bash -c  "$(curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror-backup-restore/main/mm_backup.sh)" with any parms
```



help for backup is

./mm_backup.sh -h

./mm_backup.sh takes optional parameters

	 -s MagicMirror_dir
		default $HOME/MagicMirror

	 -b backup_dir
		default $HOME/MM_backup

	 -m backup_message
		 any message (in quotes) that you would like to attach to this change for later info
		default none

	 -p auto push to github (will need repo name, username,  user password or token
	    the password/token will be prompted for by git
	    unless you set it in the -b backup folder git with git config
		default no push

	 -r github repository name (reponame)
		typically https://github.com/username/reponame.git
		default output of git remote -v (if set)
		 -r overrides the git remote setting

	 -u github username
	    the username will be extracted from the -r parm if the full url is used
		default none

# and to restore
```bash
bash -c  "$(curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror-backup-restore/main/mm_restore.sh)" with any parms
```

help for restore  is

./mm_restore.sh -h

./mm_restore.sh takes optional parameters

	 -s MagicMirror_dir
		default $HOME/MagicMirror

	 -b backup_dir
		default $HOME/MM_backup

	 -f [tag_number]
		fetch/clone repo and restore latest, or optional tag_number

	 -r github repository name (reponame)
		typically https://github.com/${username}/reponame.git
		default output of git remote -v (if set)
		 -r overrides the git remote setting

	 -u github username
		default none


on backup, each collection of files is given a label, called a tag in git.
for this application the tag is a number, starting at 1

by default list-tags will use the $HOME/MM_backup folder name

help for list_tags  is

./list_tags.sh -h

./list_tags.sh takes optional parameters

	 -b backup_dir
		default $HOME/MM_backup


# to list the tags copy/paste this command
```bash
bash -c  "$(curl -sL https://raw.githubusercontent.com/sdetweil/MagicMirror-backup-restore/main/list_tags.sh)" ??
```

# getting the github access token
* on github, select your profile

* select settings <br>
* select developer settings <br>
* personal access tokens <br>
* classic token <br>
* make sure to select write/update repository permissions <br>
* generate <br>

 >you will use this string for your password on the command prompt for the git password

 Note: github  will NOT SHOW you this token again. so if you forget it, you have to generate a new token

to set your github password so you won't be prompted there are 2 choices,  system wide(global) or 
on each repo (local) 

For global settings, open the terminal (from anywhere), run the following:
```bash
git config --global user.name "your username"
git config --global user.password "your password"
```
By that, any Git repository that you have on your machine will use that information.

You can individually configure for each repository by doing:

open the terminal at the repository folder.

run the following:
```bash
git config user.name "your username"
git config user.password "your password"
```
It affects only that folder (because your configuration is local)
 
