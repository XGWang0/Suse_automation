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
#

package Master;

use strict;
use warnings;

use IO::Socket::INET;
use IO::Select;
use MIME::Lite;
use MIME::Base64;
use Proc::Fork;
use sql;
use functions;
use POSIX 'strftime';
use hwinfo_xml_sql;
use XML::Simple;
use cmdline;

use qaconfig('&get_qa_config');
%qaconf = ( %qaconf, &get_qa_config('hamsta_master') );

use sql;
use db_common;
our $dbc;

$log::loglevel = $qaconf{hamsta_master_loglevel_job} if $qaconf{hamsta_master_loglevel_job};
$log::loginfo = 'job';

our $job_ref;
our $sub_procs;
our %machine_sock;

sub process_job($)
{
	my $job_id = shift;

	#query all information into $job_ref;
	&build_ref($job_id);
	&log_add_output(path=>$qaconf{'hamsta_master_root'}."/job.$job_id.log", unlink=>1, bzip2=>0);
	$log::loginfo = "job_$job_id";

	#split parts from whole job
	my $all_parts = &split_part();


	#set machine busy
	&set_machine_busy(1);
	&reserve_or_release_all("reserve");

	#Do the work for each part

	foreach my $sub_part (@$all_parts)
	{


		%machine_sock = ();

		&connect_all($sub_part);

		&send_xml($sub_part);

		&deploy($sub_part);

	}

	#mark the whole job result

	&mark_job_result($job_id);

	#release the machine
	&set_machine_busy(0);
	&reserve_or_release_all("release");

	#send the email

	&send_email($job_id);

}


sub set_machine_busy($)
{
	my $status = shift;

	&TRANSACTION('machine');
	foreach my $machine_id (keys %{$job_ref->{'aimed_host'}} ) 
	{
	    &machine_set_busy($machine_id,$status);
	}
	&TRANSACTION_END;

}

sub send_email()
{
	my $job_id = shift;
	my $user_id = $job_ref->{'user_id'};
	my $job_owner = &user_get_email_by_id($user_id);
	my $email = &dump_job_xml_config($job_ref->{'job_file'},"mail");
	$job_owner = ($job_owner)?$job_owner:$email;
	my $mailtype = "TEXT";

	my $message = "The job result for:" . $job_ref->{'job_name'} ;
	my $status = ($job_ref->{'result'})?"PASS":"FAILED";
	my $data = "\nStatus : $status\n For detail information refer to http://" . $job_ref->{'master_ip'} . "/hamsta/index.php?go=job_details&id=$job_id \n";
	
	my $msg = MIME::Lite->new(
		From => ($qaconf{hamsta_master_mail_from} || 'hamsta-master@suse.de'),
		To => $job_owner,
		Subject => $message,
		Type => $mailtype,
		Data => $data
	);
	
	my @args=('smtp');
	if( $qaconf{hamsta_master_smtp_relay} )
	{
		push @args, $qaconf{hamsta_master_smtp_relay};
		if($qaconf{hamsta_master_smtp_login})
		{
			push @args, (AuthUser=>$qaconf{hamsta_master_smtp_login}, ($qaconf{hamsta_master_smtp_password} ? (AuthPass=>$qaconf{hamsta_master_smtp_password}) : ()))   
		}else
		{
			@args=('sendmail');
		}
		if ($job_owner =~ /@/){ 
			$msg->send(@args) ;
			&log(LOG_DETAIL, "Mail sending done");
		}
	}
}


sub mark_job_result ($)
{
	&log(LOG_INFO,"Start to count the part result!");
	my $job_id = shift;

	&build_ref($job_id);

	foreach my $part_id (keys %{$job_ref->{'mm_jobs'}})
	{
		foreach my $jpm_id ( keys %{$job_ref->{'mm_jobs'}->{$part_id}})
		{

			if($job_ref->{'mm_jobs'}->{$part_id}->{$jpm_id}->[3] != JS_PASSED)
			{	
				#set job status JS_FAILED
				&TRANSACTION( 'job');
				&job_set_status($job_id,JS_FAILED);
				&TRANSACTION_END;
				$job_ref->{'result'} = 0;
				return;
			}

		}
	}

	#set job status JS_PASSED

	&TRANSACTION( 'job');
	&job_set_status($job_id,JS_PASSED);	
	&TRANSACTION_END;
	$job_ref->{'result'} = 1;
}

