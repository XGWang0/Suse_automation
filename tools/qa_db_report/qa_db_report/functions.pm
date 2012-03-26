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

package functions;
# See man 1 perlmod for the perl module template used here

use strict;
use POSIX qw/ :termios_h strftime /;
use File::Temp qw/ tempfile tempdir /;
use File::Basename qw/basename dirname/;
use warnings;
# Perl mySQL API
use log;
use qaconfig;

# module template pretext:  START
# 
BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # Here: RCS; the q$...$ from RCS act as a quote here(!)
    $VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ /(\d+)/g;

    @ISA         = qw(Exporter);

    # What is exported by default upon the simple "use THISMODULE"
    # (See: camel book, p. 288)
    # It's good manners to have only functions here, no other variables 
    # (putting variables into @EXPORT_OK instead)
    @EXPORT      = qw(  
			&is_bench
			&bench_func
			&get_log_dir
			&is_ltp
			&scp
			&mail
			&process_dirname
			&remove_duplicite_keyvals
			&set_product_release
			$batchmode
		);
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # What can be additionally exported, if it's specifically required
    # by means of a "use THISMODULE qw/list_of_requested_exports/"
    # (See: camel book, p. 288)
    # In particular, all exported package global _variables_ should go here.
    # _Note_: exporting non-function variables is dangerous and should
    #         be carried out carefully and with restraint.
    @EXPORT_OK   = qw(
		);
}
our @EXPORT_OK;

our $batchmode=0;
my %benchmarks=(
	'dbench[-_]\w[\w\d]*' => 'parse_dbench',
	'bonnie-default' => 'parse_bonnie',
	'tiobench' => 'parse_tiobench',
	'siege_defaultrun|qa_siege_defaultrun.sh|qa_siege|qa_siege_https?' => 'parse_siege',
	'libmicro-bench' => 'parse_libmicro',
	'specweb' => 'parse_specweb',
	'sysbench-\w+' => 'parse_sysbench',
	'interbench' => 'parse_interbench',
	'reaim(?:-(?:compute|dbase|fserver|shared))?' => 'parse_reaim',
	'aim7-(?:compute|dbase|fserver|shared)' => 'parse_aim7',
	'lmbench' => 'parse_lmbench',
	'tiobench[-\w]*' => 'parse_tiobench',
	'kernbench' => 'parse_kernbench',
	'hazard_stress' => 'parse_hazard',
	'openssl_benchmark' => 'parse_openssl',
	'fio(?:\-\w+)' => 'parse_fio',
);



sub is_bench	# 
{
	my $exp='^('.join('|',keys %benchmarks).')$';
	return $1 if $_[0] =~ $exp;
	return undef;
}

sub bench_func	# testcase
{
	foreach my $exp( keys %benchmarks )
	{	return $benchmarks{$exp} if $_[0]=~ ('^'.$exp.'$');	}
	return undef;
}


sub get_log_dir	# directory basename
{
	my $logdir;
	my %args=(
		'arch'=>`uname -m`,
		'host'=>`uname -n`,
		'kernel'=>`uname -r`,
		'testsuite'=>'',
		'date'=>'',
		'md5sum'=>'',
		'kernel_branch'=>'',
		'product'=>'',
		'release'=>'',
		@_
	);
	my $ltp=&is_ltp( $args{'testsuite'} );
	my ($type, $md5sum) = split /:/, $args{'type'};
	if( $type eq 'patch' )
	{
		# see bnc#632337 for logs structure
		if( $args{'testsuite'} =~ /^(reaim|newburn)/ or $ltp )
		{	$logdir='Maintenance/Kernel/'.$args{'product'}.'/'.$args{'arch'}.'/'.$args{'host'}.'/'.$args{'kernel'};	}
		else
		{	$logdir='Maintenance/Other/'.$args{'product'}.'/'.$args{'arch'}.'/'.$args{'host'}.'/'.$md5sum;	}
	}
	elsif( $type eq 'kotd' )
	{
		# TODO - is this correct??? Seems that it will get extra level testsuite[-date]/testsuite ? maybe delete last part?
		if( $ltp )
		{	$logdir='kotd/'.$args{'kernel_branch'}.'/'.$args{'arch'}.'/'.$args{'host'}.'/'.$args{'kernel'}.'/ltp/'.$args{'testsuite'}.'-'.$args{'date'};	}
		else
		{	$logdir='kotd/'.$args{'kernel_branch'}.'/'.$args{'arch'}.'/'.$args{'host'}.'/'.$args{'kernel'}.'/'.$args{'testsuite'};	}
	}
#	elsif( $type eq 'regression' )
#	{	$logdir=$args{'arch'}.'/'.$args{'host'}.'/'.$args{'kernel'}.'/'.$args{'testsuite'}.'-'.$args{'date'};	}
	else
	{
		$logdir='ProductTests/'.$args{'product'}.'/'.$args{'release'}.'/'.$args{'arch'}.'/'.$args{'host'};
	}
	return $logdir;
}

