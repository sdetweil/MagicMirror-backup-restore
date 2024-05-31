#!/bin/bash

#  backup MM modules  config


base=$HOME/MagicMirror
saveDir=$HOME/MM_backup
default_user=temp
user_name=$default_user
email=$user_name@somemail.com
default_email=$email
logfile=$base/installers/backup.log
push=false

# is this a mac
mac=$(uname -s)

if [ $mac == 'Darwin' ]; then
	cmd=greadlink
else
	cmd=readlink
fi
msg_prefix='updating'
#script_dir=$(dirname $($cmd -f "$0"))

#OPTIND=1 # Reset if getopts used previously
remote=
next_tagnumber=1

beginswith() {
  l=$(expr length "$2")
  leading="${1:0:$l}"
	case $2 in
		$leading):
			true
			;;
		*):
		  false
		  ;;
	esac

}

check_for_push(){
	if [ $push == true ]; then
		if [ "$repo." == "." ]; then
			# repo not connected to git
				if [ "$reponame." == "." ]; then
					echo to push, we need the repo name | tee -a $logfile
					echo see the help for the -r parm
					exit 2
				else
					if [ "$user_name" != $default_user ]; then
						cd $saveDir
						echo adding the git repmote https://github.com/$user_name/$reponame.git | tee -a $logfile
						git remote add origin https://github.com/$user_name/$reponame.git
						cd -
					else
						echo "you requested to push the local backup repository to github, but didn't specify the username" | tee -a $logfile
						exit 3
					fi
				fi
		else
			if [ "$(cd $saveDir && git config user.email)." == "." -a "$user_name" == $default_user ]; then
				echo  we will need the github userid | tee -a $logfile
				echo see the help for the -u parm
				exit 3
			else
				if [ "$(cd $saveDir && git config user.email)." == "." -a "$email." == $default_email ]; then
					echo   we will need the github user email | tee -a $logfile
					echo see the help for the -e parm
					exit 4
				fi
			fi
		fi
	else
		# if not push, but repo specified
		if [ "$repo." != "." ]; then
			echo "you specified a github repository name , but didn't request push" | tee -a $logfile
			read -p "do you want to save the results of this backup to github now? (Y/n)?" choice
			choice="${choice:-Y}"
			choice=${choice,,}
			echo user selection for push now is $choice >>$logfile
			if [ $choice == "y" ]; then
				push=true
				check_for_push
			fi
		fi
	fi

}

