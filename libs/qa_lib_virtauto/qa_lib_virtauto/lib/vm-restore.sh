#!/bin/bash
# ****************************************************************************
# Copyright © 2011 Unpublished Work of SUSE. All Rights Reserved.
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

