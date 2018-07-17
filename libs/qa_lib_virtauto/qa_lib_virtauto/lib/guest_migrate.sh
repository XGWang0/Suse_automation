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


#========================================================
#=== Guest machine migration from one host to another ===
#========================================================
pushd `dirname $0` >/dev/null

source ./virtlib

trap "echo 'Catch CTRL+C'; cleanupEnv 1" SIGINT

function usage() {
	echo "Usage: $0 -d migrateDstIP -v hypervisorType [-u migrateDstUser] [-p migrateDstPass] [-i vmProducts]"
	echo "-i: vmProducts, it is what kind of product vm should be installed, support regular expression, comma separeted,"
	echo "                format: \"sles-11-sp[34]-64,sles-12\""
	echo "                when not configured, all vm types in config file will be installed."
	exit 1
}

while getopts "d:u:p:v:i:s" OPTIONS
do
	case $OPTIONS in
		d)migrateDstIP="$OPTARG";;
		u)migrateDstUser="$OPTARG";;
		p)migrateDstPass="$OPTARG";;
		v)hostHypervisor="$OPTARG";;
		i)vmProducts="$OPTARG";;
		s)skip_install=1;;
		\?)usage;;
		*) usage;;
	esac
done

if [ -z "$migrateDstIP" ];then
	usage
fi

hostHypervisor=`echo $hostHypervisor | tr 'A-Z' 'a-z'`


sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"
getSettings="./get-settings.sh"

if [ -z "$migrateDstUser" ];then
	migrateDstUser=`$getSettings migratee.user`
fi

if [ -z "$migrateDstPass" ];then
	migrateDstPass=`$getSettings migratee.pass`
fi

# Export SSHPASS
export SSHPASS=$migrateDstPass

backupRootDir=/tmp/prj3_guest_migration/vm_backup
backupVmListFile=${backupRootDir}/vm.list
failedVmListFile=${backupRootDir}/install_fail_vm.list
backupCfgXmlDir=$backupRootDir/vm-config-xmls
backupDiskDir=$backupRootDir/vm-disk-files

overallMigrateTestRet=0

localIP=`getIP`

#Prepare the pesudo mount server use local directory on the base server
pesudo_mount_server=/tmp/pesudo_mount_server
#if [ -d $pesudo_mount_server ];then
#	rm -r $pesudo_mount_server
#fi
#mkdir -p $pesudo_mount_server

waitIntvl=5

function check_validation() {
	echo -e "\nExecuting check validation..."
	if [ "$hostHypervisor" == "kvm" ];then
		if uname -r | grep xen >/dev/null || [ -e /proc/xen/privcmd ];then
			echo "Error: You want to test migration for kvm, but source host is xen!" >&2
			exit 1
		fi
		$sshNoPass $migrateDstUser@$migrateDstIP "uname -r | grep xen || [ -e /proc/xen/privcmd ]" >/dev/null
		if [ $? -eq 0 ];then
			echo "Error: You want to test migration for kvm, but destination host is xen!" >&2
			exit 1
		fi
	elif [ "$hostHypervisor" == "xen" ];then
		if ! uname -r | grep xen >/dev/null && [ ! -e /proc/xen/privcmd ];then
			echo "Error: You want to test migration for xen, but source host is not xen!" >&2
			exit 1
		fi
		$sshNoPass $migrateDstUser@$migrateDstIP "uname -r | grep xen  || [ -e /proc/xen/privcmd ]" >/dev/null
		if [ $? -ne 0 ];then
			echo "Error: You want to test migration for xen, but destination host is not xen!" >&2
			exit 1
		fi
	else
		echo "Error: Only support migrate for kvm and xen." >&2
		exit 1
	fi
}

#function get_vm_disk_dir() {
#	#Get the common disk directory for all vms
#	release=`get_os_release`
#	if [ $release -ge 12 ];then
#		allVmDiskDir=/var/lib/libvirt/images
#	else
#		if [ "$hostHypervisor" == "xen" ];then
#			allVmDiskDir=/var/lib/xen/images
#		else
#			allVmDiskDir=/var/lib/kvm/images
#		fi
#	fi
#	echo $allVmDiskDir
#}

