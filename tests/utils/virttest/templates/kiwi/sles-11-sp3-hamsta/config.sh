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
suseInsertService nfsserver

suseConfig

echo "creating hasmta DB"
/etc/init.d/mysql start

PASS='susetesting'

# set up root password to mysql to susetesting
/usr/bin/mysqladmin -u root password "$PASS"

# create hamsta database
cd /usr/share/hamsta/db
DBPASSISSET=yes DBPASS="$PASS" sh ./create_db.sh

# add testsuser
mysql -uroot -p$PASS hamsta_db << EOF
INSERT INTO user
(extern_id,
 login,
 name,
 email,
 password
)
VALUES
('https://www.suse.com/openid/user/testuser',
 '{{ testuser.login }}',
 '{{ testuser.name }}',
 'testuser@testpage.org',
 SHA1('{{ testuser.password }}')
);

INSERT INTO user_in_role (user_id, role_id) 
  SELECT \`user\`.user_id, role_id FROM \`user\`, user_role 
  WHERE login = '{{ testuser.login }}' AND role = 'user';
EOF

# enter QA config values into hamsta network configuration

# read the qa custom config & remove comments and empty lines
cat /etc/qa/80-virtenv | sed 's/#.*$//' | grep -v '^\W*$' | while read line # process by lines
do
	k=`echo $line | cut -d= -f1`                        # key
	v=`echo $line | cut -d= -f2 | sed "s/^[\"']\(.*\)[\"']\s*\$/\1/"` # value without ' or "
	echo "insert ignore into qaconf_key (qaconf_key) values ('$k');"
	subselect="select qaconf_key_id from qaconf_key where qaconf_key='$k'"
	echo "insert into qaconf_row (qaconf_id, qaconf_key_id, val) values (4, ($subselect), '$v');"
done | mysql -u root -p$PASS hamsta_db


/etc/init.d/mysql stop

echo 'wwwrun ALL = (root) NOPASSWD: /usr/bin/ssh' >> /etc/sudoers

echo -n "Starting repoindexing scripts"
	python /srv/www/htdocs/hamsta/update-repo-index.py -r {{ proxy.urlmap['slp'] }} -s {{ proxy.urlmap['slp'] }} -o /srv/www/htdocs/virtenv

# autoyast profile upload folder

mkdir -p /srv/www/htdocs/autoinst
ln -s . /srv/www/htdocs/autoinst/autoinst
chmod 777 /srv/www/htdocs/autoinst


baseSetupUserPermissions


#======================================
# Umount kernel filesystems
#--------------------------------------
baseCleanMount

#======================================
# Exit safely
#--------------------------------------
exit 0
