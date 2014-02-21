# ****************************************************************************
# Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
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

# This modul query system stats

package Slave;

use strict;
use warnings;

BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;

# Only allow socket connection from reserved hamsta or if machine is idle.
# Reservation file format: IP on the first line of file.
sub allow_connection(){
        my $ip_addr = shift;
        open my $fh, "</var/run/hamsta/reservation" or return 1;
        my $rsv_ip = <$fh>;
        close $fh;
        chomp $rsv_ip;
        return 1 if ( !defined $rsv_ip or $rsv_ip eq $ip_addr or $rsv_ip eq ""); #reserved master
        return 0;
}


sub reserve() {
	my $rsv_ip = shift;
	my $rsv_file = '/var/run/hamsta/reservation';
	if ( ! -e $rsv_file ) {
		mkdir("/var/run/hamsta",0777);
		open my $fh, ">$rsv_file";
		print $fh "$rsv_ip\n";
		close $fh;
		&log(LOG_NOTICE,"Reservation succeeded.");
		return "Reservation succeeded.\n";
	} else {
		open my $fh, "<$rsv_file";
		my $ip_in_rsv_file = <$fh>;
		chomp $ip_in_rsv_file;

		if ( ! defined $ip_in_rsv_file or $ip_in_rsv_file eq "" ) {
			close $fh;
			open my $fh, ">$rsv_file";
                	print $fh "$rsv_ip\n";
              		close $fh;
			&log(LOG_NOTICE,"Reservation succeeded.");
                	return "Reservation succeeded.\n";
		} elsif ( $ip_in_rsv_file eq $rsv_ip ) {
                        close $fh;
                        &log(LOG_NOTICE,"Reservation succeeded.");
                        return "Reservation succeeded.\n";

		} else {
			close $fh;
			&log(LOG_NOTICE,"Reservation failed.");
			return "Reservation failed.\n";
		}	
	
	}
}

sub release () {
	my $rels_ip = shift;
	my $rsv_file = '/var/run/hamsta/reservation';
        if ( ! -e $rsv_file ) {
		&log(LOG_NOTICE,"Release succeeded.");
                return "Release succeeded.\n";
	} else {
                open my $fh, "<$rsv_file";
                my $ip_in_rsv_file = <$fh>;
                chomp $ip_in_rsv_file; 
                close $fh;
		#print "IP In reserve file is :";
		#print $ip_in_rsv_file;
		if ( ! defined $ip_in_rsv_file or $ip_in_rsv_file eq $rels_ip or $ip_in_rsv_file eq "" ){
			unlink $rsv_file;
                        &log(LOG_NOTICE,"Release succeeded.");
                        return "Release succeeded.\n";
		} else {
			&log(LOG_NOTICE,"Release failed.");
                        return "Release failed.\n";

		}
	}
}

1;
