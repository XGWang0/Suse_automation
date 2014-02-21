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

# This is the Slave Network interface.
# 
package Slave;

use warnings; 
use strict;
use vars qw(@ISA);

use threads;
#use Net::Server::PreFork;
use URI::Escape;
use XML::Simple;
use File::Temp;
use Proc::Fork;
use Sys::Hostname;
use Data::Dumper;
use Socket;
use POSIX ':sys_wait_h';

BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;
$log::loginfo='slave_diplom';

use Slave::hwinfo_xml;
use Slave::stats_xml;
use Slave::rsv_rls qw(allow_connection reserve release);

use Slave::Multicast::mcast;
use Slave::functions;

require 'Slave/config_slave.pm';

@ISA = qw(Net::Server::PreFork);

# Register the cleanup sub
$SIG{KILL} = \&deconstruct;
$SIG{INT} = \&deconstruct;
$SIG{TERM} = \&deconstruct;
#$SIG{CHLD} = 'IGNORE';

if ($> != 0) {
    &log(LOG_CRIT,"The HAMSTA slave has to be run as root (needed for hwinfo)");
    exit;
}


# If the running slave has already sent a hwinfo output, $sent_hwinfo contains
# the timestamp when it was sent. When a request for hwinfo is received and
# $sent_hwinfo != 0, send a "nothing changed" message instead of running 
# hwinfo over and over again.
my $sent_hwinfo = 0;

# If the config file specifies a working directory, use it.
# This is needed when the slave is not started manually in the right
# directory but e.g. in an init script.
if ($Slave::directory) {
    chdir $Slave::directory;
}

$log::loglevel=$Slave::debug;

# Start the server to handle messages from the master
# Oh, and keep the original STDOUT for debugging purposes, as in
# process_request STDOUT is what will be sent to the master
#
# We have to do this in a own forked process, because Net::Server::Prefork
# will confuse the backtick operator used in the Multicast module and
# both the PreFork-Server and the multicast module will hang, leaving
# the process run by the backtick operator as a zombie.
#
# If you don't do the fork, it may work often and on some machines the 
# problem won't occur ever. This does not mean the problem is gone. If
# you remove the forking again, the code will probably be broken on some
# machines.
our $last_ip = &get_slave_ip($Slave::multicast_address);
our $slave_pid;
our $multicast_pid;

child {
    $log::loginfo='hamsta-server';
    $0 .= ' server';
    &log(LOG_INFO, "Starting server");

    open(STDOUT_ORG, ">&STDOUT");
    STDOUT_ORG->autoflush(1);
    &log_set_output(handle=>*STDOUT_ORG,close=>1);
    run_slave_server();
}
parent {
    $slave_pid=shift;
}
;


# Start the multicast announcement as a new thread
# my $mcast_thread =threads->new(sub {system("/usr/bin/perl mcast.pm");});
child {
        $log::loginfo = 'hamsta-multicast';
        $0 .= ' multicast';
&log(LOG_INFO,"Starting multicast thread");
&Slave::Multicast::run();
}
parent {
    $multicast_pid=shift;
};

$log::loginfo = 'hamsta';

while(1){
    my $sleep_s=300;
    my $current_ip=&get_slave_ip($Slave::multicast_address);
    if($last_ip ne $current_ip ){
      if(! &chk_run ) { 
	kill 9,$slave_pid,$multicast_pid;
	sleep(1);
	waitpid $slave_pid, 0;
	waitpid $multicast_pid, 0;
	&log(LOG_ERR,"Multicast died");
	&log(LOG_ERR,"slave server died");
	$last_ip=$current_ip;
	sleep 5;
	child {
              $log::loginfo='hamsta-server';
              $0 .= ' server';
	      &log(LOG_INFO, "Starting server");
              open(STDOUT_ORG, ">&STDOUT");
	      STDOUT_ORG->autoflush(1);
	      &log_set_output(handle=>*STDOUT_ORG,close=>1);
	      run_slave_server();
	}
	parent {
		    $slave_pid=shift;
	}
	;
	child {
                $log::loginfo = 'hamsta-multicast';
                $0 .= ' multicast';
		&log(LOG_INFO,"Starting multicast thread");
		&Slave::Multicast::run();
	}
	parent {
		    $multicast_pid=shift;
	};

      }
      $sleep_s=600;
    }
      sleep($sleep_s);
}

# Should be never reached

# run_slave_server()
#
# Listens for incoming connections on the slave_port and forwards
# requests to process_request.
# 
sub chk_run() {
  open my $sub_p,"pstree $slave_pid |" or return 0;
  my @pstreeo = <$sub_p>;
  close $sub_p;
  return 1 if(grep { /\-/ } @pstreeo);
  return 0 ;
}


