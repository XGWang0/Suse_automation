#!/usr/bin/perl -w
# ****************************************************************************
# Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
# 
# THIS IS AN UNPUBLISHED WORK OF SUSE.	IT CONTAINS SUSE'S
# CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.	SUSE
# RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
# THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
# THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
# TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
# PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
# PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
# AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND	CIVIL
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

# vim: set et ts=4 sw=4 ai si:
#
# feed_hamsta -- command line interface for the hamsta master
#

use strict;
use Getopt::Long qw(:config no_ignore_case bundling_override);
use POSIX qw(strftime WIFEXITED WEXITSTATUS WIFSIGNALED WTERMSIG WIFSTOPPED WSTOPSIG);
# handle HUP INT PIPE TERM ABRT QUIT with die, so the END block is executed
# which unlinks temporary files
use sigtrap qw(die untrapped normal-signals ABRT QUIT);
use Encode;

use IO::Socket::INET;

$0 =~ m/([^\/]*)$/;
my $progname = $1;

# Make sure output is in UTF8
binmode(STDOUT, ":utf8");

my $debug = 0;

#correspond with version of hamsta.
my $version = "HAMSTA_VERSION";
my $protocol_version = 1;

#my $tmpfile = "/tmp/$progname.$$";
#END { unlink($tmpfile); }

# Usage message
sub usage {
	print <<"EOF";
$progname version $version

$progname [OPTIONS] <master>[:<port>]

Options:
	-t|--jobtype <jobtype>  set the job type (number)
				1 Single machine
				2 QA package
				3 Autotest
				4 Multi machine
				5 Reinstall
	-n|--testname <testname>
				set test name for the job work with -t option 
		                (only for Single machine, QA package, Autotest, Multi machine).
		                Seperate by ',' for qa_package and autotest job.
	-l|--listcases		print the support test case names for jobtypes 1 to 4
	-r|--roles		for Multi machine jobs, set roles number and host
		         	Assign SUT to roles , format like:
					-r 'r0:host1,host2;r1:host3,host4'

	-u|--re_url [url]		set reinstall url
	   --re_sdk [url]		set reinstall sdk
	   --re_opts [additional opts]	set reinstall opts
	   --pattern [pattern1,...]	set install pattern
	   --rpms [rpm1,rpm2,...]	set extra rpm packages
	   --kexec			use kexec

	-U|--user		log in as user
	-P|--password		use password (use with --user option)
	-x|--cmd		set cmd for jobtype command_line
	-m|--mail		set email address for job result
	-p|--print-active	print all active machines
	-h|--host <ip-or-hostname>
				set the target SUT for the test
	-g|--group <name>	set the target host group for test
	--force-version-ignore  do not check protocol version and execute requested action
	--query_job		query the job status from job_id
	--query_log		get the job log from job_id
	-v|--version	        print program version
	-d|--debug <level>	set debugging level (defaults to $debug)
	   --help	        print this help message
EOF
}

my $opt_help		= 0;
my $opt_version		= 0;
my $opt_w		= 0;
my $opt_jobid		= 0;
my $opt_logid		= 0;

my $opt_command		= "";
my $opt_print_active	= 0;
my $opt_job		= "";
my $opt_host		= "";
my $opt_group		= "";
my $opt_version_ignore	= 0;

#Job Type : 1)pre-define; 2)qa_package; 3)autotest; 4)mult_machine; 5)reinstall
my $opt_jobtype		= 0;
my $opt_testname 	= "";
my $opt_listcases	= 0;
#option for mult-machine job
my $opt_roles		= "";
#option for re-install job
my $opt_re_url		= "";
my $opt_re_sdk		= "";
my $opt_re_pattern	= "";
my $opt_re_rpms		= "";
my $opt_re_kexec	= "";
my $opt_re_opts		= "";
#option for cmd 
my $opt_cmd		= "";
my $opt_mail		= "";
my $opt_user		= "";
my $opt_password	= "";

# parse command line options
unless (GetOptions(
		   'help'               => \$opt_help,
		   'version|v'          => \$opt_version,
		   'wait|w'             => \$opt_w,
		   'debug|d=i'          => \$debug,
		   'command|c=s'        => \$opt_command,
		   'job|j=s'            => \$opt_job,
		   'host|h=s'           => \$opt_host,
		   'group|g=s'          => \$opt_group,
		   'print-active|p'     => \$opt_print_active,
		   'jobtype|t=i'	=> \$opt_jobtype,
		   'testname|n=s'	=> \$opt_testname,
		   'listcases|l'	=> \$opt_listcases,
		   'roles|r=s'		=> \$opt_roles,
		   're_url|u=s'		=> \$opt_re_url,
		   're_sdk=s'		=> \$opt_re_sdk,
		   're_opts=s'	=> \$opt_re_opts,
		   'kexec'		=> \$opt_re_kexec,
		   'pattern=s'		=> \$opt_re_pattern,
		   'rpms=s'		=> \$opt_re_rpms,
		   'cmd|x=s'		=> \$opt_cmd,
		   'mail|m=s'		=> \$opt_mail,
		   'user|U=s'		=> \$opt_user,
		   'password|P=s'	=> \$opt_password,
		   'force-version-ignore' => \$opt_version_ignore,
		   'query_job=i'	=> \$opt_jobid,
		   'query_log=i'	=> \$opt_logid,
		  )) {
	&usage ();
	exit 1;
}

