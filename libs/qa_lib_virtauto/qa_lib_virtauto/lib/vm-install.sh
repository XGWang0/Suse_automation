#!/bin/bash

export LANG=C

sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"
getSettings="./get-settings.sh"
getSource="./get-source.sh"
autoInstallation="../data/autoinstallation"

dirname=`dirname $0`
pushd $dirname > /dev/null
currentHostName=`hostname`

# Standard QA return values
rPASSED=0
rFAILED=1
rERROR=11
rSKIPPED=22

print_usage()
{
	echo "Usage: $0 --help -h -help | -y -M -T -o -r -p -c -t -n -m -e -x -s -d -a -i -z -g -P -F -N -I -H -D -S -C -R -l"
	echo "Options: "
	echo " -h,-help,--help - Prints the full usage"
	echo " -y <hostIp>"
	echo " -M <xenMigratee>"
	echo " -T <timesToMigrate>"
	echo " -o <operatingSystem>"
	echo " -r <release>"
	echo " -p <servicePack>"
	echo " -c <architecture>"
	echo " -t <virtualizationType>"
	echo " -n <installScenario>"
	echo " -m <installMethod>"
	echo " -e <machineMemory>"
	echo " -x <machineMaxMemory>"
	echo " -s <machineProcessors>"
	echo " -d <machineDiskSizes>"
	echo " -D <machineDiskStorages>"
	echo " -L <machineDiskStorageLocations>"
	echo " -S <machineIsoStorage>"
	echo " -a <machineNicAddresses>"
	echo " -i <machineIpAddresses>"
	echo " -z (for just printing out vm-install command)"
	echo " -g (for keeping VM after install)"
	echo " -P <settingsFile>"
	echo " -Q <sourcesFile>"
	echo " -N <nameAddition>"
	echo " -F <fullVmName>"
	echo " -I <idOfInstall>"
	echo " -H <hostName>"
	echo " -Z <hyperviZor>"
	echo " -b <bridge>"
	echo " -C (copy iso image to /tmp)"
	echo " -R (will implement save and Restore)"
	echo " -l (live migration, take effect only if -M is set)"
	echo " -A <url of autoinstallation profile>"
	echo " -f <url of installation repository (install *f*rom)>"
	echo " -O <custom boot option used for install>"
	popd > /dev/null; exit $rERROR
}

print_full_usage()
{
	echo "Purpose: This program will get rid of a VM on a host (if necessary) and kick off a new, fully-automated VM install"
	echo
	echo "Usage: $0 --help -h -help | -y -M -T -o -r -p -c -t -n -m -e -x -s -d -a -i -z -g -P -N -F -I -H -D -S"
	echo
	echo "Options: "
	echo
	echo " -h,-help,--help"
	echo "        - Prints this full usage message"
	echo
	echo " -y <hostIp>"
	echo "        - The IP address of the xen host that this VM will be installed on"
	echo "        - DEFAULT: 127.0.0.1 (localhost)"
	echo "        - EXAMPLE: 10.10.10.10"
	echo
	echo " -M <xenMigratee>"
	echo "        - The IP address of the xen host that this VM will migrate to"
	echo "        - Note that you need to have the xen hosts set up for migrations"
	echo "        - DEFAULT: if you leave this blank, migration will not be attempted"
	echo
	echo " -T <timesToMigrate>"
	echo "        - If you are doing a migration, the number of times to migrate"
	echo "        - Note that you need to have the xen hosts set up for migrations and you need to have migration enabled (with -M)"
	echo "        - If you want to migrate infinitely, then please set 0 for this value. Note that this install script will not be able to terminate as a result"
	echo "        - DEFAULT: if you leave this out, 2 migrations will be done (once there and once back)"
	echo
	echo " -o <operatingSystem>"
	echo "        - The guest operating system that you want to install"
	echo "        - The supported operating systems are: nw, oes, rhel, sled, sles, win, os"
	echo "        - DEFAULT: sles"
	echo
	echo " -r <release>"
	echo "        - The release number of the operating system you want to install"
	echo "        - This number should be numeric (no special characters like periods, underscores or hyphens)"
	echo "        - DEFAULT: 10"
	echo "        - EXAMPLE: For NetWare 6.5 put '65', for SLES 10 put '10', for RHEL 4 put '4'"
	echo
	echo " -p <servicePack>"
	echo "        - The service pack tag for this operating system and release"
	echo "        - This number depends on the directory structure of the auto-installation files"
	echo "        - DEFAULT: sp1"
	echo "        - EXAMPLE: For NetWare 6.5 SP8, put 'sp8', for RHEL 4 Update 4, put 'u4', for SLES 10 GMC, put 'fcs'"
	echo
	echo " -c <architecture>"
	echo "        - The architecture of the guest that you are installing"
	echo "        - Must be any one of the following: for 32 bit, '32', for 32 bit pae, '32p', for 64 bit '64'"
	echo "        - DEFAULT: 32"
	echo
	echo " -t <virtualizationType>"
	echo "        - The type of virtualization to be used"
	echo "        - For paravirtualization, use 'pv', for full virtualization, use 'fv'"
	echo "        - DEFAULT: pv"
	echo
	echo " -n <installScenario>"
	echo "        - The install scenario (or version of auto-installation file to use)"
	echo "        - Generally, 'def' will define the standard auto-installation file"
	echo "        - If you want the shm for Windows 2008 or Vista, then this must begin with 'shm'"
	echo "        - Other options include 'nnm' (for SLED) and 'min' (for SLES 10 SP1, which generally will define a very minimal install)"
	echo "        - DEFAULT: def"
	echo
	echo " -m <installMethod>"
	echo "        - The method to use for installation"
	echo "        - The options are 'net', 'ftp', 'http' and 'nfs' (for network) and 'iso' (for ISO installs)"
	echo "        - ISO is the same for both para and fully-virtualized installs"
	echo "        - For paravirtualized installs, network sources install directly from a network path"
	echo "        - For fully-virtualized installs, network sources require a PXE boot"
	echo "        - DEFAULT: net (which defaults to ftp, if it't not available, uses http)"
	echo
	echo " -e <machineMemory>"
	echo "        - The amount of memory (in MB) to use for the VM"
	echo "        - DEFAULT: whatever vm-install decides is the default for the VM's operating system"
	echo
	echo " -x <machineMaxMemory>"
	echo "        - The maximum amount of memory (in MB) to use for the VM"
	echo "        - DEFAULT: whatever vm-install decides is the default for the VM's operating system"
	echo
	echo " -s <machineProcessors>"
	echo "        - The number of virtual processors to use for the VM"
	echo "        - DEFAULT: whatever vm-install decides (most likely 1)"
	echo
	echo " -d <machineDiskSizes>"
	echo "        - The size of the disks (in MB) that you want installed"
	echo "        - This is an underscore-separated list of disks. The number of entries that you provide will determine the number of disks."
	echo "        - If you want vm-install to pick a default for a particular disk, simply put '.' for that entry"
	echo "        - DEFAULT: Will use 1 disk with the recommended size by vm-install"
	echo "        - EXAMPLE: -d 4096_1024_._8192 (four disks, the third is default size)"
	echo "        - EXAMPLE: -d . (one disk, size is default; this is the same as putting nothing)"
	echo
	echo " -D <machineDiskStorages>"
	echo "        - The storage type associated with the disks"
	echo "        - This is an underscore-separated list of vm-install supported storage types. The number of entries that you provide must match the number of disks."
	echo "        - If you leave any particular disk type as '.', then vm-install will just be given the disk path with no type"
	echo "        - The valid disk storages are: ., file, iscsi, nbd, npiv, phy, tap:aio, tap:qcow, tap:qcow2 and vmdk"
	echo "        - DEFAULT: Will use no prefix"
	echo "        - EXAMPLE: -D ._phy_tap:qcow_tap:aio (storage types to match the 4 given disks)"
	echo "        - EXAMPLE: -D . (no prefix for the one disk in the system)"
	echo
	echo " -L <machineDiskStorageLocations>"
	echo "        - The storage locations for the disks"
	echo "        - This is an underscore-separated list of paths. The number of entries that you provide must match the number of disks."
	echo "        - If you leave any particular disk storage location as '.', then the default /var/lib/<hypervisor>/xen/images will be used"
	echo "        - DEFAULT: /var/lib/<hypervisor>/images"
	echo "        - EXAMPLE: -L ._/dev/sdb_/dev/system/vm (storage locations to match the 3 given disks)"
	echo "        - EXAMPLE: -L . (no specified location for the one disk in the system)"
	echo
	echo " -S <machineIsoStorage>"
	echo "        - The storage type associated with the iso for the install"
	echo "        - This is a storage type prefix, and must only be used if the install method is 'iso'"
	echo "        - If you leave this as '.', then vm-install will just be given the path to the iso with no type"
	echo "        - The valid iso storages are: ., file, iscsi, nbd, npiv, phy, tap:aio, tap:qcow, tap:qcow2 and vmdk"
	echo "        - DEFAULT: Will use no prefix"
	echo "        - EXAMPLE: -S tap:qcow (storage type for the iso)"
	echo
	echo " -a <machineNicAddresses>"
	echo "        - The MAC addresses of the NICs that you want installed"
	echo "        - This is an underscore-separated list of MAC addresses. The number of entries will determine the number of disks."
	echo "        - If you want vm-install to pick a default for a particular NIC, simply put '.' for that entry"
	echo "        - DEFAULT: 1 nic with a randomly generated MAC"
	echo "        - EXAMPLE: -a 00:16:3e:ff:60:01_00:16:3e:ff:60:02_._00:16:3e:ff:60:03"
	echo "        - EXAMPLE: -a . (one NIC, MAC is default; this is the same as putting nothing)"
	echo
	echo " -i <machineIpAddresses>"
	echo "        - The IP addresses to match those nics"
	echo "        - This is an underscore-separated list of IP addresses. The number must match the number of nics entered."
	echo "        - The first IP address provided is assumed to be the default, and is used in the VM name and tree (if applicable)"
	echo "        - If the first IP address is '.', random strings will be used in the VM name and tree"
	echo "        - If you want certain ip addresses to be set by DHCP, simply put '.' for that entry"
	echo "        - DEFAULT: will set enough IPs to handle the nics that were given"
	echo "        - EXAMPLE: -a 10.10.10.10_10.10.10.11_._10.10.10.12"
	echo "        - EXAMPLE: -a . (one IP, DHCP; this is the same as putting nothing)"
	echo
	echo " -z"
	echo "        - Provide this option only if you do not actually want to install the VM, just see the vm-install command"
	echo "        - DEFAULT: Actually install"
	echo
	echo " -g"
	echo "        - Provide this option if you DO NOT want the VM removed after it is done installing"
	echo "        - DEFAULT: Remove the VM"
	echo 
	echo " -P <settingsFile>"
	echo "        - The path and name of the settings file to use."
	echo "        - This can be a fully qualified or relative path."
	echo "        - The file must exist."
	echo "        - DEFAULT: ../data/settings.local, if it does not exists, ../data/settings.<location>"
	echo "        - EXAMPLE: -P ../path/settingsfile.properties"
	echo
	echo " -Q <sourcesFile>"
	echo "        - The path and name of the sources file to use."
	echo "        - This can be a fully qualified or relative path."
	echo "        - The file must exist."
	echo "        - DEFAULT: ../data/sources.local, if it does not exists, ../data/sources.<location>"
	echo "        - EXAMPLE: -P ../path/sourcesfile.properties"
	echo
	echo " -N <nameAddition>"
	echo "        - What to add onto the end of the guest name, instead of the random letters and numbers."
	echo "        - Must be between 1 and 7 characters (letters, numbers or hyphens)."
	echo "        - DEFAULT: if you are doing dynamic IP, it will assign random values; otherwise, your ip will be assigned"
	echo "        - EXAMPLE: -N mybox"
	echo
	echo " -F <fullVmName>"
	echo "        - Replaces the entire name of the virtual machine with what this string provides."
	echo "        - Must be between 1 and 35 characters (letters, numbers, underscores or hyphens)."
	echo "        - DEFAULT: if you are doing dynamic IP, it will assign random values; otherwise, your ip will be assigned"
	echo "        - EXAMPLE: -F this-is-my-guest"
	echo
	echo " -I <installId>"
	echo "        - This is the database ID of this instance of vm-install so that status updates can be sent back."
	echo "        - Must be between 1 and 7 digits."
	echo "        - This is only useful if it is automatically passed in from the D-Ploy tool. Passing it in manually will likely have no effect."
	echo "        - DEFAULT: Without this parameter, status updates will not be sent back."
	echo "        - EXAMPLE: -I 17"
	echo
	echo " -H <hostName>"
	echo "        - The network host name for the virtual machine."
	echo "        - Must be between 2 and 10 letters, numbers, hyphens or digits."
	echo "        - DEFAULT: Uses the VM name itself."
	echo "        - EXAMPLE: -H bob"
	echo
	echo " -Z <hyperviZor>"
	echo "        - The hypervisor used."
	echo "        - Allowed values auto (autodetection), kvm, xen."
	echo "        - DEFAULT: auto"
	echo "        - EXAMPLE: -Z kvm"
	echo
	echo " -b <bridge>"
	echo "        - The bridge used for VM networking."
	echo "        - DEFAULT: let the vm-install decide"
	echo "        - EXAMPLE: -b br1"
	echo
	echo " -C"
	echo "        - Copy iso image to /tmp before the installation starts and delete it when the installation ends"
	echo "          This is to avoid the bug when installation of pv domU sometimes fail when iso is on nfs storage"
	echo "        - DEFAULT: not set"
	echo "        - EXAMPLE: -C"
	echo
	echo " -R"
	echo "        - The installed VM will implement save and Restore function."
	echo "        - DEFAULT: not set"
	echo "        - EXAMPLE: -R"
	echo
	echo " -l"
	echo "        - live migration, take effect only if -M is set"
	echo "        - DEFAULT: not set"
	echo "        - EXAMPLE: -l"
	echo
	echo " -A <url of autoinstallation profile>"
	echo "        - URL of autonstallation profile that should be used instead of the general one"
	echo "          This profile must be correct type for the system which is to be installed (not checked!)"
	echo "        - DEFAULT: not set"
	echo "        - EXAMPLE: -A 'http://10.20.1.229/autoinst/autoinst_vm_12527.xml'"
	echo
	echo " -f <url of installation repository (install *f*rom)>"
	echo "        - URL of installation repository which should be used instead of the default one"
	echo "          This repository must be correct repository for the system which is to be installed (not checked!)"
	echo "        - DEFAULT: not set"
	echo "        - EXAMPLE: -f 'http://fallback.suse.cz/install/SLP/SLE-11-SP1-SDK-GM/x86_64/DVD1'"
	echo
	echo " -O <custom boot option used for install>"
	echo "        - custom boot option added to the installation"
	echo "        - DEFAULT: not set"
	echo "        - EXAMPLE: -o 'vnc=1 vncpassword=12345678'"
	echo
	echo " -E"
	echo "        - implement performance test"
	echo "        - DEFAULT: not set"
	echo "        - EXAMPLE: -E"
	echo
	echo "Examples:"
	echo "        $0 -y 10.10.10.10 -o sles -r 10 -p sp1 -c 32 -t pv -n def -m net -e 512 -x 4096 -s 1 -d 4096 -a 00:16:3e:ff:60:01 -i 151.155.146.1"
	popd > /dev/null; exit $rERROR
}

