#!/usr/bin/perl -w

BEGIN {
# extend the include path to get our modules found
push @INC,"/usr/share/qa/lib",'.';
}

use strict;
use POSIX qw /strftime/;
use detect;
use log;
use qaconfig;

$log::loginfo='remote_qa_db_report';
&log_set_output(handle=>*STDOUT);
my $dir='/var/log/qa';
if ( defined($ENV{TESTS_LOGDIR}) ) {
	$dir = "$ENV{TESTS_LOGDIR}";
	&log (LOG_INFO, "INFO: Variable TESTS_LOGDIR is set, logs will be read from $dir.\n");
} elsif ( $> != 0) { # $> is effective UID - so if not run by root
	$dir = "$ENV{HOME}/var-log-qa";
	&log(LOG_INFO, "Not running as root, logs will be read from $dir.\n");
}

chomp(my $time=`date '+%F-%H-%M-%S'`);

my $host='';
my $arch = '';
my $product = '';
my $kernel = '';

my $rbase="/tmp";
my $rhost=$qaconf{remote_qa_db_report_host};
my $ruser=$qaconf{remote_qa_db_report_user};
my $tcflist = undef;

my $nomove=0;
my $delete=0;
my $delete_all_dir=0;
$nomove=1 if (`ls $dir | wc -l` < 1);
my $interactive=1; # AKA no batchmode
my $argf_index;
my $argP_index;

our $VERSION='0.1';
&check_version('remote_qa_db_report.pl',$VERSION);

sub usage
{
	print
"Usage: $0 [ -p PRODUCT] [-c <comment>] [-b] [-L] [-D] [-A] [-v <n>] [-a ARCH] [-f PATH] [-F TCF_LIST] [-P DIRECT_PATH_LIST]  [-k KERNEL] [-m TESTHOST] [-t TYPE] [-T TESTER]\n",
"       $0 -h\n",
"\n",
"Options and option values (options may be given in any order):\n",
"\n",
"	-h	print this help and exits\n",
"	-b	batch mode (not interactive at all)\n",
"	-c <comment>	submission comment, max. 100 chars, will be truncated when longer \n",
"	-v n	verbosity level (0-7, 5 is default, 3 only prints warnings+errors )\n",
"	-L	Omits moving the submitted logs from PATH to PATH/oldlogs/\n",
"	-R	Delete submitted logs from PATH (do not move to oldlogs)\n",
"	-D	No writing to the database\n",
"	-A	Do not scp the submitted data to the archive\n",
"\n",
"	PRODUCT:	e.g. SLES-10-beta1 | SLES-9-SP4-RC1\n",
"	ARCH:		QADB architecture, e.g. i586,ia64,x86_64,ppc,ppc64,s390x,xen0-*...\n",
"       		(default: detected arch of this host)\n",
"	KERNEL:		kernel version for KOTD tests\n",
"	PATH:		the directory containing results to submit\n",
"			If this argument is set, -P cannot be used.\n",
"       		(default: $dir)\n",
"	TCF_LIST:	comma-separated list of test-runs (subdirs) that should be processed.\n",
"			If not set, all test-runs are processed.\n",
"			If this argument is set, -P cannot be used.\n",
"			Example: -F 'ctcs2/qa_siege-2009-12-03-11-13-37,ctcs2/qa_siege-2009-12-03-12-21-12'\n",
"	DIRECT_PATH_LIST:	comma-separated list of parser:directory pairs. This allows specification of directories which\n",
"				contain individual testsuite results without the need to have them in typical results structure\n",
"				(dir/parser/testsuite-timestamp). The directory still MUST have a name in format testsuite-timestamp!\n",
"				If this argument is used, arguments -F and/or -f and/or -R cannot be used!\n",
"				This argument implies (automatically set) -L!\n",
"				Example: -P 'ctcs2:/home/lukas/qa_siege-2009-12-03-11-13-37,ctcs2:/var/log/qa/ctcs2/qa_siege-2009-12-03-12-21-12'\n",
"	TESTHOST:	hostname of system under test\n",
"			(default: hostname of this machine)\n",
"	TYPE:		kotd, patch:<md5sum>, product (default: product)\n",
"	TESTER:		login of the tester (default: hamsta-default)\n" ;
}

