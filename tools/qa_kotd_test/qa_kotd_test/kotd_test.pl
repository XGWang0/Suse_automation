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


BEGIN {
# extend the include path to get our modules found
	push @INC,"/usr/share/qa/lib",'.';
}

use strict;
use log;
use qaconfig qw(get_qa_config);
use detect;
use Getopt::Std;
use IPC::Open3;
use IO::Select;

use constant {
	CMD_SURVIVE => 0,
	CMD_DIE => 1,
};

use constant {
	F_OVERWRITE => 0,
	F_APPEND => 1,
};

our $VERSION='0.10';
$Getopt::Std::STANDARD_HELP_VERSION=1;
our %conf;

# This defines cmdline/qaconf options
# Used for: printing help, setting %conf, parsing cmdline, reading qalog, defining defaults
# Priority: cmdline, qalog, default, [autodetection]
# Syntax: array of [
#     key - used as key for both %opts and %qalog
#     cmdline letter - used to parse cmdline options; no param expected if comment ends with '?'
#     comment - used to print help, no cmdline value if ends with '?'
#     default ]
our @cmdline_opts = (
['arch',	'a', 'architecture (i586|x86_64|ia64|ppc|ppc64|s390x)',		    undef], # autodetection
['branch',	'b', 'kernel branch',						 'master'],
['daemon',	'd', 'run as daemon ?',							0],
['use_base',	'e', 'nonzero to install the *-base RPM',			    undef], # true for SLE-11 by default
['flavor',	'f', 'flavor (default|debug|vanilla...)',			'default'],
['poll_int',	'i', 'how many seconds to wait between repo polls',		       60],
['logfile',	'l', 'log file',			     '/var/log/qa_kerneltest.log'],
['max_kernels',	'm', 'keep at most this number of kernels installed by the tool',	3],
['qadb_product','p', 'product for QADB submit',					    undef], # autodetection by product.pl
['vardir',	'r', 'directory to store status files',		 "/var/lib/qa/kerneltest"],
['sleep',	's', 'how many seconds to sleep before first command',		       60],
['tester',	't', 'tester name for QADB submit',			   'kotd-default'],
['kcmt_url',	'u', 'kernel commit repo URL',					       ''],
['loglevel',	'v', 'log verbosity (0..6)',				       LOG_DETAIL],
['nocommands',	'C', 'do not process queued commands ?',				0],
['noqadb',	'Q', 'do not report to QADB ?',						0],
['noreboot',	'R', 'do not reboot ?',							0],
);

# This defines actions callable from cmdline
# Synax: array of [ name, description, function reference, function args ]
# If <name> is entered, <function> is called with <args>
our @cmdline_actions = (
['clean',	'uninstalls all installed RPMs',		\&cleanup,	[] ],
['check',	'checks for new kernel, prints info if found',	\&scheduler,	[wait=>0,install=>0,repeat=>0,test=>0] ],
['wait',	'waits  for new kernel, prints info, exits',	\&scheduler,	[wait=>1,install=>0,repeat=>0,test=>0] ],
['poll',	'waits  for new kernel, prints info, repeats',	\&scheduler,	[wait=>1,install=>0,repeat=>1,test=>0] ],
['install',	'checks for new kernel, installs if found',	\&scheduler,	[wait=>0,install=>1,repeat=>1,test=>0] ],
['loop',	'waits  for new kernel, installs, runs tests',	\&scheduler,	[wait=>1,install=>1,repeat=>1,test=>1] ],
['test',	'replaces queue with tests and runs them',	\&queue_tests,	[] ],
['rmqueue',	'removes everything from queue',		\&purge_queue,	[] ],
['queue',	'prints the queue of commands',			\&print_queue,	[] ],
['kernels',	'lists installed kernels',			\&list_kernels,	[] ],
['list',	'lists both kernels and command queue',		\&list_all,	[] ],
);


# start, process the configuration
our $curl = "curl -f -L -s";
our %qaconf = &get_qa_config('kotd');
our ($motd,$motd_bak) = ('/etc/motd','/etc/motd.bak');
&process_config();

# run as daemon ?
if($conf{'daemon'})	{
	&daemonize();
} else {
	&log_add_output(path=>$conf{'logfile'});
}
$SIG{INT}  = sub { die("SIGINT"); };
$SIG{TERM} = sub { die("SIGTERM"); };

