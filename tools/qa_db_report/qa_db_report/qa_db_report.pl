#!/usr/bin/perl -w
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


# Rewrite of /suse/rd-qa/bin/qa_db_report
# Design goal: entire submission from within just one
# connection to mysql server, to boost execution speed.

# author: kgw 2007-06-27
#
#  $Id: qa_db_report.pl,v 4.3 2007/07/04 10:33:00 kgw Exp kgw $
#

BEGIN {
# extend the include path to get our modules found
push @INC,"/usr/share/qa/lib",'.';
}
use strict;
no strict 'refs';	# for benchmark parsers
use Getopt::Std;

# Needed global variables for Getopt::Std;
our ($opt_h,$opt_d,$opt_c,$opt_p,$opt_a,$opt_f,$opt_F,$opt_m,$opt_t,$opt_v,$opt_b,$opt_C) =
    ("",    0,     "",    "",    "",    "",    "",    "",    "",    "",    "",    "");
our ($opt_L,$opt_D,$opt_A,$opt_k, $opt_T, $opt_R) =
    ("",    "",    "",    ""    , "",     "");

use File::Basename qw/basename/;
use POSIX qw /strftime/;

# source our modules
use qadb;
use bench_parsers;
use functions;
use detect;
use misc;
use log;
use qaconfig('%qaconf','&get_qa_config');
%qaconf = ( %qaconf, &get_qa_config('qa_db_report') );

$log::loginfo='qa_db_report';
&log_set_output(handle=>*STDOUT);

#
# Load all result parsers
# 
my %result_parsers = ();
for my $dir (map ($_."/results", @INC)) {
	next unless -d $dir;
	for my $parser (glob "$dir/*.pm") {
		$parser =~ /^.*\/results\/([^\/]*)\.pm$/;
		$parser = $1;
		next if $result_parsers{$parser};
		&log(LOG_INFO, "Loading parser $parser...\n");
		$result_parsers{$parser} = 1;
		eval {
			my $package = "results::$parser";
			require "results/$parser.pm";
			import $package;
		};
		die $@ if( $@ );

		# subparsers
		next unless -d "$dir/$parser";
		for my $subparser (glob "$dir/$parser/*.pm") {
			$subparser =~ /^.*\/results\/$parser\/([^\/]*)\.pm$/;
			$subparser = $1;
			next if $result_parsers{"$parser"."::$subparser"};
			&log(LOG_INFO, "Loading subparser $parser"."::$subparser...\n");
			$result_parsers{"$parser"."::$subparser"} = 1;
			eval {
				my $package = "results::$parser"."::$subparser";
				require "results/$parser/$subparser.pm";
				import $package;
			};
			die $@ if( $@ );
		}
	}
}

our $VERSION='1.1';
&check_version('qa_db_report.pl',$VERSION);

# hardcoded parameters
 
# test result summary file have this normalized name
my $filename="test_results";
# for concluding mail notification
my $reviewer=$qaconf{qa_db_report_log_reviewer};

# for mail domain
my $maildomain=$qaconf{mail_domain};

# directory for remote results
my $remote_results_dir = '/var/log/qa-remote-results';

our $dst=qadb->new();

# Log archive root
my $log_archive_root = $qaconf{log_archive_wwwroot};

# default and initialization values

my %args;
$args{'product'}="";
$args{'release'}="";
$args{'arch'}= &get_architecture;
$args{'comment'}="";
$args{'resultpath'}="/var/log/qa";
$args{'tcf_filter'} = undef;
$args{'type'}="product";
$args{'host'}=$ENV{'HOSTNAME'};
$args{'kernel'}=`uname -r`;
$args{'tester'}="hamsta-default";
my $nomove=0 ;     # move to oldlogs 0..yes 1..no
my $delete=0 ;     # delete logs 1..yes 0..no
my $delete_result_path = 0; #delete whole result path - used only if result path was temporaly created (extracted tarball)
my $noscp=0;	# scp results to log archive 0..yes 1..no

