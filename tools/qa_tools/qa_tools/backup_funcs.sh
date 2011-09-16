#!/bin/bash

# backup_funcs.sh
# Define standard SuSE password
# Can send mails;
# Can backup mysql databases;
# Can backup entire directory;
# Can backup single file;
# Can backup repo info from zypper.

standpw='STANDARD_PASSWD' # modify it when deploy scripts

sname=`hostname` # a global var

function mailsent
# USAGE: $1 mail subject
#		 $2 mailto
{
		mailx -s "$1" $2 -r hamsta-master@suse.de < /tmp/host-info
}

function db_backup
# USAGE:	used for mysql DB backup only
#	       $1 db_name
#	       $2 db_user
#	       $3 db_password (standard SuSE password is used by default)
#	       $4 backup_dir
# EXAMPLE:      db_backup hamsta_db root "" /backups
#		or:		db_backup hamsta_db root standpw /backups
{
	if [ $# -ne 4 ] || [ -z $1 -o -z $2 -o -z $4 ]; then
		echo "Error in db_backup: parameters wrong"
		exit -1
	fi
	mkdir -p $4/$sname/db
	if [ -z $3 ]; then
		mysqldump -u $2 --add-drop-table --add-locks --complete_insert --flush-logs --lock-tables $1 > "$4/$sname/db/$1.sql"
	else
		mysqldump -u $2 -p$standpw --add-drop-table --add-locks --complete_insert --flush-logs --lock-tables $1 > "$4/$sname/db/$1.sql"
	fi
}

function dir_backup
# USAGE:	used for entire dir backup
#		$1 directory you want to backup
#		$2 target for save backup files
# EXAMPLE:	dir_backup /etc/apache2 /backups
{
	if [ $# -ne 2 ] || [ -z $1 -o -z $2 ]; then
		echo "Error in dir_backup: parameters wrong"
		exit -1
	fi
	dir_name=`echo $1 | sed 's/^\///'`
	mkdir -p $2/$sname/dir/$dir_name
	cp -r $1/* $2/$sname/dir/$dir_name/
}

function file_backup
# USAGE:	used for single file backup
#		$1 the single file with full path you want to backup
#		$2 target dir for save backup files
# EXAMPLE: file_backup /usr/share/hamsta/master/config_master /backups
{
	if [ $# -ne 2 ] || [ -z $1 -o -z $2 ]; then
		echo "Error in file_backup: parameters wrong"
		exit -1
	fi
	filename=`basename $1`
	filedir=`dirname $1 | sed 's/^\///'`
	mkdir -p $2/$sname/file/$filedir
	cp $1 $2/$sname/file/$filedir/
}

function repo_backup
# USAGE: used for repo info backup
#		$1: target dir for save zypper info
# EXAMPLE: repo_backup /backups
{
	## sle10 is considered
	mkdir -p $1/$sname/repo
	VER=`egrep -o "[0-9]+ [SsPp0-9]*" /etc/issue | cut -d " " -f1`
    if [ $VER -eq 10 ] ; then
		sudo zypper sl | awk -F"|" '{if (NR>2) print $6 $7 $3}' | sed -e 's/^\s//' | awk '{ printf "%s %s %s\n", $1, $2, $3 }' > $1/$sname/repo/zypper-info
	else #sle11 and openSuSE can use below way.
		zypper sl -u | awk -F"|" '{if (NR>2) print $6 $7 $3}' | sed -e 's/^\s//' | awk '{ printf "%s %s %s\n", $1, $2, $3 }' > $1/$sname/repo/zypper-info
	fi

}
