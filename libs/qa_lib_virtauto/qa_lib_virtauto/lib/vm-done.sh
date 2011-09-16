#!/bin/bash

export LANG=C

#===================================================
#=== Checks if a machine is completely installed ===
#===================================================

sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"
getSettings="./get-settings.sh"

if [ $# -ne 3 ] && [ $# -ne 4 ]
then
	echo "ERROR - Usage: $0 <machineIp> <machineName> <machineNameFirstPart> [settingsFilePath]"
	echo "ERROR - Usage: $0 <machineIp> <machineName> <machineNameFirstPart> [settingsFilePath]" >&2
	echo "ERROR - $0 151.155.146.1 this-is-my-vm sles-10-sp1-32-all-def-146-1"
	echo "ERROR - $0 151.155.146.1 this-is-my-vm sles-10-sp1-32-all-def-146-1" >&2
	exit 1
fi
if [ $# -eq 4 ]
then
	propsFile=${4}
	getSettings="./get-settings.sh -s ${propsFile}"
fi

vmIp=${1}
vmName=${2}
vmOtherName=${3}
vmUser=`$getSettings vm.user`
vmPass=`$getSettings vm.pass`
vmOs=`echo $vmOtherName | awk -F\- '{print $1;}'`
vmRelease=`echo $vmOtherName | awk -F\- '{print $2;}'`
vmMethod=`echo $vmOtherName | awk -F\- '{print $7;}'`

sed -i -e "/^$vmIp[[:space:]]/d" ~/.ssh/known_hosts

echo
echo "            -------------"
echo "            ---VM DONE---"
echo "            -------------"
echo

echo "            Properties File: $propsFile..."
echo "            VM Ip: $vmIp..."
echo "            VM User: $vmUser..."
echo "            VM Pass: $vmPass..."
echo "            VM Name: $vmName..."
echo "            VM Name First Part: $vmOtherName..."
echo "            VM OS: $vmOs..."
echo "            VM Release: $vmRelease..."
echo "            VM Method: $vmMethod..."
echo

### If this is Linux, we SSH in to check the runlevel ###

doneInstall=NO

if [ "$vmOs" == "sles" ] || [ "$vmOs" == "sled" ] || [ "$vmOs" == "oes" ] || [ "$vmOs" == "rhel" ] || [ "$vmOs" == "os" ]
then
	# Make sure we can ping first, then try SSH (if we can ping, we try ssh; if we can't ping, we just continue)
	pingResponse=`ping $vmIp -c 2 -W 2`
	if ! echo "$pingResponse" | grep -q '100% packet loss'
	then
		runLevel=`export SSHPASS=$vmPass; $sshNoPass $vmUser@$vmIp "runlevel" 2> /dev/null`
		echo "            [Linux ($vmOs)] - The runlevel is '$runLevel'..."
		if [ "$runLevel" == "N 3" ] || [ "$runLevel" == "N 5" ]
		then
			# Able to ping AND able to SSH AND runlevel is 5 means we are done!
			doneInstall=YES
		fi
	fi
elif [ "$vmOs" == "win" ]
then
	if [ "$vmRelease" == "2k8" ] || [ "$vmRelease" == "2k8r2" ] || [ "$vmRelease" == "vista" ] || [ "$vmRelease" == "7" ]
	then
		if [ "$vmMethod" == "iso" ]
		then
			pingResponse=`ping $vmIp -c 2 -W 2`
			if ! echo "$pingResponse" | grep -q 100%\ packet\ loss
			then
				doneInstall=YES
			fi
		fi
	elif [ "$vmRelease" == "2k3" ] || [ "$vmRelease" == "xp" ]
	then
		telnetResponse=`echo quit | telnet $vmIp 445`
		if ! echo "$telnetResponse" | grep -q 'Connection refused\|No route to host\|Escape character'
		then
			doneInstall=YES
		fi
	elif [ "$vmRelease" == "2k" ]
	then
		telnetResponse=`echo quit | telnet $vmIp 445`
		telnetResponse2=`echo quit | telnet $vmIp 1025`
		telnetResponse3=`echo quit | telnet $vmIp 1026`
		if ! echo "$telnetResponse $telnetResponse2 $telnetResponse3" | grep -q 'Connection refused\|No route to host\|Escape character'
		then
			doneInstall=YES
		fi
		#telnetResponse=`echo quit | telnet $vmIp 1026`
		#if [[ ! "$telnetResponse" =~ Connection\ refused ]] && [[ ! "$telnetResponse" =~ No\ route\ to\ host ]] && [[ "$telnetResponse" =~ Escape\ character ]]
		#then
		#	doneInstall=YES
		#fi
	fi
elif [ "$vmOs" == "nw" ]
then
	telnetResponse=`echo quit | telnet $vmIp 6000`
	if ! echo "$telnetResponse" | grep -q 'Connection refused\|No route to host\|Escape character'
	then
		doneInstall=YES
	fi
else
	echo "ERROR - Unsupported scenario for checking if install is finished"
	echo "ERROR - Unsupported scenario for checking if install is finished" >&2
	exit 1
fi

if [ "$doneInstall" == "NO" ]
then
	echo "            ** DONE INSTALL: NO **"
	echo "            VM is not done installing..."
	echo "            -------------"
	echo " "
else
	echo "            ** DONE INSTALL: YES **"
	echo "            VM is done installing"
	echo "            -------------"
	echo " "
fi
