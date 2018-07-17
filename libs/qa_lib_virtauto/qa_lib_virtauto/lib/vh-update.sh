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

export LANG=C
dirname=`dirname $0`
pushd $dirname > /dev/null

source ./vm-admin-lib.sh
source ./vh-update-lib.sh

trap "echo 'catch CTRL+C';cleanup" SIGINT

function cleanup() {
	echo -e "\nExecuting cleanup..."
	if [ "$phase" = "vhUpdateVirt" ];then
		zypper lr | grep "virtDevelRepo" >/dev/null && zypper rr virtDevelRepo
		zypper lr | grep "virtTestRepo" >/dev/null && zypper rr virtTestRepo
		zypper lr | grep "rareUpdateRepo" >/dev/null && zypper rr rareUpdateRepo
	elif [ "$phase" = "vhPrepAndUpdate" ];then
		zypper lr | grep "product_upgrade_repo_$$" >/dev/null && zypper rr product_upgrade_repo_$$
	fi

	popd > /dev/null
	trap - SIGINT
	exit 1
}

function usage() {
	echo ""
	echo "Usage: $0 -p upgradePhase -t hypervisorType [-m product] [-b productRepo] [-n productUpgrade] [-u upgradeRepo] [-a autoinstall] [-y upgradeYastFile] [-r on/off] [-f on/off] [-v on/off] [-l milestoneTestRepo] [-g guestProductList]."
	echo "  -p    upgradePhase can be vhInstallation/vhUpdateVirt/vhPrepAndUpdate/vhUpdatePostVerification."
	echo "  -t    hypervisorType should be xen or kvm."
	echo "  -m/-n product and productUpgrade should follow format name-release-spack-arch, example:"
	echo "        sles-11-sp3-64"
	echo "  -b/-u productRepo/upgradeRepo can only be given when product/productUpgrade is given."
	echo "        if product/productUpgrade is given, but productRepo/upgradeRepo is not given,"
	echo "        the repo will be read from local config file:/usr/share/qa/virtautolib/data/settings.[local]"
	echo "  -y    upgradeYastFile, used for offline upgrade for PRODUCT->PRODUCT+1"
	echo "  -r    reboot flag"
	echo "  -f    update flag of virt rpms to product's update repo"
	echo "  -v    update flag of virt rpms to virt-devel/virt-test repos"
	echo "  -l    milestone test repo link which is used to update virt rpms"
	echo "  -g    the guest product list you want to test, regular expression supported, separated with a comma,"
	echo "        example \"sles-11-sp[34], sles-12-sp1\"."
	echo "        if not set, by default all in the guest config file will be installed."
	echo -e "\n  Standard call :"
	echo "  $0 -p upgradePhase -t hypervisorType -m product -n productUpgrade."
	echo -e "\n  Example:"
	echo "  $0 -p vhPrepAndUpdate -t xen -m sles-11-sp3-64 -n sles-11-sp4-64"
	cleanup
}

while getopts "p:t:b:u:a:m:n:r:f:v:y:l:g:" OPTIONS
do
	case $OPTIONS in
		p)phase="$OPTARG";;
		t)HOST_HYPERVISOR="$OPTARG";;
		b)PRODUCT_REPO="$OPTARG";;
		u)PRODUCT_UPGRADE_REPO="$OPTARG";;
		a)AUTOINSTALL_SERVER="$OPTARG";;
		m)PRODUCT="$OPTARG";;
		n)PRODUCT_UPGRADE="$OPTARG";;
		r)rebootFlag="$OPTARG";;
		f)updateRareFlag="$OPTARG";;
		v)updateVirtFlag="$OPTARG";;
		y)HOST_UPGRADE_YAST_FILE="$OPTARG";;
		l)milestoneTestRepo="$OPTARG";;
		g)GUEST_PRODUCT_LIST="$OPTARG";;
		\?)usage;;
		*)usage;;
	esac
done

