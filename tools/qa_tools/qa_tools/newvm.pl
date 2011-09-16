#!/usr/bin/perl -w

BEGIN {
# extend the include path to get our modules found
	push @INC,"/usr/share/qa/lib",'.';
}

use detect;
use strict;
use warnings;
use Getopt::Std;
use qaconfig;

our (%opts,$source,$ay_xml,$profile_url_base);
$Getopt::Std::STANDARD_HELP_VERSION=1;
getopts('p:s:o:u:r:t:c:m:M:d:DT:V:S:R:C:x',\%opts);

if (defined $opts{'p'} and length $opts{'p'} > 3 and defined $opts{'V'} and $opts{'V'} =~ /^pv|fv$/)
     { $source = $opts{'p'}; }
else { die "Usage: ./newvm.pl -p <Install repo> -V <para|full>\n" .
           "                    [ -s <SDK repo> ]\n" .
           "                    [ -o <Install options> ]\n" .
           "                    [ -u <User profile> ]\n" .
           "                    [ -r <Additional RPMS> ]\n" .
           "                    [ -t <Additional patterns> ]\n" .
           "                    [ -c <Virtual CPU count> ]\n" .
           "                    [ -m <Virtual machine initial memory> ]\n" .
           "                    [ -M <Virtual machine maximum memory> ]\n" .
           "                    [ -d <Virtual disks size> ]\n" .
           "                    [ -T <Virtual disk type> ]\n" .
           "                    [ -S <SMT service URL> (e.g. https://IPADDRESS/center/regsvc) ] #Install OS updates using SMT\n" .
           "                    [ -R <Email Address> ] #Install OS updates using NCC credentials\n" .
           "                    [ -C <Registration Code> ] #Install OS updates using NCC credentials\n" .
           "                    [ -D # Configure the system to run desktop tests\n"; }
our $url_sdk = $opts{'s'};
our $installoptions = $opts{'o'};
our $userprofile = $opts{'u'};
our $additionalrpms = $opts{'r'};
our $additionalpatterns = $opts{'t'};
our $defaultboot = undef;
our $setupfordesktoptest = defined $opts{'D'};
our $virttype = $opts{'V'};
our $virtdisksize = $opts{'d'};
our $virtdisktype = $opts{'T'};
our $initmem = $opts{'m'};
our $maxmem = $opts{'M'};
our $virtcpu = $opts{'c'};

### Update options ###
our $smt_server = $opts{'S'};
our $ncc_email = $opts{'R'};
our $ncc_code = $opts{'C'};

require "install_functions.pl";

if(($smt_server and $ncc_email and $ncc_code) or ($ncc_email and !$ncc_code) or (!$ncc_email and $ncc_code))
{
	die "You must specify an SMT update (-S) *or* NCC (-R *and* -C)\n";
}
our $install_update = ($smt_server or ($ncc_email and $ncc_code));
our $tooldir = '/usr/share/qa/tools';
our $profiledir = '/usr/share/qa/profiles';
our $mountpoint = '/mnt';

### FIXME
### simpy add nis server list here, this server list should be detected automatically from 
### DHCP answer 
our @nis_server_list = ("149.44.160.146","10.10.0.1","149.44.160.1");
$ENV{'LC_ALL'}='en_US';

# from_type: opensuse|sles
# from_version: \d+
# from_subversion (i.e. SP number in SLES): \d+
#my ($from_type, $from_version, $from_subversion, $from_release, $arch, $from_product) = &detect_product;

# this must be parsed for custom profile as well (need the info for vm-install)
my ($to_type, $to_version, $to_subversion, $to_arch) = &parse_source_url( $source ) or die "Cannot understand your URL";

if ( $userprofile ){
    $ay_xml = $userprofile;
} else {
# location: cz|de|cn|us
    my $location = &get_location or die "Unknown location (Prague|Nuernberg|Beijing|Provo)";
    print "Location: $location\n";

#    die "Cannot identify current distro" unless $from_type and $from_version;
#    $from_subversion = 0 unless $from_subversion;
#    print "Distro:\n", &stats( $from_type, $from_version, $from_subversion, $arch );

# to_type: opensuse|sles|sled|slert|slepos
    if ( $to_arch =~ /^i[3456]86$/ )
    { $to_arch = 'i386'; $to_arch = 'i586' if $to_version eq '11'; }
    print "Installing to:\n", &stats( $to_type, $to_version, $to_subversion, $to_arch );

#Location deteted. Define SDK source and autoinstall profile location
    if( $location eq 'cz' or $location eq 'de' or $location eq 'us' )
    { $profile_url_base = 'http://10.20.1.229/autoinst';
        `mount 10.20.1.229:/srv/hamsta $mountpoint -o nolock;`
    }
    elsif( $location eq 'cn' )
    { $profile_url_base = 'http://147.2.207.242/autoinst';
        `mount 147.2.207.242:/mirror_a $mountpoint -o nolock;`
    }
    
    my $to_libsata = undef;&has_libsata( $to_type, $to_version, $to_subversion, $to_arch );
    my $patterns = &get_patterns( $to_type, $to_version, $to_subversion );
    my $packages = &get_packages( $to_type, $to_version, $to_subversion, $additionalrpms, $patterns, $setupfordesktoptest );
    my $profile = &get_profile( $to_type, $to_version, $to_subversion );
    my $modfile = &make_modfile( $source, $url_sdk, $to_type, $to_version, $to_subversion, $to_libsata, $patterns, $packages, $defaultboot, $install_update, undef, $virttype);
    $ay_xml = &install_profile_newvm( $profile, $modfile );
    &command( "umount $mountpoint" );
}
print "***\nResult profile is $ay_xml\n***\n";
my $aytool = "/usr/share/qa/virtautolib/lib/vm-install.sh";
#if ($to_arch eq 'ia64') {
#    $aytool = "setupIA64liloforinstall";
#} elsif ($to_arch eq 'ppc64' or $to_arch eq 'ppc') {
#    $aytool = "setupPPCliloforinstall";
#} else {
#    $aytool = "setupgrubforinstall";
#}
my $os = $to_type =~ /^opensuse$/ ? 'os' : $to_type;
my $os_ver = $to_version;
my $os_sp = $to_subversion == 0 ? 'fsc' : "sp$to_subversion";
my $os_arch = $to_arch =~ /^i[3456]86$/ ? 32 : 64;

my $cmdline="$aytool -A $ay_xml -f $source -o $os -r $os_ver -p $os_sp -c $os_arch -t $virttype -g";
$cmdline .= " -O '$installoptions'" if defined $installoptions;
$cmdline .= " -s $virtcpu" if defined $virtcpu;
$cmdline .= " -e $initmem" if defined $initmem;
$cmdline .= " -x $maxmem" if defined $maxmem;
$cmdline .= " -d $virtdisksize" if defined $virtdisksize;
$cmdline .= " -D $virtdisktype" if defined $virtdisktype;
print $cmdline . "\n";
my $ret = system($cmdline);

# this will let hamsta know that it should regenerate the list it sends in description
# FIXME UGLY UGLY UGLY
system ("rm -f /tmp/hamsta_virtual_machines");
exit $ret;
