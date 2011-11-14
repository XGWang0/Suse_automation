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


# get the list of all virtual machines running on this hosts in format:
# mac_type;mac_type;...
#
# this list can contain multiple entries for one vm if it has more nic

export LANG=C

# not virsh -> not virtualization
which virsh > /dev/null 2>&1 || exit 0

# no virtualization running
virsh connect > /dev/null 2>&1 || exit 0

# xpath is needed on vhosts
which xpath > /dev/null 2>&1 || exit 0

first="yes"
for i in `virsh list --all | grep -v '^$' | tac | head -n -2 | grep -v 'Domain-0' | awk '{ print $2; }'` ; do
	[ $first == "yes" ] || echo -n ';'
	[ $first == "yes" ] && first="no"

	xml="`virsh dumpxml $i`"
	if echo "$xml" | xpath /domain/os/type 2> /dev/null | grep -q hvm; then
		vmtype='fv'
	else
		vmtype='pv'
	fi
	
	firstmac="yes"
	for mac in `echo "$xml" | xpath /domain/devices/interface/mac/@address 2> /dev/null | sed 's/.address="\([^"]*\)".*/\1/' | tr a-f A-F` ; do 

		[ $firstmac == "yes" ] || echo -n ';'
	        [ $firstmac == "yes" ] && first="no"
		echo -n "${mac}_$vmtype"
	done
done