unless ($args{'host'})
{
	$args{'host'}=`hostname`;
	chomp $args{'host'};
}
$args{'host'}=$1 if $args{'host'} =~ /^([^\.]+)\./;

$Getopt::Std::STANDARD_HELP_VERSION=1;

# TODO: replace the '-n' numbers by something more sane

sub usage {
print 
"Usage: $0 -p PRODUCT [-c <comment>] [-bCLRDA] [-v <n>] [-a ARCH] [-f PATH] [-F TCF_LIST] [-k KERNEL] [-m TESTHOST] [-t TYPE] [-T TESTER]\n",
"       $0 -h\n",
"\n",
"Options and option values (options may be given in any order):\n",
"\n",
"	-h	print this help and exits\n",
"	-b	batch mode (not interactive at all)\n",
"	-c <comment>	submission comment, max. 100 chars, will be truncated when longer \n",
"	-v n	verbosity level (0-7, 5 is default, 3 only prints warnings+errors )\n",
"	-L	Omits moving the submitted logs from PATH to PATH/oldlogs/\n",
"	-R	Delete (remove) logs when submitted.\n",
"	-D	No writing to the database\n",
"	-A	Do not scp the submitted data to the archive\n",
"	-C	commit after every TCF is inserted\n",
"\n",
"	PRODUCT:	e.g. SLES-10-beta1 | SLES-9-SP4-RC1\n",
"	ARCH:		QADB architecture, e.g. i586,ia64,x86_64,ppc,ppc64,s390x,xen0-*...\n",
"       		(default: detected arch of this host (".$args{'host'}."): ".$args{'arch'}.")\n",
"	PATH:		the ctcs2 directory containing the $filename files to submit\n",
"       		(default: ".$args{'resultpath'}.")\n",
"	TCF_LIST:	comma-separated list of test-runs (ctcs2 subdirs) that should be processed.\n",
"				If not set, all test-runs are processed.\n",
"				Example: -F 'qa_siege-2009-12-03-11-13-37,qa_siege-2009-12-03-12-21-12'\n",
"	TESTHOST:	hostname of system under test\n",
"			(default: ".$args{'host'}.")\n",
"	TYPE:		kotd, patch:<md5sum>, product (default: ".$args{'type'}.")\n",
"       TESTER:         login of the tester (default: ".$args{'tester'}.")\n";
}

# ask the user a yes/no question and waint until he responds
# nust not be called in batch mode!!!
sub annoy_user # question
{
	my $row;

	$dst->die_cleanly($_[0]) if $db_common::batchmode; 
	print STDERR "*** WARNING: *** ",@_,"\n";
	for(my $i=0; $i<3; $i++)
	{
		print "\r> ";
		my $row=<STDIN>;
		next unless $row;
		chomp $row;
		if($row=~ /^(y(es)?|n(o)?)$/)
		{
			return 1 if $1=~/^y/;
			return 0;
		}
		print STDERR "answer (y)es or (n)o\n";
	}
	return 0;
}


#  Cmdline options evaluation:  START
#
#  (Note: man Getopt::Std is misleading, to put it mildly.
#   Consult /usr/lib/perl5/Getopt/Std.pm itself, instead.
#
&getopts("hbLRDAv:c:p:a:f:F:k:m:t:T:");
if ("$opt_h") 
{	&usage; exit 0;	}
$log::loglevel		= $opt_v	if (defined $opt_v and $opt_v=~/^-?\d+/);
$args{'comment'}	= $opt_c	if ($opt_c);
$nomove			= 1      	if ($opt_L);
$delete			= 1      	if ($opt_R);
$db_common::nodb	= 1		if ($opt_D);
$noscp			= 1		if ($opt_A);
$db_common::batchmode	= 1		if ($opt_b);
($args{'product'},$args{'release'})	= &set_product_release($opt_p)	if ($opt_p);
$args{'arch'}		= $opt_a	if ($opt_a);
$args{'resultpath'}	= $opt_f	if ($opt_f);
$args{'host'}		= $opt_m	if ($opt_m);
$args{'kernel'}		= $opt_k	if ($opt_k);
$args{'type'}		= $opt_t	if ($opt_t);
$args{'tester'}		= $opt_T	if ($opt_T);
if ($opt_F) {
# vmarsik: the block could probably be rewritten to something like
# $args{tcf_filter} = {map {s/\/$//; $_=>1} split /,/,$opt_F};
	%{$args{tcf_filter}} = map { $_ => 1 } split(/,/, $opt_F);
	for (keys %{$args{tcf_filter}}) {
		next unless /\/$/;
		my $orig = $_;
		my $modif = $_;
		chop($modif);
	        ${$args{tcf_filter}}{$modif} = 1;	
		delete ${$args{tcf_filter}}{$orig};
	}
}