process_args(){
local OPTIND

#r=${1:0:1}
#echo "$r='$r'"
#if [ "$r." != '-.' ]; then
#echo "Illegal option '$1'"
	#exit 3
#fi
while getopts ":hs:b:m:r:u:e:p" opt
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
			echo -e "\t -m backup message "
			echo -e	"\t\t any message (in quotes) that you would like to attach to this change for later info"
			echo -e	"\t\tdefault none"
			echo
			echo -e "\t -p auto push to github (will need repo name, username,  user password or token"
			echo -e	"\t\tdefault false"
			echo
			echo -e "\t -r github repository name (reponame)"
			echo -e	"\t\ttypically https://github.com/username/reponame.git"
			echo -e	"\t\tdefault output of git remote -v (if set)"
			echo -e "\t\t -r overrides the git remote setting"
			echo
			echo -e "\t -u github username"
			echo -e	"\t\tdefault none"
			echo
			echo -e "\t -u github password or token"
			echo -e	"\t\tdefault none"
			exit 1
	 ;;
    s)
		# source MagicMirror folder
      b=$(echo $OPTARG | xargs)
			if [ -d $HOME/$b ]; then
				base=$HOME/$b
			else
				if [ -d $b ]; then
					base=$b
				else
					echo unable to find Source folder $OPTARG | tee -a $logfile
					exit 2
				fi
			fi
			logfile=$base/installers/backup.log
			echo source MagicMirror folder is $base | tee -a $logfile
    ;;
    b)
		# backup folder
		  full_path=false
		  b=$(echo $OPTARG | xargs)
		  if beginswith "$b" "/"; then
		  	full_path=true
		  fi
			if [ -d $HOME/$b -a $full_path == false ]; then
				saveDir=$HOME/$b
			else
				echo checking for backup folder $b | tee -a $logfile
				if [ -d $b ]; then
					echo backup folder $b exists | tee -a $logfile
					saveDir=$b
				else
					if [ $full_path == false ]; then
						echo folder doesn\'t exist, creating backup folder $HOME/$b | tee -a $logfile
	 					saveDir=$HOME/$b
	 				else
	 					echo folder doesn\'t exist, creating backup folder $b | tee -a $logfile
	 					saveDir=$b
	 				fi
				fi
			fi
			echo backup folder is $saveDir | tee -a $logfile
    ;;
    m)
			# message on the git tag
			msg=""
			mparm=${@:$OPTIND}
			if [[ ${vparm:0:1} != "-" ]];then
	        msg=$(echo ${@:$OPTIND}| cut -d' ' -f1)
	        OPTIND=$((OPTIND+1))
			fi
    ;;
    r)
			# github repo name or url
			repo=$OPTARG
			# check for fulll url specified, we only want the name
			IFS='/'; repoIN=($OPTARG); unset IFS;
			# if there were slashes
			if [ ${#repoIN[@]} -gt 0 ]; then
				# get the last element of split array
				index=${#repoIN[@]}
				# get the  name
				repot=${repoIN[$((index -1))]}
				# user is one array element earlier
				# get the user name from the URL
				useru=${repoIN[$(($index-2))]}
				# check for '.git'
				IFS='.'; repoN=($repot); unset IFS;
				# get just the name
				reponame=${repoN[0]}

				# if we already processed the -u parm
				if [ $user_name != $default_user ]; then
					# and the url username is not the same
					if [ $useru != $user_name ]; then
						echo "username specified with -u $user_name doesn't match the user in the github repo $useru, aborting" | tee -a $logfile
						exit 6
					fi

				fi
			else
				reponame=$repo
			fi
    ;;
    p)
			# push requested
			push=true
			# ignore the repo name , get the one from the save folder, if the folder exists and remote is set
			if [ -d $saveDir ]; then
				configured_repo=$(cd $saveDir 2>/dev/null && git remote -v 2>/dev/null| grep fetch -m1 | awk '{ print $2}')
				if [ "$configured_repo." != "." ]; then
					repo=$configured_repo
					reponame=$repo
				fi
			fi
		;;
		u)
			# username
			#echo username=$OPTARG
			user_name=$(echo $OPTARG | tr -d [:blank:])
		;;
		e)
			# email
			email=$OPTARG
		;;
    \?) echo "Illegal option '-$OPTARG'"  && exit 3
	 ;;
    esac
done
 shift $((OPTIND-1))
}

# if this script was started directly then arg0 is 'mm_backup.sh', else it is the first argument provided (oops) 
if [[ "$0" == *.sh ]]; then 
  process_args "$@"
else
  process_args "$0 $@"
fi

date +"backup starting  - %a %b %e %H:%M:%S %Z %Y" >>$logfile

if [ ! -d $saveDir ]; then
	echo creating $saveDir | tee -a $logfile
	mkdir $saveDir 2>./make_error
	if [ $? -eq 0 ]; then
		cd $saveDir
		git init &>/dev/null
		git symbolic-ref HEAD refs/heads/main
		cd - >/dev/null
		msg_prefix='creating'
	else
		echo unable to create $saveDir $(cat ./make_error)
		rm ./make_error
		exit 1
	fi
else
	if [ ! -d $saveDir/.git ]; then
		echo using $savedir | tee -a $logfile
		cd $saveDir
		echo "creating local git repo" | tee -a $logfile
		# create local repo
		git init &>/dev/null
		git symbolic-ref HEAD refs/heads/main
		cd - >/dev/null
	fi
fi
check_for_push

repo_list=$saveDir/module_list

