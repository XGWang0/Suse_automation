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


###############################################################====================
#=== Updates a virtual host and verifies the VM management tools xl/virsh works ===
###############################################################====================

source /usr/share/qa/virtautolib/lib/virtlib
#function cleanup() {
#        echo -e "\nExecuting cleanup..."
#        if [ "$phase" = "vhUpdateVirt" ];then
#                zypper lr | grep "virtDevelRepo" >/dev/null && zypper rr virtDevelRepo
#                zypper lr | grep "virtTestRepo" >/dev/null && zypper rr virtTestRepo
#                zypper lr | grep "rareUpdateRepo" >/dev/null && zypper rr rareUpdateRepo
#        elif [ "$phase" = "vhPrepAndUpdate" ];then
#                zypper lr | grep "product_upgrade_repo_$$" >/dev/null && zypper rr product_upgrade_repo_$$
#        fi
#
#        popd > /dev/null
#        trap - SIGINT
#        exit 1
#}

function get_source() {
	item=$1
	for method in http ftp;do
		itemSource=`$getSource source.$method.${item/sp0/fcs} 2>/dev/null`
		if [ -n "$itemSource" ];then
			break
		fi
	done
	echo $itemSource
}

function set_grub_default_boot_to_upgrade() {
	#detact grub version
	grub="`find /boot/ -name 'grub.cfg'`"
	g_v=2
	if [ -z "$grub" ];then
		grub="`find /boot/ -name 'menu.lst'`"
		g_v=1
	fi
	
	#get the upgrade entry index
	index=`grep -i '^menuentry\|^submenu\|^title' $grub|grep -ni 'Installation'|head -1|awk -F: '{print $1}'`
	
	#set the default boot to upgrade entry
	if [ -n "$index" ];then
		index=$((index - 1));
		
		#for grub 1
		if [ $g_v -eq 1 ];then
			sed -i "s/^default .*/default $index/;s/set default=.*/set default=$index/" $grub
		fi
		#for grub 2
		if [ $g_v -eq 2 ];then
			sed -i  '/set default=/c set default=2'
		fi
	fi

}