# Compare versions (requires format a.b.c) of the Hamsta master
# instance and this client instance. It compares only the major (a)
# and minor (b) version.
#
# Returns 1 if the version is OK and 0 if version is Not OK.
sub compare_versions () {
    chomp (my $check_result = send_command("check version $protocol_version\n"));

    if ($check_result eq 'OK') {
	return 1;
    } elsif ($check_result eq 'NOK') {
	return 0;
    } else {
	print STDERR "Master does not support version checking. You probably connect to "
	    . "an older master.\n\n";
    }
    return 0;
}

if ($opt_version) {
	print "$progname version $version\n";
	exit 0;
}

if ($opt_help) {
	&usage ();
	exit 0;
}

if ($#ARGV != 0) {
	print "Please specify the master to connect to.\n\n";
	&usage ();
	exit 1;
}

if ($opt_password && ! $opt_user) {
	print STDERR "${progname} error: Use option"
	    . " --user with --password if you want to log in.\n\n";
	usage ();
	exit 1;
}

my $opt_master;
my $opt_master_port;

($opt_master, $opt_master_port) = split(/:/, $ARGV[0]);
$opt_master_port = 18431 unless $opt_master_port;

print "Connecting to master $opt_master on $opt_master_port\n\n";

my $sock;
eval {
	$sock = IO::Socket::INET->new(
		PeerAddr => $opt_master,
		PeerPort => $opt_master_port,
		Proto    => 'tcp'
	);
};
if ($@ || !$sock) {
	print "Could not connect to master: $@$!\n";
	exit 2;
}

# Ignore the welcome message and wait for the prompt
&send_command('');

if (not $opt_version_ignore and not compare_versions()) {
    print STDERR "ERROR: Hamsta protocol mismatch. You might want to update your client.\n";
    exit 1;
}

my $job_id="";

if ($opt_user && $opt_password) {
    my $cmd = "log in ${opt_user} ${opt_password}";
    my $output = send_command ($cmd . "\n");
    if ($output !~ "[Yy]ou were authenticated") {
	print STDERR $output;
	exit 1;
    } else {
	print $output;
    }
}

if ($opt_print_active) {
	print &send_command("print active\n");
	exit 0;
}

# query job status from job_id
if($opt_jobid) {
	my $result_job;
	($result_job)=&check_status($opt_jobid);
	print "the job : $opt_jobid  stauts : $result_job \n";
	exit 0;

}

# get output from job_id
if($opt_logid) {
	my $cmd="query job log $opt_logid";
	my $output=&send_command($cmd."\n");
	print $output;
	exit 0;

}

#send cmd directly 
if ($opt_command) {
	(print "require host name/ip \n" and exit 1) unless($opt_host);
	$job_id=&send_command($opt_command."\n");
	print $job_id;
}

if ($opt_cmd) {
	$opt_cmd =~ s/ /#/g;
	(print "require host name/ip \n" and exit 1) unless($opt_host);
	my $cmd = "send one line cmd ip $opt_host $opt_cmd $opt_mail";
	$job_id=&send_command($cmd."\n");
	print $job_id; 
}

if ($opt_job) {
	if ($opt_host and $opt_group) {
		print "Please specify either a host or a group of hosts, not both.\n\n";
		exit 1;
	}

	if ($opt_host) {
		print &send_command("send job ip $opt_host $opt_job\n");
	} elsif ($opt_group) {
		print &send_command("send job group $opt_group $opt_job\n");
	} else {
		print "Please specify a host or a group of hosts.\n\n";
		exit 1;
	}
}



#list testcases 
if ($opt_listcases) {
	my $command="list jobtype $opt_jobtype \n";
	my $cases=&send_command("$command");

	if ($opt_jobtype != 5 && $opt_jobtype != 4) {
		if ($cases=~s/(----\w.*----\n)//) {
			print "$1";
		}
		
		foreach (split(/\s+/, $cases)) {
			print "$_\n";
		}
	} else {
		print $cases;
	}

	exit 0;
}

