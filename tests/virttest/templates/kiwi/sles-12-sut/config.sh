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
suseInsertService hamsta

suseConfig

#======================================
# Umount kernel filesystems
#--------------------------------------
baseCleanMount

#======================================
# Exit safely
#--------------------------------------
exit 0
