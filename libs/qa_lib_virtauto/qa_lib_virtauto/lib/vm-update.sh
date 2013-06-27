#!/bin/bash
# ****************************************************************************
# Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
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


# Script Variables
ARGS=1
E_BADARGS=65
E_USERABORT=66
E_NOTROOT=67
E_SCRIPTERROR=68
RPM_DIR="/tmp/rpms"
ARCH=$(arch | sed "s/686/586/")
SERVER="151.155.144.100"
ROOTDIR="builds"
BUILDDIR="stable"

# Initialize User Options
FORCE=0
NO_DEPS=""
GET64=0
IGNORE_ARCH=""
COPY_ONLY=0
XEN_ONLY=0
TOOLS_ONLY=0
KERNEL_ONLY=0
INSTALL_KERNEL_PAE=0

if [ $# -lt "$ARGS" ]
then
	echo "Usage: $(basename $0) project_version [directory] [options]"
	echo "Valid Options Include:"
	echo "  force     Force rpm installation"
	echo "  nodeps    Install with rpm --nodeps option"
	echo "  64        Download 64-bit version of the hypervisor"
	echo "  copyonly  Copies the rpms but does not install them"
	echo "  xen       Updates only xen*.rpm"
	echo "  kernel    Updates only kernel-xen*.rpm"
	echo "  tools     Updates only management tools (e.g. vm-install)"
	exit $E_BADARGS
fi

if [ $(whoami) != "root" ]
then
	echo "Error: This script must be run as root"
	exit $E_NOTROOT
fi

PROJECT=$1

while [ ! "$2" == "" ]
do
	case "$2" in
		force    ) FORCE=1 ;;
		nodeps   ) NO_DEPS="--nodeps" ;;
		64       ) GET64=1 ;;
		copyonly ) COPY_ONLY=1 ;;
		xen      ) XEN_ONLY=1 ;;
		kernel   ) KERNEL_ONLY=1 ;;
		tools    ) TOOLS_ONLY=1 ;;
		*        ) 
			if [ "$BUILDDIR" == "stable" ]
			then
				BUILDDIR="$2"
			else
				echo "Error: Invalid Parameter: $2 "
				echo -n "Abort operation? (Y/n) "
				read -t 10 ABORT
				case "$ABORT" in
					n | N ) 
						echo "Parameter ignored: $2"
						;;
					* )
						echo "$(basename $0) aborted."
						exit $E_USERABORT
						;;
				esac
			fi
			;;
	esac
	shift
done

## Setup rpm directory and remove old rpms
if [ ! -e $RPM_DIR ]
then
	mkdir -p $RPM_DIR
fi

cd $RPM_DIR
rm -f *.rpm

## Copy RPMS from server
if [ "$XEN_ONLY$KERNEL_ONLY$TOOLS_ONLY" == "000" ]
then 
	wget ftp://$SERVER/$ROOTDIR/$PROJECT/$BUILDDIR/$ARCH/*
else
	if [ "$XEN_ONLY" == "1" ]
	then
		wget ftp://$SERVER/$ROOTDIR/$PROJECT/$BUILDDIR/$ARCH/xen*.rpm
	fi
	if [ "$KERNEL_ONLY" == "1" ]
	then
		wget ftp://$SERVER/$ROOTDIR/$PROJECT/$BUILDDIR/$ARCH/kernel-xen*.rpm
	fi
	if [ "$TOOLS_ONLY" == "1" ]
	then
		wget ftp://$SERVER/$ROOTDIR/$PROJECT/$BUILDDIR/$ARCH/vm-install*.rpm
	fi
fi

if [[ "$GET64" == "1" && "$ARCH" != "x86_64" && "$KERNEL_ONLY" != "1" ]]
then
	rm -f xen-[34]*.i586.rpm rm xen.i586.rpm
	wget ftp://$SERVER/$ROOTDIR/$PROJECT/$BUILDDIR/x86_64/xen-[34]*.rpm
	wget ftp://$SERVER/$ROOTDIR/$PROJECT/$BUILDDIR/x86_64/xen.x86_64.rpm
	IGNORE_ARCH="--ignorearch"
fi

if [ "$COPY_ONLY" == "1" ]
then
	echo "Copy complete."
	echo "RPMs can be found in $RPM_DIR"
	exit 0
fi

# Install Dependencies
if [ -e /root/bin/dependencies.lst ]
then
	if [ "$(stat -c %b /root/bin/dependencies.lst)" != "0" ]
	then
		openvt -l -w -- yast -i $(cat /root/bin/dependencies.lst)
	fi
fi

# Install RPMs
if [ "$FORCE" = "1" ]
then
	rm xen-kmp*.rpm
	rm xen-tools-domU*.rpm
	rm kernel-xen-devel*.rpm
	rm kernel-source*.rpm
	rpm -Uvh --force $IGNORE_ARCH $NO_DEPS *.rpm
else
	rm kernel-xen-devel*.rpm
	rpm -Fvh $IGNORE_ARCH $NO_DEPS *.rpm
fi

