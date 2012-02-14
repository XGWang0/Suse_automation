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
#


BEGIN {
# extend the include path to get our modules found
	push @INC,"/usr/share/qa/lib",'.';
}

use detect;
use strict;
use warnings;
use Getopt::Std;
use Getopt::Long qw(:config no_ignore_case);
use qaconfig;
use install_functions;

$ENV{'LC_ALL'}='en_US';

# default values
our $args={
	rootfstype=>'ext3',
	defaultboot=>'',
	setupfordesktoptest=>'',
};

$args->{'newvm'} = ( $0 =~ /newvm(?:\.\w*)?$/ );
our $name = `basename $0`;
chomp $name;
# [ [ cmdline_letter, ID, parameter_desc, option_desc, manpage_desc ] ]; option takes parameter if there is a parameter_desc
our $options = [
	### Common options
	['p','source','URL','Primary installation repository URL, mandatory','This is the primary product repository to install on the machine. Currently, HTTP and FTP protocols are supported.'],
	['f','rootfstype','fstype','Root filesystem type, e.g ext3, xfs, reiserfs..',"Use the format of \n.BR mkfs (8)\n"],
	['s','url_addon','URLs','Addon / SDK repo URL(s)','Comma separated list of additional install repository URLs. Use for SDK, addons etc.'],
	['o','installoptions','options','Additional installer options', 'Can be used to fine-tune installation options, start a VNC/SSH install etc.'],
	['u','userprofile','path','Path to own AutoYaST profile',"Here you can enter your own profile, e.g. the one from system clone. In that case, it will be passed directly to the installer, most of the autodetection will be skipped, and most of the other options ignored; only install repo (-p) and installer options (-o) will be used."],
	['r','additionalrpms','RPMs','Additional RPMs','Comma separated list of additional RPMs to install.'],
	['t','patterns','patterns','Software patterns',"Comma separated list of patterns to install. When empty, a default based on the product will be used. When started with a '+', it will be merged to the product default."],
	['P','repartitiondisk','1..100','Repartition entire disk, use so many percent of it','When you specify a number between 1-100 here, all partitions will be deleted, then root, swap, /abuild and /boot (if existing) will be recreated. These four partitions together should use the given percentage of the disk size. In the rest of the disk, you can create new partitions for testing.'],
	['B','setup_bridge','','Configure the system network interface to bridge','Create a bridging pseudo-device associated with primary ethernet adapter. Happens automatically for virtualization hosts.'],
	['D','setupfordesktoptest','','Configure the system to run desktop tests','Prepares for automated desktop testing. Turns off desktop access control for X, adds accessibility features, plus more.'],
	['?','help','','Print help message',''],
	['N','manual','','Generate manual page','Used to generate this manual page and keep it up-to-date.'],

	### Update options ###
	['O','opensuse_update','','Add OpenSuSE update repository',"Similar to '-s', but you don't have to type in the URL, it will be generated."],
	['S','smt_server','SMT URL','e.g. https://IPADDRESS/center/regsvc, URL for OS updates using SMT',''],
	['R','ncc_email','mail address','Install OS updates using NCC credentials',''],
	['C','ncc_code','NCC code','Install OS updates using NCC credentials',''],
];

push @$options, (
	### reinstall-only:
	['U', 'upgrade','','Configure the system to upgrade','Does a system upgrade, instead of reinstalling.'],
	['z','root_pt','root partition','Where to install root system','By default, current root partition is used. This options allows to specify another partition.'],
	['b','defaultboot','MBR|root','Where to install bootloader',"If omitted, bootloader is installed into root partition. If set to 'root', it also sets the partition's 'active' flag in the partition table. If set to 'MBR', bootloader is installed into MBR (and the partition is marked 'active' as well)."],
	['V','virthosttype','xen|kvm','Virtualization Host Type',"Put here 'xen' or 'kvm' to install a virtualization host, or omit the flag to have a normal system."],
) unless $args->{'newvm'};

push @$options, (
	### Virt-Host option ###
	['V','virttype','pv|fv','Virtualization Guest Type',"Put here 'para' for paravirtualized guest, or 'full' for fully virtualized guest. Default is 'full'."],
	['c','virtcpu','CPUs','Virtual CPU count',"Number of virtual CPUs available to the virtual guest."],
	['m','initmem','memsize','Initial memory size of virtual machine, in megabytes',"The virtual guest is required to receive this amount of RAM at start, and can get up to 'maxmem' later."],
	['M','maxmem','memsize','Maximal memory size of virtual machine, in megabytes','If RAM available, the machine can receive up to this amount of memory.'],
	['d','virtdisksize','disksize','VM disk size, in megabytes',""],
	['T','virtdisktype','type', 'VM disk type: file | iscsi | nbd | npiv | phy | tap:aio | tap:qcow | tap:qcow2 | vmdk',''],
) if $args->{'newvm'};

