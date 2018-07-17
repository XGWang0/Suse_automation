#!/bin/bash

export LANG=C

dirname=`dirname $0`
pushd $dirname > /dev/null
currentHostName=`hostname`

getSettings="./get-settings.sh"
getSource="./get-source.sh"
autoInstallation="../data/autoinstallation"

export guest_user=`$getSettings vm.user`
export guest_password=`$getSettings vm.pass`
export SSHPASS=$guest_password
export sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"


# Standard QA return values
rPASSED=0
rFAILED=1
rERROR=11
rSKIPPED=22

source ./virtlib

source /usr/share/qa/qa_test_virtualization/shared/standalone

function interrupt
{
	trap '' SIGINT
	echo "Interrupted - destroying the vm if exist and exiting with ERROR" >&2

	# delete the domU
	echo "destroy $goname"
	virsh destroy $goname

	echo "undefine $goname"
	virsh undefine $goname

	# delete the temp files
	rm -rf /var/lib/libvirt/images/$goname.*
	
	trap - SIGINT
	exit $rERROR
}
trap interrupt SIGINT

function handleExit
{
	exitCode=$1
	
	#remove the install iso from the guest to let other guest use it to install
	if [[ $goname == *iso* ]];then
		if virsh dominfo $goname > /dev/null 2<&1;then
			rmCdromFromGuest $goname
		fi
	fi

	exit $exitCode
	
}

#default value


#p for paravirutal v for fullvirtual
virttype=v
imageformat=qcow2
imagesize=20
memsize=1024



print_usage()
{
	echo "Usage: $0 --help | -b -o -r -p -c -t -n -m -g"
	echo "-h Prints the full usage"
	echo "-u Do not remove the guest after installation"
	echo "-d Load install kernel/initrd"
	echo "-a <addition arg>"
	echo "-b <Bridge>"
	echo "-c <Architecture>"
	echo "-D <OS Disk mode>"
	echo "-f <DiskImageFormat>"
	echo "-k <MemSize Mb>"
	echo "-l <Location>"
	echo "-m <InstallMethod>"
	echo "-n <InstallScenario>"
	echo "-N <Network opt>"
	echo "-o <OperatingSystem>"
	echo "-p <ServerPack>"
	echo "-r <Release>"
	echo "-s <DiskSize>"
	echo "-t <VirtualizationType>"
	echo "-y <Hostip>"
	echo "-g <CustomGuestName>, must follow traditional format, just put customized string at last"
	echo "-x <extra args>"
	exit 1
}


while getopts "hdua:b:c:D:f:k:l:m:n:o:p:r:s:t:y:g:x:" OPTIONS
do
	case $OPTIONS in
		h) print_usage;;
		d) directly="true";;
		D) disk_mod=$OPTARG;;
		u) noremove="true";;
		a) addition="$OPTARG";;
		b) bridge="$OPTARG";;
		c) architecture="$OPTARG";;
		f) imageformat="$OPTARG";;
		k) memsize="$OPTARG";;
		l) opt_location="$OPTARG";;
		m) method="$OPTARG";;
		n) scenario="$OPTARG";;
		N) netopt="$OPTARG";;
		o) operatingsystem="$OPTARG";;
		p) servicepack="$OPTARG";;
		r) release="$OPTARG";;
		s) imagesize="$OPTARG";;
		t) virttype="$OPTARG";;
		y) hostip="$OPTARG";;
		g) guest_custom_name="$OPTARG";;
		x) extraargs="$OPTARG";;
	esac

done

if [ -n "$addition" ];then
	subfix=`echo $addition|sed 's/ \+//g;s/=/_/g;s/,/_/g;s/--/_/g;s/:/_/g;s/\.//g;s/_//g;s/\//_/g'`
	subfix=`echo $addition|sed 's/ \+//g'|md5sum|sed 's/ .*//;s/.........$//'`
else

addition=" "
fi

if [ -z "$guest_custom_name" ];then
	goname="$operatingsystem-$release-$servicepack-$architecture-$virttype-$scenario-$method$subfix"
else
	goname="$guest_custom_name"
fi

echo "Guest os name is :$goname "
#Verify the guest name
if virsh domstate $goname &>/dev/null ;then
	echo "guest already exist, Exit..."
	rm_vm $goname
fi

#Host ip

if [ -z "$hostip" ];then
	hostip=$IP
fi

if [ -z "$bridge" ];then
	bridge=$BR
fi

#Setup the virtualization type
if [ $virttype == "fv" ];then
	virt_type=v
else
   	virt_type=p
	#verify the xen kernel
	if ! uname -a|grep -i xen && [ ! -e /proc/xen/privcmd ];then
		echo "paravirtualization should under xen server"
		exit 1
	fi
fi

#Run cmd depand on different hyper visor
if ! uname -a|grep -i xen && [ ! -e /proc/xen/privcmd ];then
	kvm_hook
else
	xen_hook
fi

#gerenate mac address
macaddr=`mac_gen`
echo "Use mac address: $macaddr"


#Three ways to install Guest host
#1.PXE        for net method
#2.HTTP/FTP   for net method
#3.NFS/ISO    for iso method