# process command queue
&run_commands() unless $conf{'nocommands'};

# display help unless an action is specified
unless(@ARGV)	{
	&help_message();
	exit 2;
}

# process actions
&set_motd();
my %action_hash = map { $_->[0] => $_ } @cmdline_actions;
foreach my $action (@ARGV)	{
	&complain("Unknown action: '$action'",CMD_DIE) unless $action_hash{$action};
	my @a = @{$action_hash{$action}};
	&log(LOG_INFO,"Action: %s (%s)", $action, $a[1]);
	$a[2]->(@{$a[3]});
}

END { &restore_motd(); }

# end of program here
&log(LOG_INFO,"KOTD controller finished.");
exit 0;

###################### CMDLINE OPTIONS, HELP ##################################

# what is shown by "$0 --help"
sub HELP_MESSAGE
{
	print STDERR "Usage: $0 [options] [actions]\n";
	print STDERR "Actions:\n";
	foreach my $row (@cmdline_actions)	{
		print STDERR "\t$row->[0]\t\t$row->[1]\n";
	}
	print STDERR "Options:\n";
	foreach my $row (sort {$a->[1] cmp $b->[1]} @cmdline_opts)	{
		my ($key,$letter,$comment,$default)=@$row;
		my $param = !( $comment =~ s/\?$// );
		my $options = sprintf "[-%s%s]", $letter, ($param ? " <$key>":'');
		$options .= "\t" x int((24-length($options))/8);
		$default = ( defined $qaconf{$key} ? $qaconf{$key} : $default );
		$default = ( $param ? (defined $default ? "[$default]" : '(autodetect)') : '' );
		printf STDERR "\t%s\t%s %s\n", $options, $comment, $default ;
	}
}

# what is shown by "$0 --version"
sub VERSION_MESSAGE()
{
	print STDERR "$0 version $VERSION\n";
}

# sets %conf - cmdline, qaconf, defaults
sub process_config()
{
	# parse cmdline options
	my $cmdline_options = join('',map {$_->[1].($_->[2]=~/\?$/ ? '':':')} @cmdline_opts);
	my %opts;
	getopts($cmdline_options,\%opts);

	# get %conf from %opts or %qaconf
	foreach my $row (@cmdline_opts)	{
		my ($key,$letter,$comment,$default)=@$row;
		my $val = $default;
		$val = $qaconf{$key}  if defined $qaconf{$key};
		$val = $opts{$letter} if defined $opts{$letter};
		$conf{$key} = $val;
	}

	# paths for internal work files
	mkdir($conf{'vardir'},0755) unless -e $conf{'vardir'};
	$conf{'krnl_list'} = $conf{'vardir'}."/qa_krnl_list";	# kernels kept installed by this tool
	$conf{'kcmt_last'} = $conf{'vardir'}."/qa_kcmt_last";	# last kernel commit tested here
	$conf{'test_cmnd'} = $conf{'vardir'}."/test";		# test commands to run on this SUT
	$conf{'cmnd_fifo'} = $conf{'vardir'}."/cmnd_fifo";	# commands queued for execution
	$conf{'cmnd_stat'} = $conf{'vardir'}."/status";		# quick status info
	
	# autodetect architecture
	$conf{'arch'} = &get_architecture() unless defined $conf{'arch'};

	# detecting product is delayed because it is slow and prints log messages

	# loglevel
	$log::loglevel = $conf{'loglevel'};

	# hostname
	$conf{'hostname'} = `/bin/hostname`;
	chomp( $conf{'hostname'} );
}

# autodetect QADB settings if missing
# this is time-consuming and prints log messages, 
#  so we initialize it just before we need it
sub qadb_detect()
{
	return if $conf{'autodetected'};
	$conf{'qadb_product'} = sprintf("%s-%s",(&detect_product(net=>1))[5,3]) unless defined $conf{'qadb_product'};
	$conf{'use_base'} = ($conf{'qadb_product'}=~/^SLE[POS4A -]*11/) unless defined $conf{'use_base'};
	$conf{'autodetected'} = 1;
}


############################# RUN CONTROL #####################################

# starts tests, waits for new RPMs etc.
sub scheduler
{
	my %args = (
		wait=>0,	# wait until a new kernel appears ?
		install=>0,	# install new kernels ?
		repeat=>0,	# repeat ?
		test=>0,	# queue tests ?
		@_
	);
	my $sleep = $conf{'poll_int'};

	&log( LOG_INFO, "%s looking for kernel - branch:%s arch:%s flavor:%s flags:%s", (map {$conf{$_}} qw(hostname branch arch flavor)), join(',',map {$args{$_} ? ($_):()} qw(install repeat test wait)) );

	# delayed autodetection of QADB args
	&qadb_detect();

	my $last_datetime = &get_last_kernel();
	do	{{ # 'next' won't work unless the braces are doubled

		# poll for newer kernels
		my $new;
		while(1)	{
			$new = &check_commit_build($last_datetime);
			last if defined $new and @$new;
			last if !$args{'wait'} or $sleep>sleep($sleep);
		}

		# skip rest if not waiting or interrupted
		next unless defined $new->[0];

		# we have a new kernel here
		$last_datetime = $new->[0];

		# install the kernel
		if( $args{'install'} )	{

			# status update
			&set_status('installing '.join(' ',@$new));
			
			# install the RPM, update Grub
			&install_kernel(@$new);

			# store datetime of last tested kernel
			&write_file($conf{'kcmt_last'},$last_datetime,CMD_DIE,F_OVERWRITE);

			# tests into the command queue
			&queue_tests() if $args{'test'};

			# reboot
			&reboot();

			# exit if reboot disabled / failed
			&log(LOG_NOTICE, "No reboot, exiting");
			exit 0;
		}
	}} while($args{'repeat'});
}

# runs 'grubonce 0' and reboots
sub reboot()
{
	return 0 if $conf{'noreboot'};
	&set_status('rebooting');
	&command(CMD_DIE, "/usr/sbin/grubonce 0 && /sbin/reboot");
	0;
}

# open log, redirect STDOUT/STDERR, close STDIN, double fork
sub daemonize()
{
	my ($log, $pid);

	# chdir to root
	chdir '/' or &log(LOG_ERROR,"Can't chdir to /: $!");

	# open log
	my $logfile = $conf{'logfile'};
	open $log,">>$logfile" or &log(LOG_ERROR,"Cannot open $logfile for append: $!");
	
	# double fork to prevent zombie processes
	unless( $pid = fork() )	{
		unless(fork())	{
			# redirect I/O
			open STDIN, '/dev/null' or &log(LOG_ERROR,"Cannot read /dev/null: $!");
			if( $log )	{
				&log_set_output(handle=>$log,close=>1);
				open STDOUT, ">&", $log or &log(LOG_ERROR, "Cannot redirect STDOUT to $logfile: $!");
				open STDERR, ">&", $log or &log(LOG_ERROR, "Cannot redirect STDERR to $logfile: $!");
			}
			return 0;
		}
		exit 0;
	}

	# join the process from the first fork
	if( defined $pid )	{
		waitpid( $pid, 0 );
		exit 0;
	}

	# should not come here
	&log(LOG_CRITICAL,"Cannot fork: $!");
	exit -1;
}

# runs a command
sub command($$) # $die, $cmd
{
	my $die = shift;
	my $cmd = shift;
	&log(LOG_DETAIL,"Running: $cmd");
	my $ret = system $cmd;
	die "Command '$cmd' failed with code $ret" if $die and $ret>0;
	&log(LOG_ERROR, "Command '$cmd' failed with code $ret") if $ret>0;
	return $ret;
}

# runs a command, logs its STDOUT/STDERR 
sub command_log # $die, command + arguments ...
{
	my $die = shift;
	my $pid = open3('<&STDIN',*OUT,*ERR, '-');
	if( $pid==0 )	{
		if( @_ > 1 )	{
			exec @_;
			die "Cannot exec command: $!";
		}
		else	{
			system @_;
			exit $?;
		}
	}
	my $selector = IO::Select->new();
	$selector->add(*OUT,*ERR);

	while($selector->count() > 0)	{
		my @handles = $selector->can_read();
		foreach my $fh (@handles)	{
			my $line = <$fh>;
			unless( defined $line )	{
				$selector->remove($fh);
				next;
			}
			if( fileno($fh) == fileno(ERR) )	{
				&log(LOG_STDERR, $line);
			} else {
				&log(LOG_STDOUT, $line);
			}
		}
	}
	my $ret = waitpid($pid,0) >> 8;
#	&log(LOG_RETURN, $ret);
	die "Command '".join(' ',@_)."' failed with code $ret" if $die and $ret>0;
	&log(LOG_ERROR, "Command '".join(' ',@_)."' failed with code $ret") if $ret>0;
	return $ret;
}

# prints an error message, dies optionally
sub complain($$) # $message, $die
{
	my($message,$die)=@_;
	&log( $die ? LOG_CRITICAL : LOG_ERROR, '%s', $message );
	exit 1 if $die;
	undef;
}


############################ KERNEL TOOLS #####################################

# installs a new kernel
sub install_kernel(@) # $datetime, $baseurl, @files
{
	my ($datetime,$baseurl,@files) = @_;
	my $tmpdir = "/tmp/kotdtest/$datetime";
	my @rpm_basenames;

	# uninstall old kernel(s)
	my $installed = &read_file($conf{'krnl_list'},CMD_SURVIVE);
	if( $installed and @$installed+1 > $conf{'max_kernels'} ) {
		&uninstall_kernel(split(' ',shift @$installed));
	}

	# fetch all files
	&log(LOG_INFO, "Fetching kernel");
	foreach my $i (0..@files-1)	{
		if( defined($baseurl) and $baseurl =~ /^(http|https|ftp):/ )	{
			&command(CMD_DIE,"mkdir -p \"$tmpdir\"") unless -d $tmpdir;
			$files[$i] = &download_file("$tmpdir/".$files[$i],"$baseurl/".$files[$i]);
			push @rpm_basenames,$1 if $files[$i] =~ /([^\/]+).$conf{'arch'}.rpm/;
		}
		unless( -f $files[$i] )	{
			&log(LOG_ERROR,'File '.$files[$i].' does not exist, aborting installation');
			return 0;
		}
	}

	# store old default bootentry
	my @grub_defaults = &get_default_entry();

	# install at once
	&log(LOG_INFO, "Installing new kernel");
	&command(CMD_DIE,"PBL_AUTOTEST=1 rpm -i --oldpackage --nodeps".(join '',map {' "'.$_.'"'} @files));

	# update list of installed kernels
	push @$installed,join(' ',@rpm_basenames);
	&write_file($conf{'krnl_list'},$installed,CMD_SURVIVE,F_OVERWRITE);

	# push RPM info on the cmdline
	my $info = &get_rpm_info($files[0]);
	&add_grub_options( $info ) if %$info;

	# restore original bootentry
	&restore_default_entry(@grub_defaults);

	# delete temporary files
	unlink @files or &log(LOG_WARNING, "Cannot delete temp files: %s", $!);

	&log(LOG_INFO, "Kernel installed");
}

# uninstalls one kernel
sub uninstall_kernel(@) # @files
{
	my @files=@_;
	my @grub_defaults = &get_default_entry();
	&command(CMD_SURVIVE,'rpm -e '.join(' ',map {'"'.$_.'"'} @files));
	&restore_default_entry(@grub_defaults);
}

# uninstalls all kernels, purges status files
sub cleanup()
{
	# uninstall kernels
	my $installed = &read_file($conf{'krnl_list'},CMD_SURVIVE);
	foreach my $i (@$installed)	{
		next unless $i;
		&log(LOG_INFO, "Uninstalling %s",$i);
		&uninstall_kernel(split(' ',$i));
	}

	# purge status files
	foreach my $key (qw(krnl_list kcmt_last cmnd_fifo cmnd_stat))	{
		&write_file($conf{$key},[],CMD_SURVIVE,F_OVERWRITE);
	}

	# you should reboot soon
}

# compares version or subversion
# return values a la 'cmp' or '<=>'
sub is_newer_version($$) # $ver1, $ver2
{
	my ($v1,$v2)=@_;
	my @v1=split('.',$v1);
	my @v2=split('.',$v2);
	my $length = (@v1>@v2 ? @v1 : @v2);
	foreach my $i (0 .. ($length-1))	{
		return 1 unless defined $v2[$i];
		return -1 unless defined $v1[$i];
		return $v1[$i] <=> $v2[$i] unless $v1[$i]==$v2[$i];
	}
	return 0;
}

# compares versions of two RPM files
sub is_newer($$) # $rpm1, $rpm2
{
	my ($rpm1,$rpm2)=@_;
	my($v1,$v2,$r1,$r2);
	($_,$_,$_,$v1,$r1,$_)=&parse_rpmname($rpm1);
	($_,$_,$_,$v2,$r2,$_)=&parse_rpmname($rpm2);
	my $ret1 = &is_newer_version($v1,$v2);
	return $ret1 if $ret1;
	return &is_newer_version($r1,$r2);
}

############################# NETWORK REPO TOOLS ##############################

# scans $url
# checks for its latest build subdirectory
# compares if newer than $last_datetime, if $last_datetime defined
# if a new one found, runs &scan_dir(...) and returns result
sub check_commit_build($) # $last_datetime
{
	my ($last_datetime,$last_url,$last_files)=($_[0],undef,undef);
	my $last_datetime_num = (defined $last_datetime ? $last_datetime : 0);
	$last_datetime_num =~ s/-//;

	# read the repository
	my $base_url = $conf{'kcmt_url'}.'/'.$conf{'branch'}.'/'.$conf{'arch'};
	&log(LOG_DEBUG,"Polling URL '%s'",$base_url);
	unless(open DIR, "$curl \"$base_url\" |")	{
		&log(LOG_ERROR,"Failed to run '$curl $base_url'");
		return undef;
	}

	# look for subdir with latest timestamp
	while( my $row=<DIR> )	{
		next unless $row =~ /href="(\d{8})-(\d{6})\/">/;
		my ($datetime,$datetime_num,$url)=("$1-$2","$1$2","$base_url/$1-$2");
		next if $last_datetime_num and $datetime_num <= $last_datetime_num;
		my $files = &scan_dir( $url );
		next unless $files and @$files;
		($last_datetime,$last_datetime_num,$last_url,$last_files) = 
			($datetime,$datetime_num,$url,$files);
	}
	close DIR;
	unless( $last_url )	{
		&log(LOG_DEBUG, "No new kernel build found".($last_datetime ? " (newer than $last_datetime)" : '' ));
		return [];
	}
	&log(LOG_NOTICE,"Found new commit build %s file(s) %s",$last_datetime,join(', ',@$last_files));
	return [ $last_datetime, $last_url, @$last_files ];
}

# scans a HTTP dir at $url
# looks for kernels matching $conf{'flavor'},$conf{'arch'}
# if $use_base is true, looks for *-base-* package as well
# returns [ kernel-* ] or [ kernel-*, kernel-base-* ] or undef
# returns files with the highest version
sub scan_dir($) # $url
{
	my ($url)=@_;

	# open the repository
	unless( open LIST, "$curl $url |" )	{
		&log(LOG_ERROR,"Failed to run '$curl $url'");
		return undef;
	}
	my %bases=(); # hash to check if we have the corresponding '-base' package
	my ($ret_ver,$ret_file) = ('','');

	&log(LOG_DEBUG,"Scanning URL '%s' for flavor '%s' arch '%s' use_base=%s",$url,map {$conf{$_}} qw(flavor arch use_base));

	# scan the matching RPMs, return the one with the highest version
	while( my $row=<LIST> )	{
		next unless $row =~ /href="([^"]+)"/;
		my $file=$1;
		next unless $file =~ /^kernel-$conf{'flavor'}(-base)?-(\d.+)\.$conf{'arch'}.rpm$/;
		&log(LOG_DETAIL,"File '%s' matches",$file);
		my ($base,$version)=($1,$2);
		if( $base )	{
			$bases{$version}=$file;
			next;
		}
		next unless $version gt $ret_ver;
		$ret_ver=$version;
		$ret_file=$file;
	}
	close LIST;

	# check if we have kernel main RPM
	unless($ret_file)	{
		&log(LOG_DEBUG, "No matching RPM found in '%s'",$url);
		return undef;
	}

	# check if we have kernel base RPM (when requested)
	if($conf{'use_base'} and !$bases{$ret_ver})	{
		&log(LOG_WARNING, "Kernel RPM found, required base RPM not found");
		return undef;
	}

	# RPM(s) found, return their URLs
	my $ret = [ $conf{'use_base'} ? ( $ret_file, $bases{$ret_ver} ) : ( $ret_file ) ];
	&log(LOG_DETAIL,"Found RPM(s) %s",join(', ',@$ret));
	return $ret;
}


