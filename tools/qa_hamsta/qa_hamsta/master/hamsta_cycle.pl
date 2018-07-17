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

#
# hamsta_cycle.pl -- it harvests new builds, sets up a new installation source
# and schedules validation test
#
# pkirsch@suse.de, llwang@novell.com
#
# Make sure output is in UTF8
use File::Basename;
binmode(STDOUT, ":utf8");
my $debug = 0;
my $last_build = 0;

####### User defined prameters #########
my $nfsdir = "dist.suse.de:/dist"; # You may need "147.2.207.242:/mirror_a" for CN
my $httpurl = "http://dist.suse.de/install/SLP/"; # You may need "http://147.2.207.242/install/SLP/" for CN
my $localdir = "/newmounts"; # Local mount point
my $buildsample = "SLES-10-SP4-Build0*"; # What kind of build you want to detect?
my $productlocation = "$localdir/install/SLP/$buildsample"; # This is where the new builds located.
my $sleeptime = "100"; # Do build detection every $sleeptime seconds
our $email = "holgi\@novell.com"; # Email address could be defined here.
####### End of user configuration ######

system "mkdir -p $localdir; mount -t nfs $nfsdir $localdir" if ! -e "$localdir/install";
my $list_latest_product="ls $productlocation -dt | head -1";

sub differ_release_cyclus () {
    # look for RC
    # look for alpha/betha ..
    # look for build number
    my @data = `$list_latest_product`;
    my $buildnr;
    
    if ($data[-1]=~/uild0/) {
        chomp($data[-1]);
        # eg. SLES-10-SP1-Build00403
        #(@buildnr) = split /uild/,$data[-1];
        $data[-1]=~/uild0(.+?)-DVD/;
        if ($1) {
            $buildnr=$1;
        } else {
            $data[-1]=~/uild0(.+?)$/;
            $buildnr=$1;
        }
        $last_build=~ /$buildnr/
    } elsif ($data[-1]=~/Alpha|Beta/) {
        chomp($data[-1]);
        # e.g. openSUSE-10.3-Alpha4-DVD
        $data[-1]=~/a(\d)(plus|-DVD)/ig;
        if ($1) {
            $buildnr=$1;
        
        } else {
            print "No known Alpha or Beta Release :( \n";
        }
    } else {
        print STDERR "the grep command does not fetch a build !! \n";
        return 0;
    }
    print ".";
    # now comparing if it is newer
    # also using a temp. file, if the script is restarted to not schedule
    # job again again again ...
    if ($last_build < $buildnr) {
            # check for a restart of script
            if (! (`ls /tmp/last_build_scheduled_* > /dev/null 2>&1`)) {
                `touch /tmp/last_build_scheduled_0000`;
                # return; # do not return, use the latest build for sending
            }
            my @tmp=`ls /tmp/last_build_scheduled_*`;
            my (@file_last_build) = split /scheduled_/, $tmp[-1];
            if ($file_last_build[1] == $buildnr) {
                # this build was already scheduled, so ignore
                return 0;
            } else {
                print "\nYes! new build arrived: $buildnr ($data[-1])\n";
                # set the new one to be the std. 
                $last_build = $buildnr;

                # delete the last_build_scheduled_? file
                `rm /tmp/last_build_scheduled_* 2>/dev/null`;
                `touch /tmp/last_build_scheduled_$buildnr`;
                # return the path
                return $data[-1];
            }
     } else {
        return 0;
    }
}

sub schedule_validation () {
    my $buildpath = shift @_;
    my $config_file_path = "/srv/www/htdocs/hamsta/config.ini";
    $buildnr = basename($buildpath);
    my $rand =  int(rand(100000));
    my $autoyastfile = "/tmp/reinstall_$rand.xml";
    my $validationjob = "/tmp/validation_$rand.xml";
#    my $command = `grep '\$vmlist=' /srv/www/htdocs/hamsta/config.php`;
#    $command =~ s/\$/%/;
#    $command =~ s/array//;
#    eval "$command";
    my $conflist = `grep '^vmlist' $config_file_path`;
    $conflist =~ s/vmlist\.//;
    $conflist =~ s/ //g;
    my %vmlist = ();
    foreach ( split ("\n", $conflist) ) {
	my @vals = split '=';
	$vmlist{$vals[0]} = $vals[1];
    }

    for my $key (keys %vmlist) {
        my $value = $vmlist{$key};
        if ($value ne "N/A") {
            my $rand =  int(rand(100000));
            $autoyastfile = "/tmp/reinstall_$rand.xml";
            my $newbuild = $httpurl.$buildnr."/".$key."/DVD1";
            system "sed 's,REPOURL,$newbuild,g;s,ARGS,-p $newbuild,g;s,llwang\@novell.com,$email,' /usr/share/hamsta/xml_files/templates/reinstall-template.xml > $autoyastfile";
            system "sed 's,llwang\@novell.com,$email,' /usr/share/hamsta/xml_files/Validation_test.xml > $validationjob";
            system "/usr/share/hamsta/feed_hamsta.pl -h $value -j $autoyastfile localhost";
            system "/usr/share/hamsta/feed_hamsta.pl -h $value -j $validationjob localhost";
            #print "/usr/share/hamsta/feed_hamsta.pl -h $value -j $autoyastfile localhost\n";
            #print "/usr/share/hamsta/feed_hamsta.pl -h $value -j $validationjob localhost\n";
        }
    }
}

# main: while loop
while ( 1 ) {
    $buildnr = &differ_release_cyclus();
    &schedule_validation($buildnr) if ($buildnr);
    sleep $sleeptime;
}


