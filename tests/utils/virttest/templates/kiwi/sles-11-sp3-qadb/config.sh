#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$kiwi_iname]..."

#======================================
# Mount system filesystems
#--------------------------------------
baseMount

suseSetupProduct

#======================================
# Call configuration code/functions
#--------------------------------------
suseActivateDefaultServices
suseInsertService apache2
suseInsertService mysql

suseConfig

PASS=susetesting

/etc/init.d/mysql start

# set up root password to mysql to susetesting
/usr/bin/mysqladmin -u root password $PASS

# create qadb database
cd /usr/share/qadb/db
DBPASSISSET=yes DBPASS=$PASS sh ./create_db.sh

# create access for qa-db-report
mysql -u root -p$PASS << eof
create user 'qadb'@'%' identified by 'qadb';
grant select,insert,update,delete,lock tables on qadb.* to 'qadb'@'%';
grant all on qadb_tmp.* to 'qadb'@'%';
flush privileges;
eof

/etc/init.d/mysql stop

mkdir -p /srv/www/htdocs/Results
chmod 777 /srv/www/htdocs/Results

echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config

chmod 600 /home/rd-qa/.ssh/id_dsa
chown -R rd-qa:users /home/rd-qa
chown -R rd-qa:users /home/rd-qa/.ssh

chmod 777 /var/log/qa-remote-results

baseSetupUserPermissions



#======================================
# Umount kernel filesystems
#--------------------------------------
baseCleanMount

#======================================
# Exit safely
#--------------------------------------
exit 0
