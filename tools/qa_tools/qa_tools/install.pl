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
use qaconfig;

require "install_functions.pl";


our (%opts,$source,$ay_xml,$profile_url_base);
$Getopt::Std::STANDARD_HELP_VERSION=1;
getopts('p:f:s:o:O:u:r:t:S:R:C:z:b:V:P:UDB',\%opts);
if (defined $opts{'p'} and length $opts{'p'} > 3) {
	$source = $opts{'p'}; 
} else { 
	die "Usage: ./install.pl -p <Install repo>\n" .
		"					[ -f <fs type for root> ]\n" .
		"					[ -s <SDK repo> ]\n" .
		"					[ -o <Install options> ]\n" .
		"					[ -O <opensuse-update> ]\n" .
		"					[ -u <User profile> ]\n" .
		"					[ -r <Additional RPMS> ]\n" .
		"					[ -t <Additional patterns> ]\n" .
		"					[ -S <SMT service URL> (e.g. https://IPADDRESS/center/regsvc) ] #Install OS updates using SMT\n" .
		"					[ -R <Email Address> ] #Install OS updates using NCC credentials\n" .
		"					[ -C <Registration Code> ] #Install OS updates using NCC credentials\n" .
		"					[ -z <root_partition> (where to install root system) ]\n" .
		"					[ -b <MBR|root> (where to install bootloader) ]\n" .
		"					[ -V <xen|kvm> ] #Virtualization Host Type\n" .
		"					[ -P <root partition size> ] # Repartition entire disk\n".
		"					[ -U # Configure the system to upgrade\n". 
		"					[ -B # Configure the system network interface to bridge\n".
		"					[ -D # Configure the system to run desktop tests\n";
}

our $installoptions = $opts{'o'};
our $additionalrpms = $opts{'r'};
our $patterns = $opts{'t'} ? $opts{'t'} : '';
our $url_addon = $opts{'s'};
our $userprofile = $opts{'u'};
our $rootfstype = $opts{'f'} ? $opts{'f'} : 'ext3';
our $defaultboot = $opts{'b'} ? $opts{'b'} : '';
our $setupfordesktoptest = defined $opts{'D'};
our $setup_bridge = defined $opts{'B'};
our $repartitiondisk = $opts{'P'};
our $root_pt = $opts{'z'};

### Update options ###
our $smt_server = $opts{'S'};
our $ncc_email = $opts{'R'};
our $ncc_code = $opts{'C'};
our $opensuse_update = $opts{'O'};

### Virt-Host option ###
our $virtHostType = $opts{'V'};

die "Virtualization host type must be either xen or kvm" if defined $virtHostType and $virtHostType !~ /^xen|kvm$/;
if( ($smt_server and $ncc_email and $ncc_code) or ($ncc_email and !$ncc_code) or (!$ncc_email and $ncc_code) ) {
	die "You must specify an SMT update (-S) *or* NCC (-R *and* -C)\n";
}
our $install_update = ($smt_server or ($ncc_email and $ncc_code));
our $tooldir = '/usr/share/qa/tools';
our $profiledir = '/usr/share/qa/profiles';
our $mountpoint = '/mnt';
our $hostname = `hostname`;
chomp $hostname;
our $domainname=`domainname`;
chomp $domainname;
$domainname = 'site' if ($domainname eq '');

$ENV{'LC_ALL'}='en_US';

# from_type: opensuse|sles
# from_version: \d+
# from_subversion (i.e. SP number in SLES): \d+
our $arch;
my ($from_type, $from_version, $from_subversion, $from_release, $from_product);
($from_type, $from_version, $from_subversion, $from_release, $arch, $from_product) = &detect_product;

if ( $userprofile ) {
	$ay_xml = $userprofile;
} else {
# location: cz|de|cn|us
	my $location = &get_location or die "Unknown location";
	print "Location: $location\n";

	die "Cannot identify current distro" unless $from_type and $from_version;
	$from_subversion = 0 unless $from_subversion;
	print "Distro:\n", &stats( $from_type, $from_version, $from_subversion, $arch );

	# to_type: opensuse|sles|sled|slert|slepos
	my ($to_type, $to_version, $to_subversion, $to_arch) = &parse_source_url( $source ) or die "Cannot understand your URL";
	if ( $to_arch =~ /^i[3456]86$/ ) {
		$to_arch = ($to_version>10 ? 'i586' : 'i386');
	}
	print "Reinstalling to:\n", &stats( $to_type, $to_version, $to_subversion, $to_arch );

	#Location deteted. Define SDK source and autoinstall profile location
	&command( 'mount '.$qaconf{install_profile_nfs_server}.":".$qaconf{install_profile_nfs_dir}." $mountpoint -o nolock" );

	my $to_libsata = &has_libsata( $to_type, $to_version, $to_subversion, $to_arch );
	my $packages = &get_packages( $to_type, $to_version, $to_subversion, $to_arch, $additionalrpms, $patterns, $setupfordesktoptest);
	my $profile = &get_profile( $to_type, $to_version, $to_subversion );
	
	my $modfile;
	if ( defined($virtHostType) and $virtHostType ne "" ) {
		$modfile = &make_modfile( $source, $url_addon, $to_type, $to_version, $to_subversion, $to_libsata, $patterns, $packages, $defaultboot, $install_update, $virtHostType, undef);
	} else {
		$modfile = &make_modfile( $source, $url_addon, $to_type, $to_version, $to_subversion, $to_libsata, $patterns, $packages, $defaultboot, $install_update, undef, undef);
	}

	$ay_xml = &install_profile( $profile, $modfile );
	&command( "umount $mountpoint" );
}

my $aytool = "";
if ($arch eq 'ia64') {
	$aytool = "setupIA64liloforinstall";
} elsif ($arch eq 'ppc64' or $arch eq 'ppc') {
	$aytool = "setupPPCliloforinstall";
} else {
	$aytool = "setupgrubforinstall";
}

my $cmdline = "$tooldir/$aytool $source ";
$cmdline .= "autoupgrade=1 " if ($opts{'U'});
$cmdline .= "autoyast=$ay_xml install=$source";
$cmdline .= " $installoptions" if defined $installoptions;
&command($cmdline);
&command( "sleep 2" );
&command( "reboot" );
exit -1;


