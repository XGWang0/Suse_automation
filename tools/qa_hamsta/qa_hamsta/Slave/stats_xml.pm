# This modul query system stats

package Slave;

use strict;
use warnings;

BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;

use XML::Dumper;
use IO::Select;
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);

require 'Slave/config_slave';

my  $dumper = new XML::Dumper;


sub get_stats_xml() {

	# Iterate through all modules
	my %result = ();
	$result{'role'} = -r '/usr/share/hamsta/.VH' ? 'VH' : 'SUT';

	if ($result{'role'} eq 'VH') {
		$result{'type'} = `cat /usr/share/hamsta/.VH`;
		chomp $result{'type'};
		my @vms = ();
		my $vmline = `/usr/share/hamsta/Slave/get_vms.sh`;
		chomp $vmline;
		for my $pair in split(/;/, $vmline) {
			my ($mac, $vmtype) = split (/_/, $pair);
			my %vm = ( 'type' => $vmtype, 'mac' => $mac );
			push @vms, \%vm;
		}
		$result{'vms'} = \%vms;
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
