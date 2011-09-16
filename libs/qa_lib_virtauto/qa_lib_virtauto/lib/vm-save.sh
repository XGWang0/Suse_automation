#!/bin/bash

#====================
#===  Save a VM   ===
#====================

### Usage: vm-save.sh [directory/restore_file]

export LANG=C

function usage() {
	echo "Usage: $0 domuName [FullPath] [RestoreFile]"
	exit 1
}

if [ $# != 3 ] && [ $# != 1 ]; then
	usage
fi

if [ $# == 3 ] && [ `ls $2 1>/dev/null 2>&1` ]; then
	usage
fi

### Todo: add free disk space check

domuName=$1

# Check HyperType
uname -a | grep -iq xen 2>/dev/null
if [ $? == 0 ]; then
	hyperType="xen"
else
	hyperType="kvm"
fi

# Set Saved FullPath/File
if [ $# == 3 ]; then
	vmSavedDest="$2/$3" # two "/", like: "//" can also work.
else
	vmSavedDest="/var/lib/$hyperType/images/$domuName/$domuName.save"
fi

if [ -f $vmSavedDest ]; then
	rm -f $vmSavedDest
fi

echo
echo "          -------------------"
echo "          ---  VM SAVING  ---"
echo "          -------------------"
echo

vmInfo=`virsh dominfo $domuName 2>/dev/null`

SavedID=`echo "$vmInfo" | grep '^Id:' | sed 's/^[^:]*:[[:space:]]*//'`
SavedMemory=`echo "$vmInfo" | grep '^Used memory:' | sed 's/^[^:]*:[[:space:]]*//'`
SavedCpus=`echo "$vmInfo" | grep '^CPU(s):' | sed 's/^[^:]*:[[:space:]]*//'`
SavedState=`echo "$vmInfo" | grep '^State:' | sed 's/^[^:]*:[[:space:]]*//'`
SavedTime=`echo "$vmInfo" | grep '^CPU time:' | sed 's/^[^:]*:[[:space:]]*//'`

echo "          SavedName : $domuName..."
echo "          SavedId : $SavedID..."
echo "          SavedMemory : $SavedMemory..."
echo "          SavedCpus : $SavedCpus..."
echo "          SavedState : $SavedState..."
echo "          SavedTime : $SavedTime..."
echo "		SavedPath: $vmSavedDest..."
echo

### Save VM from $RestorePath/$RestoreFile
virsh save $domuName $vmSavedDest 2> /dev/null

if [ $? != 0 ]; then
	echo "VM save command implementation failed."
	exit 11
fi

### See if the VM saved is there ###
ls $vmSavedDest 1> /dev/null 2>&1

#virsh dominfo $domuName 1>/dev/null 2>&1

if [ $? != 0  ]; then
	echo "Error: VM saved file $vmSavedDest is not there."
	exit 11
fi

echo
echo "          ----------------------"
echo "          --- VM SAVING DONE ---"
echo "          ----------------------"
echo