&read_cmdline();
&validate_cmdline();
&set_common_args();

sub read_cmdline
{
	# argument format for Getopt::Long
	my @args = map { $_->[1].'|'.$_->[0].($_->[2] ? ':s' : '!') } @$options;
	GetOptions($args, @args);
	&print_help() if $args->{'help'};
	&print_man() if $args->{'manual'};

	# let's accept source without '-p' prefix
	$args->{'source'} = $ARGV[0] if @ARGV and !$args->{'source'};
}

sub validate_cmdline
{
	# validate source
	&print_help() if !$args->{'source'} or length($args->{'source'})<=3;

	# validate virtualization
	die "Virtualization host type must be either xen or kvm" if defined $args->{'virthosttype'} and $args->{'virthosttype'} !~ /^xen|kvm$/;
	&print_help() if $args->{'newvm'} and ( !defined $args->{'virttype'} or $args->{'virttype'}!~/^(?:pv|fv)$/ );

	# validate SMT / NCC
	if( ($args->{'smt_server'} and $args->{'ncc_email'} and $args->{'ncc_code'}) or ($args->{'ncc_email'} xor $args->{'ncc_code'}) ) {
		die "You must specify an SMT update (-S) *or* NCC (-R *and* -C)\n";
	}

}

our ($tooldir,$profiledir,$mountpoint);
sub set_common_args
{
	# to_type, to_version, to_subversion, to_arch
	my $to = &parse_source_url( $args->{'source'} ) or die "Cannot understand your URL";
	if ( $to->{'arch'} =~ /^i[3456]86$/ ) {
		$to->{'arch'} = ($to->{'version'}>10 ? 'i586' : 'i386');
	}
	map { $args->{"to_$_"}=$to->{$_} } keys %{$to};

	# from_type, from_version, from_subversion, from_type
	my $from = &detect_product();
	if ( $from->{'arch'} =~ /^i[3456]86$/ ) {
		$from->{'arch'} = ($from->{'version'}>10 ? 'i586' : 'i386');
	}
	map { $args->{"from_$_"}=$from->{$_} } keys %{$from};

	# print info
	printf "Target product:\n";
	print "  type\t\t$args->{'to_type'}\n  version\t$args->{'to_version'}\n";
	print "  subversion\t$args->{'to_subversion'}\n";
	print "  arch\t\t$args->{'to_arch'}\n" if $args->{'to_arch'};

	# update repo
	$args->{'install_update'} = ($args->{'smt_server'} or ($args->{'ncc_email'} and $args->{'ncc_code'}));

	# directories
	our $tooldir = '/usr/share/qa/tools';
	our $profiledir = '/usr/share/qa/profiles';
	our $mountpoint = '/mnt';

	# hostname / domainname
	$args->{'hostname'} = `hostname`;
	chomp $args->{'hostname'};
	$args->{'domainname'}=`domainname`;
	chomp $args->{'domainname'};
	$args->{'domainname'} = 'site' if ($args->{'domainname'} eq '');

}

sub print_help
{
	print STDERR "Usage: $name [options] [-p]<source URL>";
	print STDERR " -V<pv|fv>" if $args->{'newvm'};
	print STDERR "\n";
	foreach my $o (@$options)	{
		my $left=sprintf("[ -%s | --%s%s ]",$o->[0],$o->[1],($o->[2] ? ' <'.$o->[2].'>' : ''));
		my $pad = "\t"x(5-int((length($left))/8));
		print STDERR "\t" . $left . $pad . $o->[3] . "\n";
	}
	exit 0;
}