#1. xml file 2.name  3. vaule
sub modify_job_xml_config($$$) 
{
	my $job_xml = shift;
	my $name = shift;
	my $value = shift;
	my $job_xml_ref = XMLin($job_xml,
	                        ForceArray=>1,
	                        KeyAttr=>{ role => 'name'},
				);
	if(not $job_xml_ref){
		&log(LOG_ERR,"Can Not parser XML File !");
		return undef;
	}
	#TODO : better mail handle. or remove the notify
	if($name eq 'mail'){
		$job_xml_ref->{'config'}->[0]->{$name}->[0]->{'content'} = $value;
	}else{
		$job_xml_ref->{'config'}->[0]->{$name} = [ $value ];
	}
	$job_xml_ref->{'config'}->[0]->{$name} = [ $value ];
	open my $xmlfd,'>',$job_xml or &log(LOG_ERR,"Can Not Open XML File For Write !");
	my $out = XMLout($job_xml_ref,
	                 RootName => 'job',
			 XMLDecl => '1',
			 KeyAttr=>{ role => 'name'},
			);
	print $xmlfd $out;
	close $xmlfd;
}

sub dump_job_xml_config($$)
{
	my $job_xml = shift;
	my $option = shift;
	return undef if(not $option);
	my $job_xml_ref = XMLin($job_xml,ForceArray=>0);
	#TODO : better mail handle. or remove the notify
	if($option eq 'mail') {
		return $job_xml_ref->{'config'}->{$option}->{'content'} if defined($job_xml_ref->{'config'}->{$option}->{'content'});
		return undef;
	}
	return $job_xml_ref->{'config'}->{$option} if defined($job_xml_ref->{'config'}->{$option});
	return undef;
}


sub process_job_part_on_machine ($$$)
{

	&sql_get_connection();

	my $machine_id = shift;
	my $job_part_on_machine_id = shift;
	my $job_on_machine_id = shift;
	my $job_file = shift ;
	my $reboot = shift;
	my $job_name = $job_ref->{'job_name'} ;

	my ($ip,$hostname) = &machine_get_ip_hostname($machine_id);

	&log(LOG_DETAIL, "start to process job on machine: machine_id:$machine_id,job_on_machine_id:$job_on_machine_id,job_part_on_machine_id:$job_part_on_machine_id"); 
	#$log::loginfo = 'job_'.$job_id.'_'.$hostname;


	# Mark the job as started
	&TRANSACTION( 'job_on_machine','job_part_on_machine');
	&job_on_machine_set_status($job_on_machine_id,JS_RUNNING);
	&job_part_on_machine_start($job_part_on_machine_id);
	&TRANSACTION_END;

	# Open the XML result file for writing
	# Create the directory for the host, if it does not exist
	my $response_xml = $qaconf{'hamsta_master_root'}."/$hostname/Job_return_".$job_part_on_machine_id;
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
	my $return_codes="";
	my $submission_link;
	my @message_queue = ();
	my @summary = ();
	my @result_link = ();
	my %parsed;
	my $is_xml = 0;

	$| = 1;
	$dbc->commit();
	my $sock = $machine_sock{$ip};
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
				$parsed{'zone'} = strftime "%z", localtime;
			}
			if( $parsed{'zone'} )   {
				# no DB locking necessary
				$parsed{'time'} = &convert_timezone($parsed{'time'},$parsed{'zone'});
			}
			&TRANSACTION( 'log' );
			&log_insert(
				$machine_id,
				#$job_on_machine_id,
				$job_part_on_machine_id,
				$parsed{'time'},
				$parsed{'level'},
				'', # username - we can fix later
				defined($parsed{'info'}) ? $parsed{'info'}:'',
				$parsed{'text'}
			);
			&TRANSACTION_END;

			if ($parsed{'text'} =~ /kexecboot/ and $parsed{'level'} eq 'RETURN') {
				&log(LOG_NOTICE, "$hostname: Job ($job_file) exits with ".$parsed{'text'}); 
				$return_codes .= $parsed{'text'}."\n";
				last;
			}

			if ($parsed{'level'} eq 'RETURN')	{
				&log(LOG_NOTICE, "$hostname: Job ($job_file) exits with ".$parsed{'text'}); 
				$return_codes .= $parsed{'text'}."\n";
			}	

			if ($parsed{'text'} =~ /Please logon SUT check the job manually/)	{
				&log(LOG_NOTICE, "$hostname: TIMTOUT Job ($job_file)" ); 
				$return_codes .= "6\n";
			}	


			push @summary,$1 if $parsed{'text'} =~ /^\| (.*)$/;
			push @result_link,$1 if $parsed{'text'} =~ /(http:.*qadb\/submission\.php\?submission_id=\d+)/;
		}
	}
	close($sock);
	close FH;
	
	&log(LOG_DETAIL, "job done, updating status info");

	#&TRANSACTION( 'job_on_machine','machine' );
	#&job_on_machine_set_return($job_on_machine_id,$return_codes);
	#&job_on_machine_set_summary($job_on_machine_id,join("\n",@summary)) if (@summary);
	#&job_on_machine_set_result_link($job_on_machine_id,join("\n",@result_link)) if (@result_link);
	#&machine_set_busy($machine_id,0);
	#&TRANSACTION_END;

	my $message = "$job_name completed on $hostname";
	my $status=JS_FAILED;

	#get the final return value
	foreach my $ret ( split /\n/, $return_codes )
	{	$status=JS_PASSED if $ret=~/^(\d+)/ and $1==0;	}

	my $update_sut = 0;
	if( $reboot ) {
		if($status == JS_PASSED){
			sleep 120;
                        $message = "reinstall\/reboot $hostname completed";
			&machine_status_timeout(120,$machine_id,$hostname,$status,$message); #Timeout for 2 Hours
		}

	} elsif($update_sut) {

		if($status == JS_PASSED){
			sleep 120;
			&machine_status_timeout(10,$machine_id,$hostname,$status,$message); #Timeout for 10 Mins;
		}

	} else {
		1 == 1;
	}
	# Mark the job as finished
	&TRANSACTION( 'job_on_machine', 'job_part_on_machine' );
	&job_on_machine_stop($job_on_machine_id);
	&job_part_on_machine_stop($job_part_on_machine_id, $status);
	&TRANSACTION_END;
	$dbc->commit();
	
}