############################# GRUB tools ######################################

# adds $opts kernel options to Grub's first boot entry
sub add_grub_options($) # %$opts
{
	my $opts=$_[0];
	my @opts=();
	foreach my $key (keys %$opts)	{
		my $val = $opts->{$key};
		$val =~ s/[^\d\w \-\.:;]//g;
		$val =~ s/ +/-/g;
		push @opts,"$key=$val";
	}
	&command(CMD_DIE,'sed -ie \'1,/^\s*kernel/ { s/\(\s*kernel.\+\)/\1 '.(join ' ',@opts).'/1}\' /boot/grub/menu.lst');
}

# returns Grub's default entry (number)
sub get_default_entry()
{
	my $file = '/boot/grub/menu.lst';
	return undef unless -r $file;
	my $default = `grep ^default $file | cut -d\\  -f2`;
	my $count = `grep ^title $file | wc -l`;
	return undef unless $default and $count;
	chomp $default;
	chomp $count;
	return ($default,$count);
}

# restores Grub's default entry ($count is used to calculate the shift)
sub restore_default_entry($$) # $default, $count
{
	my ($olddefault,$oldcount)=@_;
	my ($default,$count)=&get_default_entry();
	return unless defined($olddefault) and defined($oldcount);
	return unless defined($default) and defined($count);
	$default = $olddefault + ($count-$oldcount);
	&command(CMD_DIE,"sed -ie 's/^default 0/default $default/' /boot/grub/menu.lst");
}


