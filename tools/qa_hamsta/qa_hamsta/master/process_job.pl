#!/usr/bin/perl
# ****************************************************************************
# Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
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

package Master;

use strict;
use warnings;

use IO::Socket::INET;
use IO::Select;
use MIME::Lite;
use MIME::Base64;
use sql;
use functions;
use POSIX 'strftime';
use hwinfo_xml_sql;

use qaconfig('%qaconf','&get_qa_config');
%qaconf = ( %qaconf, &get_qa_config('hamsta_master') );

use sql;
use db_common;
our $dbc;


$log::loglevel = $qaconf{hamsta_master_loglevel_job} if $qaconf{hamsta_master_loglevel_job};
$log::loginfo = 'process_job';

$SIG{'HUP'} = 'IGNORE';
$SIG{'INT'} = 'IGNORE';


# process_job(job_id)
#
# Sends a job to one (TODO: or more) slaves, gathers the slave output and 
# writes it to the database.
#
# The processing of a job is designed to be run as a seperate process because
# jobs are potentially long-running. It is even likely that there will be
# periods when the master is processing jobs all the time.
#
# It might be necessary, though, to restart the master, e.g. in case of a
# bug fix update. As the processing of jobs runs in independent processes,
# the master can be shut down and restarted while the jobs still are processed 
# and their data is correctly written to the database.
# 
# $job_id		   ID of the job (TODO This should be the ID of job_on_machine)
sub process_job($) {
	my $job_id = shift @_;

	&log_add_output(path=>$qaconf{'hamsta_master_root'}."job.$job_id.log", unlink=>1, bzip2=>0);
	$log::loginfo = "proc_job_$job_id";

	&log(LOG_NOTICE, "Processing job $job_id");
	# TODO: this only reads the first matching row
	# but we should process all assigned machines here.
	my $data = &job_on_machine_get_by_job_id($job_id);
	if( !@$data )
	{
		&log(LOG_ERR, "PROCESS_JOB: no such job with ID $job_id");
		return;
	}
	my ($job_on_machine_id,$machine_id) = @{$data->[0]};
	my ($job_file, $job_owner, $job_name) = &job_get_details($job_id);
	my ($ip, $hostname) = &machine_get_ip_hostname($machine_id);
	&log(LOG_NOTICE,"PROCESS_JOB: process_job: $hostname using XML job description in $job_file");

	# Send the job to the slave
	my $sock;
	($sock, $log::loglevel) = &send_job($ip, $job_file,$job_id);
	if (not defined($sock)) {
		&log(LOG_ERR,"PROCESS_JOB: process_job: Could not open socket. Job failed.");

		&TRANSACTION( 'job_on_machine' );
		foreach my $jom_id( &job_on_machine_list($job_id) )
		{	&job_on_machine_set_status($jom_id, JS_QUEUED);	}
		&TRANSACTION_END;
		return;
	}


	# Mark the job as started
	&TRANSACTION( 'job_on_machine' );
	&job_on_machine_start($job_on_machine_id);
	&TRANSACTION_END;

	# Open the XML result file for writing
	# Create the directory for the host, if it does not exist
	my $response_xml = $qaconf{'hamsta_master_root'}."/$hostname/Job_return_".$job_id;
	&change_working_dir($qaconf{'hamsta_master_root'}."/$hostname");

	&log(LOG_INFO,"SEND_JOB_TO: Saving results in $response_xml");
	open FH,'>', $response_xml or &log(LOG_WARNING, "SEND_JOB_TO: Could not open XML result file for job. $!");

	# Read all the stuff sent by the slave
	#
	# $return_codes	 contains the return codes of all commands of the job 
	#				   (each on one line)
	#				   
	# @message_queue	contains the last few lines of output of the job (for 
	#				   Last Output in the Frontend)
	#				   
	# $is_xml		   true if the XML result has started (The slave outputs 
	#				   raw ASCII output first when the commands are running.
	#				   Afterwards the XML result is sent.)
	my $return_codes;
	my $submission_link;
	my @message_queue = ();
	my @summary = ();
	my %parsed;
	my $is_xml = 0;

	$| = 1;
	$dbc->commit();
	while (<$sock>) {
		my $line = $_;
		$line =~ s/\n//g;
		next if $line =~ /^\s*$/;
		&log(LOG_DETAIL, "$hostname: $line");
		$is_xml=1 if $line =~ /<job/;
		# This switch will keep on in the whole sock once meet <job, until next call of process_job. So the entire of job xml will go into FH.
		last if ($line =~ /^Job ist fertig$/);
		if ($is_xml) {
			print FH $line."\n";
		} else {
			if ($line =~ /submission_id=/) {
				$submission_link .= (split(/ /, $line))[-1]."\n";
				&log(LOG_NOTICE, "QADB submission link is: $submission_link");
			}
			%parsed = &parse_log($line);
			unless( %parsed and defined($parsed{'level'}) and defined($parsed{'text'}) )
			{
				%parsed=();
				$parsed{'time'} = strftime "%Y-%m-%d %H:%M:%S", localtime;
				$parsed{'level'} = 'STDOUT';
				$parsed{'info'} = 'hamsta';
				$parsed{'text'} = $line;
			}
			&TRANSACTION( 'log' );
			&log_insert(
				$machine_id,
				$job_on_machine_id,
				$parsed{'time'},
				$parsed{'level'},
				'', # username - we can fix later
				defined($parsed{'info'}) ? $parsed{'info'}:'',
				$parsed{'text'}
			);
			&TRANSACTION_END;

			if ($parsed{'text'} =~ /Start Kexec booting/) {
				&log(LOG_NOTICE, "$hostname: Job ($job_file) exits with ".$parsed{'text'}); 
				$return_codes .= $parsed{'text'}."\n";
				last;
			}

			if ($parsed{'level'} eq 'RETURN')	{
				&log(LOG_NOTICE, "$hostname: Job ($job_file) exits with ".$parsed{'text'}); 
				$return_codes .= $parsed{'text'}."\n";
			}	
			push @summary,$1 if $parsed{'text'} =~ /^\| (.*)$/;
		}
	}

	close($sock);
	close FH;
	
	&log(LOG_DETAIL, "job done, updating status info");

	&TRANSACTION( 'job_on_machine' );
	&job_on_machine_set_return($job_on_machine_id,$return_codes,$response_xml);
	&TRANSACTION_END;

	my $message = "$job_name completed on $hostname";
	my $status=JS_FAILED;

	# send e-mail that the job has finished
	my $reboot = ( $job_file =~ /install|reboot|XENGrub|hamsta-upgrade-restart/ );
	if( $reboot ) {
		sleep 300;
		while( &machine_get_status($machine_id) != MS_UP ) {		
			# wait for reinstall/reboot jobs
			$dbc->commit(); # workaround of a DBI bug that would loop the statement
			sleep 60;	
		}
		$message = "reinstall\/reboot $hostname completed";
		$status=JS_PASSED;
	} else {
		foreach my $ret ( split /\n/, $return_codes )
		{	$status=JS_PASSED if $ret=~/^(\d+)/ and $1==0;	}
	}

	# Mark the job as finished
	&TRANSACTION( 'job_on_machine', 'job' );
	my $job_old_stauts = &job_get_status($job_id);
	&job_on_machine_stop($job_on_machine_id);
	&job_set_status($job_id,$status) if $job_old_stauts == 2;
	&TRANSACTION_END;

	# send e-mail that the job has finished
	# see http://lena.franken.de/perl_hier/sendingmail.html for example on sending attachments
	if( $job_owner =~ /@/ )
	{
		&log(LOG_DETAIL, "Sending mail to '%s'", $job_owner);
		my $response = &read_xml($response_xml);
		my $data = "";
		my $mailtype = "";
		if (length($submission_link) != 0) {
			my $embedlink = $submission_link.'&embed=1';
			my $rand = int(rand(100000));
			my $subhtml = '/tmp/sub'.$rand.'.html';
			my $ret = system("wget -O $subhtml \'$embedlink\'");
			if ($ret == 0) {
				$data = `cat $subhtml`;
				system("rm -rf '$subhtml'");
				$mailtype = "text/html";
			}
			else {
				$data = "------------------------------------------------------\nPlain text mail received,please check submission link.\n------------------------------------------------------\n\n";
				goto PMAIL;
			}
		}
		else {
			PMAIL:
			$data .= "$ip job completed at ".`date +%F-%R`;
			$data .= "\nJob status:".( $status==JS_FAILED ? 'Fail' : 'Pass' )."\n";
			if( !$reboot )
			{
				`ifconfig` =~ /inet addr:([\d\.]*)\s*Bcast/;
				my $loglink = "http://$1/hamsta/index.php?go=job_details&id=$job_id";
				$data .= "Return codes: $return_codes\nLog link:\n$loglink\nQADB submission link:\n$submission_link\nSummary result:\n".join("\n",@summary);
			}
			$mailtype = "TEXT";
		}
		my $msg = MIME::Lite->new(
				From => ($qaconf{hamsta_master_mail_from} || 'hamsta-master@suse.de'),
				To => $job_owner,
				Subject => $message,
				Type => $mailtype,
				Data => $data
				);
		if( $response->{'config'}->{'attachment'} )
		{
			my $i=0;
			foreach my $att ( @{$response->{'config'}->{'attachment'}} )
			{
				next unless defined $att->{'content'};
				$msg->attach(
					Type => ($att->{'mime'} ? $att->{'mime'} : 'text/plain'),
#					Encoding => 'base64',
					Data => decode_base64($att->{'content'}),
					Filename => ($att->{'name'} ? $att->{'name'} : 'attachment'.($i++).'.txt')
				);	# anyone knowing a way how to avoid base64 reencoding?
			}
		}
		my @args=('smtp');
		if( $qaconf{hamsta_master_smtp_relay} )
		{
			push @args, $qaconf{hamsta_master_smtp_relay};
			if($qaconf{hamsta_master_smtp_login})
			{	push @args, (AuthUser=>$qaconf{hamsta_master_smtp_login}, ($qaconf{hamsta_master_smtp_password} ? (AuthPass=>$qaconf{hamsta_master_smtp_password}) : ()))	}
		}else
                {
			@args=('sendmail');
		}
		$msg->send(@args);
		&log(LOG_DETAIL, "Mail sending done");
	}
	&log(LOG_DETAIL, "job done");
}

