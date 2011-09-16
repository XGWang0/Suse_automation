#!/bin/bash

DB=hamsta_db
DBUSER=root

# read password
if [ -z $DBPASSISSET ] ; then
	# read password
	echo -n "DB Password: "
	stty -echo
	read DBPASS
	stty echo
	echo
 	# check password
	echo | mysql --user="$DBUSER" --password="$DBPASS" || exit 1

	export DBPASS
	export DBPASSISSET="yes"
fi


if [ "`echo 'show databases;' | mysql --user="$DBUSER" --password="$DBPASS" | grep "^$DB\$" | wc -l`" == "1" ] ; then
	echo "Error: Database $DB already exist." >&2
	exit 1;
fi

if echo "create database $DB;" | mysql --user="$DBUSER" --password="$DBPASS" && mysql --user="$DBUSER" --password="$DBPASS" "$DB" < create_unpatched_db.sql
then
	echo "Initial version of database successfully created, updating to the most recent version..."
	./update_db.sh
fi
