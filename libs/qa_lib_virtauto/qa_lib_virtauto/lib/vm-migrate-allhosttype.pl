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

use detect;
use strict;
use warnings;

# no_ignore_case is required for short options to work
# no_getopt_compat is required for patterns to start with '+'
use Getopt::Long qw(:config no_ignore_case no_getopt_compat);

use qaconfig;
use install_functions;
use log;

$ENV{'LC_ALL'}='en_US';

my $myret;

sub exitWithError{
        $myret = 1;
        system ("touch /var/lib/hamsta/stats_changed");
        exit $myret;
}
# get source and destination host type
  # if type not equal
    # call cross type migration args
  # else
    # call /usr/share/qa/virtautolib/lib/vm-migrate.sh args

# Get options
my $domainName = "";
my $migrateeIP = "";
my $livemigration = "";
my $migratetimes = "";
GetOptions(
	'n=s'     => \$domainName,
	'p=s'     => \$migrateeIP,
	'l!'      => \$livemigration,
	't=i'     => \$migratetimes,
);

#error check
if ( !$domainName || !$migrateeIP || !$migratetimes){
    print "$0: Invalid null input parameters!!";
    &exitWithError;
}


# Get local virtual host hyper type
my $localHyperType;
my $remoteHyperType;
my $mycmd;
$mycmd = "uname -a | grep -iq xen 2>/dev/null";
$myret = system($mycmd);
if ( $myret == 0 ){
    $localHyperType = "xen";
} else {
    $localHyperType = "kvm";
}

# Get remote virtual host hyper type
my $sshNoPass;
$sshNoPass = "sshpass -e ssh -o StrictHostKeyChecking=no";
$mycmd = "/usr/share/qa/virtautolib/lib/get-settings.sh";
my $migrateeUser = `$mycmd migratee.user`;
my $migrateePass = `$mycmd migratee.pass`;
chomp($migrateeUser);
chomp($migrateePass);
$mycmd = 'export SSHPASS='.$migrateePass.'; '.$sshNoPass.' '.$migrateeUser.'@'.$migrateeIP.' "uname -a | grep -iq xen 2>/dev/null"';
#print "cmd is : ".$mycmd."\n";
$myret = system($mycmd);
if ( $myret == 0 ){
	    $remoteHyperType = "xen";
} elsif ($myret == 256) {
	    $remoteHyperType = "kvm";
} else {
	    print "Failed to get migratee host virtulization type. \n";
            &exitWithError;
}
print "localHyperType is ".$localHyperType.", remoteHyperType is ".$remoteHyperType."\n";

# Get the to-be migrated virtual machine info
$mycmd = "/usr/share/qa/virtautolib/lib/get-settings.sh";
my $vmUser = `$mycmd migratee.vm.user`;
my $vmPass = `$mycmd migratee.vm.pass`;
chomp($vmUser);
chomp($vmPass);

# Find out which type of migration, valid types: xen2xen,kvm2kvm,xen2kvm.
if ( $localHyperType eq $remoteHyperType ) {
    # This is xen to xen or kvm to kvm migration.
    chdir('/usr/share/qa/virtautolib/lib/');
    $mycmd = "/usr/share/qa/virtautolib/lib/vm-migrate.sh ";
    $mycmd .= "-n $domainName -p $migrateeIP -t $migratetimes ";
    if ($livemigration){
        $mycmd .= "-l";
    } 
}
elsif ( $localHyperType eq "xen" &&  $remoteHyperType eq "kvm" ){
    # This is xen to kvm migration.
    chdir('/usr/share/qa/virtautolib/lib/');
    $mycmd = "/usr/share/qa/virtautolib/lib/xen2kvm-migrate.sh ";
    $mycmd .= "$domainName $vmUser $vmPass $migrateeIP $migrateeUser $migrateePass";
    if ( $migratetimes && $migratetimes  > 1 ){
        print "This is xen to kvm migration, so migrate times will be set to 1, ignoring the set value!\n";
        $migratetimes = 1;
    }
    if ( $livemigration ){
        print "This is xen to kvm migration, so ignore live option!\n";
    }
}
else{
        print "Migration from kvm to xen is not valid!";
        &exitWithError;
}

print "The migration finally calls cmd: ".$mycmd."\n";
$myret = system($mycmd);
$myret = $myret >> 8;

#if migration is successful, undefine the migrated vm on source host to avoid machine competition.
if ($myret == 0 && ( $migratetimes % 2 == 1 ) ){
	if ( $localHyperType eq $remoteHyperType){
		print "If you want to recover the domain $domainName on source VH, please firstly execute \"virsh destroy $domainName\" on destination VH, then execute on source VH \" virsh create /var/lib/$localHyperType/images/$domainName/$domainName.orig.xml\", it will automatically start running and list the vm on QA Cloud page.\n";
	}
	print "Undefining the domain $domainName on source VH ... \n";
	system("virsh destroy $domainName 2>/dev/null;virsh undefine $domainName 2>/dev/null");
}

# Let hamsta master query the latest vm list status
system ("touch /var/lib/hamsta/stats_changed;sleep 5");
print "Touch source VH hamsta status file done.\n";
system ('export SSHPASS='.$migrateePass.'; '.$sshNoPass.' '.$migrateeUser.'@'.$migrateeIP.' "touch /var/lib/hamsta/stats_changed"');
print "Touch destination VH hamsta status file done.\n";

if ($myret != 0){
    print "The migration fails !\n";
}else{
    print "The migration is successful!\n";
}
exit $myret;

