#!/bin/bash
# ****************************************************************************
# Copyright (c) 2016 Unpublished Work of SUSE. All Rights Reserved.
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


######################################
#=== Test single guest upgrade ======#
######################################

source /usr/share/qa/virtautolib/lib/vh-update-lib.sh
PRODUCT_UPGRADE=$1
PRODUCT_UPGRADE_REPO=$2
VMNAME=$3

script=/tmp/guest-upgrade.sh

#Generate script to run guest upgrade on vm
commands='
release=`grep "VERSION" /etc/SuSE-release | sed "s/^.*VERSION = \(.*\)\s*$/\1/"`
spack=`grep "PATCHLEVEL" /etc/SuSE-release | sed "s/^.*PATCHLEVEL = \(.*\)\s*$/\1/"`
if [ "$release" -ge 11 ];then
	if zypper lr -u | grep -iq qa_auto_repo ; then
	        zypper rr qa_auto_repo
	fi
else
	if zypper sl | grep -iq qa_auto_repo ; then
		zypper --non-interactive  --no-gpg-checks  sd qa_auto_repo
	fi
fi

if [ "$spack" = "0" ];then
        QA_HEAD_REPO="http://dist.nue.suse.com/ibs/QA:/Head/SLE-$release"
else
        QA_HEAD_REPO="http://dist.nue.suse.com/ibs/QA:/Head/SLE-$release-SP${spack}"
fi
QA_HEAD_REPO=${QA_HEAD_REPO%-}

if [ "$release" -ge 11 ];then
	zypper --non-interactive --gpg-auto-import-keys ar ${QA_HEAD_REPO} qa_auto_repo
	zypper --non-interactive --gpg-auto-import-keys ref qa_auto_repo
	zypper --non-interactive --gpg-auto-import-keys in -l qa_lib_perl qa_tools qa_lib_virtauto
else
	zypper --non-interactive  --no-gpg-checks sa ${QA_HEAD_REPO} qa_auto_repo
	zypper --non-interactive  --no-gpg-checks ref qa_auto_repo
	zypper --non-interactive  --no-gpg-checks sa http://download.suse.de/ibs/QA:/Head:/Devel/SLE_10_SP4/ qa_auto_devel_repo
	zypper --non-interactive  --no-gpg-checks ref qa_auto_devel_repo
	zypper --non-interactive  --no-gpg-checks in qa_lib_perl qa_tools qa_lib_virtauto
fi

source /usr/share/qa/virtautolib/lib/vh-update-lib.sh
function cleanup() {
        echo "Executing cleanup..."
        if [ "$release" -ge 11 ];then
		zypper lr | grep product_upgrade_repo_$$ >/dev/null && zypper rr product_upgrade_repo_$$
		zypper lr | grep qa_auto_repo  >/dev/null && zypper rr qa_auto_repo
        else
		zypper sl | grep product_upgrade_repo_$$ >/dev/null && zypper sd product_upgrade_repo_$$
		zypper sl | grep qa_auto_repo >/dev/null && zypper rr qa_auto_repo
        fi
		
	exit 1
}

'

echo "$commands" > $script

commands="
do_host_upgrade $PRODUCT_UPGRADE $PRODUCT_UPGRADE_REPO \"/usr/share/qa/virtautolib/data/autoupg_template.xml\" 
"
echo "$commands" >> $script
#echo "Debug: the script to be executed on $VMNAME is:"
#cat $script
#echo "Debug end."
run_script_inside_vm "$VMNAME" "$script" "no" "no"