# If logs should be deleted, don't move them to oldlogs
$nomove=1 if $delete;

die 'Wrong product type :'.$args{'type'}."\n" unless $args{'type'} =~ /^(kotd:[^:]+:[^:]+:[^:]+:[^:]+|patch:[0-9a-f]{32}|product)$/;


unless ($args{'product'}) {
	print STDERR "EMPTY product detected from -p optarg $opt_p: please correct\n\n";
	&usage;
  	exit 1;
}
unless ($args{'release'}) {
	print STDERR "EMPTY release detected from -p optarg $opt_p: please correct\n\n";
	&usage;
  	exit 1;
}

# TODO : check the version against QADB

&log(LOG_INFO,
	"path:".$args{'resultpath'}." ".
	"filter:".($args{tcf_filter} ? join(' ',keys(%{$args{tcf_filter}})) : "<not defined>")."\n".
	"type:".$args{'type'}." ".
	"tester:".$args{'tester'}." ".
	"verbosity:".$log::loglevel." ".
	"comment: ".$args{'comment'}."\n".
	"nomove:$nomove ".
	"delete:$delete ".
	"nodb:$db_common::nodb ".
	"noscp:$noscp ".
	"batchmode:$db_common::batchmode\n".
	"host:".$args{'host'}." ".
	"kernel:".$args{'kernel'}." ".
	"product:".$args{'product'}." ".
	"release:".$args{'release'}." ".
	"arch:".$args{'arch'}."\n"
);

# if logs are in tarball., extract to remote logs dir
if ( $args{'resultpath'} =~ /\.tar\.gz$/ ) {
	my $tarball = $args{'resultpath'};
	chomp (my $dir = `basename "$args{'resultpath'}" .tar.gz`);
	&log_add_output( path=>"/var/log/qa-remote-results/$dir.log", gzip=>1, level=>LOG_DEBUG );
	$args{'resultpath'} = "$remote_results_dir/$dir";
	mkdir $args{'resultpath'};
	system "tar xzf \"$tarball\" -C \"". $args{'resultpath'}.'"' and die "Cannot extract archive.";

	unlink $tarball if $delete; 
	# we don't want to store the results here.
	$delete_result_path=1;
} elsif ( $args{'resultpath'} =~ /\.tar\.bz2$/ ) {
	# if logs are in tar.bz2., extract to remote logs dir
	my $tarball = $args{'resultpath'};
	chomp (my $dir = `basename "$args{'resultpath'}" .tar.bz2`);
	&log_add_output( path=>"/var/log/qa-remote-results/$dir.log", bzip2=>1, level=>LOG_DEBUG );
	$args{'resultpath'} = "$remote_results_dir/$dir";
	mkdir $args{'resultpath'};
	system "tar xjf \"$tarball\" -C \"". $args{'resultpath'}.'"' and die "Cannot extract archive.";

	unlink $tarball if $delete; 
	# we don't want to store the results here.
	$delete_result_path=1;
}

