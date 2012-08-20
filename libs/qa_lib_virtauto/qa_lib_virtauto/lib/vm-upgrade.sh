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


#===============================
#=== Virtual Machine Upgrade ===
#===============================

### Usage: vm-upgrade.sh repoURL autoyastfile VMName

export LANG=C

function usage() {
    cmd=`basename $0`
    echo "Usage: $cmd repoURL autoyastfile VMName"
    echo "Example: $cmd ftp://cml.suse.cz/netboot/find/openSUSE-11.0-RC3-DVD-x86_64 http://bender.suse.cz/autoinst/autoinst_vulture.xml VM_SLES11SP1-pv"
    exit 1
}

function curlprobe() {
    local url="$1"
    $curl -o /dev/null -I -L -f -s "$url" || return 1
}

if [ "$#" -lt 3 -o "$1" == "--help" ]
then
    usage
fi

echo
echo "          --------------------"
echo "          ---  VM UPGRADE  ---"
echo "          --------------------"
echo

curl=curl

# Get arg
insturl=$1
ayfile=$2
vmname=$3 # Either domUName or domUID works fine

# Get domUIP
domUmac=`virsh dumpxml $vmname | awk -F"'" '/mac address/ {print $2;exit}'`
sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"
getSettings="./get-settings.sh"
netinfoIP=`$getSettings netinfo.ip`
netinfoUser=`$getSettings netinfo.user`
netinfoPasswd=`$getSettings netinfo.pass > /dev/null 2>&1`
domUIP=`export SSHPASS=$pass; $sshNoPass $netinfoUser@$netinfoIP "mac2ip $domUmac"`

# Get vm-user vm-pass
vmuser=`$getSettings vm.user`
vmpasswd=`$getSettings vm.pass > /dev/null 2>&1`

# Create a temp file, in order to verify ssh connection.
TMPFILE=`export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP 'mktemp /tmp/distinst.XXXXXX > /dev/null 2>&1'`
if [ $? -ne 0 ]
then
    echo "$0: Cannot create temp file, VM cannot be connected by ssh. Exiting."
    exit 1
fi

# Get domUCPUArch
dumUCPUArch=`export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP 'uname -m'`

echo
echo "   Setting grub parameters and kernel parameters..."
# Set grub parameters
params="vga=normal autoyast=$ayfile netdevice=eth0 netwait=10 $domUIP install=$insturl"

# Set kernel params
bootloaderconf=/boot/grub/menu.lst
grubpartition=`export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP 'awk "/^root/ {print $2;exit}" < /etc/grub.conf'`
if [ -z "$grubpartition" ]
then
	tmpres=`export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP 'head -1 /etc/grub.conf'`
	grubpartition=`echo -n $tmpres | awk -F'(' '{print $2}'`
	grubpartition="(${grubpartition}"
fi

imagedir=`export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "mktemp -d /boot/tmp.XXXXXX > /dev/null 2>&1"`

if [ $? -ne 0 ]
then
    echo "$0: Cannot create temp directory, exiting"
    exit 1
fi

cleanup()
{
    [ -f $TMPFILE ] && rm $TMPFILE > /dev/null 2>&1
}
trap cleanup EXIT

for DIR in "boot/x86_64/loader" "boot/loader" "boot/i386/loader" "boot/i586/loader"
do
    if curlprobe "$insturl/$DIR/linux"
    then
        kernelurl="$insturl/$DIR/linux"
        initrdurl="$insturl/$DIR/initrd"
        break
    fi
done

echo
echo "   Downloading kernel and initrd files to upgraded VM..."
export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "$curl -f -L -o $imagedir/linux $kernelurl > /dev/null 2>&1"
export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "$curl -f -L -o $imagedir/initrd $initrdurl > /dev/null 2>&1"

ret1=`export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "ls $imagedir/linux > /dev/null 2>&1; echo $?"`
ret2=`export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "ls $imagedir/initrd > /dev/null 2>&1; echo $?"`
if [ $ret1 -ne 0 -o $ret2 -ne 0 ]
then
    echo "Could not download image/initrd from '$insturl' to '$imagedir'"
    exit 1
fi

# extract the product part from the URL, ugly but seems to work
title=`echo $insturl | sed -e 's/\//\n/g' | grep -v '\..\+\.' | awk '{ print length, $0 }' | sort -gr | cut -d\  -f2 | head -n1`
count=`export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "grep 'title Installation' $bootloaderconf | grep -c $title"`
if [ $count -gt 0 ]
then
    title="$title ($((count+1)))"
fi

echo
echo "   Setting grub menu..."
export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "echo \"\" >> $bootloaderconf"
export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "echo \"title Installation $title\" >> $bootloaderconf"
export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "echo \"    root $grubpartition\" >> $bootloaderconf"
export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "echo \"    kernel $imagedir/linux $params\" >> $bootloaderconf"
export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "echo \"    initrd $imagedir/initrd\" >> $bootloaderconf"
export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP sync

# start the installation with reboot
item=`export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "grep title -c $bootloaderconf"`
item=$((item-1)) # the new config is written and then its counted
if [ `export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "grep '^default' $bootloaderconf | wc -l"` -gt 0 ];then
    export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "sed  -i 's/^default.*$/default $item/' $bootloaderconf"
else # SLMS creates menu.lst without 'default'
    export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "sed -i '1idefault $item' $bootloaderconf"
fi
echo 

echo "   Grub menu setting successfully..."
echo

vmInfo=`virsh dominfo $vmname 2>/dev/null`
vmID=`echo "$vmInfo" | grep '^Id:' | sed 's/^[^:]*:[[:space:]]*//'`
vmName=`echo "$vmInfo" | grep '^Name:' | sed 's/^[^:]*:[[:space:]]*//'`
echo "   VM Upgrade Details: ..."
echo ""
echo "          UpgradeVMName : $vmName..."
echo "          UpgradeVMID   : $vmID..."
echo "          UpgradeVMIP   : $domUIP..."
echo "          UpgradeVMArch : $dumUCPUArch..."
echo "          InstallProd   : $title..."
echo "          InstallRepo   : $insturl..."
echo "          AutoYastFile  : $ayfile..."
echo

echo "   VM will reboot to start upgrading..."
export SSHPASS=$pass; $sshNoPass $vmuser@$domUIP "reboot"

echo
echo "          -----------------------"
echo "          --- VM UPGRADE DONE ---"
echo "          -----------------------"
echo
