#!/bin/bash

#  backup MM modules  config

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

OPTIND=1 # Reset if getopts used previously
remote=
next_tagnumber=1

while getopts "hs:b:m:r:u:e:p" opt
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
    m)
		# message on the git tag
		msg="because $OPTARG"
    ;;
    r)
		# github repo name
		repo=$OPTARG
    ;;
    p)
		# push requested
		push=true
		repo=$(cd $saveDir && git remote -v| awk '{ print $2}')
		if [ "$repo." == "." ]; then
			echo to push, we need the repo name
			see the help for the -r parm
			exit 2
		else
			if [ "$(cd $saveDir && git config user.email)." == "." -a "$user_name." == "." ]; then
				echo   we will need the github userid
				see the help for the -u parm
				exit 3
			else
				if [ "$(cd $saveDir && git config user.email)." == "." -a "$email." == "." ]; then
					echo   we will need the github user email
					see the help for the -e parm
					exit 4
				fi
			fi
		fi
	;;
	u)
		# username
		user_name=$OPTARG
	;;
	e)
		# email
		email=$OPTARG
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
# check for local info on username  email so commits work
#  get the git userid , if any
if [ "$(git config user.email)." == "." ]; then
	# git info not set
	if [ "$user_name." == "." ]; then
		# prompt for users name
		git config --local user.name $user_name
	fi
	if [ "$email." == "." ]; then
		# prompt for email address
		git config --local user.email $email
	fi
else
	echo no  user name or email set, required to save chnages to git,
	please see the -u and -e parameters
	exit 3
fi
savefile=temp
cat $repo_list | sort -t/ -k5 >$savefile
rm $repo_list
mv $savefile $repo_list

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
echo backup completed, see the git repo at $saveDir
# should we push now?
if [ "$push." == "." ]; then
	# no, tell user to do it
	echo recommended you "git push --tags" from this folder ($saveDir) to backup your repo on github
	see https://github.com/new
	to learn how to create a repo on github and the commands to sync your local system to the github repo
else
	# yes push
	# did they specify the repo
	if [ "$repo."  == "." ]; then
		# no, is it set already?
		$repo=$(git remote -v)
		# no, need to prompt for repo name
		if [ "$repo."  == "." ]; then
			# remote not set yet
			#  name not specified
			# need to prompt
			# repo
			# if we had their userid, we could get the list of repos to pick from
			:
		else
			remote=true
		fi
	fi
	# if the repo is set
	if [ "$repo." != "." ]; then
		if [ "$remote." !=  "." ]; then
			git remote add origin https://github.com/$user_name/$repo.git
			git branch -M main
		fi
		git push -u origin main --tags
	fi

fi
echo see this link for how to fetch tags for restore
echo https://devconnected.com/how-to-list-git-tags/

cd - >/dev/null
