#!/bin/bash

DBHOST=localhost
DBUSER=root
DB=qadb

# read password
echo -n "DB Password: "
stty -echo
read DBPASS
stty echo
echo

DBCMD="mysql --user=\"$DBUSER\" --password=\"$DBPASS\" -h \"$DBHOST\" \"$DB\""
# check password
echo | sh -c "$DBCMD" || exit 1

# SELECT TABLE_NAME, CONSTRAINT_NAME, CONCAT( table_name, '.', column_name, ' -> ', referenced_table_name, '.', referenced_column_name ) AS list_of_fks, CONCAT('ALTER TABLE ', TABLE_NAME, ' DROP FOREIGN KEY ', CONSTRAINT_NAME, ';') AS cmd FROM information_schema.KEY_COLUMN_USAGE WHERE REFERENCED_TABLE_SCHEMA = 'hamsta_db' AND REFERENCED_TABLE_NAME is not null ORDER BY TABLE_NAME, COLUMN_NAME;


cat << EOF | sh -c "$DBCMD" | grep -v 'cmd'
SELECT CONCAT('ALTER TABLE ', TABLE_NAME, ' DROP FOREIGN KEY ', CONSTRAINT_NAME, ';') AS cmd FROM information_schema.KEY_COLUMN_USAGE WHERE REFERENCED_TABLE_SCHEMA = '$DB' AND REFERENCED_TABLE_NAME is not null ORDER BY TABLE_NAME, COLUMN_NAME;
EOF

for t in `echo 'show tables;' | sh -c "$DBCMD" | grep -v "Tables_in_$DB"`; do 
#	echo "show create table \`$t\`;" | sh -c "$DBCMD" | sed 's/\\n/\n/g' | grep 'FOREIGN KEY' | sed 's/^.*\(FOREIGN KEY (`\([^`]*\)`) REFERENCES `\([^`]*\)` (`\([^`]*\).*[^,]\),\?[[:space:]]*$/ALTER TABLE XXXAAAXXXAAA ADD CONSTRAINT fk_XXXAAAXXXAAA_\2_\3_\4 \1;/' | sed "s/XXXAAAXXXAAA/$t/g" 
	echo "show create table \`$t\`;" | sh -c "$DBCMD" | sed 's/\\n/\n/g' | grep 'FOREIGN KEY' | sed 's/^.*\(FOREIGN KEY (`\([^`]*\)`) REFERENCES `\([^`]*\)` (`\([^`]*\).*[^,]\),\?[[:space:]]*$/ALTER TABLE XXXAAAXXXAAA ADD CONSTRAINT fk_XXXAAAXXXAAA_\3 \1;/' | sed "s/XXXAAAXXXAAA/$t/g" 
done


