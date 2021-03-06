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

use Data::Dumper;
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
our $job_ref;
our $sub_procs;
our %machine_sock;

$SIG{KILL} = \&set_fail_release;
$SIG{INT} = \&set_fail_release;
$SIG{TERM} = \&set_fail_release;

$log::loglevel = $qaconf{hamsta_master_loglevel_job} if $qaconf{hamsta_master_loglevel_job};
$log::loginfo = 'job';


# process_job(job_id)
#
# Sends a job to one or more slaves, gathers the slave output and 
# writes it to the database.
#
# $job_id		   ID of the job 
sub process_job($)
{
	my $job_id = shift;

	&log(LOG_NOTICE, "Processing job $job_id");

	#query all information into $job_ref;
	&build_ref($job_id);
	&log_add_output(path=>$qaconf{'hamsta_master_root'}."/job.$job_id.log", unlink=>0, bzip2=>0);
	$log::loginfo = "job_$job_id";

	#split parts from whole job
	my $all_parts = &split_part();


	#set machine busy
	&set_machine_busy(1);
	#FIXME: automatic reservation temporarily disabled for easier upgrade
	#&reserve_or_release_all("reserve");

	#Do the work for each part
	&log(LOG_DEBUG, "Processing job $job_id,job reference : " . Dumper($all_parts));

	foreach my $sub_part (@$all_parts)
	{
		&log(LOG_DEBUG, "Processing job $job_id,job sub_part reference " . Dumper($sub_part));
		%machine_sock = ();
		if(&connect_all($sub_part)){

		&send_xml($sub_part);
		&deploy($sub_part);


		}else{

			&set_fail_release("Can not get host connection");

		}
	}
	&log(LOG_DEBUG, "Done for all the sub part"  );

	#mark the whole job result
	&mark_job_result($job_id);

	#release the machine
	&set_machine_busy(0);
	#FIXME: automatic reservation temporarily disabled for easier upgrade
	#&reserve_or_release_all("release");

	#send the email, email part will be process in subprocess.
	#&send_email($job_id);

}

sub set_machine_busy($)
{
	my $status = shift;

	&TRANSACTION('machine');
	foreach my $machine_id (keys %{$job_ref->{'aimed_host'}} )	{
	    &machine_set_busy($machine_id,$status);
	}
	&TRANSACTION_END;

}

#need enhance for job detail information
sub send_email()
{
	my $job_id = shift;
	my $user_id = $job_ref->{'user_id'};
	my $job_owner = &user_get_email_by_id($user_id);
	my $email = &dump_job_xml_config($job_ref->{'job_file'},"mail");
	$job_owner = ($job_owner ? $job_owner : $email );

	# do not proceed if recipient not defined
	return unless $job_owner =~ /@/;

	&log(LOG_DETAIL, "Sending mail to '%s'", $job_owner);

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
	# FIXME: we want to send attachments, but they need to be forwarded from SUT outputs first
	#if( $response->{'config'}->{'attachment'} )
	#{
	#	my $i=0;
	#	foreach my $att ( @{$response->{'config'}->{'attachment'}} )
	#	{
	#		next unless defined $att->{'content'};
	#		$msg->attach(
	#			Type => ($att->{'mime'} ? $att->{'mime'} : 'text/plain'),
	#			Encoding => 'base64',
	#			Data => decode_base64($att->{'content'}),
	#			Filename => ($att->{'name'} ? $att->{'name'} : 'attachment'.($i++).'.txt')
	#		);	# anyone knowing a way how to avoid base64 reencoding?
	#	}
	#}
	my @args=('smtp');
	if( $qaconf{hamsta_master_smtp_relay} )
	{
		push @args, $qaconf{hamsta_master_smtp_relay};
		if($qaconf{hamsta_master_smtp_login})	{
			push @args, (AuthUser=>$qaconf{hamsta_master_smtp_login}, ($qaconf{hamsta_master_smtp_password} ? (AuthPass=>$qaconf{hamsta_master_smtp_password}) : ()))   
		}
		else	{
			@args=('sendmail');
		}
		if (defined($job_owner) and $job_owner =~ /@/){ 
			$msg->send(@args) ;
			# TODO: process return value
			&log(LOG_DETAIL, "Mail sending done");
		}
	}
}


