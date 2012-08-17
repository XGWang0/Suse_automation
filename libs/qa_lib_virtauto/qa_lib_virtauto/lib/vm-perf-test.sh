#!/bin/bash
# ****************************************************************************
# Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
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


#==============================
#===  performance test VM   ===
#==============================

### Usage: vm-perf-test.sh domuName

export LANG=C

function usage() {
	echo "Usage: $0 domuName"
	exit 1
}

if [ $# != 1 ]; then
	usage
fi

domuName=$1

# Define performance test cases
case_list="qa_test_fs_stress qa_test_process_stress qa_test_sched_stress"

echo
echo "          --------------------------------"
echo "          ---  VM Performance Testing  ---"
echo "          --------------------------------"
echo

# Get dumUIP
domUMac=`virsh dumpxml $1| grep "mac address" | cut -d"=" -f2 | sed "s/[\/>|\']//g"`
sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"
getSettings="./get-settings.sh"
netinfoIP=`$getSettings netinfo.ip`
netinfoUser=`$getSettings netinfo.user`
netinfoPasswd=`$getSettings netinfo.pass > /dev/null 2>&1`
domUIP=`export SSHPASS=$netinfoPasswd; $sshNoPass $netinfoUser@$netinfoIP mac2ip $domUMac`

# Get vm-user vm-pass
vmuser=`$getSettings vm.user`
vmpasswd=`$getSettings vm.pass > /dev/null 2>&1`

# Get OS version/subversion
dumUVersion=`export SSHPASS=$vmpasswd; $sshNoPass $vmuser@$domUIP 'grep VERSION /etc/SuSE-release | cut -d" " -f3'`
domUSubversion=`export SSHPASS=$vmpasswd; $sshNoPass $vmuser@$domUIP 'grep PATCHLEVEL /etc/SuSE-release | cut -d" " -f3'`

# Get repoURL
source /usr/share/qa/lib/config ''
install_repo=`get_qa_config install_qa_repository`

if [ "$dumUVersion" = "11" ]; then
	[ $domUSubversion = "0" ] && repoURL="$install_repo/SUSE_SLE-11_GA/"
	[ $domUSubversion = "1" ] && repoURL="$install_repo/SUSE_SLE-11-SP1_GA/"
elif [ "$dumUVersion" = "10" ]; then
	[ $domUSubversion = "3" ] && repoURL="$install_repo/SLE_10_SP3/"
	[ $domUSubversion = "4" ] && repoURL="$install_repo/SLE_10_SP4/"
fi

vmInfo=`virsh dominfo $domuName 2>/dev/null`

TestedID=`echo "$vmInfo" | grep '^Id:' | sed 's/^[^:]*:[[:space:]]*//'`
TestedMemory=`echo "$vmInfo" | grep '^Used memory:' | sed 's/^[^:]*:[[:space:]]*//'`
TestedCpus=`echo "$vmInfo" | grep '^CPU(s):' | sed 's/^[^:]*:[[:space:]]*//'`
TestedState=`echo "$vmInfo" | grep '^State:' | sed 's/^[^:]*:[[:space:]]*//'`
TestedTime=`echo "$vmInfo" | grep '^CPU time:' | sed 's/^[^:]*:[[:space:]]*//'`

echo "		TestedName : $domuName..."
echo "		TestedId : $TestedID..."
echo "		TestedOSVersion: $dumUVersion..."
echo "		TestedOSSubversion: $dumUSubversion..."
echo "		Testedrepo: $repoURL..."
echo "		TestedMemory : $TestedMemory..."
echo "		TestedCpus : $TestedCpus..."
echo "		TestedState : $TestedState..."
echo "		TestedTime : $TestedTime..."
echo "		TestedIP: $domUIP..."
echo "		TestCases: $case_list..."
echo

# Add Dev Repo
if [ "$dumUVersion" = "11" ]; then
	export SSHPASS=$vmpasswd ; $sshNoPass $vmuser@$domUIP "zypper ar -f $repoURL devrepo > /dev/null 2>&1"
	ret=$?
elif [ "$dumUVersion" = "10" ]; then
	export SSHPASS=$vmpasswd ; $sshNoPass $vmuser@$domUIP "zypper sa $repoURL devrepo > /dev/null 2>&1"
	ret=$?
fi

if [ $? != 0 ]; then
	echo "VM add repo failed."
	exit 1
fi

# Add hamsta
export SSHPASS=$vmpasswd ; $sshNoPass $vmuser@$domUIP "zypper --no-gpg-checks --non-interactive in hamsta > /dev/null 2>&1"
if [ $? != 0 ]; then
        echo "VM add hamsta failed."
        exit 1
fi

# Add test suites
export SSHPASS=$vmpasswd ; $sshNoPass $vmuser@$domUIP "zypper --no-gpg-checks --non-interactive in $case_list > /dev/null 2>&1"
if [ $? != 0 ]; then
        echo "VM add test suites: $case_list failed."
        exit 1
fi

# Implement test cases
export SSHPASS=$vmpasswd ; $sshNoPass $vmuser@$domUIP "/usr/share/hamsta/testscript/customtest $case_list > /dev/null 2>&1"

echo
echo "          --------------------------------"
echo "          --- VM Performance Test DONE ---"
echo "          --------------------------------"
echo

