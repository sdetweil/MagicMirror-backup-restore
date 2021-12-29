#!/bin/bash

#  backup MM modules and config 

base=$HOME/MagicMirror
saveDir=$HOME/MM_backup
# is this a mac
mac=$(uname -s)

if [ $mac == 'Darwin' ]; then
	cmd=greadlink
else
	cmd=readlink
fi
msg_prefix='updating'
script_dir=$(dirname $($cmd -f "$0"))

while getopts "hs:b:" opt
do
    case $opt in
    	# help
    h) echo $0 takes 2 optional parameters
			echo -e "\t -s source_dir"
			echo and
			echo -e "\t -b backup_dir "
			exit 1
	 ;;
    s)
		# source MagicMirror folder
			if [ -d $HOME/$OPTARG ]; then
				base=$HOME/$OPTARG
			else
				if [ -d $OPTARG ]; then
					base=$OPTARG
				else
					echo unable to find Source folder $OPTARG
					exit 2
				fi
			fi
			echo source MagicMirror folder is $base ;
    ;;
    b)
		# backup folder
			if [ -d $HOME/$OPTARG ]; then
				saveDir=$HOME/$OPTARG
			else
				if [ -d $OPTARG ]; then
					saveDir=$OPTARG
				else
					echo creating backup folder $HOME/$OPTARG
					saveDir=$HOME/$OPTARG
					# echo unable to find backup folder $OPTARG
					#exit 2
				fi
			fi
			echo backup folder is $saveDir;
    ;;
    *) printf "Illegal option '-%s'\n" "$opt" && exit 3
	 ;;
    esac
done

if [ ! -d $saveDir ]; then
	mkdir $saveDir
	cd $saveDir
	git init &>/dev/null
	git symbolic-ref HEAD refs/heads/main
	cd - >/dev/null
	msg_prefix='creating'
else
	if [ ! -d $saveDir/.git ]; then
		cd $saveDir
		git init &>/dev/null
		git symbolic-ref HEAD refs/heads/main
		cd - >/dev/null
	fi
fi
repo_list=$saveDir/module_list

echo $msg_prefix folder $saveDir
#copy config.js
cp -p $base/config/config.js $saveDir
# copy custom.css, no error if not found
cp -p $base/css/custom.css $saveDir 2>/dev/null

	SAVEIFS=$IFS   # Save current IFS
	IFS=$'\n'
	# get the installed module list
	# split putput on new lines, not spaces
	modules=($(find $base/modules -maxdepth 1 -type d | grep -v default | xargs -i echo "{}"))
	IFS=$SAVEIFS

# if there is a modules list, erase it, creating new
if [ ${#modules[@]} -gt 0 ]; then
	if [ -e $repo_list ]; then
		rm $repo_list >/dev/null
	fi
fi
# loop thru the modules discovered
for module in "${modules[@]}"
do
	# if its not the base modules folder
	if [ "$module" != "$base/modules" ]; then

		# change to the that module folder
		cd "$module"
			# if it has a git repo, then it was cloned
			if [ -d ".git" ]; then
				# get the remote repo url
			    repo=$(git remote -v | grep -m1 git | awk '{print $2}')
			    # just the module name, not the path
			    echo found module $(echo $module |awk -F/ '{print $NF}')
			    echo -e " \t installed from $repo"
			    # save it to the file
			    echo $repo >>$repo_list
			fi
		# back to the current folder
		cd - >/dev/null
	fi
done
cd $saveDir
# add all the changed files
git add .
# commit them to the local repo
git commit -m "updated on $(date)"
# tag this update with date/time
git tag -a $(date "+%d-%b-%Y-%H-%M-%S") -m "backup on $(date)"
echo backup completed, see the git repo at $saveDir
echo recommended you "git push --tags" from this folder to your backup repo on github
echo see this link for how to fetch tags for restore
echo https://devconnected.com/how-to-list-git-tags/
cd - >/dev/null