#Get auto-install kernel option
ik_opt=`get_ik_opt $hostip|tail -1`

if [ $method = "net" ];then
	if [ "$directly" = "true" ];then
		location=`get_install_url_location`
	else
		#by default , we use pxe 
		#Setup pxe server on localhost
		echo "Start to setup pxe server for $macaddr at HOST: $hostip"
		pxe_setup $macaddr $hostip
		ik_opt=""
	fi
elif [ $method = "iso" ];then
	#ISO way
	#Setup iso location
	echo "Start to setup iso install"
		location=`get_install_iso_location|tail -1`
		ik_opt=`get_ik_opt $hostip iso|tail -1`
		if [ -z "$location" ];then
			echo "The localtion for $goname does not exist"
			exit 1
		fi
else 
	echo "Install method is not supported"
fi

#if got extra args,must require a location
if [ -n "$extraargs"  -a  -n "$opt_location" ];then
	#overwrite the location,read it from command line opt
	location=$opt_location
	ik_opt="ignore"
fi


#Install the guest host

echo "Perform the installation"
echo "Install guest with param: $virt_type $goname $macaddr $bridge $imageformat $imagesize $ik_opt $location $extraargs"

#Clear the vm disk.
rm -rf /var/lib/libvirt/images/$goname.$imageformat
/usr/bin/qemu-img create -f $imageformat /var/lib/libvirt/images/$goname.$imageformat $imagesize"g"


if [ -n "$disk_mod" ];then
	disk_mod=",bus=$disk_mod"
fi
disk="--disk path=/var/lib/libvirt/images/$goname.$imageformat,size=$imagesize,format=$imageformat$disk_mod"


if [ -n "$netopt" ];then
	net_mod=",model=$netopt"
fi

#Different os with different extar-args
autoyast=$ik_opt
if [ -n "$autoyast" ];then
	if echo $autoyast|grep -q "device:\|notused";then
		#iso way
		iso_location=${autoyast##*,}
		autoyast=${autoyast%%,*}
		if [ "$operatingsystem" = "win" ];then
		extra_args="--disk path=$iso_location,device=cdrom "
		else
		extra_args="--disk path=$iso_location,device=cdrom --extra-args \"$autoyast\""
		fi
	else
		extra_args="--extra-args \"$autoyast\""
	fi
else
	extra_args=""
fi

#Location : install repos
if [ -n "$location" ];then
	if [ "$operatingsystem" = "win" ];then
	location="--disk path=$location,device=cdrom"
	else
	location="--location $location "
	fi
else
	location="--pxe "
	#All option should keep in the pxe config file
	extra_args=""
fi

if [ -n "$extraargs" ];then

extra_args="--extra-args \"$extraargs\""

fi


echo "the virt-install param is :"

echo "
/usr/bin/virt-install \
  --name $goname \
  -$virt_type \
  $location \
  $extra_args \
  $disk \
  --network=bridge=$bridge$net_mod \
  --ram=$memsize \
  --vcpu=2 \
  --vnc \
  --serial pty \
  --noautoconsole \
  $addition 


"
/usr/bin/virt-install \
  --name $goname \
  -$virt_type \
  $location \
  $extra_args \
  $disk \
  --network=bridge=$bridge,mac=$macaddr$net_mod \
  --ram=$memsize \
  --vcpu=2 \
  --vnc \
  --serial pty \
  $addition \
  --noautoconsole \


#Check installation timeout (mins) ,give a verylong time, ctcs2 will handle the timeout.

echo "Installation is running, Start to check timeout for installing guest OS "
t_check $goname 60

#wait some time between operations
sleep 5

#Verify

#windows require boot to get dhcp to work
if [ "$operatingsystem" = "win" ];then
	virsh start $goname
	if [ $release -ge 10 ];then
		sleep 1800
	else
		sleep 600
	fi
	echo "Start to get ip address by mac :$macaddr"
	goip=`get_ip_by_mac $macaddr|tail -1`
	if [ "$goip" = "mac-err" ];then
		echo "Can Not get ip address from dhcp log"
		handleExit 1
	fi
	echo "the ip address is : $goip"
else

	echo "Start to get ip address by mac :$macaddr"
	goip=`get_ip_by_mac $macaddr|tail -1`
	if [ "$goip" = "mac-err" ];then
		echo "Can Not get ip address from dhcp log"
		handleExit 1
	fi
	echo "the ip address is : $goip"
	
	#Check the second step installation work
	
	p_check  $goname 20 $goip
fi
	
	
echo "Verify the installation of $goname with ip $goip"
result=`install_verify $goname $goip|tail -1`

#save the xml of GUEST
virsh dumpxml $goname > /tmp/virt-install_screenshot/${goname}.xml

if [ "$result" = "pass" ];then
	echo "installation pass"
	#remove the screenshot
	rm /tmp/virt-install_screenshot/$goname*
	if [ "$noremove" = "true" ];then
		shutdown_vm $goname
	else
		rm_vm $goname
	fi
	handleExit 0
else
	echo "installation failed : $result"
	screenshot $goname /tmp/virt-install_screenshot/ log
	shutdown_vm $goname
	handleExit 1
fi