sub is_ltp # testcase 
{	
	# list can be obtained e.g. rpm -ql ltp-ctcs2-glue | grep tcf | sed 's,.*/\(.*\)\.tcf$,\1,' | grep -v '/tcf' | perl -ne 'chomp ; print ; print "|"'; echo
	return $_[0] =~ /^(admin_tools|ballista|can|cap_bounds|commands|connectors|containers|controllers|cpuacct|cpuhotplug|crashme|dio|fcntl-locktests|filecaps|fs|fs_bind|fs_ext4|fs_perms_simple|fs_readonly|fsx|hugetlb|hyperthreading|ima|io|io_cd|io_floppy|ipc|ipv6|ipv6_expect|ipv6_lib|ipv6_noexpect|ltp-aio-stress.part1|ltp-aio-stress.part2|ltp-aiodio.part1|ltp-aiodio.part2|ltp-aiodio.part3|ltp-aiodio.part4|ltplite|lvm.part1|lvm.part2|math|mm|modules|multicast|network_commands|network_stress.appl|network_stress.broken_ip|network_stress.icmp|network_stress.interface|network_stress.multicast|network_stress.route|network_stress.selected|network_stress.tcp|network_stress.udp|network_stress.whole|nfs|nptl|numa|nw_under_ns|openposix|p9auth|perfcounters|pipes|power_management_tests|power_management_tests_exclusive|pty|quickhit|rpc|rpctirpc|sched|scsi_debug.part1|sctp|selinux|smack|stress.part1|stress.part2|stress.part3|syscalls|tcore|tcp_cmds|tcp_cmds_addition|tcp_cmds_expect|tcp_cmds_noexpect|test_dma_thread_diotest7|timers|tirpc|tpm_tools)(-\d{1,4})*$/;	
}

sub scp	# srcdir, destdir
{
	my( $srcdir, $destdir)=@_;

	my $hostname = $qaconf{log_archive_host};
	my $login = $qaconf{log_archive_login};
	$destdir = $qaconf{log_archive_root_path}.'/'.$destdir;

	chomp $destdir;
	my $ret1=system("ssh $login\@$hostname mkdir -p $destdir");
	&log(LOG_ERR,"Creating remote log directory '$destdir' failed with $ret1") if $ret1;
	my $ret2=system("scp -".($log::loglevel<6 ? 'q':'')."r \"$srcdir\" $login\@$hostname:$destdir/");
	&log(LOG_ERR,"Storing the results '$srcdir'=>'$destdir' failed with $ret2") if $ret2;

	# Create backward compatibility links for maintenance kernel logs - see bnc#632337
	my $ret3 = 0;
	my $ret4 = 0;
	if ( $destdir =~ /\/Maintenance\/Kernel\// )
	{
		my @parts = split /\//, $srcdir;
		my $name = $parts[-1];
		$ret3 = system("ssh $login\@$hostname '[ -e $destdir/ltp ] || ln -sf . $destdir/ltp'") if is_ltp($name);
		for my $suite qw(reaim newburn) {
			$ret4 += system("ssh $login\@$hostname '[ -e $destdir/$suite ] || ln -sf $name $destdir/$suite'") if $name =~ /^$suite(-\d{1,4})*$/;
		}
	}

	return $ret1+$ret2+$ret3+$ret4;
}

sub mail # $from, $to, $cc, $subject, $text
{
	my ($from,$to,$cc,$subject,$text)=@_;

	($to, $cc) = ($cc, '') unless $to; # No primary reviewer defined

	if ($to) {
		return !system("echo -e \"$text\" | mail -s \"$subject\" -c \"$cc\" -r \"$from\" $to");
	} else {
		&log(LOG_NOTICE,"No mail sent since both To and CC are empty.");
		return 1;
	}
}


# Splits a product-release text into its two parts.
# One arg:		e.g. SLES-9-SP3-beta2
# Result value:		2-element list: e.g. "SLES-9-SP3", "beta2"
#
sub set_product_release {
	# That way?
	my $pr_n_r=$_[0];
	my $lasthyphen=rindex $pr_n_r,"-";
	return ($pr_n_r,'') if $lasthyphen==-1;
	return ((substr $pr_n_r,0,$lasthyphen),(substr $pr_n_r,$lasthyphen+1));
}


# Removes key/val pairs having duplicite keys
#
# Arguments:
#	@_: (key1,val1,key2,val2....)
# Return value: subset of @_ with unique keys
#
sub remove_duplicite_keyvals
{
    my %oldkeys=();
    my @ret=();
    my ($key,$val);
    while( ($key,$val) = splice(@_,0,2) )
    {
        next if $oldkeys{$key};
        push @ret,$key,$val;
        $oldkeys{$key}=1;
    }
    return @ret;
}

# returns (testsuite, testdate)
sub process_dirname # basename of the dir
{
	my ($testsuite,$testdate);
	$testsuite=$_[0];
	$testsuite =~ s/-(2\d\d\d-\d\d-\d\d-\d\d-\d\d-\d\d)$//;
	if( $1 )
	{
		$testdate=$1;
		$testdate = ( $testdate =~ /([12]\d{3})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2})/ ? "$1-$2-$3 $4:$5:$6" : undef ) if $testdate
	}
	return ($testsuite,$testdate);
}

1;