# send_job(ip, job_file)
#
# Sends a XML job description to the client and returns both the opened socket
# on which the slave respone can be read and the debuglevel for the job.
#
# $ip			   IP of the host to which the job is to be sent
# $job_file		 Local filename of the XML job description to send
#
# Return:		   ($sock, $loglevel)
#				   $sock is the opened socket for the slave response.
#				   $loglevel is the debuglevel for the job specified in the
#				   XML job description.
sub send_job($$$) {
	my $ip = shift;
	my $job_file = shift;
	my $job_id = shift;

# Open a socket to the slave
	my $sock = IO::Socket::INET->new(
			PeerAddr => "$ip",
			PeerPort => $qaconf{hamsta_client_port},
			Proto	=> 'tcp'
			);
	my $loglevel = $log::loglevel;
	if (not defined($sock)) {
		&log(LOG_NOTICE, "PROCESS_JOB: send_job $!");
		return (undef, $loglevel);
	}

# Pass the XML job description to the slave
	open (FH,'<',"$job_file");

	#query "Used By" and "Usage" information
        my($usage,$usedby,$maintainer_id)=&machine_get_info($ip);
	while (<FH>) { 
		$_ =~ s/\n//g;

		if ($_ =~ /<debuglevel>([0-9]+)<\/debuglevel>/) {
			$loglevel = $1;
		}
		#add "Used By" and "Usage" "jobid" information

                if(/<\/config>/) {
                        $_="        <useinfo> USAGE: $usage \t USEDBY: $usedby \t MAINTAINER: $maintainer_id \t </useinfo> \n".$_ ;
                        $_="        <job_id>$job_id</job_id> \n".$_ ;
                }
		eval {
			&log(LOG_DEBUG, "Sent XML: $_");
			$sock->send("$_\n");
		};
	}
	if ($@) {
		&log(LOG_ERR, "PROCESS_JOB: send_job: $@");
		return (undef, $loglevel);
	}
	close FH;
 	#Establish ack , SUT will send a Establish sync (blank-space) once the accept() method succeed.
        my $s_canread = IO::Select->new();
	$s_canread->add($sock);
        $s_canread->can_read();
 	&TRANSACTION( 'job_on_machine', 'job' );
 	&job_set_status($job_id,JS_RUNNING);
 	&TRANSACTION_END;

# Return the socket
	return ($sock, $loglevel);
}

unless(defined($ARGV[0]) and $ARGV[0] =~ /^(\d+)$/)
{
	print STDERR "Usage : $0 <job ID>\n";
	exit;
}


&sql_get_connection();
&process_job($ARGV[0]);
$dbc->commit();

