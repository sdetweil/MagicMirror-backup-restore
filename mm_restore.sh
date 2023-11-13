#!/bin/bash

known_list="request valid-url"

#  backup MM modules  config

base=$HOME/MagicMirror
saveDir=$HOME/MM_backup
logfile=$HOME/MagicMirror/installers/restore.log
# is this a mac
mac=$(uname -s)
fetch=
process_args(){
local OPTIND
while getopts ":hs:b:r:u:f" opt
do
    case $opt in
    	# help
    h) 		echo
			echo $0 takes optional parameters
			echo
			echo -e "\t -s MagicMirror_dir"
			echo -e	"\t\tdefault $base"
			echo
			echo -e "\t -b backup_dir "
			echo -e	"\t\tdefault $saveDir"
			echo
			echo -e "\t -f "
			echo -e	"\t\tfetch/clone repo and restore latest tag"
			echo
			echo -e "\t -r github repository name (reponame)"
			echo -e	"\t\ttypically https://github.com/username/reponame.git"
			echo -e	"\t\tdefault output of git remote -v (if set)"
			echo -e "\t\t -r overrides the git remote setting"
			echo
			echo -e "\t -u github username"
			echo -e	"\t\tdefault none"

			exit 1
	 ;;
    s)
		# source MagicMirror folder
      b=$(echo $OPTARG | tr -d [:blank:])
			if [ -d $HOME/$b ]; then
				base=$HOME/$b
			else
				if [ -d b ]; then
					base=$b
				else
					echo unable to find Source folder $OPTARG | tee -a $logfile
					exit 2
				fi
			fi
			echo MagicMirror folder to update is $base | tee -a $logfile
    ;;
    b)
		# backup folder
			saveDir=$(echo $OPTARG | tr -d [:blank:])
			echo backup folder is $saveDir | tee -a $logfile
    ;;
	u)
		# username
		user_name=$(echo $OPTARG | tr -d [:blank:])
	;;
	r)
		# username
		repo_name=$(echo $OPTARG | tr -d [:blank:])
	;;
    f)
		fetch=true
	;;
    *) echo "Illegal option '-$OPTARG'" && exit 3
	 ;;
    esac
done
}

# if this script was started directly then arg0 is 'mm_backup.sh', else it is the first argument provided (oops) 
if [[ "$0" == *.sh ]]; then 
  process_args "$@"
else
  process_args "$0 $@"
fi

if [ $mac == 'Darwin' ]; then
	cmd=greadlink
else
	cmd=readlink
fi
date +"restore starting  - %a %b %e %H:%M:%S %Z %Y" >>$logfile
echo restoring MM configuration from $saveDir to $base | tee -a $logfile
echo
cd $HOME

# fetch  use latest tag (bu highest number)

if [ "$fetch." != "." ]; then
	echo trying to fetch repo from github >> $logfile
	# if the directory doesn't exist
	if [ ! -d $saveDir ]; then
		echo folder $saveDir does not exist >> $logfile
		# and we have username and repo name
		if [ "$user_name." != "." -a "$repo_name." != "." ]; then
			git clone "https://github.com/$user_name/$repo_name" $saveDir # >/dev/null 2>&1
			cd $saveDir
		else
			echo -e "\t\t need both the github username and the github repository name" | tee -a $logfile
			exit 4
		fi
    else
    	cd $saveDir
    	if [ "$(git remote -v)." != "." ]; then
    		echo $saveDir exists fetching all tags >>$logfile
			git fetch --all --tags
		else
			echo -e "\t\t need both the github username and the github repository name" | tee -a $logfile
			exit 5
		fi
	fi
else
	if [ ! -d $saveDir ]; then
		echo Backup directory $saveDir not found, exiting | tee -a $logfile
		exit 1
	fi
	cd $saveDir
fi
# fet the last numeric tag
last_tag=$(git tag -l  | sort -g -r | head -n1)
# get on some known branch
git checkout main >/dev/null 2>&1
# delete the temp branch for the restore
git branch -D restore-branch >/dev/null 2>&1
# create the branch from the tag
git checkout tags/$last_tag -b restore-branch >/dev/null 2>&1

