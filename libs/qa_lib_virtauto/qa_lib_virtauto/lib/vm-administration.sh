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


#====================================
#=== Administrate VMs on the host ===
#====================================

# Usage: basic-vm-administration.sh

export LANG=C
source /usr/share/qa/virtautolib/lib/vm-admin-lib.sh

function usage() {
	echo "Usage: $0 [-m vmList] [-t adminToolList] [-c xenToolCreateVmConfigFile] [-p printAdminResultTable] [-k keepCfgFileForXen]"
	echo "       -m: vmList, the list of vm names to be administrated, use space as delimeter, default: all vms on the host;"
	echo "       -t: adminToolList, the list of virt tools to be used in administration, options: virsh, xenTool(auto detect to use xm or xl), use space as delimeter, default: virsh for kvm host, virsh and xenTool for xen host;"
	echo "       -c: xenToolCreateVmConfigFile, the config file for xm/xl to use when create a vm;"
	echo "       -p: printAdminResultTable, the flag to indicate whether print the AdminResultTable, options: on/off, default on;"
	echo "       -k: keepCfgFileForXen, the flag to indicate whether keep the config file dumpted from virsh domxml-to-native --format xen-xm/xl for xen admin tool xm/xl to create vms, value on/off, default is off."
	exit 1
}

while getopts "m:p:t:c:k:" OPTION;do
	case "$OPTION" in
		m) vmList="$OPTARG";;
		p) printFlag="$OPTARG";;
		t) virtTool="$OPTARG";;
		c) xenToolCreateCfgFile="$OPTARG";;
		k) keepCfgForXenFlag="$OPTARG";;
		*) usage;;
	esac
done

if [ -z "$vmList" ];then
	vmArr=(`virsh list --all --name | sed '/Domain-0/d'`)
else
	vmArr=(${vmList})
fi

if [ "$printFlag" != "off" ];then
	printFlag="on"
fi

if [ "$keepCfgForXenFlag" != "on" ];then
	keepCfgForXenFlag="off"
fi

if [ -z "$virtTool" ];then
	virtTool="virsh xenTool"
fi
if [[ "$virtTool" != *"virsh"* && "$virtTool" != *"xenTool"* ]];then
	usage
fi

retCode=0

tmp=/tmp/vm_admin
[ -d $tmp ] && rm -r $tmp
mkdir $tmp

#the overall admin operation list
declare -a adminOpArr

#set up administration operation list 
commonAdminTool="virsh"
if [[ "$virtTool" == *"virsh"* ]];then
	commonOpArr=("$commonAdminTool start" "$commonAdminTool list" "$commonAdminTool save" "$commonAdminTool restore" "$commonAdminTool dumpxml" "$commonAdminTool domxml-to-native" "$commonAdminTool shutdown" "$commonAdminTool undefine" "$commonAdminTool define" "$commonAdminTool start" "$commonAdminTool destroy")
	adminOpArr+=("${commonOpArr[@]}")
fi

VERSION=`grep "VERSION" /etc/SuSE-release | sed 's/^.*VERSION = \(.*\)\s*$/\1/'`
SPACK=`grep "PATCHLEVEL" /etc/SuSE-release | sed 's/^.*PATCHLEVEL = \(.*\)\s*$/\1/'`

if uname -r | grep -iq xen || [ -e /proc/xen/privcmd ];then
	translateArg="xen-xm"
	if [ $VERSION -eq 12 -a $SPACK -ge 1 ] || [ $VERSION -gt 12 ];then
		translateArg="xen-xl"
	fi
fi 

if [[ "$virtTool" == *"xenTool"* ]];then
	if uname -r | grep -iq xen || [ -e /proc/xen/privcmd ] ;then
		if [ $VERSION -lt 12 ];then
			xenAdminTool="xm"
			saveOpt="-f"
		else
			xenAdminTool="xl"
			shutdownOpt="-F"
		fi
		if [[ "$virtTool" == *"virsh"* ]];then
			xenOpArr=("$xenAdminTool create")
		fi
		xenOpArr+=("$xenAdminTool list" "$xenAdminTool save $saveOpt" "$xenAdminTool restore" "$xenAdminTool shutdown $shutdownOpt" "$xenAdminTool create" "$xenAdminTool destroy")
		adminOpArr+=("${xenOpArr[@]}")
	fi
fi

function createXenCfgFile() {
	vmName=$1
	$commonAdminTool dumpxml $vmName > $tmp/$vmName.xml
	$commonAdminTool domxml-to-native --format $translateArg $tmp/$vmName.xml > $tmp/$vmName.cfg
	cp $tmp/$vmName.cfg $adminOutputDir
}