############################ KERNEL INFO DETECTION ############################

# returns flavor, (undef|base|devel|extra), version, release, arch
# (if the filename matches the pattern)
sub parse_rpmname($)
{
	my $rpm = shift;
	return ($1,$2,$3,$4,$5) if $rpm =~ /(?:kernel|linux)-(debug|default|desktop|ec2|trace|vanilla|xen)(?:-(base|devel|extra))?-([\d\w\.]+)-([\d\w\.]+).([\d\w_]+).rpm$/;
	return ();
}



# returns hash with kernel cmdline key=>val pairs
sub parse_cmdline()
{
	my $cmdline = `cat /proc/cmdline`;
	unless ( $cmdline )	{
		&log(LOG_ERROR, "Cannot read /proc/cmdline: $!");
		return {};
	}
	chomp $cmdline;
	return { map { $_=~/([^=]+)=?(.*)/ ? ($1=>$2):() } split / +/,$cmdline };
}

# checks if $cmdline contains 'git_revision' and 'git_branch'
sub check_cmdline($) # $cmdline
{
	my $cmdline = shift;
	return 1 if defined $cmdline->{'git_revision'} and defined $cmdline->{'git_branch'};
	&log(LOG_ERROR,"According to /proc/cmdline, you seem not to be running a KOTD kernel / commit build kernel");
	0;
}