function setupNFS() {
	#prepare shared storage via nfs
	echo "Prepare shared storage via nfs..."
	#Get the common disk directory for all vms
	allVmDiskDir=`get_vm_disk_dir`

	# Make sure nfsserver is running and suitable
	echo "Changing NFS server config..."
	cp /etc/sysconfig/nfs /etc/sysconfig/nfs.org
	sed -i 's/^NFSV4LEASETIME=.*$/NFSV4LEASETIME="10"/' /etc/sysconfig/nfs
	echo "Making sure the nfs server is running..."
	rcnfsserver restart
	if [ $? -ne 0 ];then
		echo "ERROR: The NFS server is not started normally, please manually check the reason and then try running this script again."
		exit 1
	fi

	cp /etc/exports /etc/exports.org
	if ! grep "$pesudo_mount_server" /etc/exports;then
		echo "$pesudo_mount_server *(rw,sync,no_root_squash,no_subtree_check)" >>/etc/exports
		cat /etc/exports
		exportfs -r
		if [ $? -ne 0 ];then
			echo "Error: Synchronizing export failed." >&2
			cleanupEnv 1
		fi 
	fi

	# Remote mount it
	echo "Remote mounting the share..."
	echo "Mount on source host..."
	if [ ! -d $allVmDiskDir ];then
		mkdir -p $allVmDiskDir
	fi
	mount -t nfs -o vers=4,nfsvers=4 $localIP:$pesudo_mount_server $allVmDiskDir
	if [ $? -ne 0 ];then
		echo "Mount on source host failed!" >&2
		cleanupEnv 1
	else
		echo "Mount on source host succeeded!"
	fi
	echo "Creating remote directory $migrateDstIP:$allVmDiskDir..."
	$sshNoPass $migrateDstUser@$migrateDstIP "if [ ! -d $allVmDiskDir ];then mkdir -p $allVmDiskDir;fi"
	echo "Mount on destination host..."
	$sshNoPass $migrateDstUser@$migrateDstIP "mount -t nfs -o vers=4,nfsvers=4 $localIP:$pesudo_mount_server $allVmDiskDir"
	if [ $? -ne 0 ];then
		echo "Mount on destination host failed!" >&2
		cleanupEnv 1
	else
		echo "Mount on destination host succeeded!"
	fi
	
	#it blocks io for "virsh create" for nearly 90 sec
	sleep 90

}


function cleanupNFS() {
	#cleanup all nfs related operations
	#Get the common disk directory for all vms
	allVmDiskDir=`get_vm_disk_dir`

	echo "Remote unmounting the share and remove created disk directories..."
	echo "Unmounting remote disk..."
	echo "Unmounting disk on source host..."
	umount -l $allVmDiskDir
	if [ $? -ne 0 ];then
		echo "Error: Umount $allVmDiskDir failed!" >&2
	fi
	echo "Unmounting disk on destination host..."
	$sshNoPass $migrateDstUser@$migrateDstIP "umount -l $allVmDiskDir"
	if [ $? -ne 0 ];then
		echo "Error: Umount $allVmDiskDir failed!" >&2
	fi

	echo "Recovering local export file..."
	mv /etc/exports.org /etc/exports
	exportfs -r

	echo "Closing nfsserver service..."
	rcnfsserver stop

	echo "Recovering nfsserver config..."
	cp /etc/sysconfig/nfs.org /etc/sysconfig/nfs


}