# Do cleanup on sigint
function interrupt
{
	trap '' SIGINT
	echo "Interrupted - destroying the vm if exist and exiting with ERROR" >&2

	# delete the domU
	./vm-gone.sh "$xenHostIp" "$hypervisor" "$machineName" "$machineNameFirstPart" "$machineIp" "$settingsFile"

	# delete the temp files
	rm -fr  /tmp/virtautolib.$$

	trap - SIGINT
	exit $rERROR
}
trap interrupt SIGINT



if [ $# -eq 1 ]
then
	if [ "${1}" == "--help" ] || [ "${1}" == "-help" ] || [ "${1}" == "-h" ]
	then
		print_full_usage
		popd > /dev/null; exit $rERROR
	fi
fi

if ! which xpath > /dev/null 2> /dev/null 
then
	tmp_error="Required command xpath not found in PATH. Is perl-XML-XPath installed?"
	echo "ERROR - $tmp_error"
	echo "ERROR - $tmp_error" >&2
	popd > /dev/null; exit $rERROR
fi

echo
echo "    ------------------"
echo "    --- vm-install ---"
echo "    ------------------"
echo

### COMMAND LINE ###

# Defaults we provide
operatingSystem=sles
release=10
servicePack=sp1
architecture=32
virtType=pv
installScenario=def
installMethod=net
machineIsoStorage=
reallyInstall=YES
removeInstall=YES
INmachineDiskSizes=.
INmachineDiskStorages=.
INmachineDiskStorageLocations=.
originalINmachineDiskSizes=
originalINmachineDiskStorages=
originalINmachineDiskStorageLocations=
newINmachineDiskSizes=
newINmachineDiskStorages=
newINmachineDiskStorageLocations=
INmachineNicAddresses=.
INmachineIpAddresses=.
xenMigratee=
timesToMigrate=2
nameAddition=
newFullName=
installId=0
hostName=
hypervisor=auto
xenHostIp='127.0.0.1'
copyIsoToTmp=
autoinstProfile=
instRepository=
customInstallBootOption=

# Defaults vm-install provides
machineProcessors=
machineMemory=
machineMaxMemory=
bridge=

while getopts "y:M:T:o:r:p:c:Ct:n:m:e:x:s:d:a:i:P:Q:N:F:H:I:D:L:S:zgZ:b:RlA:f:O:E" OPTIONS
do
	case $OPTIONS in
		y) xenHostIp="$OPTARG";;
		M) xenMigratee="$OPTARG";;
		T) timesToMigrate="$OPTARG";;
		o) operatingSystem="$OPTARG";;
		r) release="$OPTARG";;
		p) servicePack="$OPTARG";;
		c) architecture="$OPTARG";;
		C) copyIsoToTmp=1;;
		t) virtType="$OPTARG";;
		n) installScenario="$OPTARG";;
		m) installMethod="$OPTARG";;
		e) machineMemory="$OPTARG";;
		x) machineMaxMemory="$OPTARG";;
		s) machineProcessors="$OPTARG";;
		d) INmachineDiskSizes="$OPTARG"; newINmachineDiskSizes="$OPTARG";;
		D) INmachineDiskStorages="$OPTARG"; newINmachineDiskStorages="$OPTARG";;
		L) INmachineDiskStorageLocations="$OPTARG"; newINmachineDiskStorageLocations="$OPTARG";;
		S) machineIsoStorage="$OPTARG";;
		a) INmachineNicAddresses="$OPTARG";;
		i) INmachineIpAddresses="$OPTARG";;
		P) settingsFile="$OPTARG";;
		Q) sourcesFile="$OPTARG";;
		N) nameAddition="$OPTARG";;
		F) newFullName="$OPTARG";;
		H) hostName="$OPTARG";;
		I) installId="$OPTARG";;
		z) reallyInstall=NO;;
		g) removeInstall=NO;;
		Z) hypervisor="$OPTARG";;
		b) bridge="$OPTARG";;
		R) vmSaveRestore=YES;;
		l) liveMigration=YES;;
		A) autoinstProfile="$OPTARG";;
		f) instRepository="$OPTARG";;
		O) customInstallBootOption="$OPTARG";;
		E) performanceTest=YES;;
		\?) echo "ERROR - Invalid parameter"; echo "ERROR - Invalid parameter" >&2; print_usage; popd > /dev/null; exit $rERROR;;
		*) echo "ERROR - Invalid parameter"; echo "ERROR - Invalid parameter" >&2; print_usage; popd > /dev/null; exit $rERROR;;
	esac
done

[ -z $settingsFile ] || getSettings="./get-settings.sh -s ${settingsFile}"
[ -z $sourcesFile ] || getSource="./get-source.sh -s ${sourcesFile}"

if [ ! -e ${settingsFile} ]
then
	tmpError="'${settingsFile}' doesn't exist. (Use --help to see formatting)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Cannot specify name addition and full name
if [ "$nameAddition" != "" ] && [ "$newFullName" != "" ]
then
	tmpError="You cannot use a name addition and specify a VM name at the same time"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

if ! echo "$nameAddition" | grep -q '^[a-zA-Z0-9-]\{1,7\}$' && [ "$nameAddition" != "" ]
then
	tmpError="Invalid name addition (between 1 and 7 letters, numbers, or hyphens are allowed; use --help to see formatting)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

if ! echo "$hostName" | grep -q '^[a-zA-Z0-9-]\{2,10\}$' && [ "$hostName" != "" ]
then
	tmpError="Invalid hostname (between 2 and 10 letters, numbers, or hyphens are allowed; use --help to see formatting)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

if ! echo "$newFullName" | grep -q '^[_a-zA-Z0-9-]\{1,35\}$' && [ "$newFullName" != "" ]
then
	tmpError="Invalid VM name (between 1 and 35 letters, numbers, underscores or hyphens are allowed; use --help to see formatting)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

if ! echo "$installId" | grep -q '^[0-9]\{1,7\}$' && [ "$installId" != "0" ]
then
	tmpError="Invalid install ID"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Split up the disk sizes
declare -a machineDiskSizes
counter=0
position=`echo $(expr index "$INmachineDiskSizes" _)`
if [ $position -eq 0 ]
then
        machineDiskSizes[0]=$INmachineDiskSizes
		if [[ ! "$INmachineDiskSizes" =~ ^[[:digit:]][[:digit:]]*$ ]] && [ "$INmachineDiskSizes" != "." ] || [ "$INmachineDiskSizes" == "0" ]
		then
			tmpError="Disk size parsing, ($INmachineDiskSizes) badly formatted (Use --help to see formatting)"
			echo "ERROR - $tmpError"
			echo "ERROR - $tmpError" >&2
			print_usage
		fi
