#!/bin/bash
# ****************************************************************************
# Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
# 
# THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
# CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
# RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
# THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
# THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
# TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
# PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
# PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
# AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
# LIABILITY.
# 
# SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
# AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
# LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
# WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
# ****************************************************************************
#


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