function setupEnv() {
	echo -e "\nExecuting setupEnv..."
	#shared storage, firewall, libvirt, xend, other service
	release=`get_os_release`
	#close firewall
	if rcSuSEfirewall2 status | grep running >/dev/null; then
		rcSuSEfirewall2 stop
		if [ $? -ne 0 ];then
			echo "Error: Can not shutdown firewall on source host." >&2
			cleanupEnv 1
		fi
	fi
	$sshNoPass $migrateDstUser@$migrateDstIP "rcSuSEfirewall2 stop"
	if [ $? -ne 0 ];then
		echo "Error: Can not shutdown firewall on destination host." >&2
		cleanupEnv 1
	fi

	#prepare shared storage via nfs
	setupNFS
#	echo "Prepare shared storage via nfs..."
#	#Get the common disk directory for all vms
#	allVmDiskDir=`get_vm_disk_dir`
#	#Prepare the pesudo mount server use local directory on the base server
#	pesudo_mount_server=/tmp/pesudo_mount_server
#	if [ -d $pesudo_mount_server ];then
#		rm -r $pesudo_mount_server
#	fi
#	mkdir -p $pesudo_mount_server
#
#	# Make sure nfsserver is running
#	echo "Making sure the nfs server is running..."
#	rcnfsserver start
#	if [ $? -ne 0 ];then
#		echo "ERROR: The NFS server is not started normally, please manually check the reason and then try running this script again."
#		exit 1
#	fi
#
#	cp /etc/exports /etc/exports.org
#	if ! grep "$pesudo_mount_server" /etc/exports;then
#		echo "$pesudo_mount_server *(rw,sync,no_root_squash,no_subtree_check)" >>/etc/exports
#		cat /etc/exports
#		exportfs -r
#		if [ $? -ne 0 ];then
#			echo "Error: Synchronizing export failed." >&2
#			cleanupEnv 1
#		fi 
#	fi
#
#	# Remote mount it
#	echo "Remote mounting the share..."
#	echo "Mount on source host..."
#	if [ ! -d $allVmDiskDir ];then
#		mkdir -p $allVmDiskDir
#	fi
#	mount -t nfs -o vers=4,nfsvers=4 $localIP:$pesudo_mount_server $allVmDiskDir
#	if [ $? -ne 0 ];then
#		echo "Mount on source host failed!" >&2
#		cleanupEnv 1
#	else
#		echo "Mount on source host succeeded!"
#	fi
#	echo "Creating remote directory $migrateDstIP:$allVmDiskDir..."
#	$sshNoPass $migrateDstUser@$migrateDstIP "if [ ! -d $allVmDiskDir ];then mkdir -p $allVmDiskDir;fi"
#	echo "Mount on destination host..."
#	$sshNoPass $migrateDstUser@$migrateDstIP "mount -t nfs -o vers=4,nfsvers=4 $localIP:$pesudo_mount_server $allVmDiskDir"
#	if [ $? -ne 0 ];then
#		echo "Mount on destination host failed!" >&2
#		cleanupEnv 1
#	else
#		echo "Mount on destination host succeeded!"
#	fi
#

	# Change libvirtd.conf and xend-config.sxp on both source and destination.
	if [ $hostHypervisor == "xen" ]; then
		#change xend configuration file
		changeXendConfig
		if [[ $? -ne 0 ]];then
			echo -e "Source xend configuration changes failed to take effect!\n"
			cleanupEnv 1
		fi
		$sshNoPass $migrateDstUser@$migrateDstIP "$(typeset -f get_os_release changeXendConfig);changeXendConfig" 2>/dev/null
		if [ $? -ne 0 ];then
				echo -e "Destination xend configuration changes failed to take effect!\n"
				cleanupEnv 1
		fi

		#change libvirtd configuration file
		changeLibvirtConfig
		if [[ $? != 0 ]];then
			echo -e "Source libvirtd change configuration failed!\n"
			cleanupEnv 1
		fi
		$sshNoPass $migrateDstUser@$migrateDstIP "$(typeset -f get_os_release changeLibvirtConfig);changeLibvirtConfig" 2>/dev/null
		if [[ $? != 0 ]];then
			echo -e "Destination libvirtd change configuration failed!\n"
			cleanupEnv 1
		fi

	fi

	#setup bridge used by vms on destination host
	$sshNoPass $migrateDstUser@$migrateDstIP "bash /usr/share/qa/qa_test_virtualization/shared/standalone"
	if [ $? -ne 0 ];then
		echo "Error: Failed to setup bridge on destination host!" >&2
		cleanupEnv 1
	fi

    #add destination to hosts on source
    destHostName=`$sshNoPass $migrateDstUser@$migrateDstIP "hostname"`
    srcHostName=`hostname`

    echo "$migrateDstIP $destHostName" >> /etc/hosts
    echo "$localIP $srcHostName" >> /etc/hosts

    $sshNoPass $migrateDstUser@$migrateDstIP "echo '$migrateDstIP $destHostName' >> /etc/hosts"
    $sshNoPass $migrateDstUser@$migrateDstIP "echo '$localIP $srcHostName' >> /etc/hosts"
}

function recoverXenAndLibvirtConfig() {
	release=`get_os_release`
	if [ $release -lt 12 ];then
		echo "Recovering libvirt and xend config..."
		mv /etc/xen/xend-config.sxp.org /etc/xen/xend-config.sxp
		rcxend restart
		mv /etc/libvirt/libvirtd.conf.org /etc/libvirt/libvirtd.conf
		rclibvirtd restart
	fi

}

function cleanupEnv() {
	return 0
	echo -e "\nExecuting cleanupEnv..."
	#shared storage, firewall, libvirt, xend, other service
	exitCode=$1

	#cleanup nfs
	cleanupNFS

#	#Get the common disk directory for all vms
#	allVmDiskDir=`get_vm_disk_dir`
#
#	echo "Remote unmounting the share and remove created disk directories..."
#	echo "Unmounting remote disk..."
#	echo "Unmounting disk on source host..."
#	umount -l $allVmDiskDir
#	if [ $? -ne 0 ];then
#		echo "Error: Umount $allVmDiskDir failed!" >&2
#	fi
#	echo "Unmounting disk on destination host..."
#	$sshNoPass $migrateDstUser@$migrateDstIP "umount -l $allVmDiskDir"
#	if [ $? -ne 0 ];then
#		echo "Error: Umount $allVmDiskDir failed!" >&2
#	fi
#
#	echo "Recovering local export file..."
#	mv /etc/exports.org /etc/exports
#	exportfs -r
#
#	echo "Closing nfsserver service..."
#	rcnfsserver stop

	if [ $hostHypervisor == "xen" ]; then
		recoverXenAndLibvirtConfig
		$sshNoPass $migrateDstUser@$migrateDstIP "$(typeset -f get_os_release recoverXenAndLibvirtConfig);recoverXenAndLibvirtConfig;"
	fi

	$sshNoPass $migrateDstUser@$migrateDstIP "/usr/share/qa/qa_test_virtualization/cleanup"

	popd >/dev/null

	if [ -n "$exitCode" ];then
		exit $exitCode
	fi

	return 0
}

