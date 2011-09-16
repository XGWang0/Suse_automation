#!/usr/bin/perl

# Executes a job passed in last_xml_job as a Perl hash serialized in XML.
#
# This script is part of the descripted interface towards upgradeability.

package Slave;

use strict;
use warnings;

use Slave::Job::Job;
BEGIN {
	use log;
	$log::loginfo = 'main';
	&log_set_output(handle=>*STDOUT);
}
require 'Slave/config_slave';


my $filename = $ARGV[0];
my $job = Slave::Job->new($filename);
$job->run();
print $job->destroy();