$dst->set_user();
&TRANSACTION('arch','release','product','host','tester');
my $arch_id	= $dst->enum_get_id('arch',$args{'arch'})	
	or die "Architecture '".$args{'arch'}."' not in the database";
my $release_id = $dst->enum_get_id_or_insert('release',$args{'release'});
my $product_id = $dst->enum_get_id('product',$args{'product'})	
	or die "Product '".$args{'product'}."' not found in the database";	
my $host_id = $dst->enum_get_id_or_insert('host',$args{'host'});
my $tester_id = $dst->enum_get_id_or_insert('tester',$args{'tester'});
&TRANSACTION_END;

# commit schema:
# TODO: subject to change
# - submissions are committed immediately
# - testsuites are commited when finished
# - when an error occurs, submissions and RPM configurations are deleted by die_cleanly()
# - deleted submissions' foreign keys delete testsuites and results
$db_common::delete_on_failure=1;
$db_common::transaction_max_ms=2000; # default too short for RPM info
my %submissions=();	# rpmlist_md5|hwinfo_md5 => submission_id
my %destdirs=();	# subdir on local => dir in the archive
$SIG{'INT'}=sub { $dst->die_cleanly() if defined $dst; };

# global statistics
our @stat_total=();
our @stat_keys=('testcases','runs','succeeded','failed','interr','skipped', 'time', 'bench');

# scan for results

my %rpmlist_paths = ();
my %hwinfo_paths = ();
my @skipped_list = ();