function do_host_upgrade() {
	local PRODUCT_UPGRADE=$1
	local PRODUCT_UPGRADE_REPO=$2
	local HOST_UPGRADE_YAST_FILE=$3
	local HOST_HYPERVISOR=$4
	local rebootFlag=$5

	local PRODUCT=`/usr/share/qa/tools/product.pl -n|tr '[A-Z]' '[a-z]'|tail -1|sed 's/-[^-]\+$//'`
	PRODUCT="${PRODUCT}-64"

	# Update online for sp->sp+1, offline for product->product+1
	OIFS=$IFS
	IFS='-'
	A_DEF=(${PRODUCT})
	baseRelease=${A_DEF[1]}
	A_DEF=(${PRODUCT_UPGRADE})
	upRelease=${A_DEF[1]}
	upSP=${A_DEF[2]}
	IFS=$OIFS
	unset A_DEF

	if [ $baseRelease -le $(($upRelease-1)) ];then
		# update offline
		echo -e "\nExecuting host upgrade to $PRODUCT_UPGRADE_REPO offline..."
		if [ -z "$HOST_UPGRADE_YAST_FILE" ];then
			echo "ERROR: Upgrade from PRODUCT->PRODUCT+1 needs offline upgrade, but upgrade yast file is not set!"
			echo "ERROR: Upgrade from PRODUCT->PRODUCT+1 needs offline upgrade, but upgrade yast file is not set!" >&2
			cleanup
		fi

		destYast=/root/autoupg.xml
		cp $HOST_UPGRADE_YAST_FILE $destYast

		if [ $upRelease -ge 12 ];then
			BOOTLOADER="grub2"
		else
			BOOTLOADER="grub"
		fi

		if [ `basename $HOST_UPGRADE_YAST_FILE` = "autoupg_template.xml" ];then
			# use template file, need modifications
			if [ "$upSP" = "sp0" ];then
				upSP=""
			fi
			upSP=`echo $upSP | tr [a-z] [A-Z]`
			if [ -n "$HOST_HYPERVISOR" ];then
				QA_HEAD_REPO="http://dist.nue.suse.com/ibs/QA:/Head/SLE-$upRelease-$upSP"
				QA_HEAD_REPO=${QA_HEAD_REPO%-}
				VIRT_PATTERN="${HOST_HYPERVISOR}_server"
	
				sed -i "s#QA_HEAD_REPO#$QA_HEAD_REPO#g" $destYast
				sed -i "s#VIRT_PATTERN#$VIRT_PATTERN#g" $destYast
			else
				sed -i "/QA_HEAD_REPO/d" $destYast
				sed -i "/VIRT_PATTERN/d" $destYast
			fi
			sed -i "s#BOOTLOADER#$BOOTLOADER#g" $destYast
			#set the guest to mount by UUID 
			bootpartition=`df / | awk 'END { print $1; }'`
			pname=${bootpartition##*/}
			UUID=`ls -l /dev/disk/by-uuid/ |awk -v p=$pname '{gsub(/.*\//,"",$NF);a[$NF]=$9}END{print a[p]}'`
			sed -i "s/UUID/$UUID/g" $destYast
			sed -i "s#$bootpartition#UUID=$UUID#g" /etc/fstab

		fi

		# set up boot menu for upgrade item
		grubTool=/usr/share/qa/tools/setupgrubforinstall
		# $grubTool checks grub version by checking /boot/grub first,then /boot/grub2
		if [ -d /boot/grub -a -d /boot/grub2 ];then
			mv /boot/grub /boot/grub.org
		fi

		$grubTool $PRODUCT_UPGRADE_REPO  bootloader autoupgrade=1
		#temporary fix for bug 988287: can not detect system when upgrade via autoyast
		#$grubTool $PRODUCT_UPGRADE_REPO  bootloader autoupgrade=1 self_update=0
		if [ $? -ne 0 ];then
			echo "Setup menuentry for host upgrade failed!"
			echo "Setup menuentry for host upgrade failed!" >&2
			cleanup
		fi

		# change default boot to normal system and grub once to upgrade
		if [ $baseRelease -ge 10 ];then
			set_grub_default_boot_to_upgrade
		else
			echo "Not support upgrade from product->product+1 when product is lower than 10!"
			echo "Not support upgrade from product->product+1 when product is lower than 10!" >&2
			cleanup
		fi
		if [ $? -ne 0 ];then
			echo "Grub once to upgrade menuentry $upgradeMenuentry failed!"
			echo "Grub once to upgrade menuentry $upgradeMenuentry failed!" >&2
			cleanup
		fi

		[ "$rebootFlag" = "on" ] && reboot

	elif [ $baseRelease -eq $upRelease ];then
		# update online
		echo -e "\nExecuting host upgrade to $PRODUCT_UPGRADE_REPO online..."
		productUpgradeRepoName="product_upgrade_repo_$$"
		ZYPPER addrepo $PRODUCT_UPGRADE_REPO $productUpgradeRepoName || { echo "Add upgrade product repo failed!"; cleanup; }
		ZYPPER "refresh $productUpgradeRepoName" || { echo "Refresh upgrade product repo failed!"; cleanup; }
	
		echo -e "Executing host upgrade command:\n\tzypper --non-interactive dup -l -r $productUpgradeRepoName\n"
		ZYPPER --non-interactive dup -l -r $productUpgradeRepoName
		retCode=$?
		if [ $retCode -eq 0 ];then
			echo "Host upgrade to $PRODUCT_UPGRADE_REPO is done. Need to reboot system!!!" 
			[ "$rebootFlag" = "on" ] && reboot
		else
			echo "Host upgrade to $PRODUCT_UPGRADE_REPO failed!"
			cleanup
		fi
	else
		echo "Error! Your given base release is lower than upgrade release!"
		echo "Error! Your given base release is lower than upgrade release!" >&2
		cleanup
	fi

	return 0
}

function get_vm_ip() {
	vmName=$1
	mac=`virsh dumpxml $vmName | grep -i "mac address=" | sed "s/^\s*<mac address='\([^']*\)'.*$/\1/"`
	sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"
	local getSettings="/usr/share/qa/virtautolib/lib/get-settings.sh"
	vmUser=`$getSettings vm.user`
	vmPass=`$getSettings vm.pass`
	export SSHPASS=$vmPass

	virsh start $vmName >/dev/null 2>&1
	sleep 10

	#ensure vm ssh is up and ready to handle connections
	timeoutTimer=300
	tryTimer=0
	while [ $tryTimer -lt $timeoutTimer ];do
		ip=`get_ip_by_mac $mac`
		ip=${ip##* }
		if [ "$ip" == "mac-err" ];then
			ip=''
		fi
		$sshNoPass $vmUser@$ip "echo 'Check ssh connection state!'" >/dev/null 2>&1 
		ret=$?
		if [ $ret -ne 0 ];then
			sleep 10
			((tryTimer+=10))
		else
			break
		fi
	done
		
	if [ -z "$ip" ];then
	        echo "Null"
	else
	        echo "$ip"
	fi
}

function run_script_inside_vm() {
	vmName=$1
	scriptToRun=$2
	destroyVmAfter=$3
	cleanupWhenFail=$4

	if [ -z "$destroyVmAfter" ];then
		destroyVmAfter="yes"
	fi
	if [ -z "$cleanupWhenFail" ];then
		cleanupWhenFail="yes"
	fi
	
	vmIP=$(get_vm_ip $vmName)
	if [ $vmIP = "Null" ];then
		echo "Can not get IP for VM $vmName!" 
		if [ "$cleanupWhenFail" == "yes" ];then
			cleanup
		else
			return 1
		fi
	fi

	echo -e "\nExecuting required script $scriptToRun inside vm $vmName(ip:$vmIP)..."
	#let vm idle for a while
	sleep 10
	local sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"
	local getSettings="/usr/share/qa/virtautolib/lib/get-settings.sh"
	vmUser=`$getSettings vm.user`
	vmPass=`$getSettings vm.pass`
	export SSHPASS="$vmPass"
	#cat $scriptToRun | $sshNoPass -vvv $vmUser@$vmIP bash 2>&1
	output=`cat $scriptToRun | $sshNoPass $vmUser@$vmIP bash -x 2>&1`
	ret=$?
	if echo "$output" | grep -iq "Permission denied";then
		commands=`echo "$output" | sed -n '/ssh-keygen/p'`
		eval $commands
		sleep 3
		rm /root/.ssh/known_hosts
		sleep 3
		output=`cat $scriptToRun | $sshNoPass $vmUser@$vmIP bash -x 2>&1`
		ret=$?
	fi
	echo "$output"

	#Do this to only keep one vm up on the host to avoid performance issue
	if [ "$destroyVmAfter" == "yes" ];then
		virsh destroy $vmName >/dev/null
	fi
	[ $ret -eq 0 ] && echo "The script running is successful!" && return 0
	echo "The script running failed" 
	if [ "$cleanupWhenFail" == "yes" ];then
		cleanup
	else
		return $ret
	fi
}

function verify_host_installation() {
	#Verifies the system is installed as kvm or xen hypervisor
	echo -e "\nExecuting verification for host installation ..."
	echo -e host hypervisor is ${HOST_HYPERVISOR}
	ZYPPER se -i -t pattern ${HOST_HYPERVISOR}"_server" >/dev/null
	[ $? != 0 ] && echo "Host installation as ${HOST_HYPERVISOR} server failed!" && cleanup
	if ZYPPER info -t pattern ${HOST_HYPERVISOR}"_server" | sed -n '/^\s*--+/,$p' | grep -E "^ " >/dev/null;then
		echo "There are rpms not installed in pattern ${HOST_HYPERVISOR}_server" 
		cleanup
	fi
	echo "Host installation as ${HOST_HYPERVISOR} server is successful."

}

function check_run_validation() {
	realProduct=`sed -n '1p' /etc/SuSE-release`
	if [[ "$realProduct" = "SUSE Linux Enterprise Server"* ]];then
		realProductName="sles"
	fi
	if [[ "$realProduct" = *"x86_64"* ]];then
		realArch="64"
	else
		realArch="32"
	fi
	realVersion=`grep "VERSION" /etc/SuSE-release | sed 's/^.*VERSION = \(.*\)\s*$/\1/'`
	realSp=`grep "PATCHLEVEL" /etc/SuSE-release | sed 's/^.*PATCHLEVEL = \(.*\)\s*$/\1/'`
	realProductFullName="${realProductName}-${realVersion}-sp${realSp}-${realArch}"

	if [ "$phase" = "vhPrepAndUpdate" ];then	
		if [ "$realProductFullName" != "${PRODUCT}" ];then
			echo "Error: You aim to run host upgrade test on ${PRODUCT}, but the current system is $realProductFullName." >&2
			cleanup
		fi
	elif [ "$phase" = "vhUpdatePostVerification" ];then
		if [ "$realProductFullName" != "${PRODUCT_UPGRADE}" ];then
			echo "Error: You aim to run host upgrade test on ${PRODUCT_UPGRADE}, but the current system is $realProductFullName." >&2
			cleanup
		fi
	fi
		

	if [ "${HOST_HYPERVISOR}" = "xen" ];then
		if ! uname -r | grep xen >/dev/null && [ ! -e /proc/xen/privcmd ];then
			echo "Error: You aim to run host upgrade xen test, but you are not on xen kernel." >&2
			cleanup
		fi
	elif [ "${HOST_HYPERVISOR}" = "kvm" ];then
		if uname -r | grep xen >/dev/null || [ -e /proc/xen/privcmd ];then
			echo "Error: You aim to run host upgrade kvm test, but you are on xen kernel." >&2
			cleanup
		fi
	fi
	
	echo "The test you are running is valid to be run on this system!"
	return 0

}

function ZYPPER() {
	#try zypper command multiple times to hopefully work across network failure
	args=$@
	maxTry=3
	waitTime=60
	if ! echo $args | grep "non-interactive" >/dev/null;then
		args="--non-interactive "$args
	fi

	if ! echo $args | grep "gpg-auto-import-keys" >/dev/null;then
		args="--gpg-auto-import-keys "$args
	fi

	for ((count=0;count<$maxTry;count++));do
		output=`zypper $args 2>&1`
		ret=$?
		if [ $ret -eq 4 ];then
			sleep $waitTime
			continue
		else
			break
		fi
	done

	echo "$output"
	return $ret
}

function handle_upgrade_leaving() {
	if [ -d /boot/grub -a -d /boot/grub2 ];then
		mv /boot/grub /boot/grub.org
	fi
}

