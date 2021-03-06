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

use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);

BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;
use detect;
$log::loginfo='slave_diplom';

use Slave::hwinfo_xml;
use Slave::stats_xml;
use Slave::rsv_rls('&allow_connection','&reserve','&release');
use Slave::Multicast::mcast;
use Slave::functions;
use Slave::Job::Command;

use constant {
    RFINISH => "Job ist fertig\n",
};

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
our $last_ip = &get_my_ip_addr($Slave::multicast_address);
our $slave_pid;
our $multicast_pid;

# The tmp local log file to store job log if job socket meet issues.
use constant JOB_LOG_FILE => "/var/log/hamsta-job.log";

# For new mm sync, we add algorithm to handle broken job socket, which
# detects socket breaking, does job logging to local job log file, and also
# detects socket recovery and transmits logs back from the breaking point in sequence,
# and restart real-time log transmission.
#
# How:
# We use socket-pair for communication between the job process which runs the real job code,
# i.e. the child process of slave-server process, and the slave-server process, which communicates
# about the job socket error, recovery, and event handling progress.
#
# When job socket is detected to be broken the very fist time in job child proc,
# it notifies the slave-server proc about it through the socket-pair,
# which is now waiting for the job child proc ends.
# Then the slave-server proc stops waiting and goes back to accept new connections.
# Since SUT reservation is used, only the reserved master can connect to the SUT.
# Once the new connection is accepted, it is regarded as a recovered job socket.
#
# Then the slave-server proc starts to handle the job socket recovery:
# notify the job child proc, if it is still running, to recover real-time logging by socket-pair,
# send the local job log back directly to recovered job sock from local job log file, and then
# transmit back the real-time logging, which is restarted in job child proc, from the socket-pair to the
# recovered job sock(yes, the socket-pair is reused as a data pipe from a communication pipe now).
#
# If during this process, job socket is broken again, all transmitted back logs will be removed,
# and all that not transmitted back to the recovered job socket from the break point,
# including what's left in local log file and not transmitted back real-time logs from socket-pair,
# will be stored in the local job log file in-sequence order, and notification will be sent to
# the job child proc about the socket problem, which will start logging to local job log file again.
# This process continues untils the job child proc finishes and all logs are transmitted back to the
# reserved master via socket connection.

#monitor for IP change.
my $sleep_s=300;


$log::loginfo = 'hamsta';

# On Hamsta startup: perform abort section, finish (i.e. perform finish section + remove sections from disk)
section_run($Slave::abort_section, $Slave::finish_section);