opendir(RESULTS, $args{'resultpath'}) or die "Can't open results directory $args{'resultpath'}: $!";
while( my $parser = readdir RESULTS) {
	# Skip non-parsable files/dirs
	next if $parser =~ /^\.\.?$/;	# skip . and ..
	next if $parser eq "oldlogs";	# skip oldlogs
	next if $parser eq "_REMOTE";	# skip _REMOTE
	unless ( -d $args{'resultpath'}."/$parser" ) {
		&log(LOG_WARNING, "Results directory ".$args{'resultpath'}." contains file $parser, which is not a directory. Skipped.");
		push @skipped_list, $parser;
		next;
	}
	unless ( $result_parsers{$parser} ) {
		&log(LOG_WARNING, "There is no parser for $parser. Skipped.");
		push @skipped_list, $parser;
		next;
	}

	# Get the correct parser
	&log(LOG_INFO, "Using parser $parser...");
	my $src;
	{
		no strict 'refs';
		$src = ("results::$parser")->new($args{'resultpath'}."/$parser");
	}

	$src->testsuite_list_open();
	while ( my $tcf = $src->testsuite_list_next() )
	{
		chomp $tcf;
		next if $args{'tcf_filter'} and not ($args{'tcf_filter'}->{"$parser/$tcf"} or $args{'tcf_filter'}->{"$tcf"}) ;

		# The parser used for parsing this testsuite. It is $parser or sub_$parser_$tcf if exist!
		my $the_parser = $src; 
		{
			# Create subparser if it exist
			my $subparser = $parser."::".$src->testsuite_name($tcf);
			if ( $result_parsers{$subparser} ) {
				no strict 'refs';
				&log(LOG_INFO, "Using subparser $subparser for $tcf...");
				$subparser =~ s/\./_/g;
				$the_parser = ("results::$subparser")->new($args{'resultpath'}."/$parser");
			}
		}
		$the_parser->testsuite_open($tcf) or $dst->die_cleanly("Cannot open $tcf results: $!");
		next unless $the_parser->testsuite_complete(); # Submit only completed testsuites
		&log(LOG_INFO, "Processing:\t$tcf");
	
		# find rpmlist+hwinfo, count MD5s, make submission hash key
		my $rpmlist_path = $the_parser->rpmlist($tcf);
		&log(LOG_DEBUG, "Got RPMlist path %s",$rpmlist_path);
		&rpmlist_remove_kernel($rpmlist_path) if -w $rpmlist_path and $args{'type'}=~/^kotd/;
		my $hwinfo_path  = $the_parser->hwinfo($tcf);
		&log(LOG_DEBUG, "Got hwinfo path %s",$hwinfo_path);
		&filter_hwinfo_file($hwinfo_path) or $dst->die_cleanly("Cannot filter hwinfo $hwinfo_path - insufficient rights?");
		my $rpmlist_md5 = $rpmlist_path ? `md5sum $rpmlist_path| cut -d\\  -f1` : '';
		&log(LOG_DEBUG, "RPMlist md5sum is $rpmlist_md5");
		my $hwinfo_md5  = $hwinfo_path  ? `md5sum $hwinfo_path | cut -d\\  -f1` : '';
		&log(LOG_DEBUG, "HWinfo md5sum is $hwinfo_md5");
		chomp($rpmlist_md5,$hwinfo_md5); 
		my $key="$rpmlist_md5|$hwinfo_md5";
	
		# submissions
		my $submission_id=$submissions{$key};
		unless( $submission_id or $db_common::nodb )
		{
			&log(LOG_DEBUG,"Preparing new submission for key $key");
			my $rpmlist_msg = '';
			my $hwinfo_msg = '';
			my ($config_id,$hwinfo_id);
			$rpmlist_msg = "File $rpmlist_path is different than already processed file(s):\n  ".join("\n  ", values(%rpmlist_paths))."\n\n" unless $rpmlist_paths{$rpmlist_md5};
			$hwinfo_msg = "File $hwinfo_path is different than already processed file(s):\n  ".join("\n  ", values(%hwinfo_paths))."\n\n" unless $hwinfo_paths{$hwinfo_md5};
			# annoy the user when submitting multiple configurations
			$dst->die_cleanly('User abort') unless keys(%submissions)!=1 or $db_common::batchmode or &annoy_user("The testsuite uses another rpminfo and/or hwinfo than the previous one(s):\n$rpmlist_msg$hwinfo_msg","Do you want to continue and have multiple submissions ?");
	
			# insert rpmlist
			if( $rpmlist_path )	{
				&TRANSACTION(qw(rpm_config software_config rpm rpm_basename rpm_version));
				$config_id = $rpmlist_path ? $dst->rpmlist_put($rpmlist_path) : undef;
				&TRANSACTION_END;
			}

			# insert hwinfo
			if( $hwinfo_path )	{
				&TRANSACTION('hwinfo');
				$hwinfo_id = $hwinfo_path ? $dst->hwinfo_put($hwinfo_path) : undef;
				&TRANSACTION_END;
			}
			
			# create a new submission
			&TRANSACTION('submission');
			&log(LOG_INFO,"Creating a new submission");
			$submission_id = $dst->submission_create($args{'type'},$tester_id,$host_id,$args{'comment'},$arch_id,$product_id,$release_id,$config_id,$hwinfo_id);
			$submissions{$key}=$submission_id;
			&TRANSACTION_END;
	
			# write the submission(s) type
			&log(LOG_INFO,"Writing submission types for submission $submission_id");
			&exec_submission_type($submission_id, $config_id, $args{'type'});
		}
	
		$rpmlist_paths{$rpmlist_md5} = $rpmlist_path;
		$hwinfo_paths{$hwinfo_md5} = $hwinfo_path;
		&log(LOG_DEBUG, "Submission for key $key exists, going to write testsuite now");
	
		# testsuites
		my ($testsuite,$testdate) = ($the_parser->testsuite_name($tcf), $the_parser->testsuite_date($tcf));
		&log(LOG_DEBUG, "Testsuite is $testsuite, testdate is $testdate");
	
		$destdirs{"$parser/$tcf"} = &get_log_dir(%args,'testsuite'=>$testsuite, 'date'=>$testdate, 'parser'=>$parser);

		# insert TCF record
		&TRANSACTION('testsuite','tcf_group');
		&log(LOG_DEBUG, "Log dir is %s",$destdirs{"$parser/$tcf"});
		my $testsuite_id = $dst->enum_get_id_or_insert('testsuite',$testsuite);
		&log(LOG_DEBUG, "testsuite_id is $testsuite_id");
		my $tcf_id = $dst->create_tcf( $testsuite_id, $submission_id, ($noscp ? '':$log_archive_root.'/'.$destdirs{"$parser/$tcf"}.'/'.$tcf), $testdate );
		&log(LOG_DEBUG, "tcf_id is $tcf_id");
		&TRANSACTION_END;
	
		# process results
		my @stat_testsuite=();
		while( my ($tc_name, $res) = $the_parser->testsuite_next())
		{
			# results
			&TRANSACTION('testcase','result');
			&log(LOG_DEBUG, "Processing testcase $tc_name");
			my $tc_id = $dst->testcase_get_id_or_insert_with_rel_url($tc_name, $the_parser->testsuite_tc_output_rel_url());
			my $result_id = $dst->submit_results( $res->{times_run}, $res->{succeeded}, 
				$res->{failed}, $res->{int_errors}, $res->{skipped},
				$res->{test_time}, $tc_id, $tcf_id );
			&TRANSACTION_END;
	
			# benchmarks - parse testcase log + store benchmark data
			my $bench_pairs = 0;
			if( &is_bench($tc_name) )
			{
				my $bfile=$the_parser->path()."/$tcf/".$the_parser->testsuite_tc_output_rel_url();
				my $log;
				if( open $log, $bfile )
				{
					# read and parse the testcase log
					my $func = &bench_func($tc_name);
					&log(LOG_INFO,"Parsing bench data from $tc_name using $func()");
					my @parsed = &{$func}($log);
					@parsed = &remove_duplicite_keyvals(@parsed);
					&log(LOG_INFO,"Submitting ".(0+@parsed)." benchmark keys and values");
					$bench_pairs=@parsed/2;
					&log(LOG_WARNING,"No performance data in $filename.\n") unless @parsed;
					&TRANSACTION('bench_part','bench_data');
					for( my $i=0; $i<@parsed-1; $i+=2 )
					{
						# insert one bench key/val pair into DB
						&log(LOG_DETAIL,"\t%s\t%s",$parsed[$i],$parsed[$i+1]);
						$dst->insert_benchmark_data( $result_id, $parsed[$i], $parsed[$i+1] );
					}
					&TRANSACTION_END;

					close($log);
				}
				else
				{	$dst->die_cleanly("Cannot open '$bfile': $!\n");	}
			}
	
			# statistics
			&TRANSACTION('test');
			$dst->tests_stat_update($testsuite_id,$tc_id,($bench_pairs ? 1:0)); # TODO: undo if fail
			&TRANSACTION_END;
			&log(LOG_DETAIL,"Test $tc_name, result_id $result_id: count ".$res->{times_run}.", fail ".$res->{failed}.", succ ".$res->{succeeded}.", fail ".$res->{failed}.", interr ".$res->{int_errors}.", skipped ".$res->{skipped}.", time ".$res->{test_time}.", bench pairs $bench_pairs ");
			@stat_testsuite=&add_stat([@stat_testsuite],[1,$res->{times_run}, $res->{succeeded}, 
												$res->{failed}, $res->{int_errors}, $res->{skipped},
												$res->{test_time},$bench_pairs]);
		}
		&log(LOG_DEBUG,"Testsuite done");
		$the_parser->testsuite_close();
		
		# TCF statistics
		&log(LOG_DETAIL,  
			 "I have submitted testsuite $testsuite tcf_id $tcf_id ".
			 (defined $submission_id ? "(submission_id $submission_id) : ":': ').
			 (join(' ',map {$stat_keys[$_].":".$stat_testsuite[$_]} (0 .. @stat_testsuite-1))));
		@stat_total = &add_stat([@stat_total],[@stat_testsuite]);
	}
	 # while ( $src->testsuite_list_next )
	
	$src->testsuite_list_close();
}
closedir(RESULTS);

