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