#function check_vm_up_by_ssh() {
#	echo -e "\nExecuting check vm up by ssh..."
#	vmIP=$1
#	user=`$getSettings vm.user`
#	pass=`$getSettings vm.pass`
#
#	export SSHPASS=$pass
#	$sshNoPass $user@$vmIP "echo 'Test connection by ssh!'" >/dev/null 2>&1
#	if [ $? -ne 0 ];then
#		return 1
#	else
#		return 0
#	fi
#	
#	unset SSHPASS
#}

#function start_vm_by_virttool() {
#	echo -e "Executing start vm by virttool..."
#	vmName=$1
#	migrtTool=$2
#
#	if [ "$migrtTool" = "virsh" ];then	
#		vmState=`$migrtTool dominfo $vmName | grep State |  sed 's/State:\s*//'`
#		if [ "$vmState" = 'paused' ] ;then
#			$migrtTool resume $vmName
#		elif [[ "$vmState" = 'shut off' || "$vmState" = 'crashed' ]];then
#			$migrtTool start $vmName
#		elif [[ "$vmState" = 'dying' || "$vmState" = 'shutdown' ]];then
#			sleep 120
#			$migrtTool start $vmName
#		elif [[ "$vmState" = "running" || "$vmState" = 'idle' ]];then
#			echo "The vm is already started."
#		else
#			return 1
#		fi
#	else
#		vmState=`$migrtTool list $vmName | gawk '/-/{print $5}'`
#		if [[ "$vmState" = *p* ]] ;then
#			$migrtTool unpause $vmName
#		elif [[ "$vmState" = *s* ]];then
#			$migrtTool reboot $vmName
#		elif [[ "$vmState" = *r* || "$vmState" = *b* ]];then
#			echo "The vm is already started."
#		#elif [[ "$vmState" = *c* || "$vmState" = *d* ]];then
#		else
#			return 1
#		fi
#	fi
#	return $?
#}

#function ensure_vm_running() {
#	echo -e "Executing ensure vm running..."
#	vmName=$1
#	migrateTool=$2
#
#	start_vm_by_virttool $1 $2
#	if [ $? -ne 0 ];then
#		return 1
#	fi
#
#	sshConnection="no"
#	vmMac=`virsh dumpxml $vmName | grep -i "mac address=" | sed "s/^\s*<mac address='\([^']*\)'.*$/\1/"`
#	tryTimes=0
#	maxTryTimes=20
#	while [ $tryTimes -le $maxTryTimes ] && [ "$vmState" != "running" -o "$sshConnection" != "yes" ];do
#		sleep 10
#		vmIP=`get_ip_by_mac $vmMac|tail -1`
#		if [ "$vmIP" = "mac-err" ];then
#			continue
#		fi
#		check_vm_up_by_ssh $vmIP
#		if [ $? -eq 0 ];then
#			vmState="runnning"
#			sshConnection="yes"
#			echo "The vm is up now."
#			#wait some time before migrate
#			sleep 60
#			return 0
#		fi
#		((tryTimes++))
#	done
#
#	return 1
#}

function transfer_vm_to_xen() {
	echo -e "\nExecuting transfer vm to xen..."
	#By default, vm is created by virsh, when migrate use xm/xl, the vm needs to be recreated by xen tool use config file dumpted from virsh
	migrateTool=$1
	vmName=$2
	
	cfgFileForXen=`get_config_for_xen_create $vmName`
	
	#create the vm from xm/xl
	sleep $waitIntvl
	$migrateTool create $cfgFileForXen
	if [ $? -ne 0 ];then
		echo "Create vm fail with command: $migrateTool create $cfgFileForXen!"
		return 1
	fi
	sleep 60

	ensure_vm_running $vmName $migrateTool

}

# return: 0 == pass, 1== fail 2==skip
function migrate_preparation() {
	#Do each migration specific preparations
	echo -e "\nExecuting migrate preparation..."
	vmName=$1
	migrateTool=$2
	commandOption=$3

	if [[ "$commandOption" == *"direct"* && "$hostHypervisor" = "kvm" ]];then
		echo "Skipped: kvm does not support direct migration." >&2
		return 2
	fi

	if [ "$migrateTool" != "virsh" ];then
		transfer_vm_to_xen $migrateTool $vmName
	else
		ensure_vm_running $vmName $migrateTool	
		#todo: specific preparation for --xml
	fi

}