my $submissions=join(',',values %submissions);

# clean up
$dst->commit() if %submissions;
$dst->tidy_up;


# total statistics
if( %submissions or $db_common::nodb )
{
	&log(LOG_NOTICE,  
		 "I have submitted submissions $submissions :".
		 " product:".$args{'product'}.
		 " release:".$args{'release'}.
		 " arch:".$args{'arch'}.
		 " host".$args{'host'}.
		 " tester:".$args{'tester'}."\n".
		 (join(' ',map {$stat_keys[$_].":".$stat_total[$_]} (0 .. @stat_total-1)))
		 );
} 
else 
{	
	&log(LOG_WARNING, "No CTCS2 data found, nothing submitted.");	
	$dst->tidy_up();
	exit 0;
}


# process logs - SCP, move to oldlogs/
# TODO: when using inotify, should move just after every submit of TCFs
my $base=$args{'resultpath'}."/oldlogs";
my $savedir="$base/" . strftime ("%F-%H-%M-%S", localtime);

unless( $nomove )
{
	mkdir $base unless -d $base;
	mkdir $savedir unless -d $savedir;
	unless( -d $savedir )
	{
		&log(LOG_ERR,"Unable to move Logs to target: $savedir. Not moving logs to oldlogs.\n");
		$nomove=1;
	}
}

