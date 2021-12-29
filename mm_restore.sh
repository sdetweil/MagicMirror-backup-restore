#!/bin/bash

#  backup MM modules and config 

base=$HOME/MagicMirror
saveDir=$HOME/MM_backup
# is this a mac
mac=$(uname -s)


while getopts "hs:b:" opt
do
    case $opt in
    	# help
    h) echo $0 takes 2 optional parameters
			echo -e "\t -s MagicMirror_dir"
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
					echo unable to find MagicMirror folder $OPTARG
					exit 2
				fi
			fi
			echo MagicMirror folder to update is $base ;
    ;;
    b)
		# backup folder
			if [ -d $HOME/$OPTARG ]; then
				saveDir=$HOME/$OPTARG
			else
				if [ -d $OPTARG ]; then
					saveDir=$OPTARG
				else
					echo unable to find backup folder $OPTARG
					exit 2
				fi
			fi
			echo backup folder is $saveDir;
    ;;
    *) printf "Illegal option '-%s'\n" "$opt" && exit 3
	 ;;
    esac
done

if [ $mac == 'Darwin' ]; then
	cmd=greadlink
else
	cmd=readlink
fi
echo restoring MM configuration from $saveDir to $base

if [ ! -d $saveDir ]; then
	echo Backup directory $saveDir not found, exiting
	exit 1
fi
repo_list=$saveDir/module_list

if [ -e $repo_list ]; then

	SAVEIFS=$IFS   # Save current IFS
	IFS=$'\n'
	# split output on new lines, not spaces
	urls=($(cat $repo_list))
	IFS=$SAVEIFS

	# if there modules to restore
	if [ ${#urls} -gt 0 ]; then

		# restore the config for MM
		cp -p $saveDir/config.js $base/config
		# restore the custom/.css for MM (no error if not found)
		cp -p $saveDir/custom/css $base/custom.css 2>/dev/null


		# restore the repos

		# loop thru the modules listed
		cd $base/modules
		for repo_url in "${urls[@]}"
		do
			module=$(echo $repo_url | awk -F/ '{print $(NF)}' | awk -F. '{print $1}')
			if [ ! -d $module ]; then
				echo restoring $module
				gc=$(git clone $repo_url >/dev/null)
				gc_rc=$?
				if [ $gc_rc -eq 0 ]; then
					cd $module
					if [ -e package.json ]; then
						npm install >/dev/null
					fi
					cd - >/dev/null
				fi
			else
				echo module folder $module already exists, skipping
			fi
		done
	fi
	echo restore completed, u can start MagicMirror now
else
	echo no saved module repo list
fi
