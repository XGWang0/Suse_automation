#!/bin/bash

########################################
# Check /etc/xen/xend-config.sxp       #
# Make sure migration can be implement #
########################################

# Save original xend-config.sxp
[ -f /etc/xen/xend-config.sxp.old ] || cp /etc/xen/xend-config.sxp /etc/xen/xend-config.sxp.old

# #(xend-relocation-server no) -> (xend-relocation-server yes)
line_num=`grep -n "#(xend-relocation-server no)" /etc/xen/xend-config.sxp | cut -d":" -f1`
sed -i "$line_num s/^#//" /etc/xen/xend-config.sxp
sed -i "$line_num s/no/yes/" /etc/xen/xend-config.sxp

# #(xend-relocation-port 8002) -> (xend-relocation-port 8002)
line_num=`grep -n "#(xend-relocation-port 8002)" /etc/xen/xend-config.sxp | cut -d":" -f1`
sed -i "$line_num s/^#//" /etc/xen/xend-config.sxp

# #(xend-relocation-address '') -> (xend-relocation-address '')
line_num=`grep -n "#(xend-relocation-address '')" /etc/xen/xend-config.sxp | cut -d":" -f1`
sed -i "$line_num s/^#//" /etc/xen/xend-config.sxp

# #(xend-relocation-hosts-allow '') -> (xend-relocation-hosts-allow '')
line_num=`grep -n "#(xend-relocation-hosts-allow '')" /etc/xen/xend-config.sxp | cut -d":" -f1`
sed -i "$line_num s/^#//" /etc/xen/xend-config.sxp

# Comment (xend-relocation-hosts-allow '^localhost$ ^localhost\\.localdomain$')/etc/xen/xend-config.sxp
line_num=`grep  -n "(xend-relocation-hosts-allow" /etc/xen/xend-config.sxp | tail -1 | cut -d":" -f1`
sed -i "$line_num s/^/#/" /etc/xen/xend-config.sxp

/etc/init.d/xend restart