# process args
foreach my $i (0 .. @ARGV-1)
{	
	my $a=$ARGV[$i];
	if( $a eq '-f' )
	{	$argf_index=$i+1;	}
	elsif( $a eq '-a' )
	{	$arch=$ARGV[$i+1];	}
	elsif( $a eq '-k' )
	{	$kernel=$ARGV[$i+1];	}
	elsif( $a eq '-m' )
	{	$host=$ARGV[$i+1];	}
	elsif( $a eq '-b' )
	{	$interactive=0;		}
	elsif( $a eq '-L' )
	{	$nomove=1;		}
	elsif( $a eq '-R' )
	{	$delete=1; $nomove=1;	}
	elsif( $a eq '-F' )
	{	$tcflist=$ARGV[$i+1];		}
	elsif( $a eq '-p' )
	{	$product=$ARGV[$i+1];		}
	elsif( $a eq '-P' )
	{	$argP_index=$i+1; $nomove=1; }
	elsif( $a =~ /^--?(h|help|\?)$/ )
	{	&usage();	exit;	}
}

die "It is not possible to use -P and -[fFR] at the same time!\n" if $argP_index and ($argf_index or $tcflist or $delete);
if ($argP_index) {
	# prepare temp directory and set it as -f tmpdir -R, so the rest thinks it's normal
	die "DIRECT_PATH_LIST (-P) has a wrong format.\n" unless $ARGV[$argP_index] =~ /^[^:,]+:[^,]+(,[^:,]+:[^,]+)*$/;
	$dir = `mktemp -d`;
	chomp ($dir);

	for (split ',' , $ARGV[$argP_index]) {
		my ($parser, $path) = split ':';
		
		`mkdir -p "$dir/$parser" && cp -r "$path" "$dir/$parser"`;
	}

	# now process the newly created directory as if it was specified with -f path -R
	$ARGV[$argP_index-1] = '-f';
	$ARGV[$argP_index] = $dir;
	$argf_index = $argP_index;
	$delete_all_dir = 1;
}

# allow specify tcflist without <parser>/ prefix
$tcflist=join ',', map /.\/./ ? $_ : "*/".$_, split ',', $tcflist if $tcflist;

# detect local machine
if ($arch eq '') {
	$arch = &get_architecture();
	push @ARGV,'-a',$arch;
}

if ($host eq '') {
	chomp($host=`hostname`);
	push @ARGV,'-m',$host;
}

if ($product eq '') {
	my @p = &detect_product;
	$product = $p[5].'-'.$p[3];
	push @ARGV,'-p',$product;
}

if( $kernel eq '' )
{	push @ARGV, '-k', &get_kernel_version();	}

my $rfile="$host-$time.tar.bz2";

# process path argument
if($argf_index)
{
	$ARGV[$argf_index]=$dir unless $argf_index<@ARGV;
	$dir=$ARGV[$argf_index];
	
	#$ARGV[$argf_index-1]='-f';
	$ARGV[$argf_index]="$rbase/$rfile";
}
else
{	push @ARGV,'-f',"$rbase/$rfile";	}

unless ($nomove) {
	# There's no need to move - all remote submission has unique dir
	push @ARGV,'-L';
}

unless ($delete) {
	# There's no need to keep copy of logs on submit server
	push @ARGV,'-R';
}
	

#push @ARGV, '-f', `basename $dir`; #We have -X specified -> local path in archive

