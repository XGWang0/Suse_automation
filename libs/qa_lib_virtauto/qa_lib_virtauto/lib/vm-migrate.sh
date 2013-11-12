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


#====================
#=== Migrate a VM ===
#====================

# Usage: vm-migrate.sh -n domUname -p migrateeIP  [-t migrateTimes] [-l]

export LANG=C

function usage() {
	echo "Usage: $0 -n domUname -p migrateeIP [-t migrateTimes] [-l]"
	echo "migrateTimes should be an positive integer."
	echo "by default, -t 2 is used, that means migrate to dest and back."
	exit 1
}

function cleanup(){
	# Disconnect from remote
	export SSHPASS=$migrateePass; $sshNoPass $migrateeUser@$migrateeIP "umount $domainDiskDir" 2>/dev/null
	export SSHPASS=$migrateePass; $sshNoPass $migrateeUser@$migrateeIP "rm -r $domainDiskDir" 2>&1
	# Clean nfs export file
	lineNum=`grep -n $domUname /etc/exports | cut -d: -f1`
	sed -ie "$lineNum d" /etc/exports
	exportfs -r 2>&1
}

if [ $# -ne 4 ] && [ $# -ne 6 ] && [ $# -ne 7 ] && [ $# -ne 5 ]; then
	usage
fi

while getopts "n:p:t:l" OPTIONS
do
	case $OPTIONS in
		n)domUname="$OPTARG";;
		p)migrateeIP="$OPTARG";;
		l)livemigration="yes";;
		t)migrateTimes="$OPTARG";;
		\?)usage;;
		*) usage;;
	esac
done

uname -a | grep -iq xen 2>/dev/null
if [ $? == 0 ]; then
    hyperType="xen"
else
    hyperType="kvm"
fi

if [ -z $migrateTimes ]; then
	migrateTimes=2
fi

# Define some variables
#propsFile=../data/settings.properties
sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"
#getSettings="./get-settings.sh -s ${propsFile}"
getSettings="./get-settings.sh"
migrateeUser=`$getSettings migratee.user`
migrateePass=`$getSettings migratee.pass`

# Check firewall status
echo "Checking the firewall status..."
firewallStatus=`rcSuSEfirewall2 status | grep unused | wc -l`
if [ ! $firewallStatus -eq 1 ] && [ ! $firewallStatus -eq 4 ]
then
	echo "WARNING: Firewall is active. Please make sure that either it is turned off, or the correct port is open for migration."
fi

# Make sure nfsserver is running
echo "Making sure the nfs server is running..."
nfsStatus=`rcnfsserver status | grep running | wc -l`
if [ ! $nfsStatus -eq 1 ] && [ ! $nfsStatus -eq 4 ]
then
        echo "ERROR: The NFS server is not running. Please start it (rcnfsserver start) and then try running this script again."
	exit 1
fi

# Get the local IP
echo "Retrieving your local IP address..."
localIp=`ifconfig br0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1;}'`
if [ "$localIp" == "" ]
then
	localIp=`ifconfig br1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1;}'`
        if [ "$localIp" == "" ]
        then
			localIp=`ifconfig br2 | grep 'inet addr' | cut -d: -f2 | awk '{print $1;}'`
			if [ "$localIp" == "" ]
			then
				localIp=`ifconfig eth0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1;}'`
				if [ "$localIp" == "" ]
				then
					localIp=`ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | awk '{print $1;}'`
					if [ "$localIp" == "" ]
					then
						localIp=`ifconfig eth2 | grep 'inet addr' | cut -d: -f2 | awk '{print $1;}'`
						if [ "$localIp" == "" ]
						then
							echo "ERROR: Could not get IP address from local box."
							exit 1
						fi
					fi
				fi
			fi
        fi
fi
echo "Host IP address is $localIp..."

#Get directory for the domain disk
domainDiskDir=`find /var/lib/$hyperType -name $domUname`
if [ -z $domainDiskDir ];then
	echo "The domain does not exist!"
	exit 1
fi
# Create the remote directory
echo "Creating remote directory $migrateeIP :$domainDiskDir..."
export SSHPASS=$migrateePass; $sshNoPass $migrateeUser@$migrateeIP "mkdir -p $domainDiskDir" 2>&1

if [ $? -ne 0 ]
then
	# The remote directory exists, so we just need to make sure it is empty
	totalResult=`export SSHPASS=$migrateePass; $sshNoPass $migrateeUser@$migrateeIP "ls -lR $domainDiskDir | grep total" 2>&1`
        if [ "$totalResult" == "total 0" ]
        then
            echo "The remote directory already exists, but is empty, so we are OK to mount it."
        else
            echo "ERROR: The remote directory already exists."
            exit 1
        fi
