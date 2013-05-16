#!/usr/bin/perl -w
# ****************************************************************************
# Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
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
my $version = "2.3";


#my $tmpfile = "/tmp/$progname.$$";
#END { unlink($tmpfile); }

# Usage message
sub usage {
	print <<"EOF";
$progname version $version

$progname [OPTIONS] <master>[:<port>]

Options:
	-t|--jobtype <jobtype>  set the job type(number):
				1 pre-define 
				2 qa_package
				3 autotest
				4 mult_machine
				5 reinstall
	-n|--testname <testname>
				set test name for the job work with -t option 
		                (only for pre-define, qa_package, autotest, mult_machine)
		                seperate by ',' for qa_package&autotest job
	-l|--listcases		print the support test case name for each jobtype
				work with -t option
	-r|--roles		for mult-machine jobs, set roles number and host
		         	Assign SUT to roles , format like:
					-r 'r0:host1,host2;r1:host3,host4'

	-u|--re_url		set reinstall url
	   --re_sdk		set reinstall sdk
	   --pattern		set install pattern
	   --rpms		set extra rpm packages

	-U|--user		log in as user
	-P|--password		use password (use with --user option)
	-x|--cmd		set cmd for jobtype command_line
	-m|--mail		set email address for job result
	-p|--print-active	print all active machines
	-h|--host <ip>	        set the target SUT for test
	-g|--group <name>	set the target host group for test
	-v|--version	        print program version
	-d|--debug <level>	set debugging level (defaults to $debug)
	   --help	        print this help message
EOF
}

my $opt_help		= 0;
my $opt_version		= 0;
my $opt_w		= 0;

my $opt_command		= "";
my $opt_print_active	= 0;
my $opt_job		= "";
my $opt_host		= "";
my $opt_group		= "";

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
#option for cmd 
my $opt_cmd		= "";
my $opt_mail		= "";
my $opt_user		= "";
my $opt_password	= "";
my $opt_userrole	= "";

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
		   'pattern=s'		=> \$opt_re_pattern,
		   'rpms=s'		=> \$opt_re_rpms,
		   'cmd|x=s'		=> \$opt_cmd,
		   'mail|m=s'		=> \$opt_mail,
		   'user|U=s'		=> \$opt_user,
		   'password|P=s'	=> \$opt_password,
		   'userrole|R=s'	=> \$opt_userrole
		  )) {
	&usage ();
	exit 1;
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

my $job_id="";

if ($opt_user && $opt_password) {
    my $cmd = "log in ${opt_user} ${opt_password}";
    if ($opt_userrole) {
	$cmd .= " ${opt_userrole}";
    }
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
	exit 0;
}

#check the jobtype
if (! $opt_jobtype) {
	print "please specify a jobtype\n";
	print "more help use --help\n";
	exit 1;
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
	$installopt.="-r#$opt_re_rpms#" if($opt_re_rpms);
	if($opt_re_pattern) {
		$opt_re_pattern="base,".$opt_re_pattern;
		$installopt.="-t#$opt_re_pattern#";
	}
	my $cmd = "send reinstall ip $opt_host $installopt $opt_mail";
	$job_id=&send_command($cmd."\n");
	print $job_id;
} else {
	print "jobtype not supported\n";
}

# if -w then wait for the job result
if($opt_w) {
	exit 0 unless($job_id=~/internal id/);
	$job_id =~ s/.*internal id:.//s;	
	$job_id =~ s/[^d]$//g;
	my $url="http://$opt_master/hamsta/index.php?go=job_details&id=$job_id";
	my $result_job="";
	while($result_job eq "running" or $result_job eq "queued" or $result_job eq "" or $result_job eq "connecting") {
		my $content = get $url;
		my @content = split /\n/,$content;
		for(my $i=0;$i<@content;$i++) {
			if ($content[$i] =~ />Status</) {
				$i++;
				$result_job = $content[$i];
				$result_job =~ s/.*<td>//;
				$result_job =~ s/<\/td>.*//;
				last;
			}
		}
		sleep 5;
	}
	exit 0 if($result_job=~"passed");
	exit 1 if($result_job!~"passed");
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
		print "Message could not be send: $@\n";
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

