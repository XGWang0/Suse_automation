#!/usr/bin/perl -w 
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

BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;
$log::loginfo='slave_diplom';

use Slave::hwinfo_xml;

use Slave::Multicast::mcast;
use Slave::functions;

require 'Slave/config_slave';

@ISA = qw(Net::Server::PreFork);

# Register the cleanup sub
$SIG{KILL} = \&deconstruct;
$SIG{INT} = \&deconstruct;
$SIG{TERM} = \&deconstruct;

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
child {
    $log::loginfo='hamsta';
    &log(LOG_INFO, "Starting server");
    
    open(STDOUT_ORG, ">&STDOUT");
    STDOUT_ORG->autoflush(1);
    &log_set_output(handle=>*STDOUT_ORG,close=>1);
    run_slave_server();
};


# Start the multicast announcement as a new thread
# my $mcast_thread =threads->new(sub {system("/usr/bin/perl mcast.pm");});
&log(LOG_INFO,"Starting multicast thread");
&Slave::Multicast::run();

# Should be never reached
&log(LOG_ERR,"Multicast died");
1 while 1;

# run_slave_server()
#
# Listens for incoming connections on the slave_port and forwards
# requests to process_request.
# 
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
	    my ($port,$iaddr,$paddr);
            ($connection,$paddr) = $socket->accept();
            $| = 1;
	    $connection->autoflush(1);
	    ($port,$iaddr)=sockaddr_in($paddr);
	    $ip_addr = inet_ntoa($iaddr);
            &log(LOG_NOTICE,"Connection established from $ip_addr");
            
            $SIG{'PIPE'} = 'IGNORE';
            process_request($connection, $ip_addr);
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
# * ping
#	Returns the String "pong"
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
            } elsif ($incoming =~ /^ping$/) {
                print $sock "pong\n" ;	
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
                &start_job($job, $sock);
            }
        }
    };

    if( $@ ){
        &log(LOG_ERROR, $@);
        return;
    }

}

# start_job($xml_job)
# Starts the execution of the job described by $xml_job
# The output of the job is forwarded to the master
sub start_job() {
    my $xml_job = shift @_; 	
    my $sock = shift;

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
    my $pid_main = open (FILE, "/usr/bin/perl Slave/run_job.pl $filename 2>&1|");
    my $count = 0;
    while (<FILE>) {
	chomp;
	#bug 615911
	next if ($_ =~ /A thread exited while \d+ threads were running/);
        &log(LOG_DETAIL, '%s', $_);
        print $sock $_."\n";
        $count++ if ($_ =~/\<job\>$/ );
        goto OUT if ($count == 2);
    }
    OUT:
    close FILE;
    unlink $filename;
    &log(LOG_NOTICE, "Job finished.");
    print $sock "Job ist fertig\n";
}

# deconstruct()
# Does some cleanup (TODO well, at least it should do so...)
sub deconstruct() {
 exit -1;
}


1;