# queries a RPM file for interesting attributes
sub get_rpm_info($) # $file
{
	my $file=$_[0];
	unless( open RPM, "rpm -qip \"$file\"|" )	{
		&log(LOG_ERROR, "Cannot query 'rpm -qip \"$file\"': $!" );
		return {};
	}
	my $ret={};
	while( my $row = <RPM> )	{
		chomp $row;
		$ret->{'src_timestamp'}=$1 if $row =~ /^Source Timestamp:\s*(.+)$/;
		$ret->{'git_revision' }=$1 if $row =~ /^GIT Revision:\s*(.+)$/;
		$ret->{'git_branch'   }=$1 if $row =~ /^GIT Branch:\s*(.+)$/;
		$ret->{'distribution' }=$1 if $row =~ /^Distribution:\s*(.+)$/;
	}
	close RPM;
	return $ret;
}

# parses `uname -r`, returns 'version' and 'flavor'
sub get_uname_info()
{
	my $uname = `uname -r`;
	unless ($uname)	{
		&log(LOG_ERROR, "Cannot run 'uname -r': $!");
		return {};
	}
	return { 'version'=>$1, 'flavor'=>$3} if $uname =~ /([^-]+)(-.+)?\-(.+)/;
	&log(LOG_ERROR, "Cannot parse output of 'uname -r' that is '$uname'");
	return {};
}

