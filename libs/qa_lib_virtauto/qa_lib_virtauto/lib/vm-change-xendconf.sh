#!/bin/bash
# ****************************************************************************
# Copyright © 2011 Unpublished Work of SUSE. All Rights Reserved.
# 
# THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
# CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
# RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
# THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
# THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
# TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
# PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
# PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
# AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
# LIABILITY.
# 
# SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
# AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
# LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
# WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
# ****************************************************************************
#


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