sub build_ref($)
{
	#build the job_ref;

	my $job_id = shift;
	my ($job_file, $user_id, $job_name, $job_status_id,$aimed_host) = &job_get_details($job_id) ;
	$job_ref->{'job_file'} = $job_file ;
	$job_ref->{'user_id'} = $user_id ;
	$job_ref->{'job_name'} = $job_name ;
	$job_ref->{'job_status_id'} = $job_status_id ;

	foreach my $machine_ip ( split /[\s,]+/,$aimed_host )
	{
		next unless ($machine_ip);
		my $machine_id = &machine_get_by_ip($machine_ip);
		$job_ref->{'aimed_host'}->{$machine_id} = $machine_ip ;

	}

	

	my @parts = &job_part_get_ids_by_job_id($job_id);
	my @job_on_machine_id = &job_on_machine_list($job_id);
	
	foreach my $part (@parts) {
	
		foreach my $jomid (@job_on_machine_id) {
			
			my ($xml,$job_part_on_machine_id,$status,$does_reboot) = &job_part_info_get_by_pid_jomid($part,$jomid);
			$job_ref->{'mm_jobs'}->{$part}->{$jomid} = [$xml,$job_part_on_machine_id,$jomid,$status,$does_reboot] if ($xml);

		}


	}

}

sub split_part()

{
	my @part_machines_xml;

	my @parts =	sort { $a <=> $b } keys %{$job_ref->{'mm_jobs'}};

	foreach my $part ( @parts )
	{
		
		my @job_on_machine_ids = keys %{$job_ref->{'mm_jobs'}->{$part}};

		my $part_ref ;
		
		map { my $machine_id = &job_on_machine_get_machine($_) ; $part_ref->{$machine_id} = $job_ref->{'mm_jobs'}->{$part}->{$_}; } @job_on_machine_ids;
		
		push @part_machines_xml,$part_ref;

	}

	return \@part_machines_xml;


}