while(1){
    my $current_ip=&get_my_ip_addr($Slave::multicast_address);
    if( $last_ip ne $current_ip or !$slave_pid ) {
      if( ($last_ip ne $current_ip) and !&chk_jobrun ) {
	  kill 9,$slave_pid,$multicast_pid;
	  sleep(1);
	  waitpid $slave_pid, 0;
	  waitpid $multicast_pid, 0;
	  &log(LOG_ERR,"Multicast died");
	  &log(LOG_ERR,"slave server died");
	  $last_ip=$current_ip;
	  sleep 5;
      }
      child {
        # setup logs
        $log::loginfo='hamsta-server';
        $0 .= ' server';
        &log(LOG_INFO, "Starting server");
        open(STDOUT_ORG, ">&STDOUT");
        STDOUT_ORG->autoflush(1);
        &log_set_output(handle=>*STDOUT_ORG,close=>1);

        # init the connection resuming mechanism
        our $job_sock_stat = 'normal';#normal or abnormal
        our $sock_broken_job_proc = '';
        while(1){
            unless(socketpair(JOB_CHILD, JOB_PARENT, AF_UNIX, SOCK_STREAM, PF_UNSPEC)){
                log(LOG_ERR,"Socketpair creation for JOB_CHILD and JOB_PARENT processes failed!");
                sleep 1;
                next;
            }

            #Set to non-blocking
            my $flags = fcntl(JOB_CHILD, F_GETFL, 0);
            fcntl(JOB_CHILD, F_SETFL, $flags | O_NONBLOCK);
            undef $flags;
            $flags = fcntl(JOB_PARENT, F_GETFL, 0);
            fcntl(JOB_PARENT, F_SETFL, $flags | O_NONBLOCK);

            JOB_CHILD->autoflush(1);
            JOB_PARENT->autoflush(1);
            last;
        }

        # run communication server
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

    $sleep_s=600;
    }
    sleep($sleep_s);
}

# Should be never reached

# run_slave_server()
#
# Listens for incoming connections on the slave_port and forwards
# requests to process_request.

#make sure No job is running when need to restart the process.

sub chk_jobrun() {
  my $job_sub = `ps --ppid $slave_pid|wc -l`;
  return 1 if ( $job_sub > 1 );
  return 0 ;
}

#Reinstall job will reboot here

sub reinst_grub() {
  my $sock = shift;
  print $sock RFINISH;
  close($sock)
  &command("reboot");
}

sub reinst_kexec() {
  my $sock = shift;
  print $sock RFINISH;
  close($sock)
  &command("/sbin/kexec -e");
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
		    our $job_sock_stat;
		    if($job_sock_stat eq 'abnormal'){
			    #For new mm_sync, all masters reserve SUT before doing anything,
			    #So for reconnecting, only the master reserving the machine can come here, no need to check ip again
			    #recovered connection send nothing here, just get back job log.

			    &handle_connection_recovery($connection);
		    }else{
		            process_request($connection, $ip_addr);
		    }
            }else{
		    &log(LOG_NOTICE,"Refuse connection from non-reserved master $ip_addr.");
		    print $connection "Connection failed!\n The SUT was reserved by other hamsta master already, and the reserved master ip was $Slave::reserved_hamsta_master_ip!\n";
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

# handle_connection_recovery()
#
# Handles connection recovery after job socket previously  broken  with master:
# Do what: send back local stored job log; slave_state setting; notify job child process to recover normal logging; recover real-time logging
sub handle_connection_recovery(){
	my $sock = shift;

	local $SIG{'PIPE'} = \&deal_with_broken_job_sock_parent;

	our $local_log_fh;

	our $job_sock_stat;
	our $sock_broken_job_proc;
	#how many lines of local stored job log have been transferred back to recovered job sock
	our $transfered_local_job_log_line = 0;
	#sign for whether local job log file has been all transmitted back to recovered job sock
	our $finish_local_job_log_trans = 'no';

	$job_sock_stat = 'recovered';
	log(LOG_NOTICE,"Connection recovered after job socket previously  broken!");
	my $msg_from_job_child;
	my $has_in_time_log = 'no';
	#Notify the job proc if it is still running
	unless(waitpid($sock_broken_job_proc, WNOHANG)){
		$has_in_time_log = 'yes';

		print JOB_PARENT "Recovered job sock: $sock";
		log(LOG_NOTICE, "Notification to the job child process about recovered job connection was sent!");

		#wait for child finish dealing with the norification
	  	while ( not read(JOB_PARENT,$msg_from_job_child,1024)
			or $msg_from_job_child !~ /Job child proc connection recovery handling is done!/){
			sleep 1;
		}
	        # get msg from job child process
	        chomp $msg_from_job_child;
	        log(LOG_NOTICE, "Job parent process received from job child proc: $msg_from_job_child");
	}

	unless(-e JOB_LOG_FILE and open $local_log_fh, "<".JOB_LOG_FILE){
		log(LOG_ERROR,"The local job log file can not be opened: ".JOB_LOG_FILE);
		$finish_local_job_log_trans = 'yes';
	}
	if ($local_log_fh){
		#send local stored log back
		while (<$local_log_fh>){
			log(LOG_DEBUG, "Slave-server:: in while loop of send local log to master!");
			return 1 if ($job_sock_stat eq 'abnormal');
			chomp $_;
			log(LOG_DETAIL, "Slave-server:: sent back to master log from local file: $_");
			print $sock $_."\n";
			$transfered_local_job_log_line++;
		}
		log(LOG_NOTICE, "All stored local job log was sent back!");

		close $local_log_fh;
		unlink JOB_LOG_FILE;
		$finish_local_job_log_trans = 'yes';
	}

	if($has_in_time_log eq 'yes'){
		#Transfer in-time log
		while(1){
			log(LOG_DEBUG, "Slave-server:: in while loop of send in-time pipe log to master!");
			return 1 if ($job_sock_stat eq 'abnormal');
			if(read(JOB_PARENT,$msg_from_job_child,1024)){
				chomp $msg_from_job_child;
				log(LOG_DETAIL, "Slave-server:: sent back to master in-time log: $msg_from_job_child");
				print $sock $msg_from_job_child."\n";
				my $rfinish = RFINISH;
				last if ($msg_from_job_child =~ /$rfinish/);
			}else{
				sleep 1;
			}
		}

		log(LOG_NOTICE, "All in-time job log was sent back!");
	}
	#Set the status of job sock to normal
	$job_sock_stat = 'normal';
	log(LOG_NOTICE,"Slave-server:: job_sock_stat is set to normal!");

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
#
# * Anything else is treated as XML serialized job description
#	TODO Better add a header line or something to get rid of this
#	error prone "anything else"
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

        while( <$sock> ) {
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
            } elsif ($incoming =~ /^version$/) {
				#get version from /usr/share/hamsta/Slave/.version
				my $client_version = `cat /usr/share/hamsta/Slave/.version|head -1`;
				chomp($client_version);
				$client_version = "unknown" if not $client_version =~ /^[\d\.]+$/;
                print $sock "$client_version\n" ;
            } elsif ($incoming =~ /^reserve$/) {
		my $response = &reserve($ip_addr);
		$response .= "The SUT was reserved by other hamsta master already, and the reserved master ip was $Slave::reserved_hamsta_master_ip!\n" if ( $response =~ /failed/ );
		print $sock $response;
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

    if( $@ ) {
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
    our $job_sock_stat;
    our $sock_broken_job_proc;

    #time out monitor start.
    my $sut_timeout=0;
    #find out time out value.
    my $fork_re = fork ();
    if($fork_re==0) {
	#in child, start to work;

	$SIG{'PIPE'} = \&deal_with_broken_job_sock_child;
	our $sock_just_broke_sign = 'no';

	#close share socket in child
	#keep JOB_CHILD to communicate with parent proc
	close JOB_PARENT;

	&command("/usr/share/qa/tools/sync_qa_config $ip_addr");
	my $pid_main = open (FILE, "/usr/bin/perl Slave/run_job.pl $filename 2>&1|");
	my $count = 0;
	my $msg_from_parent;
	our $job_log_fh;
	my $log_line;
        while ($log_line = <FILE>) {
	    chomp $log_line;
	    #bug 615911
	    next if ($log_line =~ /A thread exited while \d+ threads were running/);
	    #reinstall job will reboot the machine
	    if( $log_line =~ m@RETURN\s+(\d+)\s+\(/usr/share/qa/tools/setupgrubforinstall(.*)@ ) {
		my $ret = $1;
		my $cmdopt = $2;
		print $sock $log_line."\n";
		if( $ret == 0 ) {
		    &reinst_kexec($sock) if( grep(/kexecboot/,$cmdopt) );
		    &reinst_grub($sock);
		}
	        last;
	    }
	    #expection for the hamsta to reboot. not the job code to reboot;
	    if ($log_line =~ /RETURN/ && $xml_job =~ /<command\s+execution.*__hamsta_reboot/) {
		$log_line =~ s/\d+\s+\(/0 \(/;
	        print $sock $log_line."\n";
	        &reinst_grub($sock);
	        last;
	    }
	    &log(LOG_DETAIL, '%s', $log_line);

	    #check msg from parent whether job sock connection restored
	    if(read(JOB_CHILD,$msg_from_parent,1024)){
		chomp $msg_from_parent;
	        log(LOG_NOTICE,"Job child process received message from parent proc: $msg_from_parent");
		if($msg_from_parent =~ /Recovered job sock: *([^ ]+) *$/){
		    log(LOG_NOTICE,"Job child process will continue to send log to sock directly!");
		    $job_sock_stat = 'recovered';
		    close $job_log_fh;
		    undef $job_log_fh;
		    #Notify parent proc about finish dealing with the recovery notification
		    print JOB_CHILD "Job child proc connection recovery handling is done!\n";
		    log(LOG_NOTICE,"Job child process send to parent: Job child proc connection recovery handling is done!");
		}elsif($msg_from_parent =~ /The recovered job socket met error again!/){
		    log(LOG_NOTICE, "Job child process will start to store job log to local file!");
		    &deal_with_broken_job_sock_child;

		}

	    }
	    #store log
	    if ($job_sock_stat eq 'abnormal'){
                #write job log to log file
		print $job_log_fh $log_line."\n";
		log(LOG_DETAIL,"Job child process store job log to local file : $log_line");
	    }elsif($job_sock_stat eq 'recovered'){
		#send job log to parent proc to transfer to the recovered sock
		print JOB_CHILD $log_line."\n";
		log(LOG_DETAIL,"Job child process send in-time log to parent : $log_line");
	    }else{
		    #send log to sock when sock is normal, otherwise error handling
		    eval{
		    	    print $sock $log_line."\n" || log(LOG_ERROR,"Can not write to job sock!");
		    };
		    #deal with errors, SIGPIPE can not be handled here
		    if ($@){
			        log(LOG_ERR, "Job child process: $@");
				&deal_with_broken_job_sock_child;
		    }else{
			    log(LOG_DETAIL,"Job socket is normal, send to sock log: $log_line");
		    }

		    if($sock_just_broke_sign eq 'yes'){
			    print $job_log_fh $log_line."\n" if ($job_log_fh);
			    $sock_just_broke_sign = 'no';
		    }
	    }

	    $count++ if ($_ =~/\<job\>$/ );
	    last if ($count == 2);
	}
	close FILE;
	&log(LOG_NOTICE, "Job finished.");
	&log(LOG_INFO, "job sock stat is : $job_sock_stat");
	if ($job_sock_stat eq 'recovered'){
		print JOB_CHILD RFINISH."\n";
	}elsif($job_sock_stat eq 'abnormal'){
		print $job_log_fh RFINISH."\n" || log(LOG_ERROR, "Print to log file failed: ".RFINISH);
		close $job_log_fh;
	}else{
		print $sock RFINISH."\n";
	}
	&log(LOG_INFO, "Job ist ferting is logged!");

	$| = 1;
	JOB_CHILD->autoflush(1);

	unlink $filename;
	$SIG{'PIPE'} = 'IGNORE';
	close JOB_CHILD;

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
	    my $msg_from_job_child;
	    while ($current_time < $sut_timeout) {
		    goto OUT if(waitpid($fork_re, WNOHANG));

		    if (read(JOB_PARENT,$msg_from_job_child,1024)){
			    # get msg from job child process
			    chomp $msg_from_job_child;
			    log(LOG_NOTICE, "Job parent process received msg from job child process: $msg_from_job_child");
			    if ($msg_from_job_child =~ /Job sock is abnormal in child proc: *([^ ]+) *$/){
				    #job child process socket is abnormal
				    $job_sock_stat = 'abnormal';
				    $sock_broken_job_proc = $1;
				    print JOB_PARENT "Finish dealing with socket error on job socket by slave-server!\n";
				    log(LOG_NOTICE,"Job parent process sent to job child process: Finish dealing with socket error on job socket by slave-server!");
				    goto OUT;
			    }
		    }
		    #Set round timer shotter to detect sock error ASAP
		    sleep 1;
		    $current_time += 1;

	    }
	    #timeout
	    &log(LOG_ERROR, "TIMEOUT,please logon SUT check the job manually!");
	    &log(LOG_NOTICE, "Job TIMEOUT.");
	    print $sock "TIMEOUT running $sut_timeout seconds ,time is up \n";
	    print $sock "Please logon SUT check the job manually!\n";
	    print $sock RFINISH;
OUT:
    }else{
#fork error ;
	    &log(LOG_ERROR, "Fork error,exit");
	    &log(LOG_NOTICE, "Job finished.");
	    print $sock RFINISH;
    }
}

#The function is to handle the scenario that job socket is detected to be broken
#in the process(child) that running the real job code
sub deal_with_broken_job_sock_child() {
    our $job_sock_stat;
    our $job_log_fh;
    our $sock_just_broke_sign;
    log(LOG_NOTICE,"IN SIGPIPE SIGNAL HANDLING FUNC OF JOB CHILD PROCESS!");
    log(LOG_NOTICE,"Job child process socket is abnormal, it will store log to local file:".JOB_LOG_FILE);
    log(LOG_NOTICE,"Job child process set job socket status to: abnormal!");
    $sock_just_broke_sign = 'yes';
    $job_sock_stat = 'abnormal';
    print JOB_CHILD "Job sock is abnormal in child proc: $$\n";
    log(LOG_NOTICE,"Job child process sent to parent: Job sock is abnormal in child proc:");
    #wait for slave-server process finish dealing with the socket error
    my $msg_from_parent;
    while(not read(JOB_CHILD,$msg_from_parent,1024)
	  or $msg_from_parent !~ /Finish dealing with socket error on (recovered )*job socket by slave-server!/){
        sleep 1;
    }
    log(LOG_NOTICE,"Job child proc received notification from parent that it finished dealing with socket error!");
    close $job_log_fh && undef $job_log_fh if $job_log_fh;
    open($job_log_fh,">>".JOB_LOG_FILE) || log(LOG_ERROR,"Can not open ".JOB_LOG_FILE." for logging!");
}

#The function is to handle the scenario that the re-connected/recovered job socket is detected
#to be broken in the slave-server process(parent).
#It ensures the local log file keeps all lines of logs that are not transmitted back to recovered job socket
sub deal_with_broken_job_sock_parent() {
    our $transfered_local_job_log_line;
    our $finish_local_job_log_trans;
    our $job_sock_stat;
    my $local_log_file = JOB_LOG_FILE;
    log(LOG_NOTICE,"IN SIGPIPE SIGNAL HANDLING FUNC OF PARENT: SLAVE-SERVER PROCESS!");
    $job_sock_stat = 'abnormal';
    #Notify the job child proc about the socket error on the recovered job sock
    print JOB_PARENT "The recovered job socket met error again!\n";
    log(LOG_NOTICE,"Job parent process sent to child: The recovered job socket met error again!");

    our $local_log_fh;
    #only have one file handler open to the local log file
    close $local_log_fh;

    #deal with not transferred back to master local stored job log
    if($finish_local_job_log_trans eq 'no'){
        #remove lines that are already transmitted back from local job log file
	system("sed -i \"1,$transfered_local_job_log_line d\" $local_log_file");
	log(LOG_NOTICE, "Slave-server:: finish deleting $transfered_local_job_log_line transferred log lines from local job log!");
	$transfered_local_job_log_line = 0;
    }

    #deal with not transferred back to master in-time log
    my $msg_from_job_child;
    open($local_log_fh, ">>".JOB_LOG_FILE) || log(LOG_ERROR,"Can not open ".JOB_LOG_FILE." for logging!");
    while(1){
	log(LOG_DEBUG, "Slave-server:: IN deal_with_broken_job_sock_parent loop for child reply abnormal happened");
	if( not read(JOB_PARENT,$msg_from_job_child,1024)){
	    sleep 1;
	    next;
	};
    	chomp $msg_from_job_child;
    	#The last message from child job proc in the JOB_PARENT after socket meets error
    	if ($msg_from_job_child =~ /Job sock is abnormal in child proc: *([^ ]+) *$/) {
	    log(LOG_NOTICE, "Slave-server:: finish storing not transferred back real-time log!");
	    close $local_log_fh;
	    last;
    	}else{
    	    print $local_log_fh $msg_from_job_child."\n";
    	    log(LOG_DETAIL, "Slave-server:: store to local job log file in-time log: $msg_from_job_child");
        }
    }
    print JOB_PARENT "Finish dealing with socket error on recovered job socket by slave-server!\n";
    log(LOG_NOTICE,"Slave-server:: Finish dealing with socket error on recovered job socket by slave-server!\n");
    #Recover the file handler to local log file
    open $local_log_fh, "<".JOB_LOG_FILE;
    #Give enough time for socketpair communicate messages, without this, child proc sometimes can not get msg:
    #"The recovered job socket met error again!"
    sleep 3;
}



# deconstruct()
# Does some cleanup (TODO well, at least it should do so...)
sub deconstruct() {
    exit 0;
}


1;

