#!/bin/bash

export LANG=C

dirname=`dirname $0`
cd "$dirname"

print_usage()
{
	echo "Usage: $0 --help -h -help | [-s] -p"
	echo "Options: "
	echo " -h,-help,--help - Prints the full usage"
	echo " -p <source>"
	echo " -s [<settingsfilepath>]"
	popd > /dev/null; exit 1
}

print_full_usage()
{
	echo "Purpose: This program will obtain the correct installation source"
	echo
	echo "Usage: $0 --help -h -help | -p -s"
	echo
	echo "Options: "
	echo
	echo " -h,-help,--help"
	echo "        - Prints this full usage message"
	echo
	echo
	echo " -p <installation source>"
	echo "        - The name of the property to retrieve."
	echo "        - EXAMPLE: source.iso.win-xp-sp1-64"
	echo
	echo
	echo " -s [<sourcesfilepath>]"
	echo "        - The path to the settings file to use."
	echo "        - DEFAULT: ../data/sources.local, if it does not exist, use ../data/sources.<location>"
	echo
	echo 
	echo "Examples:"
	echo "        $0 -s ../data/test-sources -p source.iso.win-xp-sp1-64"
	echo "        $0 -p source.iso.win-xp-sp1-64"
	echo "        $0 source.iso.win-xp-sp1-64"
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
propFile=

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
	propFile=../data/sources.local
	if [ ! -r $propFile ] ; then
		location="`/usr/share/qa/tools/location.pl | awk '{ print $NF; }'`"
		[ "$location" == "(unknown)" -o -z $location ] || propFile="../data/sources.$location"
	fi
fi

if [ ! -r "$propFile" ]
then
	echo "ERROR - $propFile does not exist or is unreadable." >&2
	popd > /dev/null
	exit 1
fi



if [ "${property}" == "" ]
then
	echo "ERROR - You must specify a property for get-source." >&2
	popd > /dev/null
	exit 1
fi

./get-property.sh -p "${property}" -s "${propFile}"

