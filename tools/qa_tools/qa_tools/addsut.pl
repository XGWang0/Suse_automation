#!/usr/bin/perl -w
my $master_ip = shift;
my $master_net = shift;
my $pre_repo = shift;

my $conn_type = 'multicast';
my %repos = (
		"SLE_10_SP1" => "SLE_10_SP1_Head",
		"SLE_10_SP2" => "SLE_10_SP2_Head",
		"SLE_10_SP3" => "SLE_10_SP3",
		"SLE_10_SP4" => "SLE_10_SP4",
		"SLE_10_SP4_Update" => "SLE_10_SP4_Update",
		"SLE_11_SP1_Update" => "SLE_11_SP1_Update",
		"SLE_Factory" => "SLE_Factory",
		"Factory_Head" => "SUSE_Factory_Head",
		"SLE_11_SP1" => "SUSE_SLE-11-SP1_GA",
		"SLE_11_SP2" => "SUSE_SLE-11-SP2_GA",
		"SLE_11_SP3" => "SUSE_SLE-11-SP3_GA",
		"SLE_11" => "SUSE_SLE-11_GA",
		"SLE_11_Update" => "SUSE_SLE-11_Update",
		"openSUSE_11.4" => "openSUSE_11.4",
		"openSUSE_12.1" => "openSUSE_12.1",
		"openSUSE_12.2" => "openSUSE_12.2",
		"openSUSE_12.3" => "openSUSE_12.3",
		"openSUSE_Factory" => "openSUSE_Factory");

my $mycmd = "grep -qi openSUSE /etc/issue";
my $ret = system($mycmd);
my $repo;
my $OSVer;
my $PVer;
if ($ret != 0) { #SLE
	$repo = "SLE_";
	$mycmd = "grep -i VERSION /etc/SuSE-release | sed -e \'s/[A-Za-z =]//g\'";
	$OSVer = `$mycmd`;
	if ( $OSVer == "" ) {
		print "Can not get $repo OS version!";
		exit 256;
	}
	chomp($OSVer);
	$mycmd = "grep PATCHLEVEL /etc/SuSE-release | sed -e \'s/[A-Za-z= ]//g\'";	
	$PVer = `$mycmd`;
	if ($? == 0) { # OS like: SLE_11_SP2 etc
		chomp($PVer);
		$repo .= $OSVer . "_SP" . $PVer;
	} else {
		$repo .= $OSVer;
	}
} else {
	$repo = "openSUSE_";
	$mycmd = "cat /etc/SuSE-release | grep -i VERSION | sed -e \'s/[A-Za-z =]//g\'";
	$OSVer = readpipe($mycmd);
	chomp($OSVer);
	if ( $OSVer == "" ) {
               print "Can not get $repo OS version!";
               exit 256;
        }
	$repo .= $OSVer;
}
my $repo_url = $pre_repo . "/" . $repos{$repo} . "/";
$mycmd = "zypper --no-gpg-checks -n ar $repo_url hamsta 1>/dev/null";
$ret = system($mycmd);
if ($ret != 0) {
	print "Cannot add hamsta repo as $repo_url to SUT.";
	exit 256;
}
$mycmd = "zypper --no-gpg-checks --gpg-auto-import-keys in -y qa_hamsta 1>/dev/null";
$ret = system($mycmd);
if ($ret != 0) {
	print "qa_hamsta cannot be added to SUT.";
	exit 256;
}
$mycmd = "/usr/share/qa/tools/get_net_addr.pl";
$sut_net_addr = `$mycmd`;
if ( $sut_net_addr == "" ) {
	print "Can not get sut_net_addr.";
	exit 256;
}
`echo $sut_net_addr $master_net >/tmp/jhao.log`;
if ( $sut_net_addr ne $master_net ) {
	$mycmd = "sed -i s/hamsta_multicast_address=\\\'239.192.10.10\\\'/hamsta_multicast_address=\\\'$master_ip\\\'/ /etc/qa/00-hamsta-common-default";
	system($mycmd);
	$conn_type = 'unicast';
	$ret = system("grep -q \'$master_ip\' /etc/qa/00-hamsta-common-default");
	if ($ret != 0) {
		print "config unicast failed.";
		exit 256;
	}
}
$mycmd = "rchamsta start >/dev/null";
$ret = system($mycmd);
if ($ret != 0) {
	print "Cannot start hamsta service on SUT.";
	exit 256;
}
print $conn_type;