echo created git branch from last tag = $last_tag >>$logfile
# restore the config for MM
cp -p $saveDir/config.js $base/config
# restore the custom/.css for MM (no error if not found)
cp -p $saveDir/custom.css $base/custom.css 2>/dev/null

echo restored config.js and custom.css >>$logfile

repo_list=$saveDir/module_list

echo processing module_list >>$logfile
if [ -e $repo_list ]; then

	SAVEIFS=$IFS   # Save current IFS
	IFS=$'\n'
	# split output on new lines, not spaces
	urls=($(cat $repo_list))
	IFS=$SAVEIFS

	# if there modules to restore
	if [ ${#urls} -gt 0 ]; then

		# restore the repos

		cd $base/modules

			# loop thru the modules listed
			for repo_url in "${urls[@]}"
			do
				module=$(echo $repo_url | awk -F/ '{print $(NF)}' | awk -F. '{print $1}')
				# if the module folder does not exist
				if [ ! -d $module ]; then
					echo restoring $module | tee -a $logfile
					gc=$(git clone $repo_url 2>&1)
					gc_rc=$?
					if [ $gc_rc -eq 0 ]; then
						cd $module
						if [ -e package.json ]; then
							echo module $module contains package.json, doing npm install | tee -a $logfile
							npm install --only=prod --no-audit --no-fund --loglevel error --legacy-peer-deps 2>&1 >> $logfile
						else
							echo module $module DOES NOT contain package.json | tee -a $logfile
						fi
						# if there is a folder of module specific files saved by backup
						if [ -d $saveDir/$module ]; then
							# copy them from the backup
							echo there were files saved for this module , restoring | tee -a $logfile
							cp -a $saveDir/$module/. ~/MagicMirror/modules/$module
						fi
						cd - >/dev/null
					fi
				else
					echo -e "\e[91m $module folder already exists, skipping restore from $repo_url \e[90m" | tee -a $logfile
					tput init 2>/dev/null
					echo
				fi
				echo
			done

			# lets check for modules with missing requires (libs removed from MM base)
			# this skips any default modules
			echo Checking for modules with removed libraries| tee -a $logfile
			mods=($(find . -maxdepth 2 -type f -name  node_helper.js | awk -F/ '{print $2}'))

			# loop thru all the installed modules
			for  mod in "${mods[@]}"
			do
				# get the require statements from the node helper
				requires=($(grep -e "require(" $mod/node_helper.js | awk -F '[()]' '{print $2}' | tr -d '"' | tr -d "'"))
				# loop thru the requires
				for require in "${requires[@]}"
				do
					# check it against the list of known lib removals
					case " $known_list " in (*" $require "*) :;; (*) false;; esac
					# if found in the list
					if [ $? == 0 ]; then
						# if no package.json, we would have to create one
						cd $mod
						if [ ! -e package.json ]; then
							echo -e ' \n\t ' package.json not found for module $mod
							echo -e ' \n\t\t ' adding package.json for module $mod | tee -a $logfile
							npm init -y >/dev/null 2>&1
						fi
						# if package.json exists, could have been just added
						if [ -e package.json ]; then
							# check for this library in the package.json
							pk=$(grep $require package.json)
							# if not present, need to do install
							if [ "$pk." == "." ]; then
								echo -e ' \n\t\t ' require for $require in module $mod not found in package.json | tee -a $logfile
								echo -e ' \n\t\t ' installing $require for module $mod | tee -a $logfile
								npm install $require --save --no-audit --no-fund --loglevel error --legacy-peer-deps --only=prod 2>&1 >> $logfile
							fi
						fi
						cd - >/dev/null
					fi
				done
			done
	fi
	echo
	echo restore completed, you can start MagicMirror now | tee -a $logfile
else
	echo no saved module repo list | tee -a $logfile
fi
date +"restore ended  - %a %b %e %H:%M:%S %Z %Y" >>$logfile