if ($opt_jobtype==1) {
	#send pre_define job
	(print "require testcase name \n" and exit 1) unless($opt_testname);	
	(print "require host name/ip \n" and exit 1) unless($opt_host);	
	my $cmd = "send qa_predefine_job ip $opt_host $opt_testname $opt_mail";
	$job_id=&send_command($cmd."\n");
	print $job_id;
} elsif ($opt_jobtype==2) {
	#send QA package job
	(print "require testcase name \n" and exit 1) unless($opt_testname);	
	(print "require host name/ip \n" and exit 1) unless($opt_host);	
	$opt_testname =~ s/,/#/g;
	my $cmd = "send qa_package_job ip $opt_host $opt_testname $opt_mail ";
	$job_id=&send_command($cmd."\n");
	print $job_id;
} elsif ($opt_jobtype==3) {
	#send Autotest job
	(print "require testcase name \n" and exit 1) unless($opt_testname);	
	(print "require host name/ip \n" and exit 1) unless($opt_host);	
	$opt_testname =~ s/,/#/g;
	my $cmd = "send autotest_job ip $opt_host $opt_testname $opt_mail ";
	$job_id=&send_command($cmd."\n");
	print $job_id;
} elsif ($opt_jobtype==4) {
	#send mult-machine job
	(print "require host roles \n" and exit 1) unless($opt_roles);
	my @roles = split /;/ ,$opt_roles;
	my $roles = grep(/r\d+:/,@roles);
	(print "roles do not match \n" and exit 1) unless(scalar(@roles) == $roles);
	$opt_roles =~ s/\s+//g;
	my $cmd = "send multi_job $opt_testname $opt_roles $opt_mail ";
	$job_id=&send_command($cmd."\n");
	print $job_id;
} elsif($opt_jobtype==5) {
	#send reinstall job
	(print "require host name/ip \n" and exit 1) unless($opt_host);	
	(print "require install REPO \n" and exit 1) unless($opt_re_url);	
	my $installopt="-p#$opt_re_url#";
	$installopt.="-s#$opt_re_sdk#" if($opt_re_sdk);
	if($opt_re_kexec) {
	    if($opt_re_rpms){
	        $opt_re_rpms = "$opt_re_rpms,kexec-utils";
	    }else{
	        $opt_re_rpms = "kexec-utils"
	    }
	        $installopt .= "#-k#";
	}
	$installopt.="-r#$opt_re_rpms#" if($opt_re_rpms);
	if($opt_re_pattern) {
		$opt_re_pattern="base,".$opt_re_pattern;
		$installopt.="-t#$opt_re_pattern#";
		$installopt.="#-B#"if($opt_re_pattern =~ /xen|kvm/i);
	}
	if($opt_re_opts) {
		$opt_re_opts =~ s/[ \t]+/#/g;
		$installopt.="#-o#\"$opt_re_opts\"#";

	}
	my $cmd = "send reinstall ip $opt_host $installopt $opt_mail";
	$job_id=&send_command($cmd."\n");
	print $job_id;
}




# if -w then wait for the job result
if($opt_w) {
	exit 1 unless($job_id=~/internal id/);
	$job_id =~ s/.*internal id:.//s;
	$job_id =~ s/[^d]$//g;
	my ($job_status,$machine_status);
	($job_status,$machine_status)=&check_status($job_id);

	sleep 180;
	#make sure machine is up
	while( $machine_status !~ /1/ ) {
		($job_status,$machine_status)=&check_status($job_id);
		sleep 30;
	}
	#query for the pass/fail 
	while ($job_status =~ /running/ or $job_status =~ /queued/ or $job_status =~ /connecting/ or $job_status =~ /new/){
		($job_status,$machine_status)=&check_status($job_id);
		sleep 30;
	}
	($job_status,$machine_status)=&check_status($job_id);
	print "Job status is $job_status, Machine status is $machine_status \n";
	exit 0 if($job_status =~ /passed/);
	exit 1 ;
}

sub check_status {
	my $job_id = shift;
	my $cmd="query job status $job_id";
	my $result_job=&send_command($cmd."\n");
	if(! defined($result_job)){
		print "Can not find status for job : $job_id\n,Please make sure job id exist. \n";
		exit 1;
	}
	my %result_map=(0=>'new',1=>'queued',2=>'running',3=>'passed',4=>'failed',5=>'canceled',6=>'connecting');
	$result_job =~ s/[^\d]//g;
	my $exist = $result_job =~ /^[0-6]+$/ ;
	if (defined $exist && $exist == 1) {
		my($job_status,$machine_status);
		($job_status,$machine_status) = $result_job =~ /^(.)(.*)/;
		return ($result_map{$job_status},$machine_status);
	}else{
		print "Not a available status value\n";
		exit 1;
	}
}
sub send_command {
	my $cmd = shift;
	my $result = "";
	my $line = "";

	eval {
		if ($cmd) {
		    $sock->send($cmd);
		    print "Sent $cmd" if $debug > 0;
		}
	};
	if ($@) {
		print "Message could not be sent: $@\n";
		exit 2;
	}

	print "Recv " if $debug > 1;
	while (1) {
		$_ = $sock->getc(); 
		if ($_ eq '') {
		    print "Master possibly terminated our session. Please restart.\n";
		    exit 2;
		}
		
		print $_ if $debug > 1;
		$line .= $_;
		
		if ($_ eq "\n") {
		    $result .= $line;
		    $line = "";
		}

		print "Recv " if ($_ eq "\n") and ($debug > 1);
		
		last if ($line =~ /\$>/);
	}
	print "\n" if $debug > 1;

	return $result;
}