# runs slave server, binds to port, responds to connections
sub run_slave_server() {
    my $socket = new IO::Socket::INET(
        LocalPort => $Slave::slave_port,
        Proto     => 'tcp', 
        Listen    => 1,
        Timeout   => undef,
        Reuse     => 1,
    );
    
    my ($connection,$ip_addr);
    while(1) {
        eval {
	    sleep 2;
	    my ($port,$iaddr,$paddr);
            &log(LOG_DETAIL,"Accepting connections");
            ($connection,$paddr) = $socket->accept();
            $| = 1;
	    $connection->autoflush(1);
	    ($port,$iaddr)=sockaddr_in($paddr);
	    $ip_addr = inet_ntoa($iaddr);
            &log(LOG_NOTICE,"Connection established from $ip_addr");
            
            $SIG{'PIPE'} = 'IGNORE';

            if ( &allow_connection($ip_addr) ){
		    process_request($connection, $ip_addr);
            }else{
		    &log(LOG_NOTICE,"Refuse connection from non-reserved master $ip_addr.");
		    print $connection "The SUT is reserved by other hamsta already!\n";
            }
        };  
        if ($@) {
            &log(LOG_ERROR, "$@ Will retry."); 
            sleep 5;
            
            $socket = new IO::Socket::INET(
                LocalPort => $Slave::slave_port,
                Proto     => 'tcp', 
                Listen    => 1,
                Timeout   => undef,
                Reuse     => 1,
            );

            next;
        }
            
        if (defined($connection)) {
            close($connection);
        }
    }
}

# process_request()
#
# Handles a message from the server.
#
# There are the following types of messages:
#
# * set_time: <time string> 
#   Sets the slave's date. <time string> is passed to date -s.
#
# * get_hwinfo [fresh]
#	Returns a hash containing the hwinfo data, serialized in XML.
#	If fresh is not specified the slave may return "Current hwinfo
#	already sent on <timestamp>" to indicate that nothing has
#	changed since the last query.
#
# * get_stats
#       Returns a hash containing the stats of (Virtualization) host, 
#       serialized in XML. If machine is not virtualization host,
#       only limited information is returned. If machine is VH, also
#       list of VMs is returned.
#
# * ping
#	Returns the String "pong"
# * reserve
#	Return the string whether reservation is successful,"Reservation succeeded/failed.".
#
# * release
#	Return the string whether release is successful, "Release succeeded/failed."
#
# * Anything else is treated as XML serialized job description
#	TODO Better add a header line or something to get rid of this
# 	error prone "anything else"
#

# This sub was designed to get the incoming data on STDIN by 
# Net::Server::PreFork and sending outgoing data on STDOUT. Therefore
# outdated things like STDOUT_ORG are used.

sub process_request {
    my ($sock,$ip_addr) = @_;
    #Send Establish sync
    print $sock "\n";
    eval {

        STDOUT->autoflush(1);

        while( <$sock> ){
            s/\r?\n$//;
            my $incoming = $_ ;
	    &log(LOG_INFO, "[$ip_addr] IN: ".$incoming);

            if ($incoming =~ /^set_time:/ ) {
                (my $a,my $time_utc) = split (/^set_time:/,$incoming);
                eval {
                    my $return_shell = `LANG= /bin/date --set="$time_utc"`; 
                };
            } elsif ($incoming =~ /^get_hwinfo( fresh)?$/) {
                eval { 
                    print $sock uri_escape(&get_hwinfo_xml());
                };
                if ($@) {
                    &log(LOG_ERROR, $@);
                }
                &log(LOG_NOTICE, "[$ip_addr] Sent hwinfo.");
                $sent_hwinfo = time;
		last;
            } elsif ($incoming =~ /^get_stats$/) {
                eval { 
                    print $sock uri_escape(&get_stats_xml());
                };
                if ($@) {
                    &log(LOG_ERROR, $@);
                }
                &log(LOG_NOTICE, "[$ip_addr] Sent machine stats.");
		last;
            } elsif ($incoming =~ /^ping$/) {
                print $sock "pong\n" ;	
		last;
            } elsif ($incoming =~ /^reserve$/) {
		print $sock &reserve($ip_addr);
		last;	    
            } elsif ($incoming =~ /^release$/) {
		print $sock &release($ip_addr);   
		last;
	    } else {
                my $job = $incoming."\n";
		&log(LOG_NOTICE, "[$ip_addr] Start of XML job");
                while ($incoming = <$sock>) {
		    chomp $incoming;
		    &log(LOG_DETAIL, "XML:".$incoming);
                    $job = $job . $incoming . "\n";

                    last if ($incoming =~ /<\/job>/);
                    last if ($incoming =~ /%3C\/job%3E/);
                }
                &start_job($job, $sock, $ip_addr);
		last;
            }
        }
    };

    if( $@ ){
        &log(LOG_ERROR, $@);
        return;
    }
    &log(LOG_DETAIL, "Request finished.");

}