if [ $# -lt 1 ] || [ "$phase" != "vhInstallation" -a "$phase" != "vhUpdateVirt" -a "$phase" != "vhPrepAndUpdate" -a "$phase" != "vhUpdatePostVerification" ];then
	usage
fi
HOST_HYPERVISOR=`echo $HOST_HYPERVISOR | tr [A-Z] [a-z]`
[ "$HOST_HYPERVISOR" != "xen" -a "$HOST_HYPERVISOR" != "kvm" ] && echo "Hypervisor type is not supported" && usage
export HOST_HYPERVISOR

[ -z "$PRODUCT" -a -n "$PRODUCT_REPO" ] && echo "productRepo can not be given if product is not given" && usage
[ -z "$PRODUCT_UPGRADE" -a -n "$PRODUCT_UPGRADE_REPO" ] && echo "upgradeRepo can not be given if upgradeProduct is not given." && usage

[ -z "$PRODUCT" ] && PRODUCT="sles-11-sp3-64"
[ -z "$PRODUCT_UPGRADE" ] && PRODUCT_UPGRADE="sles-11-sp4-64"

PRODUCT=`echo ${PRODUCT} | tr [A-Z] [a-z]`
PRODUCT_UPGRADE=`echo ${PRODUCT_UPGRADE} | tr [A-Z] [a-z]`

getSettings="./get-settings.sh"
getSource="./get-source.sh"
[ -z "$PRODUCT_REPO" ] && PRODUCT_REPO=`get_source $PRODUCT`
[ -z "$PRODUCT_REPO" ] && echo "The repo that the host should be installed is not configured." && cleanup

[ -z "$PRODUCT_UPGRADE_REPO" ] && PRODUCT_UPGRADE_REPO=`get_source $PRODUCT_UPGRADE`
[ -z "$PRODUCT_UPGRADE_REPO" ] && echo "The repo that the host to be upgraded to is not configured." && cleanup

[ "$rebootFlag" != "off" ] && rebootFlag="on"
[ "$updateRareFlag" != "on" ] && updateRareFlag="off"
[ "$updateVirtFlag" != "on" ] && updateVirtFlag="off"

echo "Debug info:"
echo "rebootFlag is $rebootFlag"
echo "updateRareFlag is $updateRareFlag"
echo "updateVirtFlag is $updateVirtFlag"

#a file with all commands to run in the VM guest 
RUN_INSIDE_VM=`$getSettings RUN_INSIDE_VM`

#a file with all commands to run from the host to administrate VM guest 
RUN_FROM_HOST=`$getSettings RUN_FROM_HOST`

#file to store result log while running PRODUCT version 
LOG_RESULT_PRODUCT=`$getSettings LOG_RESULT_PRODUCT`

#file to store result log while running PRODUCT+1 version 
LOG_RESULT_PRODUCT_UPGRADED=`$getSettings LOG_RESULT_PRODUCT_UPGRADED`

#VM Guest parameter/conf file
VM_GUEST_CONFIG_PARAM_FILE=`$getSettings VM_GUEST_CONFIG_PARAM_FILE`

#Upgrade Yast File
[ -z "$HOST_UPGRADE_YAST_FILE" ] && HOST_UPGRADE_YAST_FILE=`$getSettings HOST_UPGRADE_YAST_FILE`

backupRootDir=/tmp/vm_backup
backupVmListFile=${backupRootDir}/vm.list
backupInstallFailVmListFile=${backupRootDir}/install_fail_vm.list
backupCfgXmlDir=$backupRootDir/vm-config-xmls
backupDiskDir=$backupRootDir/vm-disk-files

function do_log_comparison() {
	# compare log
	echo -e "\nExecuting log comparison ..."
	# Show the guests failed during guest installation
	show_guest_installation_failures $backupInstallFailVmListFile
	guestInstallFailed=$?

	if [ ! -e $LOG_RESULT_PRODUCT -o ! -e $LOG_RESULT_PRODUCT_UPGRADED ];then
		echo "There is administration log files missing, please check!"
		echo -e "\nHost upgrade virtualization test fail! Please check!!!"
		return 1
	fi

	#Print admin result before VH upgrade
	generateAdminArrFromLog $LOG_RESULT_PRODUCT
	adminResultBeforeUpgrad=("${resultArr[@]}")
	echo "Before virtual host upgrade, administration result table is:"
	printContent $columnNum 10

	#Print admin result after VH upgrade
	generateAdminArrFromLog $LOG_RESULT_PRODUCT_UPGRADED
	adminResultAfterUpgrad=("${resultArr[@]}")
	echo "After virtual host upgrade, administration result table is:"
	printContent $columnNum 10

	#Generate difference array by compare admin results before and after upgrade
	for ((index=0;index<${#adminResultBeforeUpgrad[@]};index++));do
		if [ $index -lt $columnNum -o $((index%$columnNum)) -eq 0 ];then
			diffResultArr[$index]=${adminResultBeforeUpgrad[$index]}
		else
			if [ ${adminResultBeforeUpgrad[$index]} = ${adminResultAfterUpgrad[$index]} ];then
				if [ "${adminResultBeforeUpgrad[$index]// /}" = "PASS" ];then
					diffResultArr[$index]=''
				else
					diffResultArr[$index]="FAIL/FAIL"
				fi
			else
				diffResultArr[$index]="${adminResultBeforeUpgrad[$index]}/${adminResultAfterUpgrad[$index]}"
				diffResultArr[$index]=${diffResultArr[$index]// /}
			fi
		fi
	done
	
	#Blank columns without difference or errors
	finalDiffColumnNum=$columnNum
	for ((column=0;column<columnNum;column++));do
		for ((index=column+columnNum;index<${#diffResultArr[@]};index+=columnNum));do
			if [ -n "${diffResultArr[$index]}" ];then
				continue 2
			fi
		done
		diffResultArr[$column]=''
		((finalDiffColumnNum--))
	done

	#Blank rows without difference or errors
	for ((line=1;line<${#diffResultArr[@]}/columnNum;line++));do
		for ((index=line*columnNum+1;index<\(line+1\)*columnNum;index++));do
			if [ -n "${diffResultArr[$index]}" ];then
				continue 2
			fi
		done
		diffResultArr[$((line*columnNum))]=''
	done

	# Return when no differences or errors
	if [ $finalDiffColumnNum -eq 1 ];then
		echo -e "\nCongratulations! No administration result error or difference!"
		if [ $guestInstallFailed -eq 0 ];then
			echo -e "\nHost upgrade virtualization test pass!"
			return 0
		else
			echo -e "\nHost upgrade virtualization test fail! Please check!"
			return 2
		fi
	fi

	#Generate print array without blank columns and lines
	resultIndex=0
	unset resultArr
	for ((index=0;index<${#diffResultArr[@]};index++));do
		#ignore blank column
		if [ $((index%columnNum)) -ne 0 -a -z "${diffResultArr[$((index%columnNum))]}" ];then
			continue
		fi
		#ignore blank line
		if [ $((index/columnNum)) -ne 0 -a -z "${diffResultArr[$((index/columnNum*columnNum))]}" ];then
			continue
		fi

		resultArr[$resultIndex]=${diffResultArr[$index]}
		((resultIndex++))
	done
	#Print administration difference/error array
	echo -e "\nAdministration result difference/error table(before/after upgrade) is:"
	printContent $finalDiffColumnNum 10
	echo -e "\nHost upgrade virtualization test fail! Please check!!!"
	return 3
}

function basic_vm_administration() {
	# Basic administration of VM which store in file: $RUN_FROM_HOST
	echo -e "\nExecuting basic administration for all VMs..."
	logFile=$1
	[ -f $logFile ] || mkdir -p `dirname $1`
	echo "Basic vm administration logs will be stored in file: $logFile."

	$RUN_FROM_HOST 2>&1 | tee $logFile
	ret=$?
	[ $ret -eq 0 ] && echo "basic_vm_administration is finished successfully!" && return 0
	echo "basic_vm_administration failed!" && return 1

}

function run_script_inside_all_vms() {
	echo -e "\nExecuting required script on all created VMs..."
	#wait for all vm down stablely
	sleep 10
	for vm in `virsh list --all --name | sed '/Domain-0/d'`;do
		run_script_inside_vm $vm $RUN_INSIDE_VM
		sleep 10
	done
}

#function whether_install_vm() {
#    configFile=$1
#	VM_NAME=`$getSettings -p VM_NAME -s $configFile`
#	if [ -z "$VM_NAME" ];then
#		return 1
#	fi
#
#    OIFS=$IFS
#    IFS="-"
#    baseOS=(${PRODUCT})
#    upOS=(${PRODUCT_UPGRADE})
#	A_DEF=(${VM_NAME})
#    IFS=$OIFS
#    baseRelease=${baseOS[1]}
#    baseSP=${baseOS[2]}
#    baseSP=`echo $baseSP | tr [A-Z] [a-z]`
#    upRelease=${upOS[1]}
#    upSP=${upOS[2]}
#    upSP=`echo $upSP | tr [A-Z] [a-z]`
#	VM_RELEASE=${A_DEF[1]}
#	VM_SPACK=${A_DEF[2]}
#	VM_SPACK_IN_SMALL=`echo $VM_SPACK | tr [A-Z] [a-z]`
#	[ "$VM_SPACK_IN_SMALL" = "fcs" ] && VM_SPACK_IN_SMALL="sp0"
#	VM_VIRTT=${A_DEF[4]}
#
#	#Only install VMs from baseRelease.baseSpack to upRelease.upSpack
#	[[ $VM_RELEASE < $baseRelease ]] && return 1
#	[[ $VM_RELEASE = $baseRelease && $VM_SPACK_IN_SMALL  < $baseSP ]] && return 1
#	[[ $VM_RELEASE > $upRelease ]] && return 1
#	[[ $VM_RELEASE = $upRelease && $VM_SPACK_IN_SMALL > $upSP ]] && return 1
#	[[ $HOST_HYPERVISOR = [Kk][Vv][Mm] && $VM_VIRTT = [Pp][Vv] ]] && return 1
#
#	return 0
#}

function whether_install_vm() {
    configFile=$1
	vmProducts=$2

    if [ -z "$vmProducts" ];then
        #install any kind of vm in config file
        return 0
    else 
        vmName=`$getSettings -p VM_NAME -s $configFile`
        vmName=${vmName/fcs/sp0}
        for product in ${vmProducts//,/ };do 
            if [[ $vmName == *${product}* ]];then
                return 0
            fi   
        done 

    fi   
    return 1
}


function restore_vm_guest_data() {
	# restore all VM conf and image
	echo -e "\nExecuting restoration for all VMs ..."
	# start libvirtd.service if it is not active
	if [[ "$PRODUCT_UPGRADE" == "sles-12-"* ]];then
		if systemctl status libvirtd.service | grep -iq inactive;then
			systemctl start libvirtd.service
			if [ $? -ne 0 ];then
				echo "Can not start libvirtd.sesrvice!"
				cleanup
			fi
		fi
	fi
	# clean environment
	clean_environment
	#restore files
	origWorkDir=`pwd`
	[ ! -d $backupRootDir ] && echo "Backup directory for VMs does not exist!" && cleanup
	cd $backupDiskDir
	echo "Restoring all vm disk files..."
	cp --parent -r ./* /
	cd $origWorkDir
	# restore everything in the system
	bash /usr/share/qa/qa_test_virtualization/shared/standalone
	for vmName in `cat $backupVmListFile`;do
		echo "Restoring VM $vmName..."
		virsh define ${backupCfgXmlDir}/${vmName}.xml || { echo "Define domain $vmName failed!"; cleanup; }
		virsh create ${backupCfgXmlDir}/${vmName}.xml || { echo "Create VM $vmName failed!"; cleanup; }
		virsh destroy $vmName >/dev/null || { echo "Destroy VM $vmName failed!"; cleanup; }
	done

	echo "Restore all VMs is successful!"
	# Only remove the backup directory when restore is successful, or keep it for debug
	rm -r $backupRootDir

}

#function update_rpms() {
#	#update virtualization related rpms
#	echo -e "\nExecuting update virt related rpms..."
#	#Rpm list
#	release=`echo $PRODUCT | cut -d'-' -f 2`
#
#	virtPatternRpms=`ZYPPER info -t pattern ${HOST_HYPERVISOR}"_server" | sed -n '/^--+/,$p' | sed '1d' | gawk -F\| '{print $2}'`
#	commonWatchRpms="libvirt libvirt-client libvirt-python libvirt-daemon libvirt-lock-sanlock perl-Sys-Virt-TCK"
#
#	if [ $release -ge 12 ];then
#		commonWatchRpms=${commonWatchRpms}" \
#						libvirt-daemon-driver-network libvirt-daemon-driver-qemu \
#						libvirt-daemon-driver-interface libvirt-daemon-driver-nwfilter \
#						libvirt-daemon-driver-secret libvirt-daemon-driver-nodedev libvirt-daemon-driver-storage \
#						libvirt-daemon-qemu qemu  libvirt-daemon-driver-lxc libcap-ng-utils"
#	fi
#
#	if [ "${HOST_HYPERVISOR}" = "xen" ];then
#		otherWatchRpms="xen-kmp-default xen-kmp-trace"
#	elif [ "${HOST_HYPERVISOR}" = "kvm" ];then
#		#otherWatchRpms="qemu-x86 kvm kernel-default qemu-guest-agent"
#		#remove qemu-guest-agent, because it will remove kvm.rpm
#		otherWatchRpms="qemu-x86 kvm kernel-default"
#		if [ $release -ge 12 ];then
#			otherWatchRpms=${otherWatchRpms}" qemu-tools"
#		fi
#	fi
#
#	echo -e "\nDebug info:"
#	echo "release=$release"
#	echo "virtPatternRpms is "$virtPatternRpms
#	echo "commonWatchRpms is "$commonWatchRpms
#	echo "otherWatchRpms is "$otherWatchRpms
#
#	#repos
#	rareUpdateRepo=`$getSource source.virtupdate.${PRODUCT}`
#	virtDevelRepo=`$getSource source.virtdevel.${PRODUCT}`
#	virtTestRepo=`$getSource source.virttest.${PRODUCT}`
#
#	if [ -z "$rareUpdateRepo" -o -z "$virtDevelRepo" -o -z "$virtTestRepo" ];then
#		echo "Update related repos are not set correctly, please check /usr/share/qa/virtautolib/data/sources.local!"
#		cleanup
#	fi
#
#	#install rpms
#	#update virt rpms to the product's update repo
#	if [ "$updateRareFlag" = "on" ];then
#		if ! zypper lr -u | grep rareUpdateRepo >/dev/null;then
#			ZYPPER addrepo ${rareUpdateRepo} rareUpdateRepo || { echo "Add ${PRODUCT}'s update repo failed!"; cleanup; }
#		fi
#		ZYPPER refresh rareUpdateRepo || { echo "Refresh ${PRODUCT}'s update repo failed!"; cleanup; }
#		echo "Warning: Update virt rpms to ${PRODUCT}'s update repos now..."
#		#for rpm in $virtPatternRpms $commonWatchRpms $otherWatchRpms;do
#		for rpm in $virtPatternRpms;do
#			ZYPPER --non-interactive --gpg-auto-import-keys in -l $rpm
#			ret=$?
#			echo "Debug info: return code for rpm $rpm is $ret."
#			if [ $ret -ne 0 -a $ret -ne 104 ];then
#				echo "The rpm $rpm exists in the repo, but not installed successfully."
#				cleanup
#			fi
#		done
#		echo "Update virtualization rpms to ${PRODUCT}'s update repo is finished successfully!"
#	fi
#	
#	#update virt rpms to virt-devel/virt-test repos
#	if [ "$updateVirtFlag" = "on" ];then
#		# upgrade host from sles12sp0 for devel mode needs to install some rpms  before update virt rpms
#		if [ "$PRODUCT" == "sles-12-sp0-64" ];then
#			develReqRpms="mozilla-nss"
#		fi
#		if [ -n "$develReqRpms" ];then
#			echo "Install $develReqRpms before update virt rpms for sles12sp0 upgrade scenarios when testing devel:virt repo..."
#			ZYPPER --non-interactive in $develReqRpms
#		fi
#		#add repos 
#		if ! zypper lr -u | grep virtDevelRepo >/dev/null;then
#			ZYPPER addrepo ${virtDevelRepo} virtDevelRepo || { echo "Add virt-devel repo failed!"; cleanup; }
#		fi
#		ZYPPER refresh virtDevelRepo || { echo "Refresh virt-devel repo failed!"; cleanup; }
#		if ! zypper lr -u | grep virtTestRepo >/dev/null;then
#			ZYPPER addrepo ${virtTestRepo} virtTestRepo || { echo "Add virt-test repo failed!"; cleanup; }
#		fi
#		ZYPPER refresh virtTestRepo || { echo "Refresh virt-test repo failed!"; cleanup; }
#		echo "Warning: Update virt rpms to virt-devel/virt-test repos forcefully now..."
#		#for rpm in $virtPatternRpms $commonWatchRpms $otherWatchRpms;do
#		for rpm in $virtPatternRpms;do
#			ZYPPER --non-interactive --gpg-auto-import-keys in -r ${virtDevelRepo} -r ${virtTestRepo} -l --no-recommends --force-resolution -f $rpm
#			ret=$?
#			echo "Debug info: return code for rpm $rpm is $ret."
#			if [ $ret -ne 0 -a $ret -ne 104 ];then
#				echo "The rpm $rpm exists in the repo, but not installed successfully."
#				echo "The rpm $rpm exists in the repo, but not installed successfully." >&2
#				cleanup
#			fi
#		done
#		echo "Update virtualization rpms to virt-devel/virt-test repos is finished successfully!"
#	fi
#
#	if [ "$updateRareFlag" = "on" -o "$updateVirtFlag" = "on" ];then
#		echo "Need to reboot system to make the rpms work! "
#		[ "$rebootFlag" = "on" ] && reboot
#	else
#		echo "Neither update rpm flag is on, go to next step!"
#	fi
#
#	return 0
#
#}

function update_rpms() {
	#update virt rpms to proper repo
	update_virt_rpms $rebootFlag $updateRareFlag $updateVirtFlag $milestoneTestRepo
	ret=$?
	if [ $ret -eq 2 ];then
		cleanup
	else
		return $ret
	fi

}

function installation_of_the_host() {
    # Installation of the host in $PRODUCT version
	echo -e "\nExecuting host installation with repo $PRODUCT_REPO, autoinstall file $AUTOINSTALL_SERVER ..."
	installScript="/usr/share/qa/tools/install.pl"

	#default config
	[ -z "$PRODUCT_REPO" ] && PRODUCT_REPO="http://147.2.207.1/dist/install/SLP/SLES-11-SP3-GM/x86_64/DVD1/"

	args="-p ${PRODUCT_REPO} -f default -B -t "

	case $HOST_HYPERVISOR in
        [Kk][Vv][Mm]) args=$args"kvm_server,base";;
        [Xx][Ee][Nn]) args=$args"xen_server,base";;
        *) echo "The supported hypervisor types are xen or kvm, your given type is not supported" && cleanup;;
	esac

	[ -n "$AUTOINSTALL_SERVER" ] && args=$args" -u ${AUTOINSTALL_SERVER}"

	args=`echo $args | sed 's/\([:/]\)/\\\\\1/g'`

	echo -e "Executing host installation command:\n\t$installScript $args\n"
	
	$installScript $args

	echo "Need to reboot to finish installation!"
	[ "$rebootFlag" = "on" ] && reboot

}

function enable_libvirt_debug() {
	if uname -r | grep -iq xen || [ -e /proc/xen/privcmd ];then
		sed -i '/log_level/c log_level = 1' /etc/libvirt/libvirtd.conf
		sed -i '/log_outputs\s*=/c log_outputs="1:file:/var/log/libvirt/libvirtd.log"' /etc/libvirt/libvirtd.conf
		rclibvirtd restart
		sleep 5
	fi
	return 0
}

if [ "$phase" = "vhInstallation" ];then
	installation_of_the_host
elif [ "$phase" = "vhUpdateVirt" ];then
	check_run_validation
	update_rpms
elif [ "$phase" = "vhPrepAndUpdate" ];then
	check_run_validation
	verify_host_installation
	install_vm_guests "" "$GUEST_PRODUCT_LIST"
	if [ $? -ne 0 ];then
		handle_installation_failed_guests $backupInstallFailVmListFile
		exitCode=2
	fi
	change_vm_on_crash
	run_script_inside_all_vms
	basic_vm_administration $LOG_RESULT_PRODUCT
	backup_vm_guest_data $backupRootDir $backupVmListFile $backupCfgXmlDir $backupDiskDir
    if [ $? -ne 0 ];then
        cleanup
    fi
	do_host_upgrade "$PRODUCT_UPGRADE" "$PRODUCT_UPGRADE_REPO" "$HOST_UPGRADE_YAST_FILE" "$HOST_HYPERVISOR" "$rebootFlag"
elif [ "$phase" = "vhUpdatePostVerification" ];then
	#enable_libvirt_debug
	handle_upgrade_leaving
	check_run_validation
	restore_vm_guest_data
	basic_vm_administration $LOG_RESULT_PRODUCT_UPGRADED
	do_log_comparison
fi
retCode=$?	
if [ -n "$exitCode" ];then
	retCode=$exitCode
fi

popd > /dev/null

exit $retCode