adminOutputDir=/tmp/admin-keep-output/
[ ! -d $adminOutputDir ] && mkdir -p $adminOutputDir
if [ "$virtTool" == "xenTool" ];then
	if [ -n "$xenToolCreateCfgFile" -a ! -e "$xenToolCreateCfgFile" ];then
		createXenCfgFile ${vmList%% [a-z]*}
	fi
fi

if [ -z "$adminOpArr" ];then
	usage
fi

declare -a resultArr
declare -i index
index=0

resultArr+=('' "${adminOpArr[@]}")
echo "Administrative operations list is:"
for ((adminOpIndex=0;adminOpIndex<${#adminOpArr[*]};adminOpIndex++));do
	echo -e "\t${adminOpArr[$adminOpIndex]}"
done

#set index start of real result
index=$((1+${#adminOpArr[*]}))

#set time interval for operations
interval=5
for vmName in ${vmArr[*]};do
	resultArr[$((index++))]=$vmName
	for ((adminOpIndex=0;adminOpIndex<${#adminOpArr[*]};adminOpIndex++));do
		adminOp=${adminOpArr[$adminOpIndex]}
		if [ "$adminOp" = "$commonAdminTool dumpxml" ];then
			cmd="$adminOp $vmName > $tmp/$vmName.xml"
		elif [ "$adminOp" = "$commonAdminTool domxml-to-native" ];then
			if uname -r | grep -iq xen || [ -e /proc/xen/privcmd ] ;then
				cmd="$adminOp --format $translateArg $tmp/$vmName.xml > $tmp/$vmName.cfg"
			else
				cmd="$adminOp --format qemu-argv $tmp/$vmName.xml > $tmp/$vmName.cfg"
			fi
		elif [ "$adminOp" = "$xenAdminTool create" ];then
			if [ -z "$xenToolCreateCfgFile" ];then
				xenToolCreateCfgFile=$tmp/$vmName.cfg
				if [ ! -f $xenToolCreateCfgFile ];then
					createXenCfgFile $vmName
				fi
			elif [ ! -f $xenToolCreateCfgFile ];then
				createXenCfgFile $vmName

			fi
			cmd="$adminOp $xenToolCreateCfgFile"
		elif [ "$adminOp" = "$commonAdminTool undefine" ];then
			if [ $VERSION -ge 12 ];then
				cmd="$adminOp $vmName --managed-save"
			else
				cmd="$adminOp $vmName"
			fi
		elif [[ "$adminOp" = *" save"* ]];then
			cmd="$adminOp $vmName $tmp/$vmName.chkpnt"
		elif [[ "$adminOp" = *" restore" ]];then
			cmd="$adminOp $tmp/$vmName.chkpnt"
		elif [[ "$adminOp" = *" list" ]];then
			cmd="$adminOp"
		elif [ "$adminOp" = "$commonAdminTool define" ];then
		    cmd="$adminOp $tmp/$vmName.xml"
		else
			cmd="$adminOp $vmName"
		fi
		echo "Executing command: $cmd..."
		eval $cmd
		cmdRet=$?
		resultArr[$((index++))]=$cmdRet
		[ $cmdRet -ne 0 ] && retCode=1
		sleep $interval
		if [[ "$adminOp" = *"shutdown"* ]];then
			#execute destroy to force the vm to be down in case different host os version behavior for shutdown
			destroyCmd=`echo $adminOp | sed 's/shutdown.*$/destroy/'`
			$destroyCmd $vmName >/dev/null 2>&1
			sleep $interval
			#TODO:REMOVE
			echo "Debug msg for vm state after execute shutdown cmd"
			xl list
		elif [[ "$adminOp" = *" restore" || "$adminOp" = *" start" || "$adminOp" = *" create" ]];then
			#wait for vm to be up in 'restore'
			sleep 60
			if [[ "$adminOp" = *" start" || "$adminOp" = *" restore" ]];then
				sleep 60
			fi
			if [[ "$adminOp" = *" restore" ]];then
				rm $tmp/$vmName.chkpnt
				echo "Debug: the saved file for restore should be removed"
				ls $tmp/$vmName.chkpnt
				echo "Debug: the vm status should be running"
				${adminOp/restore/list}
			fi
			if [ "$adminOp" = "$xenAdminTool create" ];then
				unset xenToolCreateCfgFile
			fi
		elif [[ "$adminOp" = *"domxml-to-native"* ]];then
			if [ $cmdRet -eq 0 ];then
				if [ "$keepCfgForXenFlag" == "on" ];then
					cp $tmp/$vmName.cfg $adminOutputDir
				fi
			fi
		fi
	done
done

echo -e "\n\n"
if [ $retCode != 0 ];then
	echo "Basic VM administration has failures."
else
	echo "Basic VM administration is successful."
	# keep for debug when fail
	rm -r $tmp
fi

if [ "$printFlag" == "on" ];then
	printf "Administration result table is:"
	printContent $((${#adminOpArr[*]}+1)) 10
fi
unset resultArr

exit $retCode
