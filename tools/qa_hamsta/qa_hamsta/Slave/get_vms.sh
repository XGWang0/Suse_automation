#!/bin/bash

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
