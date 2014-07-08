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

suseConfig

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
