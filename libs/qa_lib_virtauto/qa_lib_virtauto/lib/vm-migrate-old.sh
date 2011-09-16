#!/bin/bash

#====================
#=== Migrate a VM ===
#====================

export LANG=C

sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"
migrationScript="util/xentest.py"
getSettings="./get-settings.sh"

if [ $# -ne 5 ] && [ $# -ne 6 ]
then
	echo "Usage: $0 <xenHostIp> <hypervisor> <machineName> <migrateeIp> <timesToMigrate> [settingsFilePath]"
	echo "Usage: $0 <xenHostIp> <hypervisor> <machineName> <migrateeIp> <timesToMigrate> [settingsFilePath]" >&2
	echo "$0 151.155.190.26 kvm sles-10-sp1-32-all-def-146-1 151.155.190.27 4"
	echo "$0 151.155.190.26 kvm sles-10-sp1-32-all-def-146-1 151.155.190.27 4" >&2
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
migrateeIp=${4}
timesToMigrate=${5}
xenUser=`$getSettings xen.user`
xenPass=`$getSettings xen.pass`

sed -i -e "/^$xenIp[[:space:]]/d" ~/.ssh/known_hosts
sed -i -e "/^$migrateeIp[[:space:]]/d" ~/.ssh/known_hosts

echo
echo "        ----------------"
echo "        ---VM MIGRATE---"
echo "        ----------------"
echo

echo "        Properties File: $propsFile..."
echo "        Xen Host IP: $xenIp..."
echo "        Hypervisor: $hypervisor..."
echo "        Xen Host User: $xenUser..."
echo "        Xen Host Pass: $xenPass..."
echo "        VM Name: $vmName..."
echo "        Migratee IP: $migrateeIp..."
echo

### Setup ###

# Create .ssh directory on first server
export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "mkdir ~/.ssh" 2> /dev/null

# Create .ssh directory on second server
export SSHPASS=$xenPass; $sshNoPass $xenUser@$migrateeIp "mkdir ~/.ssh" 2> /dev/null

# Create the keys on the first server
export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "ssh-keygen -t dsa -N '' -f ~/.ssh/id_$vmName" 2> /dev/null
theKey=`export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "cat ~/.ssh/id_$vmName.pub" 2> /dev/null`

# Export the key to the 2nd server
export SSHPASS=$xenPass; echo $theKey | $sshNoPass $xenUser@$migrateeIp 'cat - >> ~/.ssh/authorized_keys' 2> /dev/null

# Get the host name of the first server
hostName=`export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "hostname" 2> /dev/null`

# Get pub key thing of 2nd box
pubKeyThing=`export SSHPASS=$xenPass; $sshNoPass $xenUser@$migrateeIp 'cat /etc/ssh/ssh_host_rsa_key.pub' | cut -d' ' -f1,2 2> /dev/null`

# Get rid of the public key if it already exists
export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "sed -i \"/^$migrateeIp\ ssh-.*\=$/d\" ~/.ssh/known_hosts" 2> /dev/null

# Add the public key to known_hosts
export SSHPASS=$xenPass; echo "$migrateeIp $pubKeyThing" | $sshNoPass $xenUser@$xenIp 'cat - >> ~/.ssh/known_hosts' 2> /dev/null

# NFS export
export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "migexport $vmName $migrateeIp id_$vmName" 2> /dev/null

### Cleanup ###

# Get rid of the public key now
export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "sed -i \"/^$migrateeIp\ ssh-.*\=$/d\" ~/.ssh/known_hosts" 2> /dev/null

# Get rid of the authorized key from the 2nd server
export SSHPASS=$xenPass; $sshNoPass $xenUser@$migrateeIp "sed -i \"/^ssh-.*\@$hostName$/d\" ~/.ssh/authorized_keys" 2> /dev/null

# Get rid of the generated keys
export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenIp "rm ~/.ssh/id_$vmName*" 2> /dev/null

### Check ### - at this point, machine 2 must have the correct folder setup (for vmName) and the disk in that directory

diskZero=`export SSHPASS=$xenPass; $sshNoPass $xenUser@$migrateeIp "ls /var/lib/$hypervisor/images/$vmName | grep disk0" 2> /dev/null`
if [ "$diskZero" == "disk0" ]
then
	echo "        Found disk0 on migratee."
else
	echo "Could not find disk0 on migratee"
	echo "Could not find disk0 on migratee" >&2
	exit 1
fi

echo
echo "        Mount is set up correctly, ready to migrate."
echo

### Migrate ###

theoutputofit=`util/xentest.py migrate $xenIp $migrateeIp $vmName -l -c $timesToMigrate | grep "completed migration" | wc -l`
echo "        Number of migrations that completed successfully: $theoutputofit (out of $timesToMigrate)..."
if [ "$timesToMigrate" == "$theoutputofit" ]
then
	echo "        The migration was successful..."
else
	echo "ERROR: Failed migration ($theoutputofit successful out of $timesToMigrate required)"
	echo "ERROR: Failed migration ($theoutputofit successful out of $timesToMigrate required)" >&2
	exit 2
fi

echo
echo "        Migration worked, now sleeping 30 seconds for any manual checks..."
sleep 30

echo
echo "        Finished migration script..."
echo "        ----------------"
echo " "
