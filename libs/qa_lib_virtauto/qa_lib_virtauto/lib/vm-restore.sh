#!/bin/bash

#====================
#=== Restore a VM ===
#====================

### Usage: vm-retore.sh fullpath_restore_file 

export LANG=C

function usage() {
	echo "Usage: $0 fullpath_restore_file"
	exit 1
}

if [ $# != 1 ] || [ ! -f $1 ]; then
	usage
fi

RestoredFile=$1

echo
echo "          ------------------"
echo "          ---VM RESTORING---"
echo "          ------------------"
echo

echo "         VM RestoredFileName: $RestoredFile..."
echo

### Restore VM from $RestoredFile
virsh restore $RestoredFile 2> /dev/null

if [ $? != 0 ]; then
	echo "VM restore command implementation failed."
	exit 11
fi

### See if the VM restored is running ###
vmID=`virsh list | tail -2 | head -1 | awk '{print $1}' 2>/dev/null`
vmInfo=`virsh dominfo $vmID 2>/dev/null`

RestoredName=`echo "$vmInfo" | grep '^Name:' | sed 's/^[^:]*:[[:space:]]*//'`
RestoredMemory=`echo "$vmInfo" | grep -i '^Used memory:' | sed 's/^[^:]*:[[:space:]]*//'`
RestoredCpus=`echo "$vmInfo" | grep '^CPU(s):' | sed 's/^[^:]*:[[:space:]]*//'`
RestoredState=`echo "$vmInfo" | grep '^State:' | sed 's/^[^:]*:[[:space:]]*//'`
RestoredTime=`echo "$vmInfo" | grep '^CPU time:' | sed 's/^[^:]*:[[:space:]]*//'`

echo "          RestoredName : $RestoredName..."
echo "          RestoredId : $vmID..."
echo "          RestoredMemory : $RestoredMemory..."
echo "          RestoredCpus : $RestoredCpus..."
echo "          RestoredState : $RestoredState..."
echo "          RestoredTime : $RestoredTime..."
echo 

# Clean up
rm -f $RestoredFile 2>/dev/null