function generate_migrate_command() {
	vmName=$1
	remoteHostIP=$2
	migrateCommand=$3

	#assume passed in commandOption only need to fill LOCAL_GUEST and REMOTE_HOST
	migrateCommand=${migrateCommand//LOCAL_GUEST/${vmName}}
	migrateCommand=${migrateCommand//REMOTE_HOST/${remoteHostIP}}

	echo "$migrateCommand"

}

function do_migration() {
	echo -e "\nExecuting do migration..."
	migrateCommand=$1

	eval $migrateCommand
	ret=$?
	if [ $ret -ne 0 ];then
		echo "Migrate failed for: $migrateCommand."
	else
		echo "Migrate succeeded for: $migrateCommand."
	fi

	return $ret
}

function migrate_result_check() {
	#Require params: vmName , migrateDstIP , VM ip ,migrateDstUser
	#This function will do a file create/read in Guest VM
	vmName=$1
	migrateCommand=$2

	#Get VM mac address
	#When undefinesource option is used, can not get mac by virsh dumpxml on source host, so use backup xml instead
	#macaddr=`virsh dumpxml $vmName|sed -n '/mac addre/{s/.*=.//;s/...$//p;q;}'`
	macaddr=`cat $backupCfgXmlDir/${vmName}.xml | sed -n '/mac addre/{s/.*=.//;s/...$//p;q;}'`
	#Get Ip address of VM
	gip=`grep "DHCPACK.*$macaddr" /var/log/messages|tail -1|grep -Po "\d+\.\d+\.\d+.\d+"`
	sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"
	guest_user=`$getSettings vm.user`
	guest_password=`$getSettings vm.pass`

	#Create a test file
	$sshNoPass $migrateDstUser@$migrateDstIP "export SSHPASS=$guest_password; $sshNoPass $guest_user@$gip 'seq 1 1000 >/tmp/Migtest;seq 1 1000 >>/tmp/Migtest' "
	retV=$?
	if [ $retV -ne 0 ];then
		echo "Migrate Verify failed for Creating FILE /tmp/Migtest on GUEST :$gip from HOST $migrateDstIP"
		return 1
	fi
	#Verify the File
	FileNo=`$sshNoPass $migrateDstUser@$migrateDstIP "export SSHPASS=$guest_password; $sshNoPass $guest_user@$gip 'cat /tmp/Migtest|wc -l' "`

	if [ $FileNo -ne 2000 ];then
		echo "Migrate Verify failed for count FILE /tmp/Migtest NO. on GUEST :$gip from HOST $migrateDstIP"
		return 1
	fi
		echo "Migrate Verify Succeed"
		return 0

}

function destroy_vm_by_virttool() {
	echo -e "\nExecuting destroy vm by virttool..."
	vmName=$1
	migTool=$2

	isVmPersistent=0
	if [ "$migTool" == "virsh" ];then
		$migTool dominfo $vmName | grep  "^Persistent:" | grep -ivq yes
		isVmPersistent=$?
	fi

	start_vm_by_virttool $vmName $migTool
	$migTool destroy $vmName
	sleep $waitIntvl

	if [ $isVmPersistent -eq 1 ];then
		$migTool undefine $vmName
	elif [ "$migTool" == "xm" ];then
		$migTool delete $vmName
	fi
	sleep $waitIntvl
	unset isVmPersistent
}

function restore_vm() {
	echo -e "\nExecuting restore vm..."
	vmName=$1
	backupCfgXmlDir=$2
	backupDiskDir=$3

	#cleanup nfs
	cleanupNFS

	#restore disk file
	vmXml=$backupCfgXmlDir/${vmName}.xml
	origDiskFile=`grep "source file=" $vmXml | sed "s/^\s*<source file='\([^']*\)'.*$/\1/"`

	currentDir=`pwd`
	cd $backupDiskDir
	vmDiskBaseDir=`get_vm_disk_dir`
	cd ${vmDiskBaseDir/\//}
	vmDiskRelativeDir=${origDiskFile/${vmDiskBaseDir}/}
	vmDiskRelativeDir="."${vmDiskRelativeDir}
	echo "Debug: current dir is "`pwd`", go to copy ${vmDiskRelativeDir} to ${pesudo_mount_server}"
	cp --parent ${vmDiskRelativeDir} ${pesudo_mount_server}
	cd $currentDir

	#setup nfs
	setupNFS

	#restore vm
	virsh define $vmXml
	sleep $waitIntvl
	virsh create $vmXml
	if [ $? -ne 0 ];then echo "Error: Can not restore vm from backup files."; cleanupEnv 1;fi
	sleep $((waitIntvl*3))
	virsh destroy $vmName
	sleep $waitIntvl
}

function post_migrate_recovery() {
	echo -e "\nExecuting post migrate recovery..."
	#recover vm on source host from the backup config and disk file, clean up the migrated vm from destination host
	vmName=$1
	migrateTool=$2
	migrateCommand=$3

	#remote destroy the vm
	$sshNoPass $migrateDstUser@$migrateDstIP "$(typeset -f start_vm_by_virttool destroy_vm_by_virttool); waitIntvl=5; destroy_vm_by_virttool $vmName $migrateTool"

	#local destroy the vm
	destroy_vm_by_virttool $vmName $migrateTool

	#restore the vm on local host
	restore_vm $vmName $backupCfgXmlDir $backupDiskDir

}

function get_config_for_xen_create() {
	vm=$1
	forRemote=$2
	if [ -n "$forRemote" ];then
		remoteRel=$3
		remoteSp=$4
	fi
	if [ -z "$forRemote" ];then
		vmXenCfgFile=$backupCfgXmlDir/$vm.cfg
		if [ -e $vmXenCfgFile ];then
			echo $vmXenCfgFile
			return 0
		fi
		release=`get_os_release`
		spack=`get_os_spack`
	else
		release=$remoteRel
		spack=$remoteSp
		vmXenCfgFile=$backupCfgXmlDir/$vm-for-sles${release}sp${spack}.cfg
		if [ -e $vmXenCfgFile ];then
			echo $vmXenCfgFile
			return 0
		fi

	fi

	vmCfgFile=$backupCfgXmlDir/$vm.xml
	if [ ! -d $backupCfgXmlDir ];then
		mkdir $backupCfgXmlDir
	fi

	if [ $release -ge 12 -a $spack -ge 1 ];then
		translateArg="xen-xl"
	else
		translateArg="xen-xm"
	fi
	virsh domxml-to-native --format $translateArg $vmCfgFile > $vmXenCfgFile
	if [ $? -ne 0 ];then
		rm $vmXenCfgFile
		return 1
	fi
	
	echo $vmXenCfgFile
	return 0
}

function do_vm_admin() {
	vm=$1
	migrateTool=$2
	phase=$3
	logFile=$4

	echo -e "\nExecuting vm admin $phase..."
	adminScript=/usr/share/qa/virtautolib/lib/vm-administration.sh
	if [ "$migrateTool" == "virsh" ];then
		virtTool="virsh"
	else
		virtTool="xenTool"
	fi

	#give control of vm to xenTool xm/xl when do administration before migrate
	doAdminFlag="yes"
	if [ "$phase" == "beforeMigrate" -a "$migrateTool" != "virsh" ];then
		configFileForXenCreate=`get_config_for_xen_create $vm`
		xenCreateParm="-c $configFileForXenCreate"
		transfer_vm_to_xen "$migrateTool" "$vm"
		if [ $? -ne 0 ];then
			return 1
		fi
	fi

	#only persistent virsh migrate and xm/xl migrate can do admin after migrate
	if [ "$phase" == "afterMigrate" ];then
		if [[ "$migrateTool" == "virsh" && "$migrateCommand" == *"persistent"* ]] || [[ "$migrateTool" != "virsh" ]];then
			if [[ "$migrateTool" == "virsh" ]];then
				$sshNoPass $migrateDstUser@$migrateDstIP "$migrateTool destroy $vm > /dev/null 2>&1; sleep $waitIntvl;"
				otherParm="-k on"
			else
				configFileForXenCreate=/tmp/admin-keep-output/$vm.cfg
				$sshNoPass $migrateDstUser@$migrateDstIP "[ ! -e $configFileForXenCreate ]"
				if [ $? -eq 0 ];then
					#this config file is created on local host by virsh, and copy to remote host
					remoteRel=`$sshNoPass $migrateDstUser@$migrateDstIP "source /usr/share/qa/virtautolib/lib/virtlib;get_os_release"`
					remoteSp=`$sshNoPass $migrateDstUser@$migrateDstIP "source /usr/share/qa/virtautolib/lib/virtlib;get_os_spack"`
					configFileForRemoteXenCreate=`get_config_for_xen_create $vm remote $remoteRel $remoteSp`
					if [ $? -eq 0 ];then
						$sshNoPass $migrateDstUser@$migrateDstIP "if [ ! -d `dirname $configFileForXenCreate` ];\
                                                                                          then mkdir `dirname $configFileForXenCreate`; fi"
						cat $configFileForRemoteXenCreate | $sshNoPass $migrateDstUser@$migrateDstIP \
                                                                                          "cat - > $configFileForXenCreate"
						xenCreateParm="-c $configFileForXenCreate"
					else
						doAdminFlag="no"
					fi
				else
					xenCreateParm="-c $configFileForXenCreate"
				fi
			fi
		else
			doAdminFlag="no"
		fi
	fi

	#do admin
	if [ "$doAdminFlag" == "yes" ];then
		echo -e "\nCheck vm administration log in $logFile..."
		if [ "$phase" == "beforeMigrate" ];then
			$adminScript -m "$vm" -t "$virtTool" -p off $xenCreateParm $otherParm> $logFile 2>&1
			adminRet=$?
		elif [ "$phase" == "afterMigrate" ];then
			$sshNoPass $migrateDstUser@$migrateDstIP "$adminScript -m \"$vm\" -t \"$virtTool\" -p off $xenCreateParm $otherParm" > $logFile 2>&1
			adminRet=$?
		fi
	else
		adminRet=0
	fi
	
	#recover, give handle of vm to virsh again after admin
	if [ "$phase" == "beforeMigrate" -a "$migrateTool" != "virsh" ];then
		destroy_vm_by_virttool $vm $migrateTool 2>/dev/null
		restore_vm  $vm $backupCfgXmlDir $backupDiskDir
	fi

	#clear the parameters for vm admin
	unset otherParm
	unset xenCreateParm
	unset configFileForXenCreate
	unset configFileForRemoteXenCreate

	return $adminRet

}

function do_guest_migrations() {
	echo "Executing do_guest_migrations..."
	vmNameList=`virsh list --all --name | sed '/Domain-0/d'`

	#generate all valid options combination to pass to migrate command
	toolSet="virsh"
	if [ "$hostHypervisor" == "xen" ];then
		release=`grep "VERSION" /etc/SuSE-release | sed 's/^.*VERSION = \(.*\)\s*$/\1/'`
		if [ $release -lt 12 ];then
			xenTool="xm"
		else
			xenTool="xl"
		fi
		toolSet=${toolSet}" $xenTool"
	fi

	resultArr=("testcase" "result" "reason")
	resultColumnNum=${#resultArr[@]}
	#TODO, change to the directory in ctcs2 after wrap guest_migrate.sh to test package
	#adminLogDir=`find /var/log/qa/ctcs2/ -name "test-guest-migration-*"`
	adminLogDir=/tmp/prj3_migrate_admin_log
	[ ! -d $adminLogDir ] && mkdir $adminLogDir

	for migrateTool in $toolSet;do
		optionCombinationList=`generate_migrate_params $migrateTool`

		#loop to test every migration option combination
		for vm in $vmNameList;do
			caseCount=0
			OIFS=$IFS
			IFS=$'\n'
			for optionCombination in $optionCombinationList;do
				IFS=$OIFS
				migrateCommand=`generate_migrate_command $vm $migrateDstIP "$optionCombination"`
				((caseCount++))
				
				#Admin vm before migrate
				phase="beforeMigrate"
				logFile=$adminLogDir/admin-by-$migrateTool-$vm-before-migrate-testcase${caseCount}.log
				do_vm_admin "$vm" "$migrateTool" "$phase" "$logFile"
				beforeMigrateAdminRet=$?

				#do real migration work
				migrate $vm $migrateTool "$migrateCommand"

				#Admin vm after migrate
				migrateRet=$?
				if [ $migrateRet -eq 0 ];then
					phase="afterMigrate"
					logFile=$adminLogDir/admin-by-$migrateTool-$vm-after-migrate-testcase${caseCount}.log
					do_vm_admin "$vm" "$migrateTool" "$phase" "$logFile"
					afterMigrateAdminRet=$?
					#Compare admin result
					if [ -n $beforeMigrateAdminRet -a $beforeMigrateAdminRet -ne 0 ] || [ -n $afterMigrateAdminRet -a $afterMigrateAdminRet -ne 0 ];then
						store_testcase_result "$migrateCommand" fail "Aministration check before and after migration failed."
					else
						store_testcase_result "$migrateCommand" pass
					fi
				fi

				#recovery after migration on both src and dst host
				post_migrate_recovery $vm $migrateTool "$migrateCommand"

				#clean status
				IFS=$'\n'
				unset beforeMigrateAdminRet
				unset afterMigrateAdminRet
				unset configFileForXenCreate
			done
			IFS=$OIFS
		done
	done

}

##columns: testcase, result, reason
##result type: pass, fail, skip
#function print_migration_result() {
#	columnNum=$1
#
#	maxFieldLen=100
#	fieldIntvlLen=10
#	echo -e "\nDebug info: \nAll result array items :"
#	echo ${resultArr[@]}
#
#	echo -e "\nOverall migration result start:\n"	
#	for ((i=0;i<$((${#resultArr[@]}/${columnNum}));i++));do
#		testcase=${resultArr[$(($i*$columnNum))]}
#		result=${resultArr[$(($i*$columnNum+1))]}
#		reason=${resultArr[$(($i*$columnNum+2))]}
#		printf "%-${maxFieldLen}s" "$testcase"
#		printf "%2s" "  "
#		for ((j=0;j<$fieldIntvlLen;j++));do
#			printf "%c" "-"
#		done
#		printf "%2s" "  "
#		printf "%-5s" "$result"
#		if [ $result != "pass" ];then
#			printf "%2s" "  "
#			for ((j=0;j<$fieldIntvlLen;j++));do
#				printf "%c" "-"
#			done
#			printf "%2s" "  "
#			printf "%s" "$reason"
#		fi
#		echo
#	done
#	echo -e "\nOverall migration result end.\n"	
#}
#
##store test result per case, format: testcase result reason
#function store_testcase_result() {
#	testcase=$1
#	result=$2
#	reason=$3
#	echo -e "\nExecuting store testcase result $result..."
#
#	resultArr+=("$testcase" "$result" "$reason")
#
#	if [ $result == "fail" ];then
#	    ((overallMigrateTestRet+=1))
#	fi
#
#	return 0
#
#}

function ensure_libvirt_running() {
	sourceRel=`get_os_release`
	destRel=`$sshNoPass $migrateDstUser@$migrateDstIP "grep VERSION /etc/SuSE-release | sed 's/^.*VERSION = \(.*\)\s*$/\1/'"`
	if [ $sourceRel -eq 11 -a $destRel -eq 12 ];then
		$sshNoPass $migrateDstUser@$migrateDstIP "sed -i '/#user =/c user = \"root\"' /etc/libvirt/qemu.conf; \
                                                          sed -i '/#group =/c group = \"root\"' /etc/libvirt/qemu.conf;\
                                                          rclibvirtd restart;"
	fi
	$sshNoPass $migrateDstUser@$migrateDstIP "if rclibvirtd status | grep -ivq running;then rclibvirtd restart;sleep 3;fi"
}

function migrate() {
	echo -e "\nExecuting migrate..."
	vmName=$1
	migrateTool=$2
	migrateCommand=$3

	#test specific preparation, prepare vm /libvirt/xml and others as migrate option required
	migrate_preparation $vmName $migrateTool "$migrateCommand"
	ret=$?
	if [ $ret -ne 0 ];then
		if [ $ret -eq 1 ];then
			store_testcase_result "$migrateCommand" fail "Migrate preparation failed."
		elif [ $ret -eq 2 ];then
			store_testcase_result "$migrateCommand" skip "Invalid test."
		fi
		return $ret
	fi

	#execute virsh/xl migrate
	ensure_libvirt_running
	do_migration "$migrateCommand"
	ret=$?
	if [ $ret -ne 0 ];then
		store_testcase_result "$migrateCommand" fail "Migration command return non-zero."
		return $ret
	fi
	
	#check migration result, return code/vm status on src and dst/vm existence etc
	migrate_result_check $vmName "$migrateCommand"
	ret=$?
	if [ $ret -ne 0 ];then
		store_testcase_result "$migrateCommand" fail "Migration result check return non-zero."
		return $ret
	fi
	return 0
}

#function whether_install_vm() {
#	configFile=$1
#	if [ -z "$vmProducts" ];then
#		#install any kind of vm in config file
#		return 0
#	else
#		vmName=`$getSettings -p VM_NAME -s $configFile`
#		vmName=${vmName/fcs/sp0}
#		for product in ${vmProducts/,/ };do
#			if [[ $vmName == ${product}* ]];then
#				return 0
#			fi
#		done
#
#	fi
#	return 1
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


function run_migration_test() {
	#check test validation for environment
	check_validation
	

	#install vm guests on host
	if [ -z "$skip_install" ];then
		#overall migration preparations
		setupEnv
		install_vm_guests "" "$vmProducts"
		if [ $? -ne 0 ];then
			handle_installation_failed_guests $failedVmListFile
			overallMigrateTestRet=2
		fi
	fi

	#change the on_crash behavior to coredump
	change_vm_on_crash

	#backup vm data to backup directory
	backup_vm_guest_data $backupRootDir $backupVmListFile $backupCfgXmlDir $backupDiskDir
	if [ $? -ne 0 ];then
		cleanupEnv 1
	fi

	#test guest migrations
	do_guest_migrations

	#overall migration cleanup
	cleanupEnv

	#print migration test result
	print_migration_result $resultColumnNum

	#show the failed guests during guest installation phase
	show_guest_installation_failures $failedVmListFile

}

run_migration_test

exit $overallMigrateTestRet
