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
        &usage;
        $myret = 1;
        system ("rpm -q qa_hamsta > /dev/null 2>&1 && touch /var/lib/hamsta/stats_changed");
        exit $myret;
}

sub usage{
print "\n
Usage: $0 (-n domainName | -m domainMac) -p migrateeIP -t migrateTimes [-l].
Description:  supports migration of xen2xen, kvm2kvm, xen2kvm.
Params: domainName: the domain name of the virtual machine to migrate,
        domainMac: the mac address of the virtual machine to migrate,
        migrateeIP: the IP address the virtual host to migrate to,
        migrateTimes: how many times to migrate around, 
	-l: indicates live migration, only supports xen2xen, kvm2kvm migration.\n";
}

# Get options
my $domainName = "";
my $domainMac = "";
my $migrateeIP = "";
my $livemigration = "";
my $migratetimes = "";
GetOptions(
	'n=s'     => \$domainName,
	'm=s'     => \$domainMac,
	'p=s'     => \$migrateeIP,
	'l!'      => \$livemigration,
	't=i'     => \$migratetimes,
);

#error check
if ((!$domainMac && !$domainName) || !$migrateeIP || !$migratetimes){
    print "$0: Invalid null input parameters!!";
    &exitWithError;
}

if (!$domainName && $domainMac){
    #Translate domainMAC to domainName
    $domainName = `for domain in \$(virsh list --name --all); do if virsh dumpxml \$domain | grep -iq "$domainMac"; then echo \$domain; fi; done`;
    chomp($domainName);
    if (!$domainName){
        print "$0: No domain found for given domain mac!!\n";
        &exitWithError;
    }
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
	    print "Failed to get migration target host virtualization type. \n";
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
        print "Migration from kvm to xen is not valid! Only xen2xen/kvm2kvm/xen2kvm are valid migration types!\n";
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
system ("rpm -q qa_hamsta > /dev/null 2>&1 && touch /var/lib/hamsta/stats_changed && echo \"Touch source VH hamsta status file done.\";sleep 5");
system ('export SSHPASS='.$migrateePass.'; '.$sshNoPass.' '.$migrateeUser.'@'.$migrateeIP.' "rpm -q qa_hamsta > /dev/null 2>&1 && touch /var/lib/hamsta/stats_changed && echo \"Touch destination VH hamsta status file done.\""');

if ($myret != 0){
    print "The migration failed !\n";
}else{
    print "The migration is successful!\n";
}
exit $myret;