# start_job($xml_job)
# Starts the execution of the job described by $xml_job
# The output of the job is forwarded to the master
sub start_job() {
    my ($xml_job, $sock, $ip_addr) = @_; 	

    # If the incoming data is uri_escaped (should be), unescape it
    if ($xml_job =~ /\%3Cjob$/) {
        $xml_job = uri_unescape($xml_job); 
    } else {
        &log(LOG_DETAIL, "start_job(): Received non-escaped data");
    }

    # Try if it really is a valid XML serialization of a Perl hash
    unless(&read_xml($xml_job,0))
    {
        &log(LOG_ERROR, "$@ : start_job(): Could not convert the datastructure ".
            "(xml -> perl). Please have a look! Received message: ".
            ">>$xml_job<<");
        return 0;
    } 

    &log(LOG_NOTICE, "Starting job.");

    # Write XML serialization of the job description to a file
    (my $fh, my $filename) = File::Temp::tempfile();
    if ($fh) {
        print $fh $xml_job;
        close ($fh);
    } else {
        &log(LOG_ERROR, "Could not open $filename. Check permissions.");
    }
    &log(LOG_DETAIL, "Written XML to file $filename");

    # Start the execution and collect the output
    
    #time out monitor start.
    my $sut_timeout=0;
    #find out time out value.
    my $fork_re = fork ();
    if($fork_re==0) {
	#in child, start to work;
	#close share socket in child
	&command("/usr/share/qa/tools/sync_qa_config $ip_addr");
        my $pid_main = open (FILE, "/usr/bin/perl Slave/run_job.pl $filename 2>&1|");
        my $count = 0;
        while (<FILE>) {
	    chomp;
	    #bug 615911
	    next if ($_ =~ /A thread exited while \d+ threads were running/);
            &log(LOG_DETAIL, '%s', $_);
            print $sock $_."\n";
            $count++ if ($_ =~/\<job\>$/ );
            last if ($count == 2);
        }
	close FILE;
	unlink $filename;
	&log(LOG_NOTICE, "Job finished.");
	print $sock "Job ist fertig\n";
	exit;
    }elsif($fork_re){
	#in parent we start to check child is finish or not;
        my $qa_package_jobs = `grep '\./customtest ' $filename`;
        chomp $qa_package_jobs;
        if($qa_package_jobs){
            $qa_package_jobs =~ s/.*customtest //;
            my @qa_package_jobs = split /\s+/,$qa_package_jobs;
            for my $j (@qa_package_jobs) {
                $j =~ s/qa_//;$j =~ s/$/-run/;
    	        my $time_o = `grep 'sut_timeout ' /usr/share/qa/tools/$j`;
	        chomp $time_o;
	        $time_o =~ s/#sut_timeout //;
		$time_o =~ s/\D+//g;
	        if ($time_o){
			&log(LOG_NOTICE, "Found package $j timeout $time_o (s)");
			$sut_timeout += $time_o ;
		} else {
        		&log(LOG_NOTICE, "Can not found package $j timeout ,use 86400 (s)");
			$sut_timeout += 86400;  #24hours
		}
            }
        }else {
		# we do not limit the job which is not qa_package,set to a very large number.
		$sut_timeout = 8640000;
	}
        &log(LOG_NOTICE, "The Job Time out is $sut_timeout (s)");

	my $current_time=0;
	while ($current_time < $sut_timeout) {
	    goto OUT if(waitpid($fork_re, WNOHANG));
	    sleep 60;
	    $current_time += 60;

	}
        #timeout
        &log(LOG_ERROR, "TIMEOUT,please logon SUT check the job manually!");
        &log(LOG_NOTICE, "Job TIMEOUT.");
	print $sock "TIMEOUT running $sut_timeout seconds ,time is up \n";
	print $sock "Please logon SUT check the job manually!\n";
        print $sock "Job ist fertig\n";
	OUT: 
    }else{
	#fork error ;
        &log(LOG_ERROR, "Fork error,exit");
	&log(LOG_NOTICE, "Job finished.");
	print $sock "Job ist fertig\n";
    }
}

# deconstruct()
# Does some cleanup (TODO well, at least it should do so...)
sub deconstruct() {
 exit 0;
}


1;

