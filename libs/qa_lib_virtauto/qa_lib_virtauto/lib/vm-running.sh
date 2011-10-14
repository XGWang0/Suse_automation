#!/bin/bash

#=======================================================================
#=== Checks if a machine is running or not                           ===
#=== The ID of the machine is returned if it is running, otherwise 0 ===
#=======================================================================

export LANG=C

sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"
getSettings="./get-settings.sh"

if [ $# -ne 2 ] && [ $# -ne 3 ]
then
	echo "ERROR - Usage: $0 <xenHostIp> <machineName> [settingsFilePath]"
	echo "ERROR - Usage: $0 <xenHostIp> <machineName> [settingsFilePath]" >&2
	exit 1
fi

if [ $# -eq 3 ]
then
	propsFile=${3}
	getSettings="./get-settings.sh -s ${propsFile}"
fi

xenIp=${1}
vmName=${2}
xenUser=`$getSettings xen.user`
xenPass=`$getSettings xen.pass`

sed -i -e "/^$xenIp[[:space:]]/d" ~/.ssh/known_hosts

echo
echo "            ----------------"
echo "            ---VM RUNNING---"
echo "            ----------------"
echo

echo "            Properties File: $propsFile..."
echo "            Xen Host Ip: $xenIp..."
echo "            Xen Host User: $xenUser..."
echo "            Xen Host Pass: $xenPass..."
echo "            VM Name: $vmName..."
echo

### See if the VM is running ###

vmInfo=`export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "virsh dominfo '$vmName'" 2> /dev/null`

discoveredName=`echo "$vmInfo" | grep '^Name:' | sed 's/^[^:]*:[[:space:]]*//'`
discoveredId=`echo "$vmInfo" | grep '^Id:' | sed 's/^[^:]*:[[:space:]]*//'`
discoveredMemory=`echo "$vmInfo" | grep '^Used memory:' | sed 's/^[^:]*:[[:space:]]*//'`
discoveredCpus=`echo "$vmInfo" | grep '^CPU(s):' | sed 's/^[^:]*:[[:space:]]*//'`
discoveredState=`echo "$vmInfo" | grep '^State:' | sed 's/^[^:]*:[[:space:]]*//'`
discoveredTime=`echo "$vmInfo" | grep '^CPU time:' | sed 's/^[^:]*:[[:space:]]*//'`

echo "            DiscoveredName : $discoveredName..."
echo "            DiscoveredId : $discoveredId..."
echo "            DiscoveredMemory : $discoveredMemory..."
echo "            DiscoveredCpus : $discoveredCpus..."
echo "            DiscoveredState : $discoveredState..."
echo "            DiscoveredTime : $discoveredTime..."
echo " "

if [ "$discoveredId" == "-" ] || [ "$discoveredId" == "" ]
then
	echo "            ** VM ID: 0 **"
	echo "            VM is not running..."
	echo "            ----------------"
	echo " "
else
	echo "            ** VM ID: $discoveredId **"
	echo "            VM is running (id=$discoveredId)"
	echo "            ----------------"
	echo " "
fi
