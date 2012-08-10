#!/bin/bash

DB=qadb
DBUSER=root

ask=no

function usage
{
	echo >&2
	echo "Usage: $0 [-a]" >&2
	echo "       -a ... ask before each patch is updated" >&2
	echo >&2
}

if [ $# -gt 1 ] ; then
	usage
	exit 1
fi

if [ "$1" != "" ] ; then
	if [ "$1" == "-a" ] ; then
		ask=yes
	elif [ "$1" == "-h" ] ; then
		usage
		exit 0
	else
		echo Invalid argument: $1
		usage
		exit 1
	fi
fi

# read password
if [ -z $DBPASSISSET ] ; then
	# read password
	echo -n "DB Password: "
	stty -echo
	read DBPASS
	stty echo
	echo
 	# check password
	echo | mysql --user="$DBUSER" --password="$DBPASS" "$DB" || exit 1

	export DBPASS
	export DBPASSISSET="yes"
fi

if [ "`echo 'show tables;' | mysql --user="$DBUSER" --password="$DBPASS" "$DB" | grep '^schema$' | wc -l`" == "0" ] ; then
	echo "Database $DB is too out-of date and does not support migration. Please update the DB manually and try again" >&2
	exit 1;
fi

version="`echo "select version from $DB.schema;" | mysql --user="$DBUSER" --password="$DBPASS" "$DB" | tail -n1`"

echo DB version is $version.

for p in patches/* ; do
	if [[ "$p" =~ ^patches/([[:digit:]]{12})_.*\.sql ]] ; then
		# it is a patch
		if [ "${BASH_REMATCH[1]}" -gt "$version" ] ; then
			if [ "$ask" == "yes" ] ; then
				# need confirmation
				answer="xxx"
				while [ "$answer" != 'yes' -a "$answer" != 'no' ] ; do
					echo -n "Apply patch $p? ([yes]/no) "
					read answer
					[ "$answer" == "" ] && answer="yes"
				done
				if [ "$answer" != "yes" ] ; then
					echo "Terminating..."
					exit 0
				fi
			fi
			echo "Applying $p..."
			mysql --user="$DBUSER" --password="$DBPASS" "$DB" < "$p" || exit $? # Error already reported
			echo "update $DB.schema set version='${BASH_REMATCH[1]}';" | mysql --user="$DBUSER" --password="$DBPASS" "$DB"
			version="${BASH_REMATCH[1]}"
			echo DB updated to version is $version.
		else
			echo "Skipping $p - already applied." >&2
		fi
	else
		echo "Skipping file $p - it does not have correct name." >&2
	fi
done

echo Updating DB stats
mysqlcheck --analyze --user="$DBUSER" --password="$DBPASS" "$DB"

