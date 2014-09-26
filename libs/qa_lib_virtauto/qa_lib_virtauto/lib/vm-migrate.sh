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

trap "echo 'catch CTRL+C';cleanup" SIGINT

function usage() {
	echo "Usage: $0 -n domUname -p migrateeIP [-t migrateTimes] [-l]"
	echo "migrateTimes should be an positive integer."
	echo "by default, -t 2 is used, that means migrate to dest and back."
	exit 1
}
function recoverVirtConfig(){
	if [ $hyperType == "xen" ]; then
		mv /etc/libvirt/libvirtd.conf.org /etc/libvirt/libvirtd.conf 2>/dev/null
        	rclibvirtd restart 2>/dev/null
		echo "Recover souce libvirtd configuration done."
		$sshNoPass $migrateeUser@$migrateeIP "mv /etc/libvirt/libvirtd.conf.org /etc/libvirt/libvirtd.conf" 2>/dev/null
      		$sshNoPass $migrateeUser@$migrateeIP "rclibvirtd restart" 2>/dev/null
		echo "Recover destination libvirtd configuration done."
		mv /etc/xen/xend-config.sxp.org /etc/xen/xend-config.sxp 2>/dev/null
		rcxend restart
		echo "Recover source xend configuration done."
		$sshNoPass $migrateeUser@$migrateeIP "mv /etc/xen/xend-config.sxp.org /etc/xen/xend-config.sxp" 2>/dev/null
		$sshNoPass $migrateeUser@$migrateeIP "rcxend restart" 2>/dev/null
		echo "Recover destination xend configuration done."
	fi

}
function cleanup(){
	# Disconnect from remote
	$sshNoPass $migrateeUser@$migrateeIP "umount $domainDiskDir" 2>/dev/null
	$sshNoPass $migrateeUser@$migrateeIP "rm -r $domainDiskDir" 2>/dev/null
	echo "Unmount remote files done."
	# Clean nfs export file
	lineNum=`grep -n $domUname /etc/exports | cut -d: -f1`
	sed -ie "$lineNum d" /etc/exports
	exportfs -r 2>&1
	echo "Recover exportfs service."
	recoverVirtConfig
	trap - SIGINT
	echo
	echo "		----------------------"
	echo "		---  MIGRATE DONE  ---"
	echo "		----------------------"
	echo
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

# Export SSHPASS
export SSHPASS=$migrateePass

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
localIp=`ifconfig2ip ip br0`
if [ "$localIp" == "" ]
then
	localIp=`ifconfig2ip ip br1`
        if [ "$localIp" == "" ]
        then
			localIp=`ifconfig2ip ip br2`
			if [ "$localIp" == "" ]
			then
				localIp=`ifconfig2ip ip eth0`
				if [ "$localIp" == "" ]
				then
					localIp=`ifconfig2ip ip eth1`
					if [ "$localIp" == "" ]
					then
						localIp=`ifconfig2ip ip eth2`
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
$sshNoPass $migrateeUser@$migrateeIP "mkdir -p $domainDiskDir" 2>&1

if [ $? -ne 0 ]
then
	# The remote directory exists, so we just need to make sure it is empty
	totalResult=`$sshNoPass $migrateeUser@$migrateeIP "ls -lR $domainDiskDir | grep total" 2>&1`
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
$sshNoPass $migrateeUser@$migrateeIP "mount -t nfs $localIp:$domainDiskDir $domainDiskDir" 2> /dev/null
if [ $? -eq 0 ];then
	echo "Mount is successful!"
else
	echo "Mount fails!"
	exit 1
fi

# Change libvirtd.conf and xend-config.sxp on both source and destination.
if [ $hyperType == "xen" ]; then
	#change libvirtd configuration file
	cp /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.org
	sed -i '/listen_tcp =/c listen_tcp = 1' /etc/libvirt/libvirtd.conf
	sed -i '/auth_tcp =/c auth_tcp = "none"' /etc/libvirt/libvirtd.conf
	#echo "checking content...."
	#cat /etc/libvirt/libvirtd.conf | grep "listen_tcp"
        #cat /etc/libvirt/libvirtd.conf | grep "auth_tcp"
	rclibvirtd restart
	if [[ $? != 0 ]];then
		echo "Source libvirtd change configuration failed!\n"
		cleanup
		exit 1
	fi
	$sshNoPass $migrateeUser@$migrateeIP "cp /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.org" 2>/dev/null
	$sshNoPass $migrateeUser@$migrateeIP "sed -i '/listen_tcp =/c listen_tcp = 1' /etc/libvirt/libvirtd.conf" 2>/dev/null
	$sshNoPass $migrateeUser@$migrateeIP "sed -i '/auth_tcp =/c auth_tcp = \"none\"' /etc/libvirt/libvirtd.conf" 2>/dev/null
        #echo "checking content...."
        #$sshNoPass $migrateeUser@$migrateeIP 'cat /etc/libvirt/libvirtd.conf | grep "listen_tcp"' 2>/dev/null
        #$sshNoPass $migrateeUser@$migrateeIP 'cat /etc/libvirt/libvirtd.conf | grep "auth_tcp"' 2>/dev/null
	$sshNoPass $migrateeUser@$migrateeIP "rclibvirtd restart" 2>/dev/null
	if [[ $? != 0 ]];then
		echo "Destination libvirtd change configuration failed!\n"
		cleanup
		exit 1
	fi	

	#change xend configuration file
	cp /etc/xen/xend-config.sxp /etc/xen/xend-config.sxp.org
	fileName=/etc/xen/xend-config.sxp
	sed -i "/(xend-port .*)/c \(xend-port 8000\)" $fileName
	sed -i "/(xend-relocation-port .*)/c \(xend-relocation-port 8002\)" $fileName
	sed -i "/xend-address .*)/c \(xend-address ''\)" $fileName
	sed -i "/(xend-relocation-address .*)/c \(xend-relocation-address ''\)" $fileName
	sed -i "/(xend-relocation-hosts-allow .*)/c \(xend-relocation-hosts-allow '')" $fileName
	sed -i "/(xend-relocation-server .*)/c \(xend-relocation-server yes\)" $fileName
	sed -i "/(xend-address localhost)/c #\(xend-address localhost\)" $fileName
	rcxend restart
	if [[ $? != 0 ]];then
		echo "Source xend configuration changes failed to take effect!\n"
		cleanup
		exit 1
        fi
	$sshNoPass $migrateeUser@$migrateeIP "cp /etc/xen/xend-config.sxp /etc/xen/xend-config.sxp.org" 2>/dev/null
	cat /etc/xen/xend-config.sxp | $sshNoPass $migrateeUser@$migrateeIP " cat - > /etc/xen/xend-config.sxp" 2>/dev/null
	$sshNoPass $migrateeUser@$migrateeIP "rcxend restart" 2>/dev/null
        if [[ $? != 0 ]];then
                echo "Destination xend configuration changes failed to take effect!\n"
                cleanup
                exit 1
        fi
fi


echo
echo "		----------------------"
echo "		---  VM MIGRATING  ---"
echo "		----------------------"
echo

# implement migration
migrateRound=`expr $migrateTimes / 2`
migrateCmd="virsh migrate"
if [ -n $livemigration ]; then
	migrateCmd=$migrateCmd" --live"
fi
if [ $hyperType == "xen" ]; then
	migrateCmd=$migrateCmd" $domUname xen+ssh://IP/ xenmigr://IP"
else
	migrateCmd=$migrateCmd" --unsafe $domUname qemu+ssh://IP/system tcp://IP"
fi
migrateCmdSrc=${migrateCmd//IP/$migrateeIP}
migrateCmdDst=${migrateCmd//IP/$localIp}
echo "Migrate command executed on source is $migrateCmdSrc"
echo "Migrate command executed on destination is $migrateCmdDst"
#read contd
for ((i=0;i<$migrateRound;i++)); do
	echo
	echo "		---- roundtrip migration ----"
	echo
	echo "		---- migration forward  $((i+1)) times ----"
	echo "		From: $localIp..."
	echo "		To: $migrateeIP..."
	echo "		VMName: $domUname..."
	echo
	$migrateCmdSrc
        if [[ $? != 0 ]];then
		echo "Migration forward failed!"
                cleanup
                exit 1
        fi
	echo "		---- migration back $((i+1)) times ----"
	echo "		From: $migrateeIP..."
	echo "		To: $localIp..."
	echo "		VMName: $domUname..."
	echo
	$sshNoPass $migrateeUser@$migrateeIP "$migrateCmdDst" 2>/dev/null
        if [[ $? != 0 ]];then
		echo "Migration back failed!"
                cleanup
                exit 1
        fi

	# Disconnect from remote
	$sshNoPass $migrateeUser@$migrateeIP "umount $domainDiskDir" 2>/dev/null
	$sshNoPass $migrateeUser@$migrateeIP "mount -t nfs $localIp:$domainDiskDir $domainDiskDir" 2> /dev/null
done

if [ `expr $migrateTimes % 2` -eq 1 ]; then
        echo
	echo "          ---- Migration times you choose is $migrateTimes ----"
        echo "          ---- final time for one way migration ---"
        echo
        echo "          From: $localIp..."
        echo "          To: $migrateeIP..."
        echo "          VMName: $domUname..."
	$migrateCmdSrc
	if [[ $? != 0 ]];then
        	echo "Migration forward failed!"
              	cleanup
                exit 1
        fi  
fi

#cleanup for successful migration if finally the domain is till on source host
if [ `expr $migrateTimes % 2` -eq 0 ]; then
	cleanup
	exit 0
fi

#success migration
recoverVirtConfig
trap - SIGINT
echo
echo "		----------------------"
echo "		---  MIGRATE DONE  ---"
echo "		----------------------"
echo
exit 0