&log(LOG_INFO,"Going to store logs to the central archive via SCP") unless $noscp;
foreach my $dir (keys %destdirs) 
{
	unless( $noscp )
	{
		# store via SCP
		&log(LOG_DETAIL,"\tSCP ".$args{'resultpath'}."/$dir => ".$destdirs{$dir});
		my $ret=&scp($args{'resultpath'}."/$dir", $destdirs{$dir});
		last if $ret==2 or $ret==256 or $ret==258;
	}
	# move to oldlogs/
	unless( $nomove )
	{
		`mkdir -p "$savedir/\$(dirname "$dir")"`;
		rename ($args{'resultpath'}."/$dir", "$savedir/$dir");
	}

	if( $delete )
	{
		# it is still there, since delete -> nomove
		`rm -fr "$args{'resultpath'}./$dir"`;
	}
}

#delete result path if it's temporaly created (extracted from tarbal)
`rm -fr "$args{'resultpath'}"` if $delete_result_path;

&log(LOG_INFO, "Submitted logs have been copied to the archive.") unless $noscp;
&log(LOG_INFO, "Submitted logs have been moved to $savedir") unless $nomove;
&log(LOG_INFO, "Submitted logs have been deleted") if $delete;


# send mail notificaiton
&log(LOG_INFO, "Sending mail notifications to $reviewer and ".$args{'tester'}."\@$maildomain");
my $msg="Hi,\n\nsubmission(s) $submissions from ".$args{'tester'}." is waiting for your review.\nThe following result files have been submitted:\n\n".join("\n",keys %destdirs)."\n\nHave fun.\n";
my $msubject="[submission(s) $submissions] ".$args{'product'}."-".$args{'release'}."-".$args{'arch'}." for ".$args{'host'}." needs review";
&mail('root@'.$args{'host'},$reviewer,$args{'tester'}."\@$maildomain",$msubject,$msg);

# finished
&log(LOG_INFO, "All done - results were submitted with following submission ID(s):\n" . join("\n" , map { "ID $_: ".$qaconf{qadb_wwwroot}."/submission.php?submission_id=$_" } values %submissions));
exit 0;


sub add_stat # \stat1, \stat2
{
	my ($s1,$s2)=@_;
	return map { defined $s1->[$_] ? $s1->[$_]+$s2->[$_] : $s2->[$_] } (0 .. @$s2-1);
}

