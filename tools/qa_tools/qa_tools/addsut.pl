#!/usr/bin/perl -w
my $master_ip = shift;
my $master_net = shift;
my $pre_repo = shift;

my $conn_type = 'multicast';

my $mycmd = "grep -qi openSUSE /etc/issue";
my $ret = system($mycmd);
my $repo;
my $OSVer;
my $PVer;
if ($ret != 0) { #SLE
	$repo = "SLE-";
	$mycmd = "grep -i VERSION /etc/SuSE-release | sed -e \'s/[A-Za-z =]//g\'";
	$OSVer = `$mycmd`;
	if ( $OSVer == "" ) {
		print "Can not get $repo OS version!";
		exit 1;
	}
	chomp($OSVer);
	$mycmd = "grep PATCHLEVEL /etc/SuSE-release | sed -e \'s/[A-Za-z= ]//g\'";	
	$PVer = `$mycmd`;
	if ($? == 0) { # OS like: SLE_11_SP2 etc
		chomp($PVer);
		$repo .= $OSVer . "-SP" . $PVer;
	} else {
		$repo .= $OSVer;
	}
} else {
	$repo = "openSUSE-";
	$mycmd = "grep -i VERSION /etc/SuSE-release | sed -e \'s/[A-Za-z =]//g\'";
	$OSVer = readpipe($mycmd);
	chomp($OSVer);
	if ( $OSVer == "" ) {
		print "Can not get $repo OS version!";
		exit 1;
	}
	$repo .= $OSVer;
}

my $repo_url = $pre_repo . "/" . $repo . "/";
$mycmd = "zypper lr -u|grep $repo_url|awk -F\\\| \'{print \$4}\'|grep \"Yes\" 1>/dev/null";
$repoOK = system($mycmd);
if ($repoOK != 0) {
	$mycmd = "zypper --no-gpg-checks -n ar $repo_url hamsta 1>/dev/null";
	$ret = system($mycmd);
	if ($ret != 0) {
		print "Cannot add hamsta repo as $repo_url to SUT.";
		exit 1;
	}
}

$mycmd = "zypper --no-gpg-checks --gpg-auto-import-keys in -y qa_hamsta 1>/dev/null";
$ret = system($mycmd);
if ($ret != 0) {
	print "qa_hamsta cannot be added to SUT.";
	exit 1;
}

$mycmd = "/usr/share/qa/tools/get_net_addr.pl";
$sut_net_addr = `$mycmd`;
if ( $sut_net_addr == "" ) {
	print "Can not get sut_net_addr.";
	exit 1;
}

if ( $sut_net_addr ne $master_net ) {
	$mycmd = "sed -i s/hamsta_multicast_address=\\\'.*\\\'/hamsta_multicast_address=\\\'$master_ip\\\'/ /etc/qa/00-hamsta-common-default";
	system($mycmd);
	$conn_type = 'unicast';
	$ret = system("grep -q \'$master_ip\' /etc/qa/00-hamsta-common-default");
	if ($ret != 0) {
		print "config unicast failed.";
		exit 1;
	}
}

$mycmd = "rchamsta start >/dev/null";
$ret = system($mycmd);
if ($ret != 0) {
	print "Cannot start hamsta service on SUT.";
	exit 1;
}
print $conn_type;