# pack info - create _REMOTE subdir with such infos
my $metadir="$dir/_REMOTE";
if ( -d $metadir ) {
	# if no other report is running -> it can be deleted
	system("ps -A | grep -q remote_qa_db_report || rm -fr $metadir");
}
mkdir $metadir or die "Unable to create directory '$metadir' for information transfer: $!\n"
						."It is possible that another submit is running. If you're sure it's not, "
						."delete directory and start again.\n";
&log(LOG_INFO,"Getting RPM info");
system('rpm -qa --qf "%{NAME} %{VERSION}-%{RELEASE}\n" | sort > "'.$metadir.'/rpmlist"');
&log(LOG_INFO,"Getting hwinfo");
system("/usr/sbin/hwinfo --all > '$metadir/hwinfo'");


#my ($type, $version, $subversion, $ar) = &parse_suse_release();
#print "type:$type version:$version subversion:$subversion arch:$arch\n";
#exit;
#my $data={ 'arch'=>$arch, 'host'=>$host, 'product'=>''}; # TODO: product


my $tmpfile="/tmp/$rfile";
my $base=`basename $dir`;
chdir $dir or die "Cannot chdir to $dir: $!";
if ($tcflist) {
	system "tar cf - ".(join ' ', map {(/ / ? '"'.$_.'"' : $_)} split(/,/, $tcflist))." | bzip2 -f > \"$tmpfile\"" and die "Cannot create archive.";
} else {
	system "ls | grep -v '^oldlogs\$' | xargs tar cf - | bzip2 -f > \"$tmpfile\"" and die "Cannot create archive.";
}
&log(LOG_INFO,"Copying files over network");
system "scp \"$tmpfile\" $ruser\@$rhost:$rbase/" and die "Cannot SCP";
unlink $tmpfile or warn "Cannot unlink $tmpfile : $!";

my $cmd="ssh $ruser\@$rhost /usr/share/qa/tools/qa_db_report.pl '".(join ' ',map {(/ / ? '"'.$_.'"' : $_)} @ARGV)."'";
&log(LOG_INFO,$cmd);
my $qadb_report_res=system ($cmd);

unlink "$metadir/hwinfo";
unlink "$metadir/rpmlist";
rmdir $metadir;

die "Cannot run $cmd" if $qadb_report_res;

# process logs - move to oldlogs/
# TODO: when using inotify, should move just after every submit of TCFs
my $oldlogs="$dir/oldlogs";
my $savedir="$oldlogs/" . strftime ("%F-%H-%M-%S", localtime);
unless( $nomove )
{
	mkdir $oldlogs unless -d $oldlogs;
	mkdir $savedir unless -d $savedir;
	if ( -d $savedir ) {
		if ($tcflist) {
			# format is parser/testsuite
			my $dirlist=join ' ', map {(/ / ? '"'.$_.'"' : $_)} split(/,/, $tcflist);
			`for i in $dirlist ; do [ "\$i" == "oldlogs" ] || ( mkdir -p "$savedir/\$(dirname "\$i")" && mv "\$i" "$savedir/\$(dirname "\$i")" ) ; done`;
		} else {
			# all parsers, no need create subdir, aleready have a right structure
			`for i in * ; do [ "\$i" == "oldlogs" ] || for j in "\$i"/* ; do mkdir -p "$savedir/\$i"; mv "\$j" "$savedir/\$i" ; done ; done`;
		}
	} else {
		&log(LOG_ERR,"Unable to move Logs to target: $savedir. Not moving logs to oldlogs.\n");
	} 
}

if($delete)
{
		if ($tcflist) {
			# format is parser/testsuite
			my $dirlist=join ' ', map {(/ / ? '"'.$_.'"' : $_)} split(/,/, $tcflist);
			`for i in $dirlist ; do rm -fr "\$i"; done`;
		} else {
			# all parsers, no need create subdir, aleready have a right structure
			`for i in * ; do [ "\$i" == "oldlogs" ] || for j in "\$i"/* ; do rm -fr "\$j"; done ; done`;
		}
}

`rm -fr "$dir"` if $delete_all_dir;	#only can happen if -P
