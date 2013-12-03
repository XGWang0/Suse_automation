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


export LANG=C

#===================================================================
#=== Shuts down (as gracefully as possible) a VM on the xen host ===
#===================================================================

sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"
getSettings="./get-settings.sh"

checkVmId()
{
	retVal=`./vm-running.sh $xenIp $vmName $propsFile`
	echo "$retVal"
	vmId=`echo "$retVal" | grep '\*\*\ VM\ ID\:\ ..*\ \*\*' | awk '{print $4;}'`
	if [[ ! "$vmId" =~ ^[[:digit:]][[:digit:]]*$ ]]
	then
		echo "ERROR - A digit was not returned from vm-running ($vmId)"
		echo "ERROR - A digit was not returned from vm-running ($vmId)" >&2
		exit 1
	fi
}

if [ $# -ne 5 ] && [ $# -ne 6 ]
then
	echo "Usage: $0 <xenHostIp> <hypervisor> <machineName> <machineNameFirstPart> <machineIp> [settingsFilePath]"
	echo "Usage: $0 <xenHostIp> <hypervisor> <machineName> <machineNameFirstPart> <machineIp> [settingsFilePath]" >&2
	exit 1
fi
if [ $# -eq 6 ]
then
	propsFile=${6}
	getSettings="./get-settings.sh -s ${propsFile}"
fi

xenIp=${1}
hypervisor=${2}
vmName=${3}
vmOtherName=${4}
vmIp=${5}
xenUser=`$getSettings xen.user`
xenPass=`$getSettings xen.pass`
vmUser=`$getSettings vm.user`
vmPass=`$getSettings vm.pass`
vmOs=`echo $vmOtherName | awk -F\- '{print $1;}'`

sed -i -e "/^$xenIp[[:space:]]/d" ~/.ssh/known_hosts
sed -i -e "/^$vmIp[[:space:]]/d" ~/.ssh/known_hosts

echo
echo "        -------------"
echo "        ---VM GONE---"
echo "        -------------"
echo

echo "        Properties File: $propsFile..."
echo "        Xen Host IP: $xenIp..."
echo "        Hypervisor: $hypervisor..."
echo "        Xen Host User: $xenUser..."
echo "        Xen Host Pass: $xenPass..."
echo "        VM User: $vmUser..."
echo "        VM Pass: $vmPass..."
echo "        VM Name: $vmName..."
echo "        VM Other Name: $vmOtherName..."
echo "        VM OS: $vmOs..."
echo "        VM IP: $vmIp..."
echo

# Gather info
diskLine=`export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "cat /etc/$hypervisor/vm/$vmName.xml 2> /dev/null" | xpath '/domain/devices/disk[@device="disk"]/source/@file' 2> /dev/null`
imageLocation=`echo $diskLine | sed 's/^[[:space:]]*file="\(.*\)"[[:space:]]*$/\1/'`
imageLocation=${imageLocation%/*}

echo "        Disk Line: $diskLine..."
echo "        Image Line: $imageLocation..."

if [ "$vmIp" != "000.000.000.000" ]
then
	### See if the VM is running ###
	
	checkVmId
	if [ $vmId -eq 0 ]
	then
		echo "        VM is not running..."
	else
		echo "        VM is running (id=$vmId)"	
	
		if [ "$vmOs" == "sles" ] || [ "$vmOs" == "oes" ] || [ "$vmOs" == "rhel" ] || [ "$vmOs" == "sled" ] || [ "$vmOs" == "os" ]
		then
			echo "        We are running Linux, we can SSH to shut the box down..."
			export SSHPASS=$vmPass; $sshNoPass $vmUser@$vmIp "halt &" 2> /dev/null &
		#elif [ "$vmOs" == "win" ]
		#then
		#	echo "        We are running Windows, we can use SHUTDOWN from our windows guy to shut the box down..."
		#	export SSHPASS=$windowsBoxPass; $sshNoPass $windowsBoxUser@$windowsBox "shutdown.exe -s -m \\$vmIp -t 2 -c \"Automation Takedown\" -f" 2> /dev/null
		else
			echo "        We have no way to shut the VM down safely (netware/windows), so we will destroy it (Muahahaha!)..."
			export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "virsh destroy $vmName; sleep 5; virsh destroy $vmName" 2> /dev/null
		fi
		
		# Now make sure the VM went down
		checkVmId
		timesThrough=0
		triedDestroy=0
		while [ $vmId -ne 0 ]
		do
			echo "        VM is not yet down..."
			echo "        We've been through this check $timesThrough time(s)..."
			
			if [ $timesThrough -ge 9 ]
			then
				
				echo "        Since we've hit 45 seconds, we'll try something else..."
				
				if [ $triedDestroy -eq 1 ]
				then
					echo "        After another 45 seconds, the VM still did not go down..."
					echo "ERROR - Despite our best efforts, we could not get the VM to shut down"
					echo "ERROR - Despite our best efforts, we could not get the VM to shut down" >&2
					echo "        -------------"
					echo " "
					exit 1
				else
					echo "        After 45 seconds, the VM still did not go down, so we will destroy it (Muahahaha!)..."
					export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "virsh destroy $vmName; sleep 5; virsh destroy $vmName" 2> /dev/null
					triedDestroy=1
					timesThrough=0
				fi
			fi
			
			echo "        Sleeping and then checking again..."
			sleep 5
			checkVmId
			let "timesThrough = $timesThrough + 1"
		done
		
		echo "        The VM has been shut down!"
	fi
else
	echo "        We just need to destroy and then remove traces"
	export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "virsh destroy $vmName; sleep 5; virsh destroy $vmName" 2> /dev/null
fi

### Remove traces ###

# Delete from management
echo "        Removing the vm from xend management..."
export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "virsh undefine $vmName 2> /dev/null 1> /dev/null" 2> /dev/null

# Install files
echo "        Removing install files, if they exist..."
export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "rm -f /etc/$hypervisor/vm/$vmName.xml; rm -f /etc/$hypervisor/vm/$vmName; rm -f /etc/$hypervisor/vm/.$vmName.xml; rm -f /etc/$hypervisor/vm/.$vmName; rm -f /etc/$hypervisor/vm/$vmName.autoinstall; rm -f /etc/$hypervisor/vm/$vmName.autoinstall" 2> /dev/null

# Disk image
if [ "$imageLocation" != "" ] && [ "$imageLocation" != "/" ]
then
	echo "        Image was discovered to be at '$imageLocation', so removing that location..."
	export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "rm -rf '$imageLocation'" 2> /dev/null
else
	echo "        Did not find an image for the VM, so it must have never existed on this box..."
fi

echo "        Everything should be OK now..."
echo "        -------------"
echo " "

