#!/usr/bin/perl
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

# This modul is used to create the identifikation for the slave in the startup
# phase.
# This modul should run with root-id.

package Slave::Multicast;

use strict;
use warnings;

BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;

use IO::Socket::Multicast;
use Time::HiRes qw{usleep};
use Slave::functions;

require 'Slave/config_slave.pm';

my $debug = $Slave::debug;
my $constant_unique_id = "";

# Returns a (hopefully) unique ID for this slave that
# can be used by the master to identify the slave
sub unique_id () {
    my $unique_id = '';

	# We already have generated a unique ID - use it,
	# so our ID does not change within a session
    if ($constant_unique_id ne '') {
		return $constant_unique_id;
    }

    &log(LOG_DETAIL, "Generating unique ID");

	# So we have to generate an ID
	# First we put in the unique IDs of all our CPUs
	#&log(LOG_DEBUG, "  CPU");
	#my @data = `/usr/sbin/hwinfo --cpu`;
	#foreach my $i (@data) {
	#if ($i =~ /Unique ID:(.+)$/) {
	#    $unique_id = $unique_id.$1;
	#} 
	#}

	# Then the BIOS serial number
	#&log(LOG_DEBUG, "  BIOS");
	#$unique_id =~ s/\n|\s//g;
	#@data = `/usr/sbin/hwinfo --bios | grep Serial`;  
	#foreach my $i (@data) {
	#if ($i =~ /Serial: "([^\s]+)"$/) {
	#    $unique_id = $unique_id.$1;
	#} 
	#} 

	# Disk serial (currently not used)
    # UUID is not really unique, due to it has to be (sometimes) set,
    # on some hosts this query blows up syslog dramatically 
    #  
    # @data = `sudo /usr/sbin/hwinfo --disk | grep 'Serial ID:'`;
    #foreach my $i (@data) {
    #if ($i =~ /Serial ID: "(.+)"$/) {
    #&log(LOG_DEBUG, "Disk Serial ist: ".$1);
    #$unique_id = $unique_id.$1;
    #} 
    #} 


    # XEN Workaround
    # check, if it runs on XEN-VM, because the _para_virtualisation let the VM
    # seems nearly the same
    #&log(LOG_DEBUG, "  XEN");
    #my $data = `/bin/uname -r`;
    # Under special circumstances, different unique-ids are delivered back, i guess race condition
    # waiting does help, introducing, constant_unique_id
    #if ($data =~ /xen$/) {
    #    my @temp_partition = `/usr/sbin/hwinfo --partition`;
    #	sleep 1;
    #    foreach my $line_ (@temp_partition) {
    #            if ($line_ =~ /Device Files:/g) {
    #                    my @array = split / /, $line_;
    #                    (my $a, $array[-1]) = split /uuid\//, $array[-1];
    #                    $unique_id .= $array[-1] if defined $array[-1];
    #            }
    #    }
    #    $unique_id=~ s/ //g;
    #}

    # MAC address workaround (for machines with exact duplicate HW, etc)
    &log(LOG_DEBUG, "  MAC");
    #get the route gateway  interface
    my $routei = `route -n|awk '\$3~/0.0.0.0/{print \$NF}'`;
    chomp $routei;
    #find the mac for the route gateway interface

    my $systemcmd = q%/{getline;print $2 ; exit;}'|tr '[a-z]' '[A-Z]'%;
    $systemcmd = q%ip a|awk '/% . $routei . $systemcmd;
    my $uid = `$systemcmd`;
    chomp $uid;
    
    if($uid =~ /^([0-9a-f]{2}([:]|$)){6}$/i)
    {
        $unique_id = "$unique_id.$uid";
    }
    else
    {
        $unique_id = "$unique_id.NoMAC";
    }

    &log(LOG_DETAIL, "Unique ID == $unique_id");
    #$unique_id .= `/bin/uname -n`;
    $unique_id =~ s/\n/ /g;

	# Use this ID in future calls of this function
    $constant_unique_id = $unique_id;

    return $unique_id;
}


