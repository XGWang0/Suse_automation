#!/bin/bash
# ****************************************************************************
# Copyright © 2011 Unpublished Work of SUSE. All Rights Reserved.
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

sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"

print_usage()
{
	echo "Usage: $0 --help -h -help | -a <architecture> [-i] [-I <initrd_name>] [-k] [-K <kernel_name>] [-t <target_directory>] -o <os> -s <source>"
	popd > /dev/null; exit 1
}

print_full_usage()
{
	echo "Purpose: This program downloads kernel and initrd from provided installation source url."
	echo
	echo "Usage: $0 --help -h -help | -a <architecture> [-i] [-I <initrd_name>] [-k] [-K <kernel_name>] [-t <target_directory>] -o <os> -s <source>"
	echo
	echo "Options: "
	echo
	echo " -h,-help,--help"
	echo "        - Prints this full usage message"
	echo
	echo " -a <architecture>"
	echo "        - The architecture (ix86, x86_64)"
	echo "        - EXAMPLE: ix86"
	echo
	echo " -i"
	echo "        - Download initrd"
	echo
	echo " -I <initrd_name>"
	echo "        - Name of file initrd will be downloaded to. Implies -i"
	echo "        - DEFAULT: initrd"
	echo
	echo " -k"
	echo "        - Download kernel"
	echo
	echo " -k <kernel_name>"
	echo "        - Name of file kernel will be downloaded to. Implies -k"
	echo "        - DEFAULT: linux"
	echo
	echo " -t <target_directory>"
	echo "        - directory the files will be downloaded into"
	echo "        - DEFAULT: ./"
	echo
	echo " -o <operatingSystem>"
	echo "        - The guest operating system that you want to install"
	echo "        - The supported operating systems are: suse, rhel"
	echo
	echo " -s <source>"
	echo "        - URL of installation source. Currently, only http and ftp are supported"
	echo
	popd > /dev/null; exit 1
}

if [ $# -eq 1 ]
then
	if [ "${1}" == "--help" ] || [ "${1}" == "-help" ] || [ "${1}" == "-h" ]
	then
		print_full_usage
		popd > /dev/null; exit $rERROR
	fi
fi

### COMMAND LINE ###

# Defaults we provide
architecture=
getInitrd=0
getKernel=0
initrdName=initrd
kernelName=linux
targetDir=`pwd`
operatingSystem=suse
installSource=

while getopts "a:iI:kK:t:o:s:" OPTIONS
do
	case $OPTIONS in
		a) architecture="$OPTARG";;
		i) getInitrd=1;;
		I) initrdName="$OPTARG"; getInitrd=1;;
		k) getKernel=1;;
		K) kernelName="$OPTARG"; getKernel=1;;
		t) targetDir="$OPTARG";;
		o) operatingSystem="$OPTARG";;
		s) installSource="$OPTARG";;
		\?) echo "ERROR - Invalid parameter"; echo "ERROR - Invalid parameter" >&2; print_usage; popd > /dev/null; exit 1;;
		*) echo "ERROR - Invalid parameter"; echo "ERROR - Invalid parameter" >&2; print_usage; popd > /dev/null; exit 1;;
	esac
done

#
# Argumetns verification
#

if [ $getInitrd -eq 0 -a $getKernel -eq 0 ]
then
	tmpError="Please specify what should be downloaded (-i and/or -k)."
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

if ! echo "$architecture" | grep -q '^ix86\|x86_64$'
then
	tmpError="Please specify architecture. Architecture can be one of: ix86, x86_64."
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

if [ "$initrdName" == "" -a $getInitrd -eq 1 ] || [ "$kernelName" == "" -a $getKernel -eq 1 ]
then
	tmpError="You must provide nonempty target filename for kernel/initrd"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

if ! echo "$operatingSystem" | grep -q '^suse\|rhel$'
then
	tmpError="Please specify OS type. It can be one of: suse, rhel."
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

if ! echo "$installSource" | grep -q '^\(http\|ftp\)://'
then
	tmpError="Specified installation source '$installSource' is not supported."
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi

# Change to targetDirectory
if ! cd "$targetDir"
then
	tmpError="Unable to chdir to target directory '$targetDir'"
	echo "ERROR - $tmpError"
	echo "ERROR - $tmpError" >&2
	print_usage
fi



# Get the correct/possible paths
case $operatingSystem in
suse)
	case $architecture in
		x86_64)
			pxeArchs=x86_64
			;;
		ix86)
			pxeArchs="i586 i386 i686"
			;;
	esac
	pxePathBase=boot/PXE_ARCH_FOLDER/loader
	pxeInitrdName=initrd
	pxeKernelName=linux
	;;

rhel)
	case $architecture in
		x86_64)
			pxeArchs=x86_64
			;;
		ix86)
			pxeArchs="i386"
			;;
	esac
	pxePathBase=images/pxeboot
	pxeInitrdName=initrd.img
	pxeKernelName=vmlinuz
	;;

esac

# Download
res=1
echo $pxeArchs ' + ""'
for arch in $pxeArchs "" # e.g. sles9 does not have arch-subfolder -> "" is needed
do
	urlbase="$installSource/`echo $pxePathBase | sed "s/PXE_ARCH_FOLDER/$arch/"`"
	echo "Trying url-base: $urlbase ..."
	if [ $getInitrd -eq 1 ] ; then
		wget -q "$urlbase/$pxeInitrdName" -O "$initrdName"
		res=$?
		[ $res -eq 0 ] && echo "Successfully dowloaded initrd image: $initrdName"
	fi
	if [ $getKernel -eq 1 ] ; then
		wget -q "$urlbase/$pxeKernelName" -O "$kernelName"
		res=$?
		[ $res -eq 0 ] && echo "Successfully dowloaded kernel image: $kernelName"
	fi
	[ $res -eq 0 ] && break

	echo "Bad url-base: $urlbase ..."
done

exit $res