sub connect_all ($)
{
	my $sock_canread = IO::Select->new();
	my $sub_job_part = shift;
	my @machine_ids = keys %$sub_job_part;
	my @m_ips = map { $job_ref->{'aimed_host'}->{$_} } @machine_ids;

	foreach my $ipaddr (@m_ips)
	{
		$machine_sock{$ipaddr} = &creat_connection($ipaddr);
		if(defined $machine_sock{$ipaddr})
		{
			$sock_canread->add($machine_sock{$ipaddr}) ;
		}else{
			&log(LOG_ERROR, "Can not create connection to $ipaddr"); 
			&set_fail_release();
			return 0;
		}
	
	}
	# send ping to sut ,and check the return value
	
	foreach (keys %machine_sock)
	{
		#send ping to SUT 
		my $tmpsock = $machine_sock{$_};
		print $tmpsock "ping\n";
	}
	
	#set a sync timeout 
	my $timeout = 100;
	for my $temp_ca (1 .. $timeout)
	{
		#check available connection
		my @available_machines = $sock_canread->can_read();
		if(@available_machines == @m_ips)
		{
			foreach (keys %machine_sock)
			{
				my $tmpsock = $machine_sock{$_};
				my $empty = <$tmpsock>;
				my $ping_ack = <$tmpsock>;
				chomp($ping_ack);
				if($ping_ack ne "pong")
				{
					&log(LOG_ERROR, "Can not get ping ACK from  $_ ,Got $ping_ack "); 
					&set_fail_release();
					return 0 ;
				}
			}
			return 1;
	
		}
	sleep 3; 
	}

	&log(LOG_ERROR, "Timeout to sync all machines :$@");
	&set_fail_release();
	return 0;

}



sub send_xml($)
{

	my $sub_job_part = shift;
	my @machine_ids = keys %$sub_job_part;

	foreach my $mid (@machine_ids)
	{
		my $ip = $job_ref->{'aimed_host'}->{$mid};
		my $xmlfile = $sub_job_part->{$mid}->[0];

		# Pass the XML job description to the slave
			
		open (FH,'<',"$xmlfile");
			
		while (<FH>) 
		{ 
			$_ =~ s/\n//g;
			eval {
			&log(LOG_DETAIL, "Sent XML: $_");
			$machine_sock{$ip}->send("$_\n");
			};
			if ($@) {
				&log(LOG_ERR, "PROCESS_JOB: send_job: $@");
				#mark the result and remove the failed job ;
				&TRANSACTION( 'job_part_on_machine');
				&job_part_on_machine_set_status( $sub_job_part->{$mid}->[1],JS_FAILED); 
				&TRANSACTION_END;
				delete $sub_job_part->{$mid};
				last;
			}
		}
			close FH;
			
			# Return the result and log level.
			&log(LOG_INFO,"PROCESS_JOB: send xml: $xmlfile to $ip succeed");
	}
	

}


sub deploy()
{

	local $SIG{'CHLD'} = sub { $sub_procs--; };
	my $sub_job_part = shift;
	$sub_procs =  scalar keys %$sub_job_part;
	my @sub_pid;

	$dbc->{'dbh'}->disconnect();
	undef $dbc;

	#start use fork
	foreach(keys %{$sub_job_part})
	{
		child {
			my $job_part_on_machine_id = $sub_job_part->{$_}->[1];
			my $job_on_machine_id = $sub_job_part->{$_}->[2];
			my $job_part_on_machine_xml = $sub_job_part->{$_}->[0];
			my $job_reboot = $sub_job_part->{$_}->[4];
			&process_job_part_on_machine($_,$job_part_on_machine_id,$job_on_machine_id,$job_part_on_machine_xml,$job_reboot);
			exit 0;
		}
		parent {
			push(@sub_pid,shift);
		};
	}
		
	
	&sql_get_connection();
	&log(LOG_NOTICE, "Going to check timeout"); 

	#get time of job 
	my $timeout = 1000000; #should read from database;
	my $init =0;

	while($init <= $timeout)
	{
		sleep 3;
		$init++;
		if($sub_procs == 0)
		{
			#Need mark the result at the end of job, not the job part

			#call waitpid to clean the process table
			for(@sub_pid)
			{
				waitpid($_,0);
			}
			&log(LOG_NOTICE, "Part job DONE"); 
			return;
		}

	}

	# TIMEOUT 
	# which means SUT could NOT able to release the connection
	# which means SUT could NOT able to receive the job;
	# maybe we should exit and mark fail of whole job.

	&log(LOG_ERROR, "Timeout the Job ");
		

}

