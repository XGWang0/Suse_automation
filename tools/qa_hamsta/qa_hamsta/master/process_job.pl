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

our $machine_job;


our %machine_sock;
our $sub_procs;

our @unsend_hosts;

$log::loglevel = $qaconf{hamsta_master_loglevel_job} if $qaconf{hamsta_master_loglevel_job};
$log::loginfo = 'process_job';

#$SIG{'HUP'} = 'IGNORE';
#$SIG{'INT'} = 'IGNORE';

# process_job(job_id)
#
# Sends a job to one (TODO: or more) slaves, gathers the slave output and 
# writes it to the database.
#
# $job_id		   ID of the job (TODO This should be the ID of job_on_machine)
sub process_job($) {

	my $job_id = shift @_;

	&log_add_output(path=>$qaconf{'hamsta_master_root'}."/job.$job_id.log", unlink=>1, bzip2=>0);
	$log::loginfo = "proc_job_$job_id";

	&log(LOG_NOTICE, "Processing job $job_id");

	my $data = &job_on_machine_get_by_job_id($job_id);
	if( !@$data )
	{
		&log(LOG_ERR, "PROCESS_JOB: no such job with ID $job_id");
		return;
	}
	#map all the job information
	for (@$data) {
		my ($job_on_machine_id,$machine_id) = @{$_};
		my ($job_file, $job_owner, $job_name) = &job_get_details($job_id);
		my ($ip, $hostname) = &machine_get_ip_hostname($machine_id);
		my @job_part_ids = &job_part_get_ids_by_job_id($job_id);
		my @job_part_on_machine_id = map { &job_part_on_machine_get_id_by_job_on_machine_and_job_part($job_on_machine_id,$_) }  @job_part_ids;                 ;

		#build the machine reference
		$machine_job->{$ip}->{'job_file'} = $job_file;
		$machine_job->{$ip}->{'job_id'} = $job_id;
		$machine_job->{$ip}->{'job_owner'} = &user_get_email_by_id($job_owner);
		$machine_job->{$ip}->{'job_name'} = $job_name;
		$machine_job->{$ip}->{'machine_id'} = $machine_id;
		$machine_job->{$ip}->{'job_on_machine_id'} = $job_on_machine_id;
		$machine_job->{$ip}->{'hostname'} = $hostname;
		$machine_job->{$ip}->{'job_part_id'} = \@job_part_ids;
		$machine_job->{$ip}->{'job_part_on_machine_id'} = \@job_part_on_machine_id;

	}

	# MM job reservation support: send reserve command before sending job xml file
	return if not &reserve_or_release_all($job_id,"reserve");

	return if not &connect_all($job_id);

	for (keys %$machine_job) {
		#query "Used By" and "Usage" information ,add them to job xml file.
		my ($usage,$users,$maintainer_id)=&machine_get_info($_);
		my $job_file = $machine_job->{$_}->{'job_file'};
		my $local_addr = $machine_sock{$_}->sockhost();
		$usage="default" unless( defined($usage) );
		$users="default" unless( defined($users) );
		$maintainer_id="default" unless( defined($maintainer_id) );
		&modify_job_xml_config($job_file,'useinfo',"USAGE: $usage ; USEDBY: $users ; MAINTAINER: $maintainer_id ");
		&modify_job_xml_config($job_file,'job_id',"http://$local_addr/hamsta/index.php?go=job_details&id=$job_id");


		&log(LOG_NOTICE,"PROCESS_JOB: process_job: " . $machine_job->{$_}->{'hostname'} . " using XML job description in" . $machine_job->{$_}->{'job_file'} );
	}


	#create xml for each machine , going to use xml2part here.

	#add machine information to XML



	#deploy job xml to slaves and process the job

	&deploy($machine_job);

	# send e-mail that the job has finished
	# see http://lena.franken.de/perl_hier/sendingmail.html for example on sending attachments

	my $submission_link;
	my @summary;

	my($response_xml,$job_owner,$short_name,$job_status_id,$aimed_host) = &job_get_details($job_id);

	#start to pick up the result from DB
	foreach(keys %$machine_job) {
		#query the return value from DB
		#$machine_job->{$_}->{'job_return_text'} = &job_on_machine_get_return_status($machine_job->{$_}->{'job_on_machine_id'});

		#query the submission link from DB
		#$machine_job->{$_}->{'submission_link'} = &job_on_machine_get_result_link($machine_job->{$_}->{'job_on_machine_id'});

		#query the job_status from DB
		$machine_job->{$_}->{'job_status_id'} = &job_on_machine_get_status($machine_job->{$_}->{'job_on_machine_id'});

		#query the summary from DB
		#my $summ = &job_on_machine_get_summary($machine_job->{$_}->{'job_on_machine_id'});
		#push(@summary,"host:$_ summary:\n");
		#push(@summary,$summ);

	}

	#let mail be the last part
	if( $job_owner =~ /@/ )
	{
		&log(LOG_DETAIL, "Sending mail to '%s'", $job_owner);
		my $response = &read_xml($response_xml);
		my $data = "";
		my $mailtype = "";
		my $reboot;
		my $message = "";
		foreach(keys %$machine_job) {
			#TODO query from database about submission_link
			if ($machine_job->{$_}->{'submission_link'}) {
				foreach my $link (split(/\n/,$machine_job->{$_}->{'submission_link'})){

					my $embedlink = $link.'&embed=1';
					my $rand = int(rand(100000));
					my $subhtml = '/tmp/sub'.$rand.'.html';
					my $ret = system("wget -O $subhtml \'$embedlink\'");
					if ($ret == 0) {
						$data .= "host $_ submission result:";
					$data .= `cat $subhtml`;
					system("rm -rf '$subhtml'");
					$mailtype = "text/html";
					}
					else {
					$data = "------------------------------------------------------\nPlain text mail received,please check submission link.\n------------------------------------------------------\n\n";
					goto PMAIL;
					}
				}
			}
			else {
PMAIL:
#$data .= "$ip job completed at ".`date +%F-%R`;
				$data .= "job completed at ".`date +%F-%R`;
#$data .= "\nJob status:".( $status==JS_FAILED ? 'Fail' : 'Pass' )."\n";
				if( !$reboot )
				{
					`ifconfig` =~ /inet addr:([\d\.]*)\s*Bcast/;
					my $loglink = "http://$1/hamsta/index.php?go=job_details&id=$job_id"; #fix me
					$data .= "\nLog link:\n$loglink\nQADB submission link:\n ". $machine_job->{$_}->{'submission_link'}."\nSummary result:\n".join("\n",@summary);
				}
				$mailtype = "TEXT";
			}
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

# send_job(ip)
#
# Sends a XML job description to the client and returns both the opened socket
# on which the slave respone can be read and the debuglevel for the job.
#
# $ip			   IP of the host to which the job is to be sent
#
# Return:		   ($tf, $loglevel)$usage
#				   $tf is true or false;
#				   $loglevel is the debuglevel for the job specified in the
#				   XML job description.
sub send_job($) {
	my $ip = shift;
	my $job_file = $machine_job->{$ip}->{'job_file'};
	my $job_id = $machine_job->{$ip}->{'job_id'};
	my $job_on_machine_id = $machine_job->{$ip}->{'job_on_machine_id'};

	#get log level from job xml file
	my $loglevel = &dump_job_xml_config($job_file,'debuglevel');
	$loglevel = $log::loglevel  unless defined($loglevel);

	# Pass the XML job description to the slave

	open (FH,'<',"$job_file");

	while (<FH>) { 
		$_ =~ s/\n//g;
		eval {
			&log(LOG_DETAIL, "Sent XML: $_");
			$machine_sock{$ip}->send("$_\n");
		};
	}
	if ($@) {
		&log(LOG_ERR, "PROCESS_JOB: send_job: $@");
		return (0, $loglevel);
	}
	close FH;

	# Return the result and log level.
	return (1, $loglevel);
}

sub machine_status_timeout($$$$$) {
	my $timeout = shift;
	my $machine_id = shift;
	my $hostname = shift;
	$timeout *= 60;
	my $init_time = 0;
	while( &machine_get_status($machine_id) != MS_UP ) {
		$dbc->commit();	# do not remove, or cause a deadlock
		if($init_time>$timeout) {
			#timeout we jump out
			$_[0] = JS_FAILED;
			$_[1] = "Reinstall/Reboot/Update $hostname Failed";
			last;
		}
		sleep 60;
		$init_time += 60;
	}
	$dbc->commit();
}

#return the vaule of config option, 
sub dump_job_xml_config($$) {

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

#1. xml file 2.name  3. vaule
sub modify_job_xml_config($$$) {
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

sub process_job_on_machine ($)
{
	&sql_get_connection();

	my $job_file = $machine_job->{$_}->{'job_file'};
	my $job_name = $machine_job->{$_}->{'job_name'};
	my $hostname = $machine_job->{$_}->{'hostname'};
	my $machine_id = $machine_job->{$_}->{'machine_id'};
	my $job_on_machine_id = $machine_job->{$_}->{'job_on_machine_id'};
	my $job_id = $machine_job->{$_}->{'job_id'};
	#fix me
	my $job_part_on_machine_id = $machine_job->{$_}->{'job_part_on_machine_id'};
	$job_part_on_machine_id = $job_part_on_machine_id->[0];

	&log(LOG_DETAIL, "start to process job on machine $_,job_file:$job_file ,job_name:$job_name,hostname:$hostname,machine_id:$machine_id,job_on_machine_id:$job_on_machine_id,job_id:$job_id"); 

	# Mark the job as started
	&TRANSACTION( 'job_on_machine','machine','job_part_on_machine');
	&job_on_machine_set_status($job_on_machine_id,JS_RUNNING);
	&job_part_on_machine_start($job_part_on_machine_id);
	&machine_set_busy($machine_id,1);
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
	my $return_codes="";
	my $submission_link;
	my @message_queue = ();
	my @summary = ();
	my @result_link = ();
	my %parsed;
	my $is_xml = 0;

	$| = 1;
	$dbc->commit();
	my $sock = $machine_sock{$_};
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

	&TRANSACTION( 'job_on_machine','machine' );
	#&job_on_machine_set_return($job_on_machine_id,$return_codes);
	#&job_on_machine_set_summary($job_on_machine_id,join("\n",@summary)) if (@summary);
	#&job_on_machine_set_result_link($job_on_machine_id,join("\n",@result_link)) if (@result_link);
	&machine_set_busy($machine_id,0);
	&TRANSACTION_END;
    # REMOVE USELESS RETURN OF job_on_machine
	# &TRANSACTION( 'job_on_machine' );
	# &job_on_machine_set_return($job_on_machine_id,$return_codes,$response_xml);
	# &TRANSACTION_END;

	my $message = "$job_name completed on $hostname";
	my $status=JS_FAILED;

	#get the final return value
	foreach my $ret ( split /\n/, $return_codes )
	{	$status=JS_PASSED if $ret=~/^(\d+)/ and $1==0;	}

	my $reboot = &dump_job_xml_config($job_file,'reboot');
	my $update_sut = &dump_job_xml_config($job_file,'update');
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
	$dbc->commit();
		
	# Mark the job as finished
	&TRANSACTION( 'job_on_machine', 'job', 'job_part_on_machine' );
	my $job_old_stauts = &job_on_machine_get_status($job_on_machine_id);
	&job_on_machine_stop($job_on_machine_id);
	&job_part_on_machine_stop($job_part_on_machine_id, $status);
	&job_on_machine_set_status($job_on_machine_id,$status) if $job_old_stauts == JS_RUNNING;
	&TRANSACTION_END;
	
}

sub connect_all ($)
{
	#get the job id
	my $sock_canread = IO::Select->new();
	my $job_id = shift;
	my $aimeds = &job_get_aimed_host($job_id);
	my @m_ips = split(/\s*,\s*/,$aimeds);
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

	return $sock;
}

sub deploy {
	local $SIG{'CHLD'} = sub { $sub_procs--; };
	my $job_id;

	# Send the job xml to the slave
	my $result;
	foreach (keys %$machine_job){
		my $ip = $_;
		($result, $log::loglevel) = &send_job($ip);
		if( $result ) {
			&log(LOG_NOTICE, "Send job XML to $ip");
		}else{
			#save the hosts which is not able to get XML
			&log(LOG_NOTICE, "Can NOT send job XML to $ip");
			push @unsend_hosts,$ip;
			

			&TRANSACTION( 'job_on_machine');
			&job_on_machine_set_status($machine_job->{$ip}->{'job_on_machine_id'},JS_FAILED);
			&TRANSACTION_END;

			#remove the hosts with errors.
			delete $machine_job->{$ip};

		}
		
	}

	my @sub_pid;
	#mark the max machine
	$sub_procs =  scalar keys %$machine_job;
	$dbc->{'dbh'}->disconnect();
	undef $dbc;

	#start use fork 
	foreach(keys %$machine_job){

		child {
			&log(LOG_NOTICE, "start to process_job_on_machine $_"); 
			&process_job_on_machine($_);
			exit 0;

		}

		parent {

			push(@sub_pid,shift);
	
		}

		;
	}
	&sql_get_connection();
	&log(LOG_NOTICE, "going to check timeout"); 

	#get time of job 
	my $timeout = 1000; #should read from database;
	my $init =0;

	while($init <= $timeout)
	{
		sleep 3;
		$init++;
		if($sub_procs == 0)
		{
			my ($jom_status,$fail_tag);
			foreach( keys %$machine_job ) {

				my $sub_job_on_machine_id = $machine_job->{$_}->{'job_on_machine_id'};
				$job_id = $machine_job->{$_}->{'job_id'};
				$jom_status = &job_on_machine_get_status($sub_job_on_machine_id);
				#set it fail if the status is connecting
				if( $jom_status == JS_CONNECTING ) {
					&TRANSACTION( 'job_on_machine','job');
					&job_on_machine_set_status($sub_job_on_machine_id,JS_FAILED);
					&job_set_status($job_id,JS_FAILED);
					&TRANSACTION_END;
					$fail_tag = 1;
					last;
				}
				if( $jom_status != JS_PASSED ) {
					&TRANSACTION( 'job' );
					&job_set_status($job_id,JS_FAILED);
					&TRANSACTION_END;
					$fail_tag = 1;
					last;
				}

			}
			if( scalar @unsend_hosts ) {
				&TRANSACTION( 'job' );
				&job_set_status($job_id,JS_FAILED);
				&TRANSACTION_END;
				$fail_tag = 1;
				
			}
			if( !$fail_tag ) {
				&TRANSACTION( 'job' );
				&job_set_status($job_id,JS_PASSED);
				&TRANSACTION_END;
			}

			#call waitpid to clean the process table
			for(@sub_pid)
			{
				waitpid($_,0);
			}
			return;
		}

	}
	# timeout , send error message.
	&log(LOG_ERROR, "Timeout the Job ");
	&set_fail_release();
		
}

sub set_fail_release() {

  #when jobs failed with some error, need to mark the result and 
  #release the machine
  
  my $job_id;

  &TRANSACTION( 'job_on_machine','job','machine');
  foreach( keys %$machine_job ) {
    &job_on_machine_set_status($machine_job->{$_}->{'job_on_machine_id'},JS_FAILED);
    &machine_set_busy($machine_job->{$_}->{'machine_id'},0);
    $job_id = $machine_job->{$_}->{'job_id'};
  }
  &job_set_status($job_id,JS_FAILED);
  &TRANSACTION_END;
}

# 1. job_id 2. 'reserve' | 'release'
sub reserve_or_release_all ($$)
{
	my $job_id = shift;
	my $action = shift;
	my $aimeds = &job_get_aimed_host($job_id);
	my @m_ips = split(/\s*,\s*/,$aimeds);
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
					

unless(defined($ARGV[0]) and $ARGV[0] =~ /^(\d+)$/)
{
	print STDERR "Usage : $0 <job ID>\n";
	exit;
}


&sql_get_connection();
&process_job($ARGV[0]);