############################### QADB REPORT ###################################

# runs remote_qa_db_report.pl
sub qa_db_report($) # $comment 
{
	my($comment)=@_;
	return if $conf{'noqadb'};
	&qadb_detect();
	my $uname=&get_uname_info();
	my $cmdline=&parse_cmdline();
	return unless %$uname and &check_cmdline($cmdline);
	my $type = join(':', 'kotd', $cmdline->{'git_revision'}, $uname->{'version'}, $cmdline->{'git_branch'}, $uname->{'flavor'});
	my $options="-b -p $conf{'qadb_product'} -t \"$type\"";
	$options .= " -T $conf{'tester'}" if $conf{'tester'};
	$options .= " -c \"$comment\"" if $comment;
	&command_log(CMD_DIE,"/usr/share/qa/tools/remote_qa_db_report.pl $options");
}


############################## COMMAND QUEUE ##################################

# processes one command
sub process_command($) # $command
{
	return unless $_[0];
	my ($cmd,$args) = split /\s+/, $_[0], 2;
	&set_status("Command ".$_[0]);
	if( $cmd eq 'REBOOT' )	{
		&reboot();
	}
	elsif( $cmd eq 'SUBMIT' )	{
		&qa_db_report($args);
	}
	elsif( $cmd eq 'RUN' )	{
		&command(CMD_SURVIVE,$args);
	}
	elsif( $cmd eq 'START' )	{
		&start_test($args);
	}
	elsif( $cmd eq 'STOP' )	{
		&stop_test($args);
	}
	elsif( $cmd eq 'SLEEP' and $args =~ /^\d+/ )	{
		sleep $1;
	}
	elsif( $cmd eq 'CHECKFORNEW' )	{
		&scheduler(wait=>0,install=>1,repeat=>0,test=>1,last_datetime=>&get_last_kernel());
	}
	else	{
		&complain("Wrong command: '$cmd'",CMD_DIE);
	}
}

