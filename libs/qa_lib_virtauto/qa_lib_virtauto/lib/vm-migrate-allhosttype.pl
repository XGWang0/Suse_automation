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
    exit 255;
}


# Get local virtual host hyper type
my $localHyperType;
my $remoteHyperType;
my $mycmd;
my $myret;
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
print "cmd is : ".$mycmd."\n";
$myret = system($mycmd);
if ( $myret == 0 ){
	    $remoteHyperType = "xen";
} else {
	    $remoteHyperType = "kvm";
}

print "localHyperType is ".$localHyperType.", remoteHyperType is ".$remoteHyperType."\n";

# Find out which script to use
if ( $localHyperType eq $remoteHyperType ) {
    chdir('/usr/share/qa/virtautolib/lib/');
    $mycmd = "/usr/share/qa/virtautolib/lib/vm-migrate.sh ";
}
else{
    #TODO: create the cross virtual type migration script
    $mycmd = "";
}
$mycmd .= "-n $domainName -p $migrateeIP -t $migratetimes ";
if ($livemigration){
    $mycmd .= "-l";
}
print "The migration finally calls cmd: ".$mycmd."\n";
$myret = system($mycmd);
$myret = $myret >> 8;
system ("touch /var/lib/hamsta/stats_changed");

if ($myret != 0){
    print "The migration fails !";
}else{
    print "The migration is successful!";
}
exit $myret;

