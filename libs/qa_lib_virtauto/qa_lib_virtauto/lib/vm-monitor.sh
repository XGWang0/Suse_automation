#!/bin/bash

#============================
#=== Monitor a VM install ===
#============================
export LANG=C


sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"
getSettings="./get-settings.sh"

# This is for reporting failure if the guest has disappeared
howManyNotThereVmChecks=0

checkVmId()
{
	retVal=`./vm-running.sh $xenIp $vmName $propsFile`
	echo "$retVal"
	vmId=`echo "$retVal" | grep '\*\*\ VM\ ID\:\ ..*\ \*\*' | awk '{print $4;}'`
	
	# If a valid number was not returned (either the ID or 0, for not there)
	if [[ ! "$vmId" =~ ^[[:digit:]][[:digit:]]*$ ]]
	then
		echo "ERROR - A digit was not returned from vm-running ($vmId)"
		echo "ERROR - A digit was not returned from vm-running ($vmId)" >&2
		exit 1
	# If zero was returned (guest is no longer there)
	elif [ "$vmId" == "0" ]
	then
		let "howManyNotThereVmChecks = $howManyNotThereVmChecks + 1"
		echo "        The guest is no longer listed, so incrementing the lost guest check value to $howManyNotThereVmChecks...."
	# If a valid ID was returned (guest is there) -- we may want to get rid of this resetting of the value
	else
		if [ "$howManyNotThereVmChecks" != "0" ]
		then
			howManyNotThereVmChecks=0
			echo "        The guest previously wasn't there, but now it is, so resetting the lost guest check value to $howManyNotThereVmChecks...."
		fi
	fi
}

checkInstalled()
{
	#if [ "$vmIp" == "000.000.000.000" ]
	if [ "$thisIsDHCP" == "yes" ]
	then
		# Make sure we have an IP first
		tmpIP="$(export SSHPASS=$netinfoPass; echo mac2ip "$vmMac" | $sshNoPass $netinfoUser@$netinfoServer bash -l )"
		[ "$tmpIP" != "" ] && vmIp="$tmpIP"
	fi
	
	echo "        The most recent IP we have is $vmIp..."
	
	# If we got an ip
	if [ "$vmIp" != "000.000.000.000" ]
	then
		echo "        We have an IP ($vmIp), so we will check if the VM is done installing..."
		retVal=`./vm-done.sh $vmIp $vmName $vmOtherName $propsFile`
		echo "$retVal"
		doneInstall=`echo "$retVal" | grep '\*\*\ DONE\ INSTALL\:\ ...*\ \*\*' | awk '{print $4;}'`
		if [ "$doneInstall" != "YES" ] && [ "$doneInstall" != "NO" ]
		then
			echo "ERROR - YES/NO was not returned from vm-done ($doneInstall)"
			echo "ERROR - YES/NO was not returned from vm-done ($doneInstall)" >&2
			exit 1
		fi
	else
		echo "        We DON'T have an IP, so we will NOT check if the VM is done installing..."
		doneInstall="NO"
	fi
}