echo $msg_prefix folder $saveDir | tee -a $logfile
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
		echo will create new $repo_list | tee -a $logfile
		rm $repo_list >/dev/null
	fi

	# loop thru the modules discovered
	for module in "${modules[@]}"
	do
		# if its not the base modules folder
		if [ "$module" != "$base/modules" ]; then

			# change to the that module folder
			cd "$module"
			    echo Backing up for $module | tee -a $logfile
				# if it has a git repo, then it was cloned
				if [ -d ".git" ]; then
					# get the remote repo url
				    repo1=$(git remote -v | git remote -v| grep fetch -m1 | awk '{ print $2}')
				    # just the module name, not the path
				    mname=$(echo $module |awk -F/ '{print $NF}')
				    if [[ "$repo1" == *"$mname"* ]]; then
					    echo -e "found module $mname \n\t installed from $repo1" | tee -a $logfile
					    # save it to the file
					    echo $repo1 >>$repo_list
					    cd $module
					    untracked=$(git ls-files --other | grep -v / | grep -v package-lock.json | grep -v package.json)
					    if [ "$untracked." != "." ]; then
					    	echo untracked files for module $module = $untracked >> $logfile
					    	# if the folder doesn't exist
					    	if [ ! -d $saveDir/$mname ]; then
					    		# create it.
					    		mkdir $saveDir/$mname 2>/dev/null
					    	fi
					    	# copy the untracked(extra)  files to the backup for this module
					    	cp -a $untracked $saveDir/$mname
					    fi
					else
						echo -e "\e[91m module $repo cloned to unique folder name $mname not backed up \e[90m"
						# reset the echo ansi code back to default
						# could save the folder name along with the url
						# and then clone to the correct folder, rename the modulename.js and use sed to change the register clause too..
						tput init 2>/dev/null
						echo
				    fi
				    cd - >/dev/null
				else
            echo -e "\e[91m module $module was not cloned from github, so no link can be saved, not backed up \e[90m"
            tput init 2>/dev/null
				    echo
				fi
			# back to the current folder
			cd - >/dev/null
		fi
	done
	if [ -e $repo_list ]; then 
		savefile=temp
		cat $repo_list | sort -t/ -k5 >$savefile
		rm $repo_list
		mv $savefile $repo_list
	fi 
fi

cd $saveDir
# check for local info on username  email so commits work
#  get the git userid , if any
if [ "$(git config user.email)." == "." ]; then
	# git info not set
	if [ "$user_name." == "." ]; then
		# prompt for users name
		git config --local user.name $user_name
	else	
		git config --local user.name $user_name
	fi
	if [ "$email." == "." ]; then
		# prompt for email address
		git config --local user.email $email
	else
		git config --local user.email $email
	fi
#else
#	echo no  user name or email set, required to save changes to git, please see the -u and -e parameters | tee -a $logfile
#	exit 3
fi

# add all the changed files
git add .
# commit them to the local repo
git commit -m "updated on $(date) $msg"
	# check for any new named tags
	last_tag=$(git for-each-ref --sort=creatordate --format '%(refname)'  | grep tags | grep -v - | awk -F/ {'print $3'} | sort -r -g | head -n1)
	# if we found some then we have the highest number
	if [ "$last_tag." != "." ]; then
		next_tagnumber=$((last_tag+1))
	fi
	# lets check  rename any old date named tags
	SAVEIFS=$IFS   # Save current IFS
	IFS=$'\n'
	# split output on new lines, not spaces
	tag_list=($(git for-each-ref --sort=creatordate --format '%(refname)'  | grep tags | grep - | awk -F/ {'print $3'}))
	IFS=$SAVEIFS
	if [ ${#tag_list} -gt 0 ]; then
		for tag in "${tag_list[@]}"
		do
			git tag $next_tagnumber $tag 2>/dev/null
			git tag -d $tag 2>/dev/null
			next_tagnumber=$((next_tagnumber+1))
		done
	else
		:
	fi

git tag -a $next_tagnumber -m "backup on $(date) $msg"
echo backup completed, see the git repo at $saveDir| tee -a $logfile
remote=false
# should we push now?
if [ "$push." == "." ]; then
	# no, tell user to do it
	echo "because you didn't request push"
	echo recommended you "git push --tags" from this folder \($saveDir\) to backup your repo on github | tee -a $logfile
	echo see "https://github.com/new"
	echo to learn how to create a repo on github and the commands to sync your local system to the github repo
else
	# yes push
	cd $saveDir
	# did they specify the repo
	if [ "$reponame."  != "." ]; then
		remote=true
		# no, is it set already?
		repo=$(git remote -v 2>/dev/null| grep fetch -m1 | awk '{ print $2}')
		# no, need to prompt for repo name
		if [ "$repo."  == "." ]; then
			# remote not set yet
			#  name not specified
			# need to prompt
			# repo
			# if we had their userid, we could get the list of repos to pick from
			git remote add origin "https://github.com/$user_name/$reponame.git"
			git branch -M main
			repo=$(git remote -v| grep fetch -m1 | awk '{ print $2}')
		fi
		#	git remote add origin https://github.com/$user_name/$reponame.git
		#	git branch -M main
		#fi
		git push -u origin main --tags
	fi

fi
echo see this link for how to fetch tags for restore
echo https://devconnected.com/how-to-list-git-tags/
echo or run the list_tags.sh command from this repo

cd - >/dev/null

date +"backup ended  - %a %b %e %H:%M:%S %Z %Y" >>$logfile
