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

dirname=`dirname $0`
pushd $dirname > /dev/null

#propFile="../data/settings.properties"

print_usage()
{
	echo "Usage: $0 --help -h -help | [-s] -p"
	echo "Options: "
	echo " -h,-help,--help - Prints the full usage"
	echo " -p <property>"
	echo " -s [<settingsfilepath>]"
	popd > /dev/null; exit 1
}

print_full_usage()
{
	echo "Purpose: This program will get rid of a VM on a host (if necessary) and kick off a new, fully-automated VM install"
	echo
	echo "Usage: $0 --help -h -help | -p -s"
	echo
	echo "Options: "
	echo
	echo " -h,-help,--help"
	echo "        - Prints this full usage message"
	echo
	echo
	echo " -p <property>"
	echo "        - The name of the property to retrieve."
	echo "        - EXAMPLE: dhcp.ip"
	echo
	echo
	echo " -s [<settingsfilepath>]"
	echo "        - The path to the settings file to use."
	echo "        - DEFAULT: ../data/settings.properties"
	echo
	echo 
	echo "Examples:"
	echo "        $0 -s ../data/test-settings.properties -p dhcp.ip"
	echo "        $0 -p dhcp.ip"
	echo "        $0 dhcp.ip"
	popd > /dev/null; exit 1 
}

if [ $# -eq 1 ]
then
	if [ "${1}" == "--help" ] || [ "${1}" == "-help" ] || [ "${1}" == "-h" ]
	then
		print_full_usage
		popd > /dev/null; exit 1
	fi
fi

### COMMAND LINE ###

# Defaults we provide
propFile=../data/settings.properties

# Required
property=${1}
if [ "${1}" == "-s" ]
then
	property=${3}
fi

while getopts "p:s:" OPTIONS
do
	case $OPTIONS in
		s) propFile="$OPTARG";;
		p) property="$OPTARG";;
		\?) echo "ERROR - Invalid parameter" >&2; print_usage; popd > /dev/null; exit 1;;
		*) echo "ERROR - Invalid parameter" >&2; print_usage; popd > /dev/null; exit 1;;
	esac
done

if [ "${propFile}" == "" ]
then
	echo "ERROR - You must specify a property file." >&2
	popd > /dev/null
	exit 1
#else
#	echo "INFO - Using settings file '${propFile}'."
#	echo "INFO - Using settings file '${propFile}'." >&2
fi

if [ "${property}" == "" ]
then
	echo "ERROR - You must specify a property for getSettings." >&2
	popd > /dev/null
	exit 1
fi

quotedProperty=${property//./\/.}

returnVal=`cat $propFile | grep "^${property}\=" | awk -F\= '{print $2;}'`

if ! grep -q "^${property}\=" "$propFile"
then
	echo "ERROR - Property '${property}' does not exist in the properties file" >&2
	popd > /dev/null
	exit 1
fi

if [ "$returnVal" == "" ]
then
	echo "NOTICE - Property '${property}' exists in the properties file, but is empty..." >&2
fi

echo "$returnVal"

popd > /dev/null

