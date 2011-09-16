#!/bin/bash

# Usage: $0 [-l|-c]
# Purpose: Save current VM to a list, after VH restart, check VM status.

export LANG=C

function usage()
{
        echo "Usae: $0 [-l|-c]"
        echo "-l - list current Virtual Machines and save a list."
        echo "-c - after VH restart, start up Virtual Machines from saved list."
}

function cleanup()
{
	rm $vmlistfile $vmlisttmp
}

if [ $# -ne "1" ]; then
	echo "Usae: $0 [-l|-c]"
	echo "-l - list current Virtual Machines and save a list."
	echo "-c - after VH restart, start up Virtual Machines from saved list."
	exit 1
fi

while getopts "lc" OPTIONS
do
	case $OPTIONS in
		l)act="list";;
		c)act="check";;
		\?)usage;;
		*) usage;;
	esac
done

#getSettings="./get-settings.sh -s ${propsFile}"
getSettings="./get-settings.sh"
vmlistfile=`$getSettings vmlist`
vmlisttmp=`$getSettings vmlisttmp`

if [ "$act" == "list" ]; then
	virsh list | awk '/^  \d*/ {print $2}' > $vmlistfile
	if [ $? -eq 0 ]; then
		echo "Save Virtual Machines list to $vmlistfile successfully."
		exit 0
	else
		echo "Save Virtual Machines list to $vmlistfile failed."
		exit 2
	fi
elif [ "$act" == "check" ]; then
	for vm in `cat $vmlistfile`; do
		virsh start $vm
	done
	virsh list | awk '/^  \d*/ {print $2}' > $vmlisttmp
	res=`diff $vmlistfile $vmlisttmp`
	if [ -z "$res" ]; then
		echo "After restart, Virtual Machines work fine."
		cleanup
	else
		echo "Some Virtual Machines aren't started up successfully."
		exit 2
	fi
fi