if [ $# -ne 7 ] && [ $# -ne 8 ]
then
	echo "Usage: $0 <xenHostIp> <machineName> <machineNameFirstPart> <machineIp> <machineMac> <isDHCP> <installId> [settingsFilePath]"
	echo "Usage: $0 <xenHostIp> <machineName> <machineNameFirstPart> <machineIp> <machineMac> <isDHCP> <installId> [settingsFilePath]" >&2
	exit 1
fi

if [ $# -eq 8 ]
then
	propsFile=${8}
	getSettings="./get-settings.sh -s ${propsFile}"
fi

xenIp=${1}
vmName=${2}
vmOtherName=${3}
vmIp=${4}
vmMac=${5}
thisIsDHCP=${6}
installId=${7}
netinfoServer=`$getSettings netinfo.ip`
netinfoUser=`$getSettings netinfo.user`
netinfoPass=`$getSettings netinfo.pass`
xenUser=`$getSettings xen.user`
xenPass=`$getSettings xen.pass`
vmUser=`$getSettings vm.user`
vmPass=`$getSettings vm.pass`
vmOs=`echo $vmOtherName | awk -F\- '{print $1;}'`
vmRelease=`echo $vmOtherName | awk -F\- '{print $2;}'`
vmServicePack=`echo $vmOtherName | awk -F\- '{print $3;}'`
vmVirtType=`echo $vmOtherName | awk -F\- '{print $5;}'`

sed -i -e "/^$netinfoServer[[:space:]]/d" ~/.ssh/known_hosts
sed -i -e "/^$xenIp[[:space:]]/d" ~/.ssh/known_hosts
sed -i -e "/^$vmIp[[:space:]]/d" ~/.ssh/known_hosts

echo
echo "        ----------------"
echo "        ---VM MONITOR---"
echo "        ----------------"
echo

echo "        Properties File: $propsFile..."
echo "        Xen Host IP: $xenIp..."
echo "        Xen Host User: $xenUser..."
echo "        Xen Host Pass: $xenPass..."
echo "        VM User: $vmUser..."
echo "        VM Pass: $vmPass..."
echo "        VM Name: $vmName..."
echo "        VM Name First Part: $vmOtherName..."
echo "        VM OS: $vmOs..."
echo "        VM MAC: $vmMac..."
echo "        VM Release: $vmRelease..."
echo "        VM Service Pack: $vmServicePack..."
echo "        VM Virt Type: $vmVirtType..."
echo "        VM IP: $vmIp..."
echo "        Is DHCP: $thisIsDHCP..."
echo "        Install ID: $installId..."
echo

### Monitor until we get an id ###

echo "        [Step 1] Going to monitor until the VM comes up for install..."
checkVmId
timeLimit1=0
maxTime=30
while [ "$vmId" == "" ] || [ $vmId -eq 0 ]
do
	echo "        [Step 1] After $timeLimit1 seconds, the VM has not yet come up for install (id: $vmId)..."
	let "timeLimit1 = $timeLimit1 + 5"
	if [ $timeLimit1 -ge $maxTime ]
	then
		echo "ERROR - After $maxTime seconds, the VM did not come up to start its install"
		echo "ERROR - After $maxTime seconds, the VM did not come up to start its install" >&2
		exit 1
	fi
	sleep 5
	checkVmId
done
echo "        [Step 1] The VM has come up for install (id: $vmId, took $timeLimit1 seconds)"
initialId=$vmId

### Now monitor until we get an id change ###

# The one exception to this is OpenSUSE 11.1 FV, which will not change IDs
if [ "$vmOs" == "os" ] && [ "$vmRelease" == "11" ] && [ "$vmServicePack" == "sp1" ] && [ "$vmVirtType" == "fv" ]
then
	echo "        [Step 2] Since this is $vmOs-$vmRelease-$vmServicePack-$vmVirtType, the ID should not change, so skipping this check..."
	checkVmId
	if [ $howManyNotThereVmChecks -gt 2 ]
	then
		echo "ERROR - The VM disappeared (waiting for 2nd stage)"
		echo "ERROR - The VM disappeared (waiting for 2nd stage)" >&2
		exit 1
	fi
	echo "        [Step 2] Moving to the step 3 checks with id=$vmId..."
# Everything else should change (at least once)
else
	echo "        [Step 2] Going to monitor until the VM comes up for the 2nd stage of the install..."
	checkVmId
	if [ $howManyNotThereVmChecks -gt 2 ]
	then
		echo "ERROR - The VM disappeared (waiting for 2nd stage)"
		echo "ERROR - The VM disappeared (waiting for 2nd stage)" >&2
		exit 1
	fi
	timeLimit2=0
	if [ "$vmOs" == "os" ] && [ "$vmRelease" == "11" ] && [ "$vmVirtType" == "fv" ]
	then
		maxTime=4500
	elif [ "$vmOs" == "sles" ] && [ "$vmRelease" == "11" ]
	then
		maxTime=4500
	elif [ "$vmOs" == "sled" ] && [ "$vmRelease" == "11" ]
	then
		maxTime=4500
	elif [ "$vmOs" == "sles" ] || [ "$vmOs" == "rhel" ] || [ "$vmOs" == "oes" ] || [ "$vmOs" == "os" ] && [ "$vmVirtType" == "pv" ]
	then
		maxTime=2700
	elif [ "$vmOs" == "win" ]
	then
		if [ "$vmRelease" == "2k" ] || [ "$vmRelease" == "xp" ] || [ "$vmRelease" == "2k3" ]
		then
			maxTime=900
		elif [ "$vmRelease" == "2k8" ] || [ "$vmRelease" == "2k8r2" ] || [ "$vmRelease" == "vista" ] || [ "$vmRelease" == "7" ]
		then
			maxTime=2700
		else
			maxTime=3600
		fi
	else
		maxTime=3600
	fi

	# FIXME: Temporal hack for KVM, which is really slow, need better fix!
	[ "$vmVirtType" == "fv" ] && maxTime=$(($maxTime * 2))

	while [ $vmId -eq $initialId ] || [ $vmId -eq 0 ]
	do
		echo "        [Step 2] After $timeLimit2 seconds, the VM has not yet gone to the 2nd stage of the install (id: $vmId)..."
		let "timeLimit2 = $timeLimit2 + 30"
		if [ $timeLimit2 -ge $maxTime ]
		then
			echo "ERROR - After $maxTime seconds, the VM did not start the second stage of the install"
			echo "ERROR - After $maxTime seconds, the VM did not start the second stage of the install" >&2
			exit 1
		fi
		sleep 30
		checkVmId
		if [ $howManyNotThereVmChecks -gt 2 ]
		then
			echo "ERROR - The VM disappeared (waiting for 2nd stage)"
			echo "ERROR - The VM disappeared (waiting for 2nd stage)" >&2
			exit 1
		fi
	done
	echo "        [Step 2] The VM has started the 2nd stage (id: $vmId, took $timeLimit2 seconds)"
fi

#if [ "$installId" != "0" ]
#then
#	echo "        Sending the time for the first stage of the install to the DB..."
#	sentOne=`curl -k -d "override=yes&updatemid=yes&updateid=$installId" https://${ipweb}/automation/admin/SM-newdeploy.php 2>/dev/null`
#	sentOneResult=`echo $sentOne | awk -F' - ' '{print $1;}'`
#	if [ "$sentOneResult" != "SUCCESS" ]
#	then
#		echo "ERROR - MONITOR 1 - WE WERE UNABLE TO UPDATE THE DATABASE WITH MID TIMES BECAUSE OF SOME FAILURE"
#		echo "ERROR - MONITOR 1 - WE WERE UNABLE TO UPDATE THE DATABASE WITH MID TIMES BECAUSE OF SOME FAILURE" >&2
#	fi
#fi

### Now monitor until the VM is fully installed ###

echo "        [Step 3] Going to monitor until the VM is fully installed..."
checkVmId
if [ $howManyNotThereVmChecks -gt 2 ]
then
	echo "ERROR - The VM disappeared (waiting for it to be fully installed)"
	echo "ERROR - The VM disappeared (waiting for it to be fully installed)" >&2
	exit 1
fi
timeLimit3=0
if [ "$vmOs" == "os" ] && [ "$vmRelease" == "11" ] && [ "$vmServicePack" == "sp1" ] && [ "$vmVirtType" == "fv" ]
then
	maxTime=3600
elif [ "$vmOs" == "sles" ] || [ "$vmOs" == "rhel" ] || [ "$vmOs" == "oes" ] || [ "$vmOs" == "os" ]
then
	maxTime=1800
elif [ "$vmOs" == "win" ]
then
	if [ "$vmRelease" == "2k" ] || [ "$vmRelease" == "xp" ] || [ "$vmRelease" == "2k3" ]
	then
		maxTime=3600
	else
		maxTime=1800
	fi
else
	maxTime=2700
fi

# FIXME: Temporal hack for KVM, which is really slow, need better fix!
[ "$vmVirtType" == "fv" ] && maxTime=$(($maxTime * 2))

doneInstall=NO
checkInstalledTimes=0
while [ "$doneInstall" == "NO" ]
do
	echo "        [Step 3] After $timeLimit3 seconds, the VM has not yet finished installing fully..."
	let "timeLimit3 = $timeLimit3 + 30"
	if [ $timeLimit3 -ge $maxTime ]
	then
		echo "ERROR - After $maxTime seconds, the VM still was not done installing"
		echo "ERROR - After $maxTime seconds, the VM still was not done installing" >&2
		exit 1
	fi
	sleep 30
	checkVmId
	if [ $howManyNotThereVmChecks -gt 2 ]
	then
		echo "ERROR - The VM disappeared (waiting for it to be fully installed)"
		echo "ERROR - The VM disappeared (waiting for it to be fully installed)" >&2
		exit 1
	fi
	checkInstalled
done
echo "        [Step 3] The VM has finished installing fully (took $timeLimit3 seconds)"

#if [ "$installId" != "0" ]
#then
#	echo "        Sending the time for the second stage of the install to the DB..."
#	sentOne=`curl -k -d "override=yes&updateend=yes&updateid=$installId" https://${ipweb}/automation/admin/SM-newdeploy.php 2>/dev/null`
#	sentOneResult=`echo $sentOne | awk -F' - ' '{print $1;}'`
#	if [ "$sentOneResult" != "SUCCESS" ]
#	then
#		echo "ERROR - MONITOR 1 - WE WERE UNABLE TO UPDATE THE DATABASE WITH END TIMES BECAUSE OF SOME FAILURE"
#		echo "ERROR - MONITOR 1 - WE WERE UNABLE TO UPDATE THE DATABASE WITH END TIMES BECAUSE OF SOME FAILURE" >&2
#	fi
#fi

echo "        Going to sleep 30 seconds to let services load..."
sleep 30

# The total install time (not including startup time)
let "totalTime = $timeLimit2 + $timeLimit3"
echo "        The total install took $totalTime seconds."

echo "        The VM is installed..."
echo "        ----------------"
echo " "
