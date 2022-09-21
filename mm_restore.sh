#!/bin/bash

known_list="request valid-url"

#  backup MM modules  config

base=$HOME/MagicMirror
saveDir=$HOME/MM_backup
# is this a mac
mac=$(uname -s)
fetch=
while getopts "hs:b:r:u:f" opt
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
			saveDir=$OPTARG
			echo backup folder is $saveDir;
    ;;
	u)
		# username
		user_name=$OPTARG
	;;
	r)
		# username
		repo_name=$OPTARG
	;;
    f)
		fetch=true
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

cd $HOME

# fetch  use latest tag (bu highest number)

if [ "$fetch." != "." ]; then
	# if the directory doesn't exist
	if [ ! -d $saveDir ]; then
		# and we have username and repo name
		if [ "$user_name." != "." -a "$repo_name." != "." ]; then
			git clone https://github.com/$user_name/$repo_name $saveDir >/dev/null 2>&1
			cd $saveDir
		else
			echo -e "\t\t need both the github username and the github repository name"
			exit 4
		fi
    else
    	cd $saveDir
    	if [ "$(git remote -v)." != "." ]; then
			git fetch --all --tags
		else
			echo -e "\t\t need both the github username and the github repository name"
			exit 5
		fi
	fi
else
	if [ ! -d $saveDir ]; then
		echo Backup directory $saveDir not found, exiting
		exit 1
	fi
	cd $saveDir
fi
# fet the last numeric tag
last_tag=$(git tag -l  | sort -g -r | head -n1)
# get on some known branch
git checkout main >/dev/null 2>&1
# delete the temp branch foe the restore
git branch -D restore-branch >/dev/null 2>&1
# create the bracnh from the tag
git checkout tags/$last_tag -b restore-branch >/dev/null 2>&1

# restore the config for MM
cp -p $saveDir/config.js $base/config
# restore the custom/.css for MM (no error if not found)
cp -p $saveDir/custom.css $base/custom.css 2>/dev/null

repo_list=$saveDir/module_list

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
				if [ ! -d $module ]; then
					echo restoring $module
					gc=$(git clone $repo_url >/dev/null)
					gc_rc=$?
					if [ $gc_rc -eq 0 ]; then
						cd $module
						if [ -e package.json ]; then
							npm install &>/dev/null
						fi
						cd - >/dev/null
					fi
				fi
			done

			# lets check for modules with missing requires (libs removed from MM base)
			# this skips any default modules
			echo Checking for modules with removed libraries
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
							echo adding package.json for module $mod
							npm init -y >/dev/null
						fi
						# if package.json exists, could have been just added
						if [ -e package.json ]; then
							# check for this library in the package.json
							pk=$(grep $require package.json)
							# if not present, need to do install
							if [ "$pk." == "." ]; then
								echo -e ' \n\t 'require for $require in module $mod not found in package.json package.json for module $mod
								echo installing $require for module $mod
								npm install $require --save
							fi
						fi
						cd - >/dev/null
					fi
				done
			done
	fi
	echo restore completed, u can start MagicMirror now
else
	echo no saved module repo list
fi
