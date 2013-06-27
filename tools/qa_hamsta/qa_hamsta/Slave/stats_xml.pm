# ****************************************************************************
# Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
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

use XML::Dumper;
use IO::Select;
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);

require 'Slave/config_slave.pm';

my  $dumper = new XML::Dumper;


sub get_stats_xml() {

	# Iterate through all modules
	my %result = ();
	$result{'role'} = -r '/var/lib/hamsta/VH' ? 'VH' : 'SUT';

	if ($result{'role'} eq 'VH') {
		$result{'type'} = `cat /var/lib/hamsta/VH`;
		chomp $result{'type'};
		my @vms = ();
		my $vmline = `/usr/share/hamsta/Slave/get_vms.sh`;
		chomp $vmline;
		for my $pair (split(/;/, $vmline)) {
			my ($mac, $vmtype) = split (/_/, $pair);
			my %vm = ( 'type' => $vmtype, 'mac' => $mac );
			push @vms, \%vm;
		}
		$result{'vms'} = \@vms;
	}

	# Convert to XML string and write to debugging file
	my $xml = $dumper->pl2xml(\%result);
	if ($Slave::debug > 1 && open (FH, ">/tmp/debug_stats.xml")) {
		print FH $xml;
		close (FH);
	} elsif ($Slave::debug > 1) {
		&log(LOG_ERR,"Could not open /tmp/debug_stats.xml");
	}

	$xml =~ tr/\x00-\x07\x0b-\x19\x80-\xFF//d; # remove non-ASCII characters
	return $xml;
	
}

1;