fi

# Now set up the export
echo "Setting up local export..."
if ! grep "$domainDiskDir $migrateeIP" /etc/exports;then
	echo "$domainDiskDir $migrateeIP(rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports
else
	echo "There already is export item for \"$domainDiskDir $migrateeIP\", please remove it first!"
	exit 1
fi
exportfs -r 2>&1

# Remote mount it
echo "Remote mounting the share..."
export SSHPASS=$migrateePass; $sshNoPass $migrateeUser@$migrateeIP "mount -t nfs $localIp:$domainDiskDir $domainDiskDir" 2> /dev/null
if [ $? -eq 0 ];then
	echo "Mount is successful!"
else
	echo "Mount fails!"
	exit 1
fi

echo
echo "		----------------------"
echo "		---  VM MIGRATING  ---"
echo "		----------------------"
echo

# implement migration
migrateRound=`expr $migrateTimes / 2`
for ((i=0;i<$migrateRound;i++)); do
	echo
	echo "		---- roundtrip migration ----"
	echo
	echo "		---- migration forward  $((i+1)) times ----"
	echo "		From: $localIp..."
	echo "		To: $migrateeIP..."
	echo "		VMName: $domUname..."
	echo
	if [ -z $livemigration ]; then
		if [ $hyperType == "xen" ]; then
			xm migrate $domUname $migrateeIP
			export SSHPASS=$migrateePass; $sshNoPass $migrateeUser@$migrateeIP "xm migrate $domUname $localIp" 2>/dev/null
		else # KVM
			virsh migrate --unsafe $domUname qemu+ssh://$migrateeIP/system tcp://$migrateeIP
			export SSHPASS=$migrateePass; $sshNoPass $migrateeUser@$migrateeIP "virsh migrate --unsafe $domUname qemu+ssh://$localIp/system tcp://$localIp" 2>/dev/null
		fi
	else # live migration
		echo "		MigrationType: live..."
		if [ $hyperType == "xen" ]; then
			xm migrate -l $domUname $migrateeIP
			export SSHPASS=$migrateePass; $sshNoPass $migrateeUser@$migrateeIP "xm migrate -l $domUname $localIp" 2>/dev/null
		else
			virsh migrate --live --unsafe $domUname qemu+ssh://$migrateeIP/system tcp://$migrateeIP
			export SSHPASS=$migrateePass; $sshNoPass $migrateeUser@$migrateeIP "virsh migrate --live --unsafe $domUname qemu+ssh://$localIp/system tcp://$localIp" 2>/dev/null
		fi
	fi
        if [[ $? != 0 ]];then
		echo "Migration fails!"
                cleanup
                exit 1
        fi

	# Disconnect from remote
	export SSHPASS=$migrateePass; $sshNoPass $migrateeUser@$migrateeIP "umount $domainDiskDir" 2>/dev/null
	echo "		---- migration back $((i+1)) times ----"
	echo "		From: $migrateeIP..."
	echo "		To: $localIp..."
	echo "		VMName: $domUname..."
	echo
	export SSHPASS=$migrateePass; $sshNoPass $migrateeUser@$migrateeIP "mount -t nfs $localIp:$domainDiskDir $domainDiskDir" 2> /dev/null
done

if [ `expr $migrateTimes % 2` -eq 1 ]; then
        echo
	echo "          ---- Migration times you choose is $migrateTimes ----"
        echo "          ---- final time for one way migration ---"
        echo
        echo "          From: $localIp..."
        echo "          To: $migrateeIP..."
        echo "          VMName: $domUname..."
        if [ -z $livemigration ]; then
                if [ $hyperType == "xen" ]; then
                        xm migrate $domUname $migrateeIP
                else # else KVM
                        virsh migrate --unsafe $domUname qemu+ssh://$migrateeIP/system tcp://$migrateeIP
		fi
       	else
		echo "          MigrationType: live..."
		if [ $hyperType == "xen" ]; then
			xm migrate -l $domUname $migrateeIP
		else
			virsh migrate --live --unsafe $domUname qemu+ssh://$migrateeIP/system tcp://$migrateeIP
		fi
 	fi
	if [[ $? != 0 ]];then
        	echo "Migration fails!"
              	cleanup
                exit 1
        fi  
fi

#cleanup for successful migration if finally the domain is till on source host
if [ `expr $migrateTimes % 2` -eq 0 ]; then
	cleanup
fi

echo
echo "		----------------------"
echo "		---  MIGRATE DONE  ---"
echo "		----------------------"
echo