sub creat_connection {
	
	my $ip = shift;
	my $port = $qaconf{hamsta_client_port};
	my $sock;

	eval { 
		$sock = IO::Socket::INET->new(
		PeerAddr => "$ip",
		PeerPort => $port,
		Proto	=> 'tcp'
		);
	};
	if(!$sock || $@) {
		&log(LOG_ERROR, "Can not connect to ip '$ip' port '$port' :$@ $! ");
		return undef;
	}

	$job_ref->{'master_ip'} = $sock->sockhost() unless(defined($job_ref->{'master_ip'}));

	return $sock;
}

# 'reserve' | 'release'
sub reserve_or_release_all ($)
{
	my $action = shift;
	my @m_ips = values %{$job_ref->{'aimed_host'}};
	my @success_ips;
	my $orig_reserve_stat = {};
	foreach my $ip (@m_ips){
		my $reserved_master_id = &machine_get_hamsta_master_id_by_ip($ip);
		$orig_reserve_stat->{$ip} = ((defined $reserved_master_id)? 1: 0);
		my $ret = &Master::process_hamsta_reservation(undef,$action, $ip);
		if (! $ret){
			if ($action =~ /reserve/){
				&log(LOG_ERR, "PROCESS_JOB: Reserve all SUT before sending job xml failed when reserving $ip!");
			}elsif($action =~ /release/){
				&log(LOG_ERR, "PROCESS_JOB: Release all SUT failed when releasing $ip!");
			}
			#Revert the action, only do once in case cycle revert.
			my $revert_result = 1;
			my $revert_action = (($action =~ /reserve/)?'release':'reserve');
			my @revert_failed_ips;
			foreach my $revert_ip (@success_ips){
				next if (($action =~ /reserve/ and $orig_reserve_stat->{$revert_ip}) or 
				         ($action =~ /release/ and !$orig_reserve_stat->{$revert_ip}));
				&log(LOG_DETAIL, "PROCESS_JOB: Reverting action \"$action\" on $revert_ip...");
				my $ret = &Master::process_hamsta_reservation(undef,$revert_action, $revert_ip);
				push @revert_failed_ips, $revert_ip if not $ret;
				$revert_result &= $ret;
			}
			if ($revert_result){
				&log(LOG_NOTICE, "PROCESS_JOB: Revert action \"$action all SUT\" for this job succeeded!");
			}else{
				&log(LOG_ERR, "PROCESS_JOB: Revert action \"$action all SUT\" for this job failed on ".join(',',@revert_failed_ips)."!");
			}
			return 0;
		}
		push @success_ips,$ip;
	}
	&log(LOG_INFO,"PROCESS_JOB: $action all SUT succeeded!");
	return 1;
}

sub set_fail_release()
{
	#Set Fail
	&TRANSACTION( 'job_on_machine', 'job_part_on_machine' );
	foreach my $part (keys %{$job_ref->{'mm_jobs'}} )
	{
	        foreach my $jomid (keys %{$job_ref->{'mm_jobs'}->{$part}}) 
	        {
			my $job_part_on_machine_id = $job_ref->{'mm_jobs'}->{$part}->{$jomid}->[1];
			&TRANSACTION( 'job_on_machine', 'job_part_on_machine' );
			&job_on_machine_stop($jomid);
			&job_part_on_machine_stop($job_part_on_machine_id,JS_FAILED);
         	}

	}
	&TRANSACTION_END;
	$dbc->commit();


	&TRANSACTION('machine');
	foreach my $machine_id (keys %{$job_ref->{'aimed_host'}} ) 
	{
	    &machine_set_busy($machine_id,0);
	}
	&TRANSACTION_END;
	&log(LOG_NOTICE, "PROCESS_JOB: Set job failed and release the machine");

	exit 1;


}
unless(defined($ARGV[0]) and $ARGV[0] =~ /^(\d+)$/)
{
	print STDERR "Usage : $0 <job ID>\n";
	exit;
}


&sql_get_connection();
&process_job($ARGV[0]);