else
        while [ "$INmachineDiskSizes" != "" ]
        do
                val=${INmachineDiskSizes%%_*}
                machineDiskSizes[$counter]=$val
				if [[ ! "$val" =~ ^[[:digit:]][[:digit:]]*$ ]] && [ "$val" != "." ] || [ "$val" == "0" ]
				then
					tmpError="Disk size parsing, ($val) badly formatted (Use --help to see formatting)"
					echo "ERROR - $tmpError"
					echo "ERROR - $tmpError" >&2
					print_usage
				fi
				INmachineDiskSizes=${INmachineDiskSizes#*_}
                let "counter = $counter + 1"

                # See if we need to stop
                position=`echo $(expr index "$INmachineDiskSizes" _)`
                if [ $position -eq 0 ]
                then
                        machineDiskSizes[$counter]=$INmachineDiskSizes
		                if [[ ! "$INmachineDiskSizes" =~ ^[[:digit:]][[:digit:]]*$ ]] && [ "$INmachineDiskSizes" != "." ] || [ "$INmachineDiskSizes" == "0" ]
						then
							tmpError="Disk size parsing, ($INmachineDiskSizes) badly formatted (Use --help to see formatting)"
							echo "ERROR - $tmpError"
							echo "ERROR - $tmpError" >&2
							print_usage
						fi
                        break
                fi
        done
fi

# Split up the disk storages
declare -a machineDiskStorages
counter=0
# This means that they did not pass in any machine disk storages, so we will make them all "."
if [ "$originalINmachineDiskStorages" == "$newINmachineDiskStorages" ]
then
	# We will set them all as default, with the same number as the disk sizes, based on the disk sizes that were declared above
	for i in ${machineDiskSizes[@]}
	do
		machineDiskStorages[$counter]=.
		let "counter = $counter + 1"
	done
# This means that they did pass in some machine disk storages
else
	position=`echo $(expr index "$INmachineDiskStorages" _)`
	# This means that there is only one disk storage, not multiple (which would be handled in the else case below)
	if [ $position -eq 0 ]
	then
	        machineDiskStorages[0]=$INmachineDiskStorages
	        # So, then this checks if (since we only have one storage) it is valid (i.e. that it is either default (.) or one of the supported types)
			if [ "$INmachineDiskStorages" != "file" ] && [ "$INmachineDiskStorages" != "iscsi" ] && [ "$INmachineDiskStorages" != "nbd" ] && [ "$INmachineDiskStorages" != "npiv" ] && [ "$INmachineDiskStorages" != "phy" ] && [ "$INmachineDiskStorages" != "tap:aio" ] && [ "$INmachineDiskStorages" != "tap:qcow" ] && [ "$INmachineDiskStorages" != "tap:qcow2" ] && [ "$INmachineDiskStorages" != "vmdk" ] && [ "$INmachineDiskStorages" != "." ]
			then
				tmpError="Disk storage parsing, ($INmachineDiskStorages) badly formatted (Use --help to see formatting)"
				echo "ERROR - $tmpError"
				echo "ERROR - $tmpError" >&2
				print_usage
			fi
	# This means that there is not just one disk storage, so we need to parse and check them all
	else
	        while [ "$INmachineDiskStorages" != "" ]
	        do
	                val=${INmachineDiskStorages%%_*}
	                machineDiskStorages[$counter]=$val
					if [ "$val" != "file" ] && [ "$val" != "iscsi" ] && [ "$val" != "nbd" ] && [ "$val" != "npiv" ] && [ "$val" != "phy" ] && [ "$val" != "tap:aio" ] && [ "$val" != "tap:qcow" ] && [ "$val" != "tap:qcow2" ] && [ "$val" != "vmdk" ] && [ "$val" != "." ]
					then
						tmpError="Disk storage parsing, ($val) badly formatted (Use --help to see formatting)"
						echo "ERROR - $tmpError"
						echo "ERROR - $tmpError" >&2
						print_usage
					fi
					INmachineDiskStorages=${INmachineDiskStorages#*_}
	                let "counter = $counter + 1"
	
	                # See if we need to stop
	                position=`echo $(expr index "$INmachineDiskStorages" _)`
	                if [ $position -eq 0 ]
	                then
	                        machineDiskStorages[$counter]=$INmachineDiskStorages
							if [ "$INmachineDiskStorages" != "file" ] && [ "$INmachineDiskStorages" != "iscsi" ] && [ "$INmachineDiskStorages" != "nbd" ] && [ "$INmachineDiskStorages" != "npiv" ] && [ "$INmachineDiskStorages" != "phy" ] && [ "$INmachineDiskStorages" != "tap:aio" ] && [ "$INmachineDiskStorages" != "tap:qcow" ] && [ "$INmachineDiskStorages" != "tap:qcow2" ] && [ "$INmachineDiskStorages" != "vmdk" ] && [ "$INmachineDiskStorages" != "." ]
							then
								tmpError="Disk storage parsing, ($INmachineDiskStorages) badly formatted (Use --help to see formatting)"
								echo "ERROR - $tmpError"
								echo "ERROR - $tmpError" >&2
								print_usage
							fi
	                        break
	                fi
	        done
	fi
fi

# Split up the disk storage locations
declare -a machineDiskStorageLocations
counter=0
# This means that they did not pass in any machine disk storage locations, so we will make them all "."
if [ "$originalINmachineDiskStorageLocations" == "$newINmachineDiskStorageLocations" ]
then
	# We will set them all as default, with the same number as the disk sizes, based on the disk sizes that were declared above
	for i in ${machineDiskSizes[@]}
	do
		machineDiskStorageLocations[$counter]=.
		let "counter = $counter + 1"
	done
# This means that they did pass in some machine disk storage locations
else
	position=`echo $(expr index "$INmachineDiskStorageLocations" _)`
	# This means that there is only one disk storage locations, not multiple (which would be handled in the else case below)
	if [ $position -eq 0 ]
	then
	        machineDiskStorageLocations[0]=$INmachineDiskStorageLocations
	# This means that there is not just one disk storage location, so we need to parse and check them all
	else
	        while [ "$INmachineDiskStorageLocations" != "" ]
	        do
	                val=${INmachineDiskStorageLocations%%_*}
	                machineDiskStorageLocations[$counter]=$val
					INmachineDiskStorageLocations=${INmachineDiskStorageLocations#*_}
	                let "counter = $counter + 1"
	
	                # See if we need to stop
	                position=`echo $(expr index "$INmachineDiskStorageLocations" _)`
	                if [ $position -eq 0 ]
	                then
	                        machineDiskStorageLocations[$counter]=$INmachineDiskStorageLocations
							break
	                fi
	        done
	fi
fi

# Split up the disk sizes, nics and ip addresses
declare -a machineNicAddresses
counter=0
position=`echo $(expr index "$INmachineNicAddresses" _)`
if [ $position -eq 0 ]
then
        machineNicAddresses[0]=$INmachineNicAddresses
		if ! echo "$INmachineNicAddresses" | grep -q  '^[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]$' && [ "$INmachineNicAddresses" != "." ]
		then
			tmpError = "MAC address parsing, ($INmachineNicAddresses) badly formatted (Use --help to see formatting)"
			echo "ERROR - $tmpError"
			echo "ERROR - $tmpError" >&2
			print_usage
		fi
else
        while [ "$INmachineNicAddresses" != "" ]
        do
                val=${INmachineNicAddresses%%_*}
                machineNicAddresses[$counter]=$val
				if ! echo "$val" | grep -q '^[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]$' && [ "$val" != "." ]
				then
					tmpError="MAC address parsing, ($val) badly formatted (Use --help to see formatting)"
					echo "ERROR - $tmpError"
					echo "ERROR - $tmpError" >&2
					print_usage
				fi
				INmachineNicAddresses=${INmachineNicAddresses#*_}
                let "counter = $counter + 1"

                # See if we need to stop
                position=`echo $(expr index "$INmachineNicAddresses" _)`
                if [ $position -eq 0 ]
                then
                        machineNicAddresses[$counter]=$INmachineNicAddresses
		                if ! echo "$INmachineNicAddresses" |grep -q '^[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]$' && [ "$INmachineNicAddresses" != "." ]
						then
							tmpError="MAC address parsing, ($INmachineNicAddresses) badly formatted (Use --help to see formatting)"
							echo "ERROR - $tmpError"
							echo "ERROR - $tmpError" >&2
							print_usage
						fi
                        break
                fi
        done
fi

# Split up the disk sizes, nics and ip addresses
declare -a machineIpAddresses
counter=0
position=`echo $(expr index "$INmachineIpAddresses" _)`
if [ $position -eq 0 ]
then
        machineIpAddresses[0]=$INmachineIpAddresses
		if [[ ! "$INmachineIpAddresses" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]] && [ "$INmachineIpAddresses" != "." ]
		then
			tmpError="IP address parsing, ($INmachineIpAddresses) badly formatted (Use --help to see formatting)"
			echo "ERROR - $tmpError"
			echo "ERROR - $tmpError" >&2
			print_usage
		fi
else
        while [ "$INmachineIpAddresses" != "" ]
        do
                val=${INmachineIpAddresses%%_*}
                machineIpAddresses[$counter]=$val
				if [[ ! "$val" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]] && [ "$val" != "." ]
				then
					tmpError="IP address parsing, ($val) badly formatted (Use --help to see formatting)"
					echo "ERROR - $tmpError"
					echo "ERROR - $tmpError" >&2
					print_usage
				fi
				INmachineIpAddresses=${INmachineIpAddresses#*_}
                let "counter = $counter + 1"

                # See if we need to stop
                position=`echo $(expr index "$INmachineIpAddresses" _)`
                if [ $position -eq 0 ]
                then
                        machineIpAddresses[$counter]=$INmachineIpAddresses
		                if [[ ! "$INmachineIpAddresses" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]] && [ "$INmachineIpAddresses" != "." ]
						then
							tmpError="IP address parsing, ($INmachineIpAddresses) badly formatted (Use --help to see formatting)"
							echo "ERROR - $tmpError"
							echo "ERROR - $tmpError" >&2
							print_usage
						fi
                        break
                fi
        done
fi

#for i in ${machineNicAddresses[@]}
#do
#	echo "___${i}___"
#done
#exit 1

### PROPERTIES FILE ###

dhcpReservedPool=`$getSettings dhcp.reserved.pool`
dhcpReservedPool=${dhcpReservedPool//:/ }

httpServer=`$getSettings http.ip`
httpUser=`$getSettings http.user`
httpPass=`$getSettings http.pass`
httpAutoyastWeb=`$getSettings http.autoyast.web`
httpAutoyastLocal=`$getSettings http.autoyast.local`

netinfoServer=`$getSettings netinfo.ip`
netinfoUser=`$getSettings netinfo.user`
netinfoPass=`$getSettings netinfo.pass`

pxeServer=`$getSettings pxe.ip`
pxeUser=`$getSettings pxe.user`
pxePass=`$getSettings pxe.pass`

xenUser=`$getSettings xen.user`
xenPass=`$getSettings xen.pass`

netMask=`$getSettings network.mask`
netGateway=`$getSettings network.gateway`
netNameServer=`$getSettings network.nameserver`
netNetwork=`$getSettings network.network`
netBcast=`$getSettings network.bcast`
netDomain=`$getSettings network.domain`

#echo "...${machineNicAddresses[@]}..."
#exit 1

### INITIAL CHECK ###

case "$hypervisor" in
	kvm)
	;;

	xen)
	;;

	auto)
		if export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenHostIp "uname -r" | grep -q '\-xen' 2> /dev/null ; then
			hypervisor=xen
		elif export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenHostIp "ls /dev/kvm" 2> /dev/null ; then
			hypervisor=kvm
		else
			tmpError="Unable to detect hypervisor: nor XEN neither KVM detected!"
			echo "ERROR - $tmpError"
			echo "ERROR - $tmpError" >&2
			exit $rERROR
		fi
	;;

	*)
		tmpError="Incorecct hypervisor entered, ($hypervisor). (Use --help to see allowed values)"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	;;
esac

# Make sure that bridge exist
[ "$bridge" != "" ] && if ! ifconfig "$bridge" > /dev/null 2>&1 
then
	tmpError="Network bridge ($bridge) does not exist in the system."
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Make sure that a xen host ip was provided and is of the correct format
if [[ ! "$xenHostIp" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]]
then
	tmpError="Xen Host IP ($xenHostIp) badly formatted (Use --help to see formatting)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Make sure that a http server ip was provided and is of the correct format
if [[ ! "$httpServer" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]]
then
	tmpError="DHCP server IP ($httpServer) is badly formatted (it needs to be a valid IP address)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Make sure that a netinfo server ip was provided and is of the correct format
if [[ ! "$netinfoServer" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]]
then
	tmpError="DHCP server IP ($netinfoServer) is badly formatted (it needs to be a valid IP address)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Make sure that a pxe server ip was provided and is of the correct format
if [[ ! "$pxeServer" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]]
then
	tmpError="DHCP server IP ($pxeServer) is badly formatted (it needs to be a valid IP address)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Make sure that a mask ip was provided and is of the correct format
if [[ ! "$netMask" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]]
then
	tmpError="Network mask ($netMask) is badly formatted (it needs to be a valid IP address)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Make sure that a gateway ip was provided and is of the correct format
if [[ ! "$netGateway" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]]
then
	tmpError="Gateway ($netGateway) is badly formatted (it needs to be a valid IP address)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Make sure that a nameserver ip was provided and is of the correct format
if [[ ! "$netNameServer" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]]
then
	tmpError="Network nameserver ($netNameServer) is badly formatted (it needs to be a valid IP address)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Make sure that a network ip was provided and is of the correct format
if [[ ! "$netNetwork" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]]
then
	tmpError="Network ($netNetwork) is badly formatted (it needs to be a valid IP address)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Make sure that a broadcast ip was provided and is of the correct format
if [[ ! "$netBcast" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]]
then
	tmpError="Network broadcast ($netBcast) is badly formatted (it needs to be a valid IP address)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Make sure that a domain name was provided and is of the correct format
if ! echo "$netDomain" | grep -q '^[a-zA-Z0-9.-]\{2,100\}$' 
then
	tmpError="Network domain ($netDomain) is badly formatted"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Make sure nics are of the correct format
for i in ${machineNicAddresses[@]}
do
	#if [ "$i" != "." ] && [ "$operatingSystem" != "oes" ]
	if [ "$i" != "." ]
	then
		#tmpError="Specified MAC addresses are not yet supported (except for oes)"
		tmpError="Specified MAC addresses are not yet supported"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		popd > /dev/null; exit $rERROR
	fi
	
	if ! echo "$i" | grep -q '^[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]$' && [ "$i" != "." ]
	then
		tmpError="MAC address ($i) badly formatted (Use --help to see formatting)"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	fi
done

# Make sure ips are of the correct format
for i in ${machineIpAddresses[@]}
do
#	if [ "$i" != "." ]
#	then
#		tmpError="Specified IP addresses are not yet supported"
#		echo "ERROR - $tmpError"
#		echo "ERROR - $tmpError" >&2
#		popd > /dev/null; exit 1
#	fi
	
	if [[ ! "$i" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]] && [ "$i" != "." ]
	then
		tmpError="IP address ($i) badly formatted (Use --help to see formatting)"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	fi
done

# Make sure disk sizes are of the correct format
for i in ${machineDiskSizes[@]}
do
	if [[ ! "$i" =~ ^[[:digit:]][[:digit:]]*$ ]] && [ "$i" != "." ] || [ "$i" == "0" ]
	then
		tmpError="Disk size ($i) badly formatted (Use --help to see formatting)"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	fi
done

# Make sure disk storages are of the correct format
for i in ${machineDiskStorages[@]}
do
	if [ "$i" != "file" ] && [ "$i" != "iscsi" ] && [ "$i" != "nbd" ] && [ "$i" != "npiv" ] && [ "$i" != "phy" ] && [ "$i" != "tap:aio" ] && [ "$i" != "tap:qcow" ] && [ "$i" != "tap:qcow2" ] && [ "$i" != "vmdk" ] && [ "$i" != "." ]
	then
		tmpError="Disk storage ($i) badly formatted (Use --help to see formatting)"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	fi
done

# Make sure the # of ips equals the # of MAC addresses
numberOfNicAddresses=${#machineNicAddresses[@]}
numberOfIpAddresses=${#machineIpAddresses[@]}
if [ $numberOfNicAddresses -ne $numberOfIpAddresses ]
then
	tmpError="The number of IP addresses does not match the number of MAC addresses (Use --help to see formatting)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Make sure the # of disk sizes equals the number of disk storage types and the number of disk storage locations
numberOfDiskSizes=${#machineDiskSizes[@]}
numberOfDiskStorages=${#machineDiskStorages[@]}
numberOfDiskStorageLocations=${#machineDiskStorageLocations[@]}
if [ $numberOfDiskSizes -ne $numberOfDiskStorages ] || [ $numberOfDiskSizes -ne $numberOfDiskStorageLocations ] || [ $numberOfDiskStorageLocations -ne $numberOfDiskStorages ]
then
	tmpError="The number of disk sizes does not match the number of disk storages or disk storage locations (Use --help to see formatting)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# If the migratee is not empty, it must be a valid IP address (it must also be using /var/lib/<hypervisor>/images (or default))
if [ "$xenMigratee" != "" ]
then
	if [[ ! "$xenMigratee" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]]
	then
		tmpError="Xen Migratee IP ($xenMigratee) must either be empty, or be an IP"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	fi
#	if [[ ! "$timesToMigrate" =~ ^[[:digit:]]{1,7}$ ]]
#	then
#		tmpError="Times to migrate ($timesToMigrate) must either be left out, or be a positive integer"
#		echo "ERROR - $tmpError"
#		echo "ERROR - $tmpError" >&2
#		print_usage
#	fi
	#Todo: call vm-migrate.sh here; add some xen.conf check on vm-migrate.sh
	diskStorageLocationsLen=${#machineDiskStorageLocations[@]}
	for ((k=0;k<$diskStorageLocationsLen;k++))
	do
		TMPdiskStorageLocation=${machineDiskStorageLocations[${k}]}
		# If this one was not "." or /var/lib/<hypervisor>/images, then we fail
		if [ "$TMPdiskStorageLocation" != "." ] && [ "$TMPdiskStorageLocation" != "/var/lib/$hypervisor/images" ] && [ "$TMPdiskStorageLocation" != "var/lib/$hypervisor/images" ] && [ "$TMPdiskStorageLocation" != "/var/lib/$hypervisor/images/" ] && [ "$TMPdiskStorageLocation" != "var/lib/$hypervisor/images/"]
		then
			tmpError="Migration using this system currently requires each disk to be at the default location -- /var/lib/$hypervisor/images"
			echo "ERROR - $tmpError"
			echo "ERROR - $tmpError" >&2
			print_usage
		fi
	done
fi

# check architecture
# TODO: FIXME, it ispossible to install 64bit domU on 64bit hypervisor with 32bit dom0!
if [ $architecture -ne 32 ] && ! /usr/share/qa/tools/arch.pl | grep -q '64$'
then
	echo "SKIPPING: tried to install non-32bit VM on 32bit dom0 - this is not supported"
	echo "SKIPPING: tried to install non-32bit VM on 32bit dom0 - this is not supported" >&2
	popd > /dev/null; exit $rSKIPPED
fi

########## TODO ##########
### allow multiple ips ###
### allow defined nics ###
### allow defined ips  ###
### allow multiple nic ###
##########################

# TODO: check autoinstProfile and instRepository are valid!

# Deal with IPs
if [ $numberOfIpAddresses -gt 1 ]
then
	tmpError="SORRY, Multiple IP addresses are not yet supported!!!"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	popd > /dev/null; exit $rERROR
fi

machineIp=${machineIpAddresses[0]}
if [ "$machineIp" == "." ]
then
	# Netware and OES2 static pull from the pool
	#if [ "$operatingSystem" == "nw" ] || [ "$operatingSystem" == "oes" ]
	if [ "$operatingSystem" == "nw" ]
	then
		machineCnet=OOPS
		machineIpEnd=OOPS
		machineIp=OOPS
		
		# This outer loop is so that we keep running (until a timeout) to get an IP that we can use (once we have a valid IP)
		# The inner code makes sure that we get a valid IP address, period
		NWsleepThresholdStart=0
		NWsleepThresholdEnd=10
		NWFINALipAddress=10.10.10.11
		while [ "$NWFINALipAddress" == "10.10.10.11" ]
		do
			# Find out how many ips there are in the pool
			NWendCounter=0
			for i in $dhcpReservedPool
			do
				let "NWendCounter = $NWendCounter + 1"
			done
			echo "    Number of total IPs in the NW IP pool: $NWendCounter..."
			
			# Get a random integer between 0 and that maximum number
			NWrandomNumber=$RANDOM
			let "NWrandomNumber %= $NWendCounter"
			echo "    This is the random number below $NWendCounter: $NWrandomNumber..."
			
			# Now get the IP that matches that random value
			NWstartCounter=0
			NWipAddressToUse=10.10.10.10
			for i in $dhcpReservedPool
			do
				# Is this a valid IP address? (OK, it might seem strange to fail if ANY IP in the pool is invalid, but since it is selected on a random basis I don't want there to be any surprises later. Also, an error in one address could mean another address, though valid, is not what the person expected. I guess this argument could be compared to compilers... do we want a compiler to catch an error, or do we want to ship a product with a potential error that doesn't show itself until it is in a customer's production environment? OK, ending my rant now.
				if [[ ! "$i" =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]]
				then
					tmpError="Badly formatted ip address in ip pool!!!"
					echo "ERROR - $tmpError"
					echo "ERROR - $tmpError" >&2
					popd > /dev/null; exit $rERROR
				fi
				
				# Is this the IP that our random number generator says we should try?
				if [ $NWstartCounter -eq $NWrandomNumber ]
				then
					NWipAddressToUse=$i
					break
				fi
				let "NWstartCounter = $NWstartCounter + 1"
			done
			echo "    The IP we will be using from the NW IP pool is: $NWipAddressToUse..."
			
			# We should definitely have retrieved a valid address by now, or else we fail
			if [ "$NWipAddressToUse" == "10.10.10.10" ]
			then
				tmpError="Oops! The NW IP pool address selector made it through without assigning an IP other than 10.10.10.10!!!"
				echo "ERROR - $tmpError"
				echo "ERROR - $tmpError" >&2
				popd > /dev/null; exit $rERROR
			fi
			
			# Get the last two parts to formulate what would become the name string
			thirdPart=`echo $NWipAddressToUse | awk -F\. '{print $3;}'`
			fourthPart=`echo $NWipAddressToUse | awk -F\. '{print $4;}'`
			
			# Check if that IP address is even available; this is a simple check which makes sure it is not in a VM name on your box, and it makes sure it is not pingable yet (it doesn't however work if you've renamed your netware VM on your machine, or if that IP is about to be used somewhere else, but it just isn't detected yet)
			inUseCount1=`export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenHostIp "hostname" 2> /dev/null`
			echo "    ...$inUseCount1..."
			inUseCount2=`export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenHostIp "virsh list" 2> /dev/null`
			echo "    ...$inUseCount2..."
			inUseCount3=`export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenHostIp "virsh list | grep ${thirdPart}-${fourthPart}" 2> /dev/null`
			echo "    ...$inUseCount3..."
			inUseCount=`export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenHostIp "virsh list | grep ${thirdPart}-${fourthPart} | wc -l" 2> /dev/null`
			echo "    ...$thirdPart...$fourthPart...$inUseCount..."
			if [ $inUseCount -eq 0 ]
			then
				# OK, we think at this point it is not being used on the same box, but what about elsewhere? Make sure you can't ping this ip.
				pingResponse=`ping $NWipAddressToUse -c 2 -W 2`
				if echo "$pingResponse" | grep -q 100%\ packet\ loss
				then
					machineCnet=$thirdPart
					machineIpEnd=$fourthPart
					NWFINALipAddress=$NWipAddressToUse
					break
				else
					echo "    That IP already appears to be in use somewhere, so we are going to try another one..."
				fi
			else
				echo "    That IP already appears to be in use on the box, so we are going to try another one..."
			fi
			
			# OK, at this point we got an ip address to use, but it still wasn't available; so, we will try again with another random address
			let "NWsleepThresholdStart = $NWsleepThresholdStart + 1"
			if [ $NWsleepThresholdStart -ge $NWsleepThresholdEnd ]
			then
				tmpError="Oops! After $NWsleepThresholdEnd tries, we couldn't find an IP address to use for this install!!!"
				echo "ERROR - $tmpError"
				echo "ERROR - $tmpError" >&2
				popd > /dev/null; exit $rERROR
			fi
		done
		
		if [ "$NWFINALipAddress" == "10.10.10.11" ]
		then
			tmpError="Oops! The NW IP pool address selector made it through all of its possible iterations without assigning an IP other than 10.10.10.11!!!"
			echo "ERROR - $tmpError"
			echo "ERROR - $tmpError" >&2
			popd > /dev/null; exit $rERROR
		else
			# We found an IP and it was available (as far as we can tell), so we will use it
			machineIp=$NWFINALipAddress
		fi
		
		# Random Mac
		machineMac=${machineNicAddresses[0]}
		#if [ "$machineMac" == "." ] && [ "$operatingSystem" == "oes" ]
		#then
		#	procId="$$"
		#	hashedProcId=$( echo "$procId" | md5sum | md5sum | md5sum )
		#	machineMacThePartOne="${hashedProcId:2:2}"
		#	machineMacThePartTwo="${hashedProcId:8:2}"
		#	machineMacThePartThree="${hashedProcId:14:2}"
		#	machineMac="00:16:3e:$machineMacThePartOne:$machineMacThePartTwo:$machineMacThePartThree"
		#fi
	# Others will have random strings generated
	else
		procId="$$"
		hashedProcId=$( echo "$procId" | md5sum | md5sum )
		machineCnet="${hashedProcId:2:3}"
		machineIpEnd="${hashedProcId:5:3}"
	fi
else
	machineCnet=`echo $machineIp | awk -F\. '{print $3;}'`
	machineIpEnd=`echo $machineIp | awk -F\. '{print $4;}'`
fi

# Deal with NICs
if [ $numberOfNicAddresses -gt 1 ]
then
	tmpError="SORRY Multiple NICs are not yet supported!!!"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	popd > /dev/null; exit $rERROR
fi

if [ "$machineMac" == "." ] || [ "$machineMac" == "" ]
then
	machineMac=${machineNicAddresses[0]}
fi

##########################
##########################
##########################

# Make sure our autoinstallation file is there
if [ -z $autoinstProfile ]
then
	if [ "$machineIp" == "." ]
	then
		autoInstallationPath="$autoInstallation/$operatingSystem/$release/$servicePack/$architecture/$virtType/$installScenario"
	else
		autoInstallationPath="$autoInstallation/$operatingSystem/$release/$servicePack/$architecture/$virtType/static/$installScenario"
	fi
	if [ ! -f "$autoInstallationPath" ]
	then
		tmpError="The autoinstallation path you specified ($autoInstallationPath) does not exist (Use --help to see formatting)"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	fi
fi

machineNameFirstPart="$operatingSystem-$release-$servicePack-$architecture-$virtType-$installScenario-$installMethod"

# Install method must be 'net', 'ftp', 'http', 'nfs' or 'iso'
if [ "$installMethod" != "net" ] && [ "$installMethod" != "ftp" ] && [ "$installMethod" != "http" ] && [ "$installMethod" != "nfs" ] && [ "$installMethod" != "iso" ]
then
	tmpError="The installation method must be 'net', 'ftp', 'http', 'nfs' or 'iso' (Use --help to see formatting)"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# If the install method is ISO, the iso storage can be missing, or it can be a valid value; if not ISO, then cannot have storage type
if [ "$installMethod" == "iso" ]
then
	if [ "$machineIsoStorage" != "file" ] && [ "$machineIsoStorage" != "iscsi" ] && [ "$machineIsoStorage" != "nbd" ] && [ "$machineIsoStorage" != "npiv" ] && [ "$machineIsoStorage" != "phy" ] && [ "$machineIsoStorage" != "tap:aio" ] && [ "$machineIsoStorage" != "tap:qcow" ] && [ "$machineIsoStorage" != "tap:qcow2" ] && [ "$machineIsoStorage" != "vmdk" ] && [ "$machineIsoStorage" != "" ]
	then
		tmpError="Since the install method is ISO, the machine iso storage must either be empty, or be a valid disk storage type (use --help to see formatting)"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	fi
else
	if [ "$machineIsoStorage" != "" ]
	then
		tmpError="Since the install method is not ISO, you cannot have a machine iso storage"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	fi
fi

# Set the full machine name
if [ "$nameAddition" == "" ] && [ "$newFullName" == "" ]
then
	machineName="$machineNameFirstPart-$machineCnet-$machineIpEnd"
	machineTree="T_${machineCnet}_$machineIpEnd"
elif [ "$newFullName" == "" ]
then
	machineName="$machineNameFirstPart-$nameAddition"
	machineTree="T_$nameAddition"
else
	machineName="$newFullName"
	machineTree="T_$newFullName"
fi

# Set the host name
if [ "$hostName" == "" ]
then
	hostName=$machineName
else
	hostName=$hostName
fi

# Remove the DHCP,http,netinfo and pxe server host entries and the Xen host entry
sed -i -e "/^$httpServer[[:space:]]/d" ~/.ssh/known_hosts
sed -i -e "/^$netinfoServer[[:space:]]/d" ~/.ssh/known_hosts
sed -i -e "/^$pxeServer[[:space:]]/d" ~/.ssh/known_hosts
sed -i -e "/^$xenHostIp[[:space:]]/d" ~/.ssh/known_hosts

# Memory must be all digits or empty
if [[ ! "$machineMemory" =~ ^[[:digit:]][[:digit:]]*$ ]]
then
	if [ "$machineMemory" != "" ]
	then
		tmpError="Memory must be all digits (in KB), or empty (Use --help to see formatting)"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	fi
else
	if [ "$machineMemory" == "0" ]
	then
		tmpError="Memory must be all digits (in KB), or empty (Use --help to see formatting)"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	fi
fi

# Max memory must be all digits or empty
if [[ ! "$machineMaxMemory" =~ ^[[:digit:]][[:digit:]]*$ ]]
then
	if [ "$machineMaxMemory" != "" ]
	then
		tmpError="Max memory must be all digits (in KB), or empty (Use --help to see formatting)"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	fi
else
	if [ "$machineMaxMemory" == "0" ]
	then
		tmpError="Max memory must be all digits (in KB), or empty (Use --help to see formatting)"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	fi
fi

# Processors must be all digits or empty
if [[ ! "$machineProcessors" =~ ^[[:digit:]][[:digit:]]*$ ]]
then
	if [ "$machineProcessors" != "" ]
	then
		tmpError="Processors must be all digits (non-zero), or empty (Use --help to see formatting)"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	fi
else
	if [ "$machineProcessors" == "0" ]
	then
		tmpError="Processors must be all digits (non-zero), or empty (Use --help to see formatting)"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		print_usage
	fi
fi

### INITIAL SETTINGS (Everything up to this point has had to do with their input) ###

echo "    INITIAL SETTINGS"
echo "    Settings File: ${settingsFile}..."
echo "    Running Host: ${currentHostName}..."
echo "    Web Host: ${ipweb}..."
echo "    Operating System: $operatingSystem..."
echo "    Release: $release..."
echo "    Service Pack: $servicePack..."
echo "    Architecture: $architecture..."
echo "    Hypervisor: $hypervisor..."
echo "    Virtualization Type: $virtType..."
echo "    Install Scenario: $installScenario..."
echo "    Install Method: $installMethod..."
echo "    Machine ISO Storage: $machineIsoStorage..."
echo "    Machine Disk Sizes: ${machineDiskSizes[@]}..."
echo "    Machine Disk Storages: ${machineDiskStorages[@]}..."
echo "    Machine Disk Storage Locations: ${machineDiskStorageLocations[@]}..."
echo "    Number Nics: $numberOfNicAddresses..."
echo "    Network Bridge: $bridge..."
echo "    Machine MAC Addresses: ${machineNicAddresses[@]}..."
echo "    Number IPs: $numberOfIpAddresses..."
echo "    Machine IP Addresses: ${machineIpAddresses[@]}..."
echo "    Machine IP: $machineIp..."
echo "    Machine MAC: $machineMac..."
echo "    Machine Name First Part: $machineNameFirstPart..."
echo "    Machine Name: $machineName..."
echo "    Machine Host Name: $hostName..."
echo "    Auto-installation Path: $autoInstallationPath..."
echo "    Machine Cnet: $machineCnet..."
echo "    Machine IP End: $machineIpEnd..."
echo "    Machine Name Addition: $nameAddition..."
echo "    Machine Full Name Provided: $newFullName..."
echo "    Machine Install ID: $installId..."
echo "    Machine Tree: $machineTree..."
echo "    Machine Processors: $machineProcessors..."
echo "    Machine Memory: $machineMemory..."
echo "    Machine Max Memory: $machineMaxMemory..."
echo "    Xen Host IP: $xenHostIp..."
echo "    Xen Host User: $xenUser..."
echo "    Xen Host Pass: $xenPass..."
echo "    DHCP Reserved Pool: $dhcpReservedPool..."
echo "    HTTP IP: $httpServer..."
echo "    HTTP User: $httpUser..."
echo "    HTTP Pass: $httpPass..."
echo "    HTTP Autoyast Web: $httpAutoyastWeb..."
echo "    HTTP Autoyast Local: $httpAutoyastLocal..."
echo "    NETINFO IP: $netinfoServer..."
echo "    NETINFO User: $netinfoUser..."
echo "    NETINFO Pass: $netinfoPass..."
echo "    PXE IP: $pxeServer..."
echo "    PXE User: $pxeUser..."
echo "    PXE Pass: $pxePass..."
echo "    Mask: $netMask..."
echo "    Gateway: $netGateway..."
echo "    Name Server: $netNameServer..."
echo "    Network: $netNetwork..."
echo "    Broadcast: $netBcast..."
echo "    Domain: $netDomain..."
if [ "$performanceTest" == "" ]
then
	echo "	domU:$machineName will not implement performance tests..."
else
	echo "  domU:$machineName will implement performance tests..."
fi
if [ "$xenMigratee" == "" ]
then
	echo "    Migratee: N/A..."
	echo "    Times to Migrate: N/A..."
else
	echo "    Migratee: $xenMigratee..."
	if [ $timesToMigrate -eq 0 ]
	then
		echo "    Times to Migrate: Inf..."
	else
		echo "    Times to Migrate: $timesToMigrate..."
	fi
fi
if [ "$vmSaveRestore" == "" ]; then
	echo "	domU:$machineName will not implement SAVE and RESTORE..."
else
	echo "	domU:$machineName will verify SAVE and RESTORE function..."
fi
echo

### Knock out any unsupported installations ###

# KVM - only full virtualization
if [ "$virtType" != "fv" ] && [ "$hypervisor" == "kvm" ]
then
	tmpError="Only full-virtualization is supported in KVM (but '$virtType' specified)"
	echo "SKIPPED - $tmpError"
	echo "SKIPPED - $tmpError" >&2
	exit $rSKIPPED
fi

# SLES 10 FCS FV
if [ "$virtType" == "fv" ] && [ "$operatingSystem" == "sles" ] && [ "$release" == "10" ] && [ "$servicePack" == "fcs" ] && [ "$hypervisor" == "xen" ]
then
	tmpError="Fully-virtualized, sles 10 fcs is not supported in Xen"
	echo "SKIPPED - $tmpError"
	echo "SKIPPED - $tmpError" >&2
	exit $rSKIPPED
fi

# ALL SUSE ISOS FV (boots to hard-disk by default)
if [ "$virtType" == "fv" ] && [ "$operatingSystem" == "sles" ] && [ "$installMethod" == "iso" ]
then
	tmpError="Fully-virtualized, sles iso installs are currently not supported"
	echo "SKIPPED - $tmpError"
	echo "SKIPPED - $tmpError" >&2
	exit $rSKIPPED
fi

# OES ISO (add-on tries to get network, but can't)
if [ "$operatingSystem" == "oes" ] && [ "$installMethod" == "iso" ]
then
	tmpError="We cannot do an OES install with ISO in this system because no network is available to retrieve the add-on product"
	echo "SKIPPED - $tmpError"
	echo "SKIPPED - $tmpError" >&2
	exit $rSKIPPED
fi

# SLES 9 SP4 ISO (no DVD)
if [ "$operatingSystem" == "sles" ] && [ "$release" == "9" ] && [ "$installMethod" == "iso" ]
then
	tmpError="SLES 9 iso installs are not supported in Xen"
	echo "SKIPPED - $tmpError"
	echo "SKIPPED - $tmpError" >&2
	exit $rSKIPPED
fi

# All WINDOWS PV
if [ "$operatingSystem" == "win" ] && [ "$virtType" == "pv" ]
then
	tmpError="Windows paravirtualized installs are not supported in Xen"
	echo "SKIPPED - $tmpError"
	echo "SKIPPED - $tmpError" >&2
	exit $rSKIPPED
fi

### DISCOVERED SETTINGS (Everything after this point has to do with programming regarding their input) ###

graphics=
diskPrefix=
virtOption=
workingLocation=
newLocation=
osFlag=
additionalInstallSource=

# Other Settings
if [ "$virtType" == "pv" ]
then
	graphics=para
	diskPrefix=xvd
	virtOption=-v
else
	graphics=cirrus
	diskPrefix=hd
	virtOption=-V
fi
workingLocation=$autoInstallation/$operatingSystem/$release/$servicePack/$architecture/$virtType
newLocation=$machineName.autoinstall
if [ "$operatingSystem" == "sles" ] || [ "$operatingSystem" == "rhel" ] || [ "$operatingSystem" == "sled" ]
then
	osFlag=$operatingSystem$release
elif [ "$operatingSystem" == "os" ] && [ "$release" == "11" ]
then
	osFlag=opensuse11
elif [ "$operatingSystem" == "os" ]
then
	osFlag=opensuse
elif [ "$operatingSystem" == "nw" ]
then
	if [ "$release" == "65" ]
	then
		if [ "$servicePack" == "sp7" ] || [ "$servicePack" == "sp8" ]
		then
			osFlag=oes2nw
		else
			osFlag=netware
		fi
	else
		osFlag=netware
	fi
elif [ "$operatingSystem" == "oes" ]
then
	osFlag=oes2l
elif [ "$operatingSystem" == "win" ]
then
	if [ "$release" == "2k8" ] || [ "$release" == "2k8r2" ]
	then
		if echo "$installScenario" | grep -q '^shm.*$'
		then
			if [ "$architecture" == "32" ]
			then
				osFlag=winserver2008
			else
				osFlag=winserver2008x64
			fi
		else
			if [ "$architecture" == "32" ]
			then
				osFlag=windowsvista
			else
				osFlag=windowsvistax64
			fi
		fi
	elif [ "$release" == "vista" ]
	then
		if echo "$installScenario" | grep -q '^shm.*$'
		then
			if [ "$architecture" == "32" ]
			then
				osFlag=winserver2008
			else
				osFlag=winserver2008x64
			fi
		else
			if [ "$architecture" == "32" ]
			then
				osFlag=windowsvista
			else
				osFlag=windowsvistax64
			fi
		fi
	elif [ "$release" == "7" ]
	then
		if echo "$installScenario" | grep -q '^shm.*$'
		then
			if [ "$architecture" == "32" ]
			then
				osFlag=winserver2008
			else
				osFlag=winserver2008x64
			fi
		else
			if [ "$architecture" == "32" ]
			then
				osFlag=windowsvista
			else
				osFlag=windowsvistax64
			fi
		fi
	elif [ "$release" == "2k" ] || [ "$release" == "2k3" ] || [ "$release" == "xp" ]
	then
		if [ "$architecture" == "32" ]
		then
			osFlag=windowsxp
		else
			osFlag=windowsxpx64
		fi
	fi
fi
if [ "$osFlag" == "" ]
then
	tmpError="OS Flag not set"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	popd > /dev/null; exit $rERROR
fi
if [ "$operatingSystem" == "oes" ] && [ "$release" == "2" ]
then
	if [ "$servicePack" == "fcs" ]
	then
		if [ "$architecture" == "64" ]
		then
			InstSource=`$getSource source.ftp.oes-2-fcs-64 | sed 's/\//\\\//g'`
			additionalInstallSource="$InstSource"
		else
			InstSource=`$getSource source.ftp.oes-2-fcs-32 | sed 's/\//\\\//g'`
			additionalInstallSource="$InstSource"
		fi
	elif [ "$servicePack" == "sp1" ]
	then
		if [ "$architecture" == "64" ]
		then
			InstSource=`$getSource source.ftp.oes-2-sp1-64 | sed 's/\//\\\//g'`
			additionalInstallSource="$InstSource"
		else
			InstSource=`$getSource source.ftp.oes-2-sp1-32 | sed 's/\//\\\//g'`
			additionalInstallSource="$InstSource"
		fi
    elif [ "$servicePack" == "sp2" ]
	then
		if [ "$architecture" == "64" ]
		then
			InstSource=`$getSource source.ftp.oes-2-sp2-64 | sed 's/\//\\\//g'`
			additionalInstallSource="$InstSource"
		else
			InstSource=`$getSource source.ftp.oes-2-sp2-32 | sed 's/\//\\\//g'`
			additionalInstallSource="$InstSource"
		fi
	fi

	if [ "$additionalInstallSource" == "" ]
	then
		tmpError="Additional install source was not set for oes 2"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		popd > /dev/null; exit $rERROR
	fi
fi

### ADDITIONAL SETTINGS (We should have everything we need now) ###

echo "    ADDITIONAL SETTINGS"
echo "    Graphics Card: $graphics..."
echo "    Disk Prefix: $diskPrefix..."
echo "    Virtualization Option: $virtOption..."
echo "    New Location: $newLocation..."
echo "    OS Flag: $osFlag..."
echo "    Additional Install Source: $additionalInstallSource..."
echo

# Get rid of old autoinstall profile
if [ -f $newLocation ]
then
	rm -f $newLocation
fi

# Get the AUTOINSTALLATION file that we will be using - THIS WILL NOT BE USED IF CUSTOM WERE PROVIDED -A
cp $autoInstallationPath $newLocation

# Do the replace on the AUTOINSTALLATION file
if [ "$machineIp" != "." ]
then
	sed -i "s/REPLACEMEWITHMAC/$machineMac/g" $newLocation
	sed -i "s/REPLACEMEWITHNAME/$hostName/g" $newLocation
	sed -i "s/REPLACEMEWITHDOMAIN/$netDomain/g" $newLocation
	sed -i "s/REPLACEMEWITHDNS/$netNameServer/g" $newLocation
	sed -i "s/REPLACEMEWITHBCAST/$netBcast/g" $newLocation
	sed -i "s/REPLACEMEWITHIP/$machineIp/g" $newLocation
	sed -i "s/REPLACEMEWITHNETWORK/$netNetwork/g" $newLocation
	sed -i "s/REPLACEMEWITHMASK/$netMask/g" $newLocation
	sed -i "s/REPLACEMEWITHGATEWAY/$netGateway/g" $newLocation
	sed -i "s/REPLACEMEWITHTREE/$machineTree/g" $newLocation
	sed -i "s/REPLACEMEWITHADDITIONALINSTALLSOURCE/$additionalInstallSource/g" $newLocation
fi

# Disk string section
diskLen=${#machineDiskSizes[@]}
diskStr=
diskLetters=( a b c d e f g h i j k l m n o p q r s t u v w x y z )
for ((k=0;k<$diskLen;k++))
do
	diskLetter=${diskLetters[${k}]}
	diskSize=${machineDiskSizes[${k}]}
	diskStorage=${machineDiskStorages[${k}]}
	diskStorageLocation=${machineDiskStorageLocations[${k}]}
	if [ "$diskSize" == "." ]
	then
		diskSize=""
	else
		diskSize=",$diskSize"
	fi
	if [ "$diskStorage" == "." ]
	then
		diskStorage="/"
	elif [ "$diskStorage" == "iscsi" ]
	then
		diskStorage="iscsi:"
	else
		diskStorage="$diskStorage:/"
	fi
	if [ "$diskStorageLocation" == "." ]
	then
		diskStorageLocation="var/lib/$hypervisor/images/$machineName/disk${k}"
	else
		# If it starts with a "/", then we need to shave off the first character
		if echo "$diskStorageLocation" | grep -q '^/.*$'
		then
			diskStorageLocation=${diskStorageLocation:1}
		else
			diskStorageLocation=$diskStorageLocation
		fi
		# If they told us to use var/lib/$hypervisor/images, then we add the extra stuff
		if [ "$diskStorageLocation" == "var/lib/$hypervisor/images" ] || [ "$diskStorageLocation" == "var/lib/$hypervisor/images/" ]
		then
			diskStorageLocation="var/lib/$hypervisor/images/$machineName/disk${k}"
		fi
	fi
	diskStr="${diskStr}-d \"${diskStorage}${diskStorageLocation},${diskPrefix}${diskLetter},disk,w${diskSize}\" "
done

# Nic string section
macStr=
for ((l=0;l<$numberOfNicAddresses;l++))
do
	macName=${machineNicAddresses[${l}]}
	if [ "$macName" == "." ]
	then
		macPart=""
		[ "$bridge" == "" ] || macPart="bridge=$bridge "
	else
		macPart="mac=$macName "
		[ "$bridge" == "" ] || macPart="bridge=$bridge,$macPart"
	fi

	macStr="${macStr}--nic ${macPart}"
done
if [ "$macStr" == "--nic " ]
then
	macStr=
fi

# Os settings string section
if [ "$virtType" == "pv" ]
then
	if [ -z $autoinstProfile ] 
	then
		if [ "$operatingSystem" == "sles" ] || [ "$operatingSystem" == "sled" ] || [ "$operatingSystem" == "nw" ] || [ "$operatingSystem" == "oes" ] || [ "$operatingSystem" == "os" ]
		then
			osSettings="--os-settings /etc/$hypervisor/vm/$machineName.autoinstall "
		elif [ "$operatingSystem" == "rhel" ]
		then
			osSettings="--os-settings http://$httpServer/$httpAutoyastWeb/$machineName.autoinstall-$$ " 
		fi
	elif [ "$operatingSystem" == "sles" ] || [ "$operatingSystem" == "sled" ] || [ "$operatingSystem" == "nw" ] || [ "$operatingSystem" == "oes" ] || [ "$operatingSystem" == "os" ] || [ "$operatingSystem" == "rhel" ] 
	then
		osSettings="--os-settings $autoinstProfile "
	fi
fi

# Extra parameters string section
if [ "$virtType" == "pv" ]
then
	if [ "$operatingSystem" == "oes" ] || [ "$operatingSystem" == "sles" ] || [ "$operatingSystem" == "sled" ] || [ "$operatingSystem" == "os" ]
	then
		#extraSettings="-x \"hostip=$machineIp netmask=$netMask gateway=$netGateway nameserver=$netNameServer\" "
		extraSettings=""
	fi
fi

diskLetter=${diskLetters[${k}]}

mkdir /tmp/virtautolib.$$

# Installation source
if [ "$installMethod" == "iso" ]
then
	if [ -z $instRepository ]
	then
		isoStringTag="source.iso.$operatingSystem-$release-$servicePack-$architecture"
		testIsoString=`$getSource $isoStringTag`
		if echo "$testIsoString" | grep -q ^ERROR || [ "$testIsoString" = "" ]
		then
			tmpError="Could not retrieve ISO install source for '$isoStringTag'. It is either not listed in your settings file, or the ISO file does not exist on your file system."
			echo "SKIPPED - $tmpError"
			echo "SKIPPED - $tmpError" >&2
			popd > /dev/null; exit $rSKIPPED
		fi
	else
		testIsoString="$instRepository"
		#TODO check
	fi

	
	if [ "$copyIsoToTmp" == "1" ] 
	then
		if [ "$machineIsoStorage" != "" ] ; then
			echo "Warning: Copying iso to /tmp is not supported together with -S argument, not copying..." >&2
		else
			baseName="`basename "$testIsoString"`"
			echo "Copying iso $baseName to /tmp/virtautolib.$$ ..." 
			cp "$testIsoString" /tmp/virtautolib.$$
			testIsoString="/tmp/virtautolib.$$/$baseName"
		fi
	fi

	if [ "$virtType" == "fv" ]
	then
		if [ "$operatingSystem" != "win" ]
		then
			tmpError="Non-windows fully-virtualized iso installs are currently not supported"
			echo "SKIPPED - $tmpError"
			echo "SKIPPED - $tmpError" >&2
			popd > /dev/null; exit $rSKIPPED
		else
			if [ "$machineIsoStorage" == "" ]
			then
				machineIsoStorageString=
			elif [ "$machineIsoStorage" == "iscsi" ]
			then
				# With iscsi, we take a substring to remove initial "/" for the iso string
				testIsoString=${testIsoString:1}
				machineIsoStorageString="iscsi:"
			else
				machineIsoStorageString="$machineIsoStorage:"
			fi
			isoString="-d \"$machineIsoStorageString$testIsoString,${diskPrefix}${diskLetter},cdrom,r\" "
		fi
	else
		if [ "$machineIsoStorage" == "" ]
		then
			machineIsoStorageString=
		elif [ "$machineIsoStorage" == "iscsi" ]
		then
			# With iscsi, we take a substring to remove initial "/" for the iso string
			testIsoString=${testIsoString:1}
			machineIsoStorageString="iscsi:"
		else
			machineIsoStorageString="$machineIsoStorage:"
		fi
		isoString="-d \"$machineIsoStorageString$testIsoString,${diskPrefix}${diskLetter},cdrom,r\" "
	fi
	
	if [ "$isoString" == "" ]
	then
		tmpError="isoString not set for an iso install"
		echo "SKIPPED - $tmpError"
		echo "SKIPPED - $tmpError" >&2
		popd > /dev/null; $rSKIPPED
	fi
	
	# Set up install source
	installSource="-s dev:/${diskPrefix}${diskLetter} "

elif [ "$installMethod" == "ftp" ] || [ "$installMethod" == "http" ] || [ "$installMethod" == "nfs" ] || [ "$installMethod" == "net" ] 
then
	if [ -z $instRepository ]
	then
		installSourceTag="source.$installMethod.$operatingSystem-$release-$servicePack-$architecture"
		if [ "$installMethod" == "net" ] ; then
			# ftp first
			tmpTag="source.ftp.$operatingSystem-$release-$servicePack-$architecture"
			testInstallSource=`$getSource $tmpTag`
			if echo "$testInstallSource" | grep -q '^ftp://' ; then
				installMethod=ftp
			else
				# try http
				tmpTag="source.http.$operatingSystem-$release-$servicePack-$architecture"
				testInstallSource=`$getSource $tmpTag`
				echo "$testInstallSource" | grep -q '^http://'  && installMethod=http
			fi
		else
			testInstallSource=`$getSource $installSourceTag`
		fi
		if echo "$testInstallSource" | grep -q ^ERROR || [ "$testInstallSource" = "" ] || ! echo "$testInstallSource" | grep -q "^$installMethod://" 
		then
			tmpError="Could not retrieve install source for '$installSourceTag' (if .net. -> failed to get both ftp & http)"
			echo "SKIPPED - $tmpError"
			echo "SKIPPED - $tmpError" >&2
			popd > /dev/null; exit $rSKIPPED
		fi
	else
		testInstallSource="$instRepository"
		#TODO: check!
	fi

	if [ "$virtType" == "fv" ]
	then
		
		# Set up PXE boot
		isoString="-p "
		prePxeInstallSource=$testInstallSource
	
	elif [ "$virtType" == "pv" ]
	then
		
		# Set up install source
		installSource="-s $testInstallSource "
		[ -z $customInstallBootOption ] || extraArgs="--extra-args \"$customInstallBootOption\" "		
	fi
fi

# Memory string
if [ "$machineMemory" != "" ]
then
	memoryString="-m $machineMemory "
else
	memoryString=
fi

# Max memory string
if [ "$machineMaxMemory" != "" ]
then
	memoryMaxString="-M $machineMaxMemory "
else
	memoryMaxString=
fi

# Processors string
if [ "$machineProcessors" != "" ]
then
	processorsString="-c $machineProcessors "
else
	processorsString=
fi

### FINAL SETTINGS (This is it, let's install!) ###

echo "    FINAL SETTINGS"
echo "    ISO String: $isoString..."
echo "    Install Source: $installSource..."
echo "    Extra Settings: $extraSettings..."
echo "    OS Settings: $osSettings..."
echo "    Disk String: $diskStr..."
echo "    MAC String: $macStr..."
echo "    Number of Disks: $diskLen..."
echo "    Memory String: $memoryString..."
echo "    Max Memory String: $memoryMaxString..."
echo "    Processors String: $processorsString..."
[ -z $extraArgs ] || echo "    Extra Args: $extraArgs..."
echo

### INSTALL SETTING (Come on! Run it already!) ###

installCommand="vm-install ${processorsString}${diskStr}${isoString}--graphics $graphics ${memoryString}${memoryMaxString}-n $machineName ${macStr}${virtOption} -o $osFlag ${osSettings}${extraSettings}${installSource}${extraArgs}--background"

echo "    INSTALL STUFF"
echo "    Really Install: $reallyInstall..."
echo "    Remove After Install: $removeInstall..."
echo "    Install Command: $installCommand..."
echo

### Now run the install ###

if [ "$reallyInstall" == "NO" ]
then
	tmpError="'reallyInstall' setting was set to NO"
	echo "SKIPPED - $tmpError"
	echo "SKIPPED - $tmpError" >&2
	popd > /dev/null; exit $rSKIPPED
fi

# Get rid of the old install, if necessary
echo "    Getting rid of the old install, if necessary..."
./vm-gone.sh $xenHostIp $hypervisor $machineName $machineNameFirstPart $machineIp $settingsFile
returnVal=$?
if [ $returnVal -ne 0 ]
then
	tmpError="Could not get rid of the old install"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	popd > /dev/null; exit $rERROR
fi
if [ "$virtType" == "pv" ]
then
	# Now get the autoyast file over to the host
	echo "    Putting the auto-install file on the host..."
	if [ "$operatingSystem" != "rhel" ]
	then
		export SSHPASS=$xenPass; cat $newLocation | $sshNoPass $xenUser@$xenHostIp "cat - > /etc/$hypervisor/vm/$machineName.autoinstall" 2> /dev/null
	else
		export SSHPASS=$httpPass; cat $newLocation | $sshNoPass $httpUser@$httpServer "cat - > $httpAutoyastLocal/$machineName.autoinstall-$$" 2> /dev/null
	fi
fi # else in fv -> move it during pxe setup

# Run the install
echo "    Running the install..."
installText=`export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenHostIp "$installCommand" 2> /dev/null`
echo "    The install text was '$installText'..."
echo "    ***** INSTALL STARTED *****"

# Pause the VM
echo "    Waiting to let the VM install command register..."

checkRunningTimesThrough=0
retVal=`./vm-running.sh $xenHostIp $machineName $settingsFile`
vmId=`echo "$retVal" | grep '\*\*\ VM\ ID\:\ ..*\ \*\*' | awk '{print $4;}'`
if [[ ! "$vmId" =~ ^[[:digit:]][[:digit:]]*$ ]]
then
	#./vm-gone.sh $xenHostIp $hypervisor $machineName $machineNameFirstPart "000.000.000.000" $settingsFile
	tmpError="Invalid number returned ($vmId) while waiting for VM install command to register"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	echo "    ***** INSTALL ERRORED *****"
	rm -rf /tmp/virtautolib.$$
	popd > /dev/null; exit $rFAILED
fi
while [ $vmId -eq 0 ]
do
	retVal=`./vm-running.sh $xenHostIp $machineName $settingsFile`
	vmId=`echo "$retVal" | grep '\*\*\ VM\ ID\:\ ..*\ \*\*' | awk '{print $4;}'`
	
	if [[ ! "$vmId" =~ ^[[:digit:]][[:digit:]]*$ ]]
	then
		#./vm-gone.sh $xenHostIp $hypervisor $machineName $machineNameFirstPart "000.000.000.000" $settingsFile
		tmpError="Invalid number returned ($vmId) while waiting for VM install command to register"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		echo "    ***** INSTALL ERRORED *****"
		rm -rf /tmp/virtautolib.$$
		popd > /dev/null; exit $rFAILED
	fi
	
	let "checkRunningTimesThrough = $checkRunningTimesThrough + 1"
	if [ $checkRunningTimesThrough -ge 600 ]
	then
		#./vm-gone.sh $xenHostIp $hypervisor $machineName $machineNameFirstPart "000.000.000.000" $settingsFile
		tmpError="Timeout waiting for VM install command to register"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		echo "    ***** INSTALL ERRORED *****"
		rm -rf /tmp/virtautolib.$$
		popd > /dev/null; exit $rFAILED
	fi
done

#sleep 1
echo "    Pausing the VM"
export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenHostIp "virsh suspend $machineName" 2> /dev/null

# If they have not defined a mac, we need to get it
if [ "$machineMac" == "." ]
then
	echo "    MAC address was not defined, so we will read it via virsh"
	installMacInitialLine=`export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenHostIp "virsh dumpxml $machineName 2> /dev/null" | xpath '/domain/devices/interface/mac/@address' 2> /dev/null`


	# From experiments, it seems that xpath always uses " regardless whether in 
	# original XML are " or ' used. If it stop working in the future, the change in 
	# this behavior is most likely the cause!
	installMac=`echo "$installMacInitialLine" | sed 's/^[[:space:]]*address="\(.*\)"[[:space:]]*$/\1/'`

	if ! echo "$installMac" | grep -q '^[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]:[a-zA-Z0-9][a-zA-Z0-9]$' 
	then
		############################################################################################
		
		./vm-gone.sh $xenHostIp $hypervisor $machineName $machineNameFirstPart "000.000.000.000" $settingsFile
		tmpError="Could not retrieve MAC address ($installMac) via virsh"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		echo "    ***** INSTALL ERRORED *****"
		rm -rf /tmp/virtautolib.$$
		popd > /dev/null; exit $rFAILED
	fi
	
	echo "    MAC: $installMac..."
else
	echo "    MAC address was already defined"
	installMac=$machineMac
fi

## TODO REMOVE?
## Get the RAM, number of PROCS and number of disks
#if [ "$installId" != "0" ]
#then
#	echo "    Sending additional VM information to the DB..."
#	if [ "$memoryString" == "" ]
#	then
#		# Get amount of RAM
#		getMemoryInitialLine=`export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenHostIp "virsh dumpxml $machineName 2> /dev/null" | xpath "/domain/memory" 2> /dev/null`
#		echo ""
#		if [ "$getMemoryInitialLine" == "" ]
#		then
#			sentOneResult=ERROR
#			sentOneResultMessage="Could not read the amount of RAM from the conf file"
#		else
#			getMemoryInitialLine1=`echo "$getMemoryInitialLine" | sed 's/^.*<memory>\(.*\)<\/memory>.*$/\1/'`
#			if [[ ! "$getMemoryInitialLine1" =~ ^[0-9]{1,10}$ ]]
#			then
#				sentOneResult=ERROR
#				sentOneResultMessage="The amount of RAM listed in the conf file was invalid"
#			else
#				getMemoryInitialLine1=`echo "$getMemoryInitialLine1" | awk '{print $1/1024;}'`
#				if [[ ! "$getMemoryInitialLine1" =~ ^[0-9]{1,5}$ ]]
#				then
#					sentOneResult=ERROR
#					sentOneResultMessage="The amount of RAM listed in the conf file could not be divided by 1024"
#				else
#					echo "Amount of RAM detected: $getMemoryInitialLine1..."
#					sentOne=`curl -k -d "override=yes&updatememory=yes&updateid=$installId&updatememoryvalue=$getMemoryInitialLine1" https://${ipweb}/automation/admin/SM-newdeploy.php 2>/dev/null`
#					sentOneResult=`echo $sentOne | awk -F' - ' '{print $1;}'`
#					sentOneResultMessage=`echo $sentOne | awk -F' - ' '{print $2;}'`
#				fi
#			fi
#		fi
#	else
#		sentOneResult=SUCCESS
#		sentOneResultMessage="Memory value should already be set"
#	fi
#	if [ "$processorsString" == "" ]
#	then
#		# Get number of processors
#		getProcsInitialLine=`export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenHostIp "virsh dumpxml $machineName 2> /dev/null" | xpath "/domain/vcpu" 2> /dev/null`
#		echo "===== $getProcsInitialLine ====="
#		if [ "$getProcsInitialLine" == "" ]
#		then
#			sentTwoResult=ERROR
#			sentTwoResultMessage="Could not read the number of processors from the conf file"
#		else
#			getProcsInitialLine1=`echo "$getProcsInitialLine" | sed 's/^.*<vcp\(.*\)>\(.*\)<\/vcpu>.*$/\2/'`
#			echo "===== $getProcsInitialLine1 ====="
#			if [[ ! "$getProcsInitialLine1" =~ ^[0-9]{1,3}$ ]]
#			then
#				sentTwoResult=ERROR
#				sentTwoResultMessage="The value for the number of processors was invalid in the conf file"
#			else
#				echo "Number of procs detected: $getProcsInitialLine1..."
#				sentTwo=`curl -k -d "override=yes&updateprocessors=yes&updateid=$installId&updateprocessorsvalue=$getProcsInitialLine1" https://${ipweb}/automation/admin/SM-newdeploy.php 2>/dev/null`
#				sentTwoResult=`echo $sentTwo | awk -F' - ' '{print $1;}'`
#				sentTwoResultMessage=`echo $sentTwo | awk -F' - ' '{print $2;}'`
#			fi
#		fi
#	else
#		sentTwoResult=SUCCESS
#		sentTwoResultMessage="Disk value should already be set"
#	fi
#	sentThree=`curl -k -d "override=yes&updatename=yes&updateid=$installId&updatenamevalue=$machineName" https://${ipweb}/automation/admin/SM-newdeploy.php 2>/dev/null`
#	sentThreeResult=`echo $sentThree | awk -F' - ' '{print $1;}'`
#	sentThreeResultMessage=`echo $sentThree | awk -F' - ' '{print $2;}'`
#	# If they didn't pass any disks in, then disks weren't already set, so we set them now in the DB
#	if [ "$newINmachineDiskSizes" == "" ]
#	then
#		echo "Disk sizes detected: $newINmachineDiskSizes..."
#		sentFour=`curl -k -d "override=yes&updatedisks=yes&updateid=$installId&updatedisksvalue=$numberOfDiskSizes" https://${ipweb}/automation/admin/SM-newdeploy.php 2>/dev/null`
#		sentFourResult=`echo $sentFour | awk -F' - ' '{print $1;}'`
#		sentFourResultMessage=`echo $sentFour | awk -F' - ' '{print $2;}'`
#	else
#		sentFourResult=SUCCESS
#		sentFourResultMessage="Disk sizes should have already been set"
#	fi
#	echo "Install MAC detected: $installMac..."
#	sentFive=`curl -k -d "override=yes&updatemac=yes&updateid=$installId&updatemacvalue=$installMac" https://${ipweb}/automation/admin/SM-newdeploy.php 2>/dev/null`
#	sentFiveResult=`echo $sentFive | awk -F' - ' '{print $1;}'`
#	sentFiveResultMessage=`echo $sentFive | awk -F' - ' '{print $2;}'`
#	echo "Install hypervisor detected: $hypervisor..."
#	sentSix=`curl -k -d "override=yes&updatehypervisor=yes&updateid=$installId&updatehypervisorvalue=$hypervisor" https://${ipweb}/automation/admin/SM-newdeploy.php 2>/dev/null`
#	sentSixResult=`echo $sentSix | awk -F' - ' '{print $1;}'`
#	sentSixResultMessage=`echo $sentSix | awk -F' - ' '{print $2;}'`
##	sentSix=`curl -k -d "override=yes&updateip=yes&updateid=$installId&updateipvalue=$machineIp" https://${ipweb}/automation/admin/SM-newdeploy.php 2>/dev/null`
##	sentSixResult=`echo $sentSix | awk -F' - ' '{print $1;}'`
##	if [ "$sentOneResult" != "SUCCESS" ] || [ "$sentTwoResult" != "SUCCESS" ] || [ "$sentThreeResult" != "SUCCESS" ] || [ "$sentFourResult" != "SUCCESS" ] || [ "$sentFiveResult" != "SUCCESS" ] || [ "$sentSixResult" != "SUCCESS" ]
#	if [ "$sentOneResult" != "SUCCESS" ] || [ "$sentTwoResult" != "SUCCESS" ] || [ "$sentThreeResult" != "SUCCESS" ] || [ "$sentFourResult" != "SUCCESS" ] || [ "$sentFiveResult" != "SUCCESS" ] || [ "$sentSixResult" != "SUCCESS" ]
#	then
#		echo "ERROR - MAIN 2 - WE WERE UNABLE TO UPDATE THE DATABASE WITH VM NAME, MEMORY, MAC, DISK SIZES AND PROCESSORS BECAUSE OF SOME FAILURE:\n$sentOneResult ($sentOneResultMessage), $sentTwoResult ($sentTwoResultMessage), $sentThreeResult ($sentThreeResultMessage), $sentFourResult ($sentFourResultMessage), $sentFiveResult ($sentFiveResultMessage)"
#		echo "ERROR - MAIN 2 - WE WERE UNABLE TO UPDATE THE DATABASE WITH VM NAME, MEMORY, MAC, DISK SIZES AND PROCESSORS BECAUSE OF SOME FAILURE:\n$sentOneResult ($sentOneResultMessage), $sentTwoResult ($sentTwoResultMessage), $sentThreeResult ($sentThreeResultMessage), $sentFourResult ($sentFourResultMessage), $sentFiveResult ($sentFiveResultMessage)" >&2
#	fi
#fi

# If we are fully-virtualized, network, we need to create a pxe file
if [ "$virtType" == "fv" ]
then
	if [ "$installMethod" == "ftp" ] || [ "$installMethod" == "http" ] || [ "$installMethod" == "nfs" ] || [ "$installMethod" == "net" ]

	then
		# Replace colons with hyphens
		pxeFileName=`export SSHPASS=$netinfoPass; echo mac2pxefilename "$installMac" | $sshNoPass $netinfoUser@$netinfoServer bash -l`
		
		if [ "$pxeFileName" == "" ]
		then
			#./vm-gone.sh $xenHostIp $hypervisor $machineName $machineNameFirstPart "000.000.000.000" $settingsFile
			tmpError="Could not convert the MAC address to PXE-ability ($pxeFileName)"
			echo "ERROR - $tmpError"
			echo "ERROR - $tmpError" >&2
			echo "    ***** INSTALL ERRORED *****"
			rm -rf /tmp/virtautolib.$$
			popd > /dev/null; exit $rERROR
		fi
		
		echo "    The MAC address has been converted for PXE usage ($pxeFileName)"
		autoyastFileName="${pxeFileName##*/}"
		
		### This section depends on what was passed in, compared to what is on the dhcp server ###
		
		pxe_os=OOPS
		pxe_rl=OOPS
		pxe_sp=OOPS
		pxeInstallSource=OOPS
		pxeInstallOptions=OOPS
		autoInstallationType=OOPS
		installBootOption=OOPS
		if [ "$architecture" == "32" ] || [ "$architecture" == "32p" ]
		then
			archFolder="ix86"
		elif [ "$architecture" == "64" ]
		then
			archFolder="x86_64"
		fi

		if echo "$operatingSystem" | grep -q '^sle[sd]\|oes$' 
		then
			autoInstallationType="autoyast"
			installBootOption="install"
			pxe_os="$operatingSystem"
			pxe_rl="$release"
			pxe_sp="$servicePack"
			pxeInstallOptions="ro quiet splash vga=0x317"
			pxeInstallSource=$prePxeInstallSource
		elif [ "$operatingSystem" == "os" ]
		then
			autoInstallationType="autoyast"
			installBootOption="install"
			pxe_os="opensuse"
			pxe_rl="$release"
			pxe_sp="$servicePack"
			pxeInstallOptions="ro quiet splash vga=0x317"
			pxeInstallSource=$prePxeInstallSource
		elif [ "$operatingSystem" == "rhel" ]
		then
			pxe_os="$operatingSystem"
			export SSHPASS=$httpPass; $sshNoPass $httpUser@$httpServer "mkdir $httpAutoyastLocal/$autoyastFileName" 2> /dev/null
			autoyastFileName="$autoyastFileName/ks.cfg"
			autoInstallationType="ks"
			installBootOption="method"
			pxe_rl="$release"
			pxe_sp="$servicePack"
			pxeInstallOptions="noipv6"
			pxeInstallSource=$prePxeInstallSource
		fi
		
		if [ "$pxe_os" == "OOPS" ] || [ "$pxe_rl" == "OOPS" ] || [ "$pxe_sp" == "OOPS" ] || [ "$archFolder" == "OOPS" ] || [ "$pxeInstallSource" == "OOPS" ] || [ "$pxeInstallOptions" == "OOPS" ] || [ "$autoInstallationType" == "OOPS" ] || [ "$installBootOption" == "OOPS" ]
		then
			#./vm-gone.sh $xenHostIp $hypervisor $machineName $machineNameFirstPart "000.000.000.000" $settingsFile
			tmpError="PXE os --$pxe_os--, PXE release --$pxe_rl--, PXE sp --$pxe_sp--, folder three --$archFolder--, autoinstallation type --$autoInstallationType--, install boot option --$installBootOption--, pxe install source --$pxeInstallSource-- or pxe install options --$pxeInstallOptions-- not set correctly"
			echo "ERROR - $tmpError"
			echo "ERROR - $tmpError" >&2
			echo "    ***** INSTALL ERRORED *****"
			popd > /dev/null; exit $rFAILED
		fi
		
		# Echo out the text to the file on the DHCP server
		export SSHPASS=$pxePass; $sshNoPass $pxeUser@$pxeServer "echo 'default $machineName' > $pxeFileName" 2> /dev/null
		export SSHPASS=$pxePass; $sshNoPass $pxeUser@$pxeServer "echo >> $pxeFileName" 2> /dev/null
		export SSHPASS=$pxePass; $sshNoPass $pxeUser@$pxeServer "echo 'label $machineName' >> $pxeFileName" 2> /dev/null
		export SSHPASS=$pxePass; $sshNoPass $pxeUser@$pxeServer "echo '        kernel /qa-virtauto/$pxe_os/$pxe_rl/$pxe_sp/$archFolder/linux' >> $pxeFileName" 2> /dev/null
		if [ -z $autoinstProfile ] 
		then
			autoyastURL="http://$httpServer/$httpAutoyastWeb/$autoyastFileName"
		
			# Get the autoyast file over to the http server
			export SSHPASS=$httpPass; cat $newLocation | $sshNoPass $httpUser@$httpServer "cat - > $httpAutoyastLocal/$autoyastFileName" 2> /dev/null
		else
			autoyastURL="$autoinstProfile"
		fi

		export SSHPASS=$pxePass; $sshNoPass $pxeUser@$pxeServer "echo '        append initrd=/qa-virtauto/$pxe_os/$pxe_rl/$pxe_sp/$archFolder/initrd $pxeInstallOptions $installBootOption=$pxeInstallSource $autoInstallationType=$autoyastURL $customInstallBootOption' >> $pxeFileName" 2> /dev/null
	fi
fi

# Remove the autoyast file from the local directory
rm -f $newLocation

# Unpause the VM
echo "    Un-pausing the VM"
export SSHPASS=$xenPass; $sshNoPass $xenUser@$xenHostIp "virsh resume $machineName" 2> /dev/null
echo "    Sleeping 30 seconds to let the VM load and access DHCP"
sleep 30

# If they have not defined an IP address, we need to get it
if [ "$machineIp" == "." ]
then
	echo "    Machine IP address was not defined, so reading it from the DHCP log file"

	# Get the IP address
	installIp=`export SSHPASS=$netinfoPass; echo mac2ip "$installMac" | $sshNoPass $netinfoUser@$netinfoServer bash -l`
	if [ "$installIp" == "" ]
	then
		if [ "$installMethod" == "iso" ]
		then
			echo "    Since this is an ISO install, we won't have an IP yet, we will get it later..."
			installIp="000.000.000.000"
		else
			if [ "$operatingSystem" == "sles" ] && [ "$release" == "9" ] && [ "$servicePack" == "sp4" ]
			then
				echo "    This is not an ISO install, and we still don't have an IP, and it is SLES 9 SP4. Waiting 300 seconds, then trying again..."
				sleep 300
			elif [ "$operatingSystem" == "sled" ] && [ "$release" == "10" ]
			then
				echo "    This is not an ISO install, and we still don't have an IP, and it is SLED 10. Waiting 180 seconds, then trying again..."
				sleep 180
			else
				echo "    This is not an ISO install, and we still don't have an IP. Waiting 90 seconds, then trying again..."
				sleep 90
			fi
			
			installIp=`export SSHPASS=$netinfoPass; echo mac2ip "$installMac" | $sshNoPass $netinfoUser@$netinfoServer bash -l`
			if [ "$installIp" == "" ]
			then
				# NOT POSSIBLE - We Don't have root access to dhcp -> cannot read messages!
				#foundLeaseError=`export SSHPASS=$dhcpPass; $sshNoPass $dhcpUser@$dhcpServer "tail --lines=50 /var/log/messages | grep -i \"no dynamic leases\"" 2> /dev/null`
				#if [[ "$foundLeaseError" =~ ^.*no\ dynamic\ leases.*$ ]]
				#then
				#	echo "    ERROR - 'No dynamic leases' message found."
				#fi

				echo "    After two attempts, still no IP from the DHCP server..."
				./vm-gone.sh $xenHostIp $hypervisor $machineName $machineNameFirstPart "000.000.000.000" $settingsFile
				tmpError="Could not retrieve IP address ($installIp) from the DHCP server"
				echo "ERROR - $tmpError"
				echo "ERROR - $tmpError" >&2
				echo "    ***** INSTALL ERRORED *****"
				rm -rf /tmp/virtautolib.$$
				popd > /dev/null; exit $rFAILED
			else
				echo "    We got the IP on the second try from the DHCP server..."
			fi
		fi
	fi
	
	echo "    IP: $installIp..."
	thisIsDHCP=yes
else
	echo "    Machine IP was already defined"
	installIp=$machineIp
	thisIsDHCP=no
fi

# Send the updated IP
#sentUpdatedIp=`curl -k -d "override=yes&updateip=yes&updateid=$installId&updateipvalue=$installIp" https://${ipweb}/automation/admin/SM-newdeploy.php 2>/dev/null`
#sentUpdatedIpResult=`echo $sentUpdatedIp | awk -F' - ' '{print $1;}'`
#if [ "$sentUpdatedIpResult" != "SUCCESS" ]
#then
#	echo "ERROR - UPDATE IP 2 - WE WERE UNABLE TO UPDATE THE DATABASE WITH THE VM IP"
#	echo "ERROR - UPDATE IP 2 - WE WERE UNABLE TO UPDATE THE DATABASE WITH THE VM IP" >&2
#fi

echo
echo "    DISCOVERED IP AND MAC STUFF"
echo "    Install MAC: $installMac..."
echo "    Install IP: $installIp..."
echo "    Is DHCP: $thisIsDHCP..."
echo

echo "    VM install kicked off!"
echo

### Monitor Installation ###
echo "    We will now monitor the VM until it is fully installed..."
./vm-monitor.sh $xenHostIp $machineName $machineNameFirstPart $installIp $installMac $thisIsDHCP $installId $settingsFile
returnVal=$?
if [ $returnVal -eq 0 ]
then
	echo "    The install completed successfully"
	installResult=PASS
	installResultMessage="The install completed successfully"
elif [ $returnVal -eq 1 ]
then
	tmpError="There was a problem monitoring the install or install did not complete successfully"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
#	installResult=ERROR  # this is not a nerror, it's a failure - install was not sussessful
	installResult=FAIL
	installResultMessage="$tmpError"
else
	tmpError="The install did not complete successfully"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	installResult=FAIL
	installResultMessage="$tmpError"
fi

# If we are fully-virtualized, 'net', we need to get rid of the pxe file and the autoyast file
if [ "$virtType" == "fv" ]
then
	if [ "$installMethod" == "ftp" ] || [ "$installMethod" == "http" ] || [ "$installMethod" == "nfs" ] || [ "$installMethod" == "net" ]
	then
		export SSHPASS=$pxePass; $sshNoPass $pxeUser@$pxeServer "rm $pxeFileName" 2> /dev/null
		export SSHPASS=$httpPass; $sshNoPass $httpUser@$httpServer "rm -f $httpAutoyastLocal/$autoyastFileName" 2> /dev/null
		if [ "$operatingSystem" == "rhel" ]
		then
			export SSHPASS=$httpPass; $sshNoPass $httpUser@$httpServer "rmdir $httpAutoyastLocal/${pxeFileName##*/}" 2> /dev/null
		fi
	fi
elif [ "$operatingSystem" == "rhel" ]
then
	SSHPASS=$httpPass; $sshNoPass $httpUser@$httpServer "rm -f $httpAutoyastLocal/$machineName.autoinstall-$$"
fi


# If they have not defined an IP address, we need to get it
if [ "$machineIp" == "." ]
then
	echo "    Since no IP was defined originally, we need to read it from the DHCP log file (it could have changed via dhcp by now)"
	
	# Get the IP address
	installIp=`export SSHPASS=$netinfoPass; echo mac2ip "$installMac" | $sshNoPass $netinfoUser@$netinfoServer bash -l`
	if [ "$installIp" == "" ]
	then
		if [ "$installResult" == "PASS" ]
		then
			./vm-gone.sh $xenHostIp $hypervisor $machineName $machineNameFirstPart "000.000.000.000" $settingsFile
			tmpError="Could not retrieve IP address ($installIp) from the DHCP server (after install), but result ($installResult - $installResultMessage)"
			echo "ERROR - $tmpError"
			echo "ERROR - $tmpError" >&2
			echo "    ***** INSTALL ERRORED *****"
			popd > /dev/null; exit $rFAILED
		else
			tmpError="No IP address was retrieved from the DHCP server after install, but since the install result was '$installResult' ($installResultMessage), this is likely a result of that other error, so we are letting that status filter through"
			echo "ERROR - $tmpError"
			echo "ERROR - $tmpError" >&2
		fi
	fi
	echo "    IP: $installIp..."
else
	echo "    Machine IP was already defined"
fi

## Send the installed IP
#if [ "$installIp" != "" ]
#then
#	sentInstalledIp=`curl -k -d "override=yes&updateip=yes&updateid=$installId&updateipvalue=$installIp" https://${ipweb}/automation/admin/SM-newdeploy.php 2>/dev/null`
#	sentInstalledIpResult=`echo $sentInstalledIp | awk -F' - ' '{print $1;}'`
#	if [ "$sentInstalledIpResult" != "SUCCESS" ]
#	then
#		echo "ERROR - UPDATE IP 2 - WE WERE UNABLE TO UPDATE THE DATABASE WITH THE VM IP"
#		echo "ERROR - UPDATE IP 2 - WE WERE UNABLE TO UPDATE THE DATABASE WITH THE VM IP" >&2
#	fi
#fi

### Performance Test ###
if [ "$performanceTest" == "YES" ]
then
	echo "    Performance tests are scheduled."
	if [ "$installResult" == "PASS" ]
	then
		echo "    Implementing performance tests."
		## Usage of vm-perf-test.sh: "vm-perf-test.sh $machineName"
		./vm-perf-test.sh $machineName
		returnVal=$?
		if [ $returnVal -eq 0 ]
		then
			echo "    The performance tests completed successfully."
			installResult=PASS
			installResultMessage="$installResultMessage -- then -- The performance tests completed successfully"
		elif [ $returnVal -eq 1 ]
		then
			tmpError="There was a problem doing the performance tests."
			echo "ERROR - $tmpError"
			echo "ERROR - $tmpError" >&2
			installResult=ERROR
			installResultMessage="$installResultMessage -- then -- $tmpError"
		else
			tmpError="The performance tests did not complete successfully."
			echo "ERROR - $tmpError"
			echo "ERROR - $tmpError" >&2
			installResult=FAIL
			installResultMessage="$installResultMessage -- then -- $tmpError"
		fi
	else
		tmpError="Performance tests were scheduled, but since the install failed, we will not attempt performance tests."
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		installResultMessage="$installResultMessage -- then -- $tmpError"
	fi
else
	echo "    No performance tests were scheduled."
fi

### Migrate ###

if [ "$xenMigratee" != "" ]
then
	echo "    A migration is scheduled"
	if [ "$installResult" == "PASS" ]
	then
		echo "    Running the migration script"
		## Usage of vm-migrate.sh: "vm-migrate.sh -n $machineName -p $migrateeIP [ -T migrationTime ] [ -l ]", default times is 2
		if [ -z $liveMigration ]; then
			./vm-migrate.sh -n $machineName -p $xenMigratee
		else
			./vm-migrate.sh -n $machineName -p $xenMigratee -l
		fi
		returnVal=$?
		if [ $returnVal -eq 0 ]
		then
			echo "    The migrate completed successfully"
			installResult=PASS
			installResultMessage="$installResultMessage -- then -- The migrate completed successfully"
		elif [ $returnVal -eq 1 ]
		then
			tmpError="There was a problem doing the migrate"
			echo "ERROR - $tmpError"
			echo "ERROR - $tmpError" >&2
			installResult=ERROR
			installResultMessage="$installResultMessage -- then -- $tmpError"
		else
			tmpError="The migrate did not complete successfully"
			echo "ERROR - $tmpError"
			echo "ERROR - $tmpError" >&2
			installResult=FAIL
			installResultMessage="$installResultMessage -- then -- $tmpError"
		fi
	else
		tmpError="A migration was scheduled, but since the install failed, we will not attempt it"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		installResultMessage="$installResultMessage -- then -- $tmpError"
	fi
else
	echo "    No migration was scheduled"
fi

### Save & Restore ###
if [ "$vmSaveRestore" == "YES" ]; then
	./vm-save.sh $machineName
	returnVal=$?
	if [ $returnVal -eq 0 ]; then
		echo "    The save completed successfully, and then it will be restored."
	else
		tmpError="There was a problem doing the save."
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		installResult=ERROR
		installResultMessage="$installResultMessage -- then -- $tmpError"
	fi
	sleep 10
	./vm-restore.sh /var/lib/$hypervisor/images/$machineName/${machineName}.save
	returnVal=$?
	if [ $returnVal -eq 0 ]; then
		echo "    The restore completed successfully, and then it will be restored."
	else
		tmpError="There was a problem doing the restore."
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		installResult=ERROR
		installResultMessage="$installResultMessage -- then -- $tmpError"
	fi
else
	echo "    No save & restore were scheduled"
fi
### Cleanup ###

# Get rid of the new install, if necessary
if [ "$removeInstall" == "YES" ]
then
	echo "    We are going to remove the installed VM..."
	./vm-gone.sh $xenHostIp $hypervisor $machineName $machineNameFirstPart $installIp $settingsFile
	returnVal=$?
	if [ $returnVal -ne 0 ]
	then
		tmpError="Could not get rid of the new install"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		echo "    ***** INSTALL ERRORED *****"
		popd > /dev/null; exit $rERROR
	fi
	rm -rf /tmp/virtautolib.$$
	returnVal=$?
	if [ $returnVal -ne 0 ]
	then    
		tmpError="Could not get rid of the iso file in /tmp/virtautolib.$$"
		echo "ERROR - $tmpError"
		echo "ERROR - $tmpError" >&2
		echo "    ***** INSTALL ERRORED *****"
		popd > /dev/null; exit $rERROR
	fi
else
	echo "    We are not going to remove the installed VM"
fi

### Finish ###

if [ "$installResult" == "PASS" ]
then
	echo "    ***** INSTALL PASSED *****"
	retval=$rPASSED
elif [ "$installResult" == "FAIL" ]
then
	echo "    ***** INSTALL FAILED *****"
	retval=$rFAILED
else
	echo "    ***** INSTALL ERRORED *****"
	retval=$rERROR
fi

echo "    Install Result: $installResult..."
echo "    ------------------"
echo " "

popd > /dev/null
exit $retval

