#!/usr/bin/perl -w
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


# Design goal: returns resutls off all testsuites, including running as XML
# author: Lukas Lipavsky <llipavsky@suse.cz>

BEGIN {
	# extend the include path to get our modules found
	push @INC,"/usr/share/qa/lib",'.';
}
use strict;
use Getopt::Std;
use XML::Simple qw(:strict);

# Needed global variables for Getopt::Std;
our ($opt_h,$opt_f,$opt_v) = ("",0);

use File::Basename qw/basename/;
use POSIX qw /strftime/;

# source our modules
use log;

#
# Load all result parsers
# 
my %result_parsers;	# this must not be initialized here! it would overwrite data from "BEGIN"
BEGIN {
	%result_parsers = ();
	for my $dir (map ($_."/results", @INC)) {
		next unless -d $dir;
		for my $parser (glob "$dir/*.pm") {
			$parser =~ /^.*\/results\/([^\/]*)\.pm$/;
			$parser = $1;
			next if $result_parsers{$parser};
			print STDERR "Loading parser $parser...\n";
			$result_parsers{$parser} = 1;
			eval "use results::$parser;";
		}
	}
}

our $VERSION='1.1';
# default and initialization values

my %args;
$args{'resultpath'}="/var/log/qa";

$Getopt::Std::STANDARD_HELP_VERSION=1;

sub usage {
print 
"Usage: $0 [-f PATH]\n",
"       $0 -h\n",
"\n",
"Options and option values (options may be given in any order):\n",
"\n",
"	-h	print this help and exits\n",
"\n",
"	PATH:		the results directory containing the results\n",
"       		(default: ".$args{'resultpath'}.")\n",
}


#  Cmdline options evaluation:  START
#
#  (Note: man Getopt::Std is misleading, to put it mildly.
#   Consult /usr/lib/perl5/Getopt/Std.pm itself, instead.
#
&getopts("hf:v:");
if ("$opt_h") 
{	&usage; exit 0;	}
$log::loglevel		= $opt_v	if (defined $opt_v and $opt_v=~/^-?\d+/);
$args{'resultpath'}	= $opt_f	if ($opt_f);

# scan for results

my $output = {};

opendir(RESULTS, $args{'resultpath'}) or die "Can't open results directory $args{'resultpath'}: $!";
while( my $parser = readdir RESULTS) {
	# Skip non-parsable files/dirs
	next if $parser =~ /^\.\.?$/;	# skip . and ..
	next if $parser eq "oldlogs";	# skip oldlogs
	next if $parser eq "_REMOTE";	# skip _REMOTE
	unless ( -d $args{'resultpath'}."/$parser" ) {
		&log(LOG_WARNING, "Results directory ".$args{'resultpath'}." contains file $parser, which is not a directory. Skipped.");
		next;
	}
	unless ( $result_parsers{$parser} ) {
		&log(LOG_WARNING, "There is no parser for $parser. Skipped.");
		next;
	}

	# Get the correct parser
	&log(LOG_NOTICE, "Loading parser $parser...");
	my $src;
	{
		no strict 'refs';
		$src = ("results::$parser")->new($args{'resultpath'}."/$parser");
	}

	$src->testsuite_list_open();
    $output->{testsuite} = ();
	while ( my $tcf = $src->testsuite_list_next() )
	{
		chomp $tcf;
	
		# testsuites
		my ($testsuite,$testdate) = ($src->testsuite_name($tcf), $src->testsuite_date($tcf));
	
		# process results
		$src->testsuite_open($tcf) or die("Cannot open $tcf results: $!");
        my $ts = {};
        $ts->{'name'} = $testsuite;
		$ts->{'date'} = $testdate;
		$ts->{'complete'} = $src->testsuite_complete() ? 'true' : 'false';
        $ts->{'testcase'} = ();
		while( my ($tc_name, $res) = $src->testsuite_next())
		{
			# results
            my $tc = {};
            $tc->{name} = $tc_name;
            $tc->{times_run} = $res->{times_run};
            $tc->{succeeded} = $res->{succeeded};
            $tc->{failed} = $res->{failed};
            $tc->{int_errors} = $res->{int_errors};
            $tc->{skipped} = $res->{skipped};
            $tc->{test_time} = $res->{test_time};
            $tc->{complete} = 'true';
            push @{$ts->{'testcase'}}, $tc;
		}
		# TODO running if possible (make sure not returning twice or skip something! Maybe open at same time?
	 	for ($src->testsuite_running_testcases()) {
            my $tc = {};
            $tc->{name} = $_;
            $tc->{complete} = 'false';
            push @{$ts->{'testcase'}}, $tc;
		}
		$src->testsuite_close();
		
		push @{$output->{'testsuite'}}, $ts;
	}
	 # while ( $src->testsuite_list_next )
	
	$src->testsuite_list_close();
}
closedir(RESULTS);


#print as XML
my $xs = XML::Simple->new();
#my $xml = $xs->XMLout($output, KeyAttr => 'testsuite', NoAttr => 0, RootName => 'results');
my $xml = $xs->XMLout($output, KeyAttr => {}, NoAttr => 0, RootName => 'results');
print $xml;