# starts a testsuite in a way that detects a reboot instead of regular finish
sub start_test($) # $command
{
	my $cmd = shift;
	&unshift_commands("STOP $cmd");
	&command(CMD_SURVIVE,$cmd);
	&shift_command();
}

# this should only be reached after rebooting a crashed testsuite
sub stop_test($) # $command
{
	&complain("Crashed command '$_[0]'",CMD_DIE);
}

# runs all commands in $conf{'cmnd_fifo'}
sub run_commands()
{
	return unless -f $conf{'cmnd_fifo'};
	my $first=1;
	while( my $cmd = &shift_command() )	{
		next if $cmd =~ /^\s*(#.*)?$/;
		if( $first )	{
			&set_motd();
			&log(LOG_INFO,"Processing first command in the queue" . ($conf{'sleep'} ? ", sleeping for $conf{'sleep'} seconds":'') );
			sleep $conf{'sleep'};
		}
		&log(LOG_INFO,"Command '$cmd'");
		&set_status($cmd);
		&process_command($cmd);
		$first=0;
	}
	&log(LOG_INFO,"Processing command queue done") unless $first;
}

# reads first command and removes it from the list
sub shift_command()
{
	return '' unless -r $conf{'cmnd_fifo'};
	my $cmd = `head -n1 $conf{'cmnd_fifo'}; sed -i '1d' $conf{'cmnd_fifo'}`;
	chomp $cmd;
	return $cmd;
}

# puts commands at the end
sub push_commands(@) # @commands
{
	&write_file($conf{'cmnd_fifo'},@_,CMD_DIE,F_APPEND);
}

# inserts commands at the beginning
sub unshift_commands(@) # @commands
{
	my $oldcmds=( -r $conf{'cmnd_fifo'} ? &read_file($conf{'cmnd_fifo'},CMD_DIE) : () );
	&write_file($conf{'cmnd_fifo'},[@_,@$oldcmds],CMD_DIE,F_OVERWRITE);
}

# prints command queue
sub print_queue()
{
	my $lines=&read_file($conf{'cmnd_fifo'},CMD_DIE);
	unless( @$lines )	{
		print "Queue is empty.\n";
	} else {
		my $i=0;
		map { print $i++.": $_\n" } @$lines;
	}
}

# clears the command queue ($conf{'cmnd_fifo'})
sub purge_queue()
{
	&write_file($conf{'cmnd_fifo'},[],CMD_DIE,F_OVERWRITE);
	print "Queue purged.\n";
}

sub list_all()
{
	&list_kernels();
	&print_queue();
}

######################### MANIPULATING STATUS FILES ###########################

sub set_status($) # $status
{
	&write_file($conf{'cmnd_stat'},$_[0],CMD_SURVIVE,F_OVERWRITE);
}

# replaces cmd_fifo with test_cmnd
sub queue_tests()
{
	my $commands=&read_file($conf{'test_cmnd'},CMD_DIE);
	&write_file($conf{'cmnd_fifo'},$commands,CMD_DIE,F_OVERWRITE);
}



# prints info about installed kernels
sub list_kernels()
{
	# list of maintained kernels
	my $kernels=&read_file($conf{'krnl_list'},CMD_SURVIVE);
	if( $kernels and @$kernels )	{
		print "Maintained KOTD kernels:\n";
		map {print "\t$_\n"} @$kernels;
	} else {
		print "No maintained KOTD kernels.\n";
	}

	# last kernel
	my $last=&get_last_kernel();
	if( $last )	{
		print "Last tested kernel commit: $last\n";
	} else {
		print "No KOTD tested yet.\n";
	}

}

# reads $conf{'kcmt_last'}, returns undef or kernel RPM basename
sub get_last_kernel()
{
	my $last = &read_file($conf{'kcmt_last'},CMD_SURVIVE);
	return ( defined $last->[0] ? $last->[0] : undef );
}

# sets a MOTD message
sub set_motd()
{
	unless( -f $motd_bak )	{
		unless( rename($motd,$motd_bak) )	{
			&complain("Cannot rename '$motd' to '$motd_bak': $!",CMD_SURVIVE);
			return 0;
		}
	}
	my $message=<<EOF;
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                           *
 *                  This machine is used for                 *
 *                  Kernel-Of-The-Day testing                *
 *                                                           *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

    Architecture:	$conf{'arch'}

    Branch:		$conf{'branch'}

    Flavor:		$conf{'flavor'}

    Repo URL:		$conf{'kcmt_url'}

    Tester:		$conf{'tester'}

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *                                                           *
 *                   Kerneltests Running                     *
 *                                                           *
 *                     Do not Disturb                        *
 *                                                           *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
EOF
	&write_file($motd,$message,CMD_SURVIVE,0);
}

# restore original MOTD file
sub restore_motd()
{
	return 0 unless -f $motd_bak;
	rename($motd_bak,$motd) or &complain("Cannot rename '$motd_bak' to '$motd': $!", CMD_SURVIVE);
}

############################ FILE TOOLS #######################################

# reads the whole file as an arrayref [ $row1 $row2 ... ]
sub read_file($$) # $file, $die
{
	my ($file,$die)=@_;
	my @ret;
	return &complain("Cannot open '$file' for reading: $!",$die) unless open FILE, $file;
	while(<FILE>)	{
		chomp;
		push @ret,$_;
	}
	close FILE;
	return [@ret];
}

# writes a file from an arrayref [ $row1, $row2 ... ]
sub write_file($$$$) # $file, $contents, $die, $append
{
	my ($file,$contents,$die,$append)=@_;
	$contents=[$contents] unless ref($contents) eq 'ARRAY';
	unless( open FILE, ($append ? '>>':'>').$file )	{
		return &complain('Cannot '.($append ? 'append':'rewrite')." '$file': $!",$die);
	}
	map { chomp; print FILE "$_\n"; } @$contents;
	close FILE;
	1;
}

# removes first line from a file and returs
sub shift_file($$) # $file, $die
{
	my ($file,$die) = shift;
	return &complain("Cannot read a line from '$file' - no such file",$die) unless -w $file;
	return `head -n1 $file; sed -i '1d' $file`;
}

# downloads a file using CURL
sub download_file($$) # $out, $url
{
	my ($out,$file) = @_;
	&command(CMD_SURVIVE,"$curl -o '$out' '$file'");
	return $out;
}