sub exec_submission_type # $submission_id, $config_id, $type
{
	my ($submission_id,$config_id) = @_;
	my @parts = split /:/, $_[2];
	if( $parts[0] eq 'kotd' )
	{
		shift @parts;
		my ($release,$version,$kernel_branch,$kernel_flavor)=@parts;
		
		# check if the kernel branch exists in QADB
		my $kernel_branch_id = $dst->enum_get_id('kernel_branch',$kernel_branch);
		$dst->die_cleanly("The specified KotD branch \"$kernel_branch\" does not exist.\nPlease check for typos or contact the DB admin\n") unless $kernel_branch_id;

		&TRANSACTION('kernel_flavor','kotd_testing');
		# check if the kernel flavor exists in QADB
		my $kernel_flavor_id = $dst->enum_get_id_or_insert('kernel_flavor',$kernel_flavor);
		$dst->die_cleanly("The specified KotD flavor \"$kernel_flavor\" does not exist.\nPlease check for typos or contact the DB admin\n") unless $kernel_flavor_id;

		# record as kotd_testing
		$dst->kotd_testing_insert($submission_id,$kernel_branch_id,$kernel_flavor_id,$release,$version);
		&TRANSACTION_END;
	}
	elsif( $parts[0] eq 'patch' )
	{
		my $md5sum=$parts[1];
		my @released_rpms=&get_patch_details($md5sum);
		my $patch_id=shift @released_rpms;
		$dst->die_cleanly("No patch submit possible") unless @released_rpms;

		&TRANSACTION('rpm_basename','software_config','rpm','released_rpm','maintenance_testing');
		my $maintenance_testing_id = $dst->maintenance_testing_insert($submission_id, $patch_id, $md5sum);
		foreach my $rpm( @released_rpms )
		{
			my $rpm_basename_id=$dst->enum_get_id('rpm_basename',$rpm);
			unless($rpm_basename_id)
			{
				&log(LOG_WARNING,"The package '$rpm' is specified in patchinfo for md5sum $md5sum, but not installed");
				next;
			}
			my @rpm_version_ids = $dst->get_rpm_versions($config_id, $rpm_basename_id);
			if( @rpm_version_ids )
			{
				&log(LOG_WARNING,"Multiple versions installed for '$rpm'") if @rpm_version_ids>1;
				$dst->released_rpms_insert($maintenance_testing_id, $rpm_basename_id, $rpm_version_ids[0] );
			}
			else
			{	&log(LOG_WARNING,"The RPM '$rpm' was not installed, not submitting");	}
		}
		&TRANSACTION_END;
	}
	elsif( $parts[0] eq 'product' )
	{
		&TRANSACTION('product_testing');
		$dst->product_testing_insert($submission_id);	
		&TRANSACTION_END;
	}
}

# returns patch_id and a list of RPM basenames, if /mounts/work/built/patchinfo exists and contains needed md5summed data
sub get_patch_details # md5sum
{
	my $md5sum=shift;
	my $patch_id;
	my $patchpath="/mounts/work/built/patchinfo";
	my $p="$patchpath/$md5sum";
	# patch ID file is named "satno" for SLE-11, "zyppno" for SLE-10, "patchno" for SLES-9...
	foreach my $f( "$p/satno", "$p/zyppno", "$p/patchno" )
	{	$patch_id = `cat $f 2>/dev/null` if -r $f;	}
	&log(LOG_WARNING,"Could not read patchnumber from $p/{satno/patchno/zyppno}") unless $patch_id;
	chomp $patch_id;
	my @released_rpms = split /,/, `grep '^PACKAGE: ' $p/patchinfo | cut -d' ' -f2-`;
	&log(LOG_CRIT,"Could not read packages from $p/patchinfo") unless @released_rpms;
	return ($patch_id,@released_rpms);
}

sub rpmlist_remove_kernel($) { # path
	my $file = shift;
	&log(LOG_DETAIL, "Removing kernel RPMs from list in '%s'", $file);
	system( "sed -i '/^kernel-/d' '".$file."'");
}

sub TRANSACTION	{
	$dst->TRANSACTION(@_);
}

sub TRANSACTION_END	{
	$dst->TRANSACTION_END(@_);
}

