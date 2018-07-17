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
#==================================
# Create a vm via vm-install.sh ===
#==================================

function usage() {
echo << EOF
    Usage: $0 VM_NAME ARGS SLEEPTIME
           VM_NAME: name of the vm, following rule os-release-spack-arch-virttype-scenario-method
           ARGS: the arguments need to pass to vm-install.sh script
           SLEEPTIME: time to sleep before call vm-install.sh

EOF
}

if [ $# -ne 3 ];then
    usage
    exit 1
fi

VM_NAME=$1
args=$2
sleepTime=$3

#Variables needed by /usr/share/qa/qa_test_virtualization/shared/standalone
OIFS=$IFS
IFS="-"
A_DEFINITION=($VM_NAME)
IFS="$OIFS"
OPERATING_SYSTEM=${A_DEFINITION[0]}
RELEASE=${A_DEFINITION[1]}
SERVICE_PACK=${A_DEFINITION[2]}
ARCHITECTURE=${A_DEFINITION[3]}
VIRT_TYPE=${A_DEFINITION[4]}
SCENARIO=${A_DEFINITION[5]}
INSTALL_METHOD=${A_DEFINITION[6]}

#download kernel and initrd files
source /usr/share/qa/qa_test_virtualization/shared/standalone

#take a rest after each round of vm creation
sleep 10

#avoid competition when parallelly run
sleep $sleepTime
#/usr/share/qa/virtautolib/lib/vm-install.sh -o sles -r 11 -p sp4 -c 64 -t fv -n def -m net -D tap:qcow2 -d 4096 -e 512 -F sles-11-sp4-64-fv-def-net -y 192.168.123.1 -b br123 -P /usr/share/qa/qa_test_virtualization/loc/settings.standalone -g | tee ./vm-install.log 2>&1
source /usr/share/qa/virtautolib/lib/vm-install.sh $args