# get_slave_description() : string
# Returns a string that describes this slave and can be used for display
# For now, this is a uname output including the hostname
sub get_slave_description() {
    my $stats_version = $_[0];
    my $desc = `hostname|cut -d. -f1`;
    chomp $desc;
    my $kernelnum = `/bin/uname -r`;
    chomp $kernelnum;
    $desc = $desc." ".$kernelnum;

    # If this is i*86, we want to know if it can support x86_64
    # If it does, we report *that* as the real architecture
    # We are currently only doing this for i*86 (s390, ppc, etc. are treated as usual)
    my $arch = `/bin/uname -i`;
    chomp $arch;
    if($arch =~ /^i.86$/)
    {
        # Check if it is x86_64 capable (by the "lm" flag)
        my $flags = `cat /proc/cpuinfo | grep '^flags' | head --lines=1`;
        if($flags =~ /\slm\s/) {
            $arch = "x86_64";
        } else {
            $arch = "i586";
        }
    }
    $desc = $desc." ".$arch." ".$stats_version;

    my @release = `cat /etc/SuSE-release`;
    foreach (@release) {
        chomp ($_);
        $desc = $desc." $_";
    }
    # find out which beta
    my $release = `cat /etc/issue | grep -i Beta`;
    $release=~ /(Beta.+?)\(/i; 
    if (defined($1)) {
        $desc .= " $1";
    }
    
     # find out which which XEN U|0
    if ( -e "/proc/xen/capabilities") {
        my $data = ` cat /proc/xen/capabilities | grep control_d`;
        if ( $data =~ /control_d/g) {
            $desc = $desc." Dom0";
        } else {
            $desc = $desc." DomU";
        }

    }


    return $desc;
}

sub get_update_status {
	return 0;
        #we do not want the refresh too much , once in 30mins .
	#this will generate competition with system zypper
        my $num=shift;
        return "skip" if($num%180!=0);
	my $run_ck = `ps -ef|grep "[r]un_job\.pl"|tail -1`;
	chomp($run_ck);
	return "skip" if($run_ck);
	#get the hamsta version sum from local
	my $current_v=`rpm -qa|grep 'qa_hamsta-[0-9]\\|qa_hamsta-cmdline\\|qa_hamsta-common\\|qa_tools\\|qa_lib_perl\\|qa_lib_config\\|qa_lib_keys'|sed -r 's/.*-([^-]+-[^-]+)\$/\\1/'|awk -F"-" '{split(\$NF""\$(NF-1),a,"");for(i in a){if(a[i]~/[0-9]/)s+=a[i]}}END{print s}'`;
	chomp($current_v);
	return 0 unless($current_v);
	#get the hamsta version sum from repo
	system('zypper --non-interactive --gpg-auto-import-keys refresh &>/dev/null' );
	my $repo_v=`zypper --non-interactive search --details --type package qa_ 2>/dev/null|grep 'qa_hamsta[^-]\\|qa_hamsta-cmdline\\|qa_hamsta-common\\|qa_tools\\|qa_lib_perl\\|qa_lib_config\\|qa_lib_keys'|awk -F\"|\" '!b[\$2]++{split(\$4,a,"");for(i in a){if(a[i]~/[0-9]/)s+=a[i]}}END{print s}'`;
	chomp($repo_v);
	return 0 unless($repo_v);
	return 1 if($current_v!=$repo_v);
	return 0;
}


# konfiguration() : string
# this is the placeholder for client configuration
# to be transmitted to the master
# at this moment, this wish for encrypted communication
sub konfiguration ()  {
	# TODO Rename, implement
    my $data = `cat /usr/share/hamsta/Slave/.version`;
    chomp($data);
    return "ssh-on\tclient-version_$data";
}

1;

