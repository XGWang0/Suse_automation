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
use File::Basename;

#Declare the reservation file as constant value
use constant RESV_FILE => "/var/run/hamsta/reservation";


#Declare a gloval var to store the current reserved master IP of the SUT.
our $reserved_hamsta_master_ip = "";

# Only allow socket connection from reserved hamsta or if machine is idle.
# Reservation file format: IP on the first line of file, support both IPV4/IPV6.
# Since before SUT process reserve or release command via &reserve/&release, &allow_connection must have been just run for checking, no need to check reservation file again in &reserve/&release.
sub allow_connection(){
	my $ip_addr = shift;
	$reserved_hamsta_master_ip = &get_reserved_hamsta_ip();
        return 1 if (!$reserved_hamsta_master_ip or $reserved_hamsta_master_ip eq $ip_addr );
	return 0;
}

sub reserve() {
	my $rsv_ip = shift;
	my $rsv_dir = dirname(RESV_FILE);
	unless( -d $rsv_dir or mkdir($rsv_dir,0777) ) {
		&log(LOG_ERROR, "Cannot create reservation directory $rsv_dir!");
		&log(LOG_NOTICE,"Reservation failed.");
		return "Reservation failed.\n";
	}
	my $fh;
	unless( open $fh, ">".RESV_FILE ) {
		&log(LOG_ERROR, "Cannot write to reservation file".RESV_FILE."!");
		&log(LOG_NOTICE,"Reservation failed.");
		return "Reservation failed.\n";
	}
	print $fh "$rsv_ip\n";
	close $fh;
	$reserved_hamsta_master_ip = $rsv_ip;
	&log(LOG_NOTICE,"Reservation succeeded.");
	return "Reservation succeeded.\n";
}


sub release() {
	if ( -e RESV_FILE and !unlink RESV_FILE ) {
		&log(LOG_ERROR, "Cannot unlink ".RESV_FILE."!");
		&log(LOG_NOTICE, "Release failed.");
		return "Release failed.\n";
	}
	$reserved_hamsta_master_ip = "";
	&log(LOG_NOTICE,"Release succeeded.");
	return "Release succeeded.\n";
}

#Return ip address in the reservation file as a string, return '' if no reservation.
sub get_reserved_hamsta_ip()
{
   my $ret_ip = '';
   return $ret_ip if (! -e RESV_FILE);
   open my $fh , "<".RESV_FILE || return $ret_ip;
   my $file_content = <$fh>;
   if (defined $file_content and $file_content  =~ /^\s*(\d{1,3}(\.\d{1,3}){3})\s*$/){
      $ret_ip = $1;
   }
   close $fh;
   return $ret_ip;
}

1;
