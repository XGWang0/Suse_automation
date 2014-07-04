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
suseInsertService hamsta-master

suseConfig

echo "creating hasmta DB"
/etc/init.d/mysql start

PASS='susetesting'

# set up root password to mysql to susetesting
/usr/bin/mysqladmin -u root password "$PASS"

# create hamsta database
cd /usr/share/hamsta/db
DBPASSISSET=yes DBPASS="$PASS" sh ./create_db.sh

# change global QA configuration for hamsta to point to correct file
echo "update qaconf set sync_url='http://{{ network.hamsta.fqdn }}/global.conf' where qaconf_id=1;" | mysql -u root -p$PASS hamsta_db

/etc/init.d/mysql stop

echo -n "Starting repoindexing scripts"
	python /srv/www/htdocs/hamsta/update-repo-index.py -r {{ proxy.urlmap['slp'] }} -s {{ proxy.urlmap['slp'] }} -o /srv/www/htdocs/hamsta/virtenv


#======================================
# Umount kernel filesystems
#--------------------------------------
baseCleanMount

#======================================
# Exit safely
#--------------------------------------
exit 0