sub mark_job_result ($)
{
	# &log(LOG_INFO,"Start to count the part result!" . Dumper($job_ref));
	my $job_id = shift;

	&build_ref($job_id);
	&log(LOG_DEBUG,"Start to count the part result! The job reference is:" . Dumper($job_ref));

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


#This function going to process the connection from SUT
#update the database require the information below
#1.machine_id
#2.job_part_on_machine_id
#3.job_on_machine_id
#4.job_part_on_machine_xml  the xml send to the	SUT
#5.job_reboot	reboot flag

sub process_job_part_on_machine ($$$$$)
{

	&sql_get_connection();

	my ($machine_id, $job_part_on_machine_id, $job_on_machine_id, $job_file, $reboot) = @_;
	my $job_name = $job_ref->{'job_name'} ;
	my $job_owner = $job_ref->{'job_owner'};
	my $job_id = $job_ref->{'job_id'};

	my ($ip,$hostname) = &machine_get_ip_hostname($machine_id);

	&log(LOG_DETAIL, "start to process job on machine: machine_id:$machine_id,job_on_machine_id:$job_on_machine_id,job_part_on_machine_id:$job_part_on_machine_id"); 
	$log::loginfo = 'job_'.$job_id.'_'.$hostname;


	# Mark the job as started
	&TRANSACTION( 'job_on_machine','job_part_on_machine');
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
	my $master_ip="";

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
	$master_ip = $sock->sockhost();
	close($sock);
	close FH;
	
	&log(LOG_DETAIL, "job done, updating status info");

	my $message = "$job_name completed on $hostname";
	my $status=JS_FAILED;

	#get the final return value
	foreach my $ret ( split /\n/, $return_codes )
	{	$status=JS_PASSED if $ret=~/^(\d+)/ and $1==0;	}

	&log(LOG_DEBUG, "Job_status is : '%s' , message: '%s'", $status,'just finish close the socket connection');

	my $update_sut = 0;
	if( $reboot ) {
		if($status == JS_PASSED){
			&log(LOG_INFO, "reboot time check, status should be pass Job_status is : '%s' , message: '%s', reboot flag is '%s'", $status,$message,$reboot);
			sleep 360;
                        $message = "reinstall\/reboot $hostname completed";
			($status,$message) = &machine_status_timeout(120,$machine_id,$hostname,$status,$message); #Timeout for 2 Hours
		}

	} elsif($update_sut) {

		if($status == JS_PASSED){
			sleep 360;
			($status,$message) = &machine_status_timeout(60,$machine_id,$hostname,$status,$message); #Timeout for 1 Hours;
		}

	} else {
		1 == 1;
	}
	&log(LOG_DEBUG, "Finished timeout check,Job_status is : '%s' , message: '%s', reboot flag is '%s'", $status,$message,$reboot);
	# Mark the job as finished
	&TRANSACTION( 'job_on_machine', 'job_part_on_machine' );
	&job_part_on_machine_stop($job_part_on_machine_id, $status);
	&TRANSACTION_END;
	$dbc->commit();
	&log(LOG_DEBUG, "After mark job_part_on_machine ,Job_status is : '%s' , message: '%s', reboot flag is '%s'", $status,$message,$reboot);

	#start to process email

	if( defined($job_owner) and $job_owner =~ /@/ )
	{
		&log(LOG_DETAIL, "Sending mail to '%s'", $job_owner);
		my $response = &read_xml($job_file);
		my $data = "";
		my $mailtype = "";
		if (defined($submission_link) and length($submission_link) != 0) {
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
			$data .= "$job_name on HOST:$hostname ( $ip ) completed at ".`date +%F-%R`;
			$data .= "\nJob status:".( $status==JS_FAILED ? 'Fail' : 'Pass' )."\n";
			if( !$reboot )	{
				my $loglink = "http://$master_ip/hamsta/index.php?go=job_details&id=$job_id";
				$data .= "Return codes: $return_codes\nLog link:\n$loglink\nSummary result:\n".join("\n",@summary);
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


}


sub build_ref($)
{
	#build the job_ref;

	my $job_id = shift;
	my @data = &job_get_details($job_id) ;
	if( !@data )
	{
	    &log(LOG_ERR, "PROCESS_JOB: no such job with ID $job_id");
	    exit 0;
	}
	my ($job_file, $user_id, $job_name, $job_status_id,$aimed_host) = @data;
	$job_ref->{'job_id'} = $job_id ;
	$job_ref->{'job_file'} = $job_file ;
	$job_ref->{'user_id'} = $user_id ;
	$job_ref->{'job_name'} = $job_name ;
	$job_ref->{'job_status_id'} = $job_status_id ;
	$job_ref->{'job_owner'} = &user_get_email_by_id($user_id);
	my $email = &dump_job_xml_config($job_file,"mail");
	$job_ref->{'job_owner'} = ($email)?$email:$job_ref->{'job_owner'};


	foreach my $machine ( split /[\s,]+/,$aimed_host )
	{
		next unless ($machine);
		if($machine =~ /\.\d+\./)
		{
			#the format of machine is ip address xx.xx.xx.xx
			my $machine_id = &machine_get_by_ip($machine);
			$job_ref->{'aimed_host'}->{$machine_id} = $machine ;

		}else {
			#the format of machine is machine_id 

			my $machine_ip = &machine_get_ip($machine) ;
			$job_ref->{'aimed_host'}->{$machine} = $machine_ip ;
		}
	}

	my @parts = &job_part_get_ids_by_job_id($job_id);
	my @job_on_machine_id = &job_on_machine_list($job_id);

	foreach my $part (@parts) {

		foreach my $jomid (@job_on_machine_id) {

			# FIXME: this should be accessed by the PK job_part_on_machine_id, not by (job_part_id,job_on_machine_id)
			my ($xml,$job_part_on_machine_id,$status,$does_reboot,$machine_id) = &job_part_info_get_by_pid_jomid($part,$jomid);
			$job_ref->{'mm_jobs'}->{$part}->{$jomid} = [$xml,$job_part_on_machine_id,$jomid,$status,$does_reboot,$machine_id] if ($xml);

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
	# FIXME: this is wrong, we must use job_on_machine.machine_id, not machine.aimed_host
	my @m_ips = map { $job_ref->{'aimed_host'}->{$_} } @machine_ids;

	foreach my $ipaddr (@m_ips)
	{
		$machine_sock{$ipaddr} = &creat_connection($ipaddr) unless (defined($machine_sock{$ipaddr}));
		if(defined $machine_sock{$ipaddr})
		{
			&log(LOG_INFO,"create connection success to $ipaddr");
			$sock_canread->add($machine_sock{$ipaddr}) ;
		}else{
			&log(LOG_INFO,"create connection failed to $ipaddr");
			return 0;
		}

	}
	&log(LOG_INFO,"creat part is finished");

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
				&log(LOG_INFO,"Send ping cmd to $_");
				my $tmpsock = $machine_sock{$_};
				my $empty = <$tmpsock>;
				my $ping_ack = <$tmpsock>;
				chomp($ping_ack);
				&log(LOG_INFO,"Get response from $_ : $ping_ack");
				if($ping_ack ne "pong")
				{
					&set_fail_release("Can not get ping ACK from  $_ ,Got $ping_ack");
					return 0 ;
				}
			}
			return 1;
		}
	my $numb = @available_machines;
	&log(LOG_INFO,"sleep 3 , wait for all can read socket,avaiable is $numb");
	sleep 3; 
	}

	&set_fail_release("Timeout to sync all machines");
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
				&set_fail_release("Sent XML to $ip failed");
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


sub machine_status_timeout($$$$$) {
	my $timeout = shift;
	my $machine_id = shift;
	my $hostname = shift;
	my $job_status =shift;
	my $job_msg = shift;

	$timeout *= 60;
	my $init_time = 0;
	while( &machine_get_status($machine_id) != MS_UP ) {
		$dbc->commit();	# do not remove, or cause a deadlock
		if($init_time>$timeout) {
			#timeout we jump out
			$job_status = JS_FAILED;
			$job_msg = "Reinstall/Reboot/Update $hostname Failed";
			last;
		}
		sleep 60;
		$init_time += 60;
	}
	$dbc->commit();
	return ($job_status,$job_msg);
}


sub set_fail_release()
{
	my $err_message = shift;
	#Set Fail
	&TRANSACTION( 'job_part_on_machine', 'log' );
	foreach my $part (keys %{$job_ref->{'mm_jobs'}} )
	{
		foreach my $jomid (keys %{$job_ref->{'mm_jobs'}->{$part}})
		{
			my $job_part_on_machine_id = $job_ref->{'mm_jobs'}->{$part}->{$jomid}->[1];
			my $machine_id = $job_ref->{'mm_jobs'}->{$part}->{$jomid}->[5];
			&backend_err_log($machine_id,$job_part_on_machine_id,$err_message);
			&job_part_on_machine_stop($job_part_on_machine_id,JS_FAILED);
		}
	}
	&TRANSACTION_END;

	&TRANSACTION('job');

	&job_set_status($job_ref->{'job_id'},JS_FAILED);

	&TRANSACTION_END;

	#set machine free
	&TRANSACTION('machine');
	foreach my $machine_id (keys %{$job_ref->{'aimed_host'}} )
	{
	    &machine_set_busy($machine_id,0);
	}
	&TRANSACTION_END;

	$dbc->commit();

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

