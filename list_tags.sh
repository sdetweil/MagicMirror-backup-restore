#!/bin/bash
# list tags and the message
savedir=MM_backup
process_args(){
local OPTIND

r=${1:0:1}
if [ $r != '-' ]; then
	echo "Illegal option '$1'"
	exit 3
fi

while getopts ":hb:" opt
do

	echo "opt = $opt"
  case $opt in
    	# help

   h) echo
			echo $0 takes optional parameters
			echo
			echo -e "\t -b backup_dir "
			echo -e	"\t\tdefault $saveDir"
			echo
			exit 1
		;;
   b)
		# message on the git tag
		savedir=$(echo $OPTARG | tr -d [:blank:])
    ;;
   *)
		#
		echo "Illegal option '-$OPTARG'"
		exit 3
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
cd $savedir
git for-each-ref --sort=creatordate --format '%(tag)  %(creatordate) label-> %(contents)' | sort -h |grep -v '^[[:space:]]*$'| egrep '^[^[:space:]]'
cd - >/dev/null