sub print_man
{
	print ".\\\" Process this file with\n.\\\" groff -man -Tascii $name.8\n.\\\"\n";
	print ".TH \"$name\" \"8\"\n";
	if( $args->{'newvm'} )	{
		print ".SH NAME\n$name \- tries to install a new virtual guest\n\n";
	} else {
		print ".SH NAME\n$name \- tries to reinstall the current machine using \n";
		print ".BR grub (8)\n,\n.B AutoYaST\n, and \n.BR setupgrubforinstall (8)\n\n";
	}
	print ".SH USAGE\n.B $name \n.B ";
	foreach my $o (@$options)	{
		print '[-'.$o->[0];
		print " \n.I <".$o->[2].">\n.B " if $o->[2];
		print '] ';
	}
	unless( $args->{'newvm'} )	{
		print <<EOF;

.SH DESCRIPTION
.B $name
does following actions:

(1) analyzes the system to find out partitions, IP address, location etc.

(2) creates an AutoYaST reinstall profile and stores it to a NFS share

(3) using
.BR setupgrubforinstall (8)
, sets up the system to boot from the CML source using the prepared profile

(4) reboots, causing the reinstallation to start.

Every product has different syntax of the AutoYaST config files.
And every product has different bugs.
For this reason, the script has different base AutoYaST script for different products, the functions select different patterns and packages, and so on.
You will probably need to customize this script for newer products.

.SH OPTIONS

EOF
	}
	foreach my $o (@$options)	{
		printf ".IP \"\\fB-%s\\fR, \\fB--%s",$o->[0],$o->[1];
		print ' <'.$o->[2].'>' if $o->[2];
		print "\"\n";
		print $o->[3].". " if $o->[3];
		print $o->[4]."\n";
	}
	print <<EOF;

.SH BUGS
Multiple, we try to fix those you report them.

If you encounter a problem, it may be a bug in AutoYaST instead.

.SH AUTHOR
Vilem Marsik and the rest of the QA-Automation team

.SH "SEE ALSO"
.BR reinstall.pl (1)
.BR newvm.pl (1)
.BR setupgrubforinstall (8)
.BR grub (8)
.BR modify_xml.pl (1)
EOF
	exit 0;
}

our ($ay_xml,$aytool);

if ( $args->{'userprofile'} ) {
	$ay_xml = $args->{'userprofile'};
} else {
	&command( 'mount '.$qaconf{install_profile_nfs_server}.":".$qaconf{install_profile_nfs_dir}." $mountpoint -o nolock" );

	my $profile = &get_profile( $args, $profiledir );
	
	my $modfile = &make_modfile( $args );

	$ay_xml = 'autoinst_'.$args->{'hostname'} . ($args->{'newvm'} ? "_vm_$$" : '') . '.xml';
	&command( "$tooldir/modify_xml.pl -m '$modfile' '$profile' '$mountpoint/autoinst/$ay_xml'" );
	$ay_xml = $qaconf{'install_profile_url_base'} . '/' . $ay_xml;

	&command( "umount $mountpoint" );
}
print "***\nResult profile is $ay_xml\n***\n";

# setup tool
if( $args->{'newvm'} )	{
	$aytool = "/usr/share/qa/virtautolib/lib/vm-install.sh";
} elsif ($args->{'from_arch'} eq 'ia64') {
	$aytool = $tooldir."/setupIA64liloforinstall";
} elsif ($args->{'from_arch'} eq 'ppc64' or $args->{'from_arch'} eq 'ppc') {
	$aytool = $tooldir."/setupPPCliloforinstall";
} else {
	$aytool = $tooldir."/setupgrubforinstall";
}

# install new VM
if( $args->{'newvm'} )	{
	my $os = $args->{'to_type'} =~ /^opensuse$/ ? 'os' : $args->{'to_type'};
	my $os_ver = $args->{'to_version'};
	my $os_sp = $args->{'to_subversion'} == 0 ? 'fsc' : "sp".$args->{'to_subversion'};
	my $os_arch = $args->{'to_arch'} =~ /^i[3456]86$/ ? 32 : 64;

	my $cmdline="$aytool -A $ay_xml -f $args->{'source'} -o $os -r $os_ver -p $os_sp -c $os_arch -t $args->{'virttype'} -g";
	$cmdline .= " -O '".$args->{'installoptions'}."'" if defined $args->{'installoptions'};
	$cmdline .= " -s ".$args->{'virtcpu'} if defined $args->{'virtcpu'};
	$cmdline .= " -e ".$args->{'initmem'} if defined $args->{'initmem'};
	$cmdline .= " -x ".$args->{'maxmem'} if defined $args->{'maxmem'};
	$cmdline .= " -d ".$args->{'virtdisksize'} if defined $args->{'virtdisksize'};
	$cmdline .= " -D ".$args->{'virtdisktype'} if defined $args->{'virtdisktype'};
	print $cmdline . "\n";
	my $ret = system("$cmdline");
	$ret = $ret >> 8;
# this will let hamsta know that it should increase stats version -> master will then query 
# this host for changes
	system ("touch /var/lib/hamsta/stats_changed");
	exit $ret;
}
# reinstall / upgrade
else {
	my $cmdline = "$aytool ".$args->{'source'}.' ';
	$cmdline .= "autoupgrade=1 " if $args->{'upgrade'};
	$cmdline .= "autoyast=$ay_xml install=".$args->{'source'};
	$cmdline .= ' '.$args->{'installoptions'} if defined $args->{'installoptions'};
	&command($cmdline);
	&command( "sleep 2" );
	&command( "reboot" );
	exit -1;
}

