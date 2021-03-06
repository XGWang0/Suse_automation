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

use Switch;
use XML::Simple;

use hwinfo_xml_sql;
use threads;

use Config::IniFiles;
use Digest::SHA1 qw(sha1_hex);
use qaconfig;
use active_hosts qw(update_machine_hamsta_master_reservation);
BEGIN { push @INC, '.', '/usr/share/qa/lib'; }
use detect;
use functions;
require sql;

# Usual location of the Hamsta front-end configuration file

# pkacer@suse.com: TODO This should not be hard-coded but I have no
# idea where to put this, yet. Perhaps it would be better if required
# values were moved to the general configuration. For now it would be
# duplication.
my $config_file_path = "/srv/www/htdocs/hamsta/config.ini";

# Here we store user id. Value should be set only if the user is
# authenticated.
my $user_id;

# This variable is used to mark changes in the command line
# protocol. The version should be changed if the command line protocol
# changes.
my $protocol_version = 1;

# Master->command_line_server()
#
# Listens on the command line server port for incoming connections. For each
# connection a thread is created to handle the requests

sub command_line_server() {

    my $Socket=new IO::Socket::INET->new(
        LocalPort => $qaconf{hamsta_master_cli_port},
        Proto     => 'tcp',
        Listen    => $qaconf{hamsta_master_max_cli_connections},
        Timeout   => undef,
        Reuse     => 1,
    );

    eval {
        # each client needs its own thread
        while(my $new_sock = $Socket->accept)
        {
            my $thread = threads->new(\&thread_evaluate, $new_sock);
	    &log(LOG_NOTICE,"COMMAND_LINE_SERVER: Started new connection with thread id ".$thread->tid());
            $thread->detach();
		    undef $thread;
        }
    };
    if ($@) {
        if ($@ =~ /method \"accept\"/) {
            &log(LOG_ERR, "$@\tThe commandline interface port is not yet freed from the OS. Thread terminated.");
        } else {
            &log(LOG_ERR, "COMMAND_LINE_SERVER: $@");
        }
    }

    $Socket->close if $Socket;

}

# This function is executed when a client connects (user connection)
# It holds the connection and loops in the interaction between master
# and client.
# TODO more debug information needed eg who is connected from where
sub thread_evaluate () {
	my $sock_handle = shift @_;

	local $SIG{'PIPE'} = 'IGNORE';

	my $version = join ('.', get_master_version ());
	print $sock_handle "Welcome to HAMSTA (version $version) "
	    . "(Hardware Maintenance, Setup and Test Automation) console. \n";
	&sql_get_connection();

	while (1) {
		print $sock_handle "\n\$>";

		if (eof($sock_handle)) {
		    &log(LOG_DETAIL, "EOF received.");
		    last;
		}

		$_ = <$sock_handle>;
		s/\r?\n$//;
		&parse_cmd($_, $sock_handle);
		$dbc->commit();
	}

	$sock_handle->close;
}

# Master->parse_cmd()
#
# when the command line client sends data to master, this data is
# parsed here and appropriate handler is executed.
sub parse_cmd() {
    my $cmd = shift @_;
    my $sock_handle = shift @_;
    my $ips="";
    my @ips;
    
    #verify the hostname & ip
    if ($cmd =~ / ip ([^ ]+)/) {
        my $host = $1;
        my $mihash = &mih();

	foreach ( split(/[,\s]+/,$host)) {
		if (defined($mihash->{$_})) {
			my $ip = $mihash->{$_};
			push @ips, $ip;
			
		} else {
			print $sock_handle "$_ Not Available\n";
			return ;
		}
	}
	$ips = join ',', @ips;
	$cmd =~ s/ ip [^ ]+/ ip $ips/;
    }

    switch ($cmd) {
	case /^version/			{ cmd_version ($sock_handle); }
	case /^(exit|quit)/			{ cmd_exit ($sock_handle); }
	case /^protocol version/	{ cmd_protocol_version ($sock_handle); }
	case /^check version/		{ cmd_check_protocol_version ($sock_handle, $cmd); }
	case /^(print|list) all/	{ cmd_print_all_machines ($sock_handle); }
        case /^(print|list) active/     { cmd_print_active($sock_handle); }
        case /^query job status /	{ cmd_print_job_stauts($sock_handle,$cmd); }
        case /^query job log /		{ cmd_print_job_log($sock_handle,$cmd); }
#        case /^which job where/    	{ which_job_where(); }
#        case /^search hardware/	{ which_hardware_where($sock_handle, $cmd); }
        case /^(print|list) groups/ 	{ cmd_print_groups($sock_handle, $cmd); }
#        case /^group add host/		{ group_add_host($sock_handle, $cmd); }
#        case /^group del host/		{ group_delete_host($sock_handle, $cmd); }
#        case /^group_add/		{ create_group($sock_handle, $cmd); }
#        case /^group_del/		{ delete_group($sock_handle, $cmd); }
#        case /^send job group/		{ send_job_to_group($sock_handle, $cmd); }
        case /^send job ip/		{ send_job_to_host($sock_handle, $cmd); }
        case /^send qa_predefine_job ip/{ send_predefine_job_to_host($sock_handle, $cmd); }
        case /^send qa_package_job ip/	{ send_qa_package_job_to_host($sock_handle, $cmd); }
        case /^send autotest_job ip/	{ send_autotest_job_to_host($sock_handle, $cmd); }
        case /^send multi_job /		{ send_multi_job_to_host($sock_handle, $cmd); }
        case /^send xen set ip/		{ send_xen_set_to_host($sock_handle, $cmd); }
        case /^send reinstall ip/	{ send_re_job_to_host($sock_handle, $cmd); }
        case /^send one line cmd ip/	{ send_line_job_to_host($sock_handle, $cmd); }
        case /^send job anywhere/	{ $cmd =~ s/anywhere/ip none/; &send_job_to_host($sock_handle, $cmd); }
	case /^(print|list) jobtype/	{ list_testcases($sock_handle,$cmd); }
	case /^log in/			{ log_in ($sock_handle, $cmd); }
	case /^log out/			{ log_out ($sock_handle, $cmd); }
	case /^(print|list) status/	{ print_status ($sock_handle, $cmd); }
	case /^(print|list) roles/	{ print_roles ($sock_handle, $cmd); }
	case /^(print|list) privileges/ { print_privileges ($sock_handle, $cmd); }
	case /^can i/			{ print_can_user ($sock_handle, $cmd); }
	case /^can send/		{ print_user_can_send_jobs ($sock_handle, $cmd); }
	case /^(reserve|release) /	{ reserve_release ($sock_handle, $cmd); }
        case /^help/			{ cmd_help($sock_handle); }
        else {
            if ($cmd eq '') {
                print $sock_handle "no command entered, try >help< \n";
            } else {
                print $sock_handle "command not found, try >help< \n";
            }
        }
    }
  SWSW:
}

# Master->cmd_exit()
#
# close the sock and exit
sub cmd_exit() {
    my $sock_handle = shift @_;
    $sock_handle->close;
	exit 0;
}
# Master->cmd_help()
#
# Prints the command line interface help
sub cmd_help() {
    my $sock_handle = shift @_;
    select ($sock_handle);

    print "Following commands are available. 'list' can be used instead of 'print'.\n";
    print "syntax = 'command' : explanation \n";
    print "\t 'version' : print master's version\n";
    print "\t 'protocol version' : print master's protocol version\n";
    print "\t 'check version <version>' : check if the master supports this protocol version\n";
    print "\t 'print status' : prints users status, reserved machines and possibly other information \n";
    print "\t 'log in <username> <password>' : authenticate the user (for this CLI session only) \n";
    print "\t 'log out' : log out from the Hamsta \n";
    print "\t 'print roles [<username>]' : list available roles, with username only roles for that user\n";
    print "\t 'can i <privilege>' : check if you have access to the specified privilege \n";
    print "\t 'can send <IP>' : tells you if you can send a job to the machine denoted by IP \n";
    print "\t 'print active' : prints active hosts \n";
    print "\t 'print all' : prints all available hosts \n";
#    print "\t 'search hardware <perl-pattern (Regular Expression) or string>' : prints all hosts which hwinfo-output matches the desired string/pattern \n";
    print "\t 'save groups to </path/file>' : save (dumps) the groups as XML in the specific file (relativ to Master root-directory) \n";
    print "\t 'load groups from </path/file>' : loads the specified XML-groups-file \n";
    print "\t 'print groups' : prints groups (from SQL) \n";
#    print "\t 'group_add <name>' : creates a new group \n";
#    print "\t 'group_del <name>' : be aware, deletes group (with all members)  \n";
#    print "\t 'group add host <group> <IP>' : adds <IP> to the group, no wildcards (atm.) \n";
#    print "\t 'group del host <group> <IP>' : removes <IP> from the group, no wildcards (atm.) \n";
#    print "\t 'send job group <group> <file>' : submits the job to all members in the group  \n";
    print "\t 'send job ip <IP> <file>' : submits the job to the IP  \n";
    print "\t 'send qa_package_job ip <IP> <PACKAGE NAME> <Email> <Tag>' : submits the job to the IP  \n";
    print "\t 'send xen set ip <IP> <Tag>' : submits the job to the IP  \n";
    print "\t 'send reinstall ip <IP> <Reinstall_repo> <Email> <Tag> ' : submits the reinstall job to the IP  \n";
    print "\t 'send one line cmd ip <IP> <cmd> <Email> <Tag>' : submits the one line job to the IP (replace space with # in cmd)  \n";
    print "\t 'send job anywhere <file>' : submits the job to one of the available machines \n";
    print "\t 'print jobtype <number>' : lists available jobs of the given type (1 - pre-defined jobs, 2 - qa-package jobs, 3 - autotest jobs, 4 - multi-machine jobs) \n";
    print "\t 'reserve <host> for user <login>' : Reserve machine (IP or name) for user identified by <login> \n";
    print "\t 'release <host> for user <login>' : Release (unreserve) machine (IP or name) for user identified by <login> \n";
    print "\t 'reserve <host> for master' : Reserve machine (IP or name) for this hamsta master \n";
    print "\t 'release <host> for master' : Release (unreserve) machine (IP or name) for this hamsta master \n";
    print "\n end of help \n";
}

sub use_master_authentication ()
{
    return $qaconf{'hamsta_master_authentication'};
}

sub cmd_version ($) {
    my $socket = shift;
    my @version = get_master_version ();
    if (@version) {
	print $socket "HAMSTA Master version " . join ('.', @version);
    } else {
	log(LOG_ERROR, "Could not retrieve master version from file '"
	    . Hamsta::HAMSTA_DIR . "/.version'");
	print $socket "ERROR: Could not retrieve master version.";
    }
}

sub cmd_protocol_version ($) {
    my $socket = shift;
    print $socket "HAMSTA Master protocol version $protocol_version";
}

# Master->cmd_print_active
#
# Print the IP address, free hostname and description of all hosts in status "up" 
sub cmd_print_active()  {
    my $sock_handle = shift @_;

    my $machines = &machine_search('fields'=>[qw(ip name description)],'return'=>'matrix','machine_status_id'=>MS_UP,'busy'=>0);
    print $sock_handle "List of active machines (status up).\n";
    printf $sock_handle "%15s : %15s : %s\n", "MACHINE", "IP ADDRESS", "DESCRIPTION";
    foreach my $machine (@$machines) {
        printf $sock_handle "%15s : %15s : %s\n", $machine->[1], $machine->[0], $machine->[2];
    }
}

sub cmd_print_job_stauts(){
    my $sock_handle = shift @_;
    my $cmd = shift @_;
    my $job_id;
    ($job_id) = $cmd =~ /(\d+)/;
    my $job_status = &job_get_status($job_id);
	#Get all host id/ip
	my $aimed_host = &job_get_aimed_host($job_id);
	chomp $aimed_host;
	my $host_status="";
	for my $host_ip (split(/,/,$aimed_host)){
		$host_status .= &machine_get_status_by_ip($host_ip);
	}
    print $job_status;
    print $sock_handle $job_status . $host_status . "\n";
}

#query the job information
#return part , role , machine_name , machine_ip , job_part_on_machine_id
sub cmd_print_job_log(){
    my $sock_handle = shift @_;
    my $cmd = shift @_;
    my $job_id;
    my $ref;
    ($job_id) = $cmd =~ /(\d+)/;
    print $sock_handle "Start to query job log for job_id:$job_id";
    my $job_ref = &job_get_info($job_id);
    if (! scalar(@$job_ref)){
        print $sock_handle "Can NOT find log for Job id:$job_id ,Please make sure Job id exist\n";
        return 1;
    }
    foreach my $info (@$job_ref) {
        #printf $sock_handle "--log--part[%d]--role[%s]--machine_name[%s]--machine_ip[%s]--machine_pid[%d]\n",$info->[0],$info->[1],$info->[2],$info->[3],$info->[4];
	$ref->{$info->[0]}{$info->[1]}{$info->[2]}=$info->[4];
    }
    my $part=1;
    foreach my $_part ( sort {$a<=>$b} keys %{$ref}) {
        printf $sock_handle "--log--part[%s]\n",$part ;
        foreach my $_role ( keys %{$ref->{"$_part"}} ) {
            printf $sock_handle "--log--part[%d]--role[%s]\n",$part,$_role;
            foreach my $_name (keys %{$ref->{$_part}{$_role}}) {
                printf $sock_handle "--log--part[%d]--role[%s]--machine_name[%s]\n",$part,$_role,$_name;
		my $_log = &log_get_by_job_part_on_machine_id($ref->{$_part}{$_role}{$_name});
                foreach my $job_log (@$_log) {
                    printf $sock_handle "%s %s %s %s %s\n",$job_log->[0],$job_log->[1],$job_log->[2],$job_log->[3],$job_log->[4];

                }

            }
        }
	
    $part++;
    }
	
}
    


sub cmd_check_protocol_version ($) {
    my $sock_handle = shift;
    my @cmd = split ' ', shift (@_);

    if (@cmd == 3 and int($cmd[2]) <= $protocol_version) {
	print $sock_handle "OK";
    } else {
	print $sock_handle "NOK";
    }
}

#build machine ip hash
sub mih {
  my $machine_status = shift;
  my $miref = {};
  my $machines = undef;

  if ($machine_status) {
      $machines = machine_search('fields'=>[qw(ip name)],'return'=>'matrix',
				 'machine_status_id'=>$machine_status);
  } else {
      $machines = machine_search('fields'=>[qw(ip name)],'return'=>'matrix');
  }

  foreach my $machine (@$machines) {
    $miref->{$machine->[1]} = $machine->[0];
    $miref->{$machine->[0]} = $machine->[0];
  }
  return $miref;
}

sub cmd_print_groups() {
    my $sock_handle = shift @_;
    my @groups = $dbc->enum_list_val ('group');
    local $" = "', '"; # Use this to interpolate list values
    print $sock_handle "There are following groups: '@groups'.\nEmpty groups are not listed below.\n\n";
    foreach my $group (@groups) {
	my $group_id = $dbc->enum_get_id ('group', $group);
	unless (defined ($group_id)) {
	    print $sock_handle "Oops, the group '${$group}' has been probably deleted.";
	} else {
	    my $data = group_list_status ($group_id);
	    if ((scalar @$data) > 0) {
		print $sock_handle "${group}: ";
		foreach my $row (@$data) {
		    # Output: machine_name (machine_status)
		    print $sock_handle "@{$row}[0] (@{$row}[1]) ";
		}
		print $sock_handle "\n";
	    }
        }
    }
}

sub parse_xml() {
    my $sock_handle = shift @_;
    my $file = shift @_;

    my $data = "";
    open (FH,'<', "$file");
    $data .= $_ while(<FH>);
    close (FH);

    if ($data =~ /(group_)?job\%3E\%0A$/) {
        # file is encoded
        $data = uri_unescape($data);
    } elsif ($data =~/<\/(group_)?job>[ \n\r]*$/) {
        # file in plain XML

    } else {
        &log(LOG_DETAIL, $data);
        &log(LOG_ERR, "file $file is neither XML, nor escaped-XML");
        print $sock_handle "file $file is neither XML, nor escaped-XML \n";
        return undef;
    }

    my $ref = &read_xml($data);
    if (!$ref) {
        print $sock_handle "There is a syntax error in XML $file: $@ \n";
        return undef;
    }
    return $ref
}

sub which_hardware_where() {
    # reads all hwinfo-data from actives host
    my $sock_handle = shift @_;
    my $cmd = shift @_ ;
    my $ref_backbone = &read_latest_backbone();

    (my @cmd_line) = split / /,$cmd;
    my $string_searching = $cmd_line[-1];

    while ((my $host, my $values) = each %{$ref_backbone->{'active'}}) {
        # directory
        open (FH, '<', $ref_backbone->{'master_root'}."/".$host."/".$values->{'hwinfo_time'}."_hwinfo");
        my @data = <FH>;
        close (FH);
        my $data;
        foreach (@data) { $data = $data.$_;}			# serialiszing
        my $xml = new XML::Dumper;
        my $hash_ref = $xml->xml2pl($data);
        my @result = datasearch(data => $hash_ref, search => 'all', find => qr/$string_searching/i, return => 'all' );
        if (@result) {
            print $sock_handle "\n hwinfo from $values->{'ip'}
            $values->{'description'} matches :\n";
            foreach my $item (@result) {
                print $sock_handle "\t $item";

            }
            print $sock_handle "\n";	# for display niceness
        } else {
            print $sock_handle "hwinfo from $values->{'ip'}
            $values->{'description'} does not match '$string_searching' \n";
        }
    }

}

sub machine_ip2id
{
	my ($sock_handle,$host)=@_;
	unless ($host=~ /(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/ )
	{
		print $sock_handle "'$host' is not a valid IP-adress.\n";
		return 0;
	}

	my $machine_id = &machine_get_by_ip($host);
	unless( $machine_id )
	{
		print $sock_handle "'$host' is not a known machine.\n";
		return 0;
	}
	return $machine_id;
}

sub group_add_host() {
	my $sock_handle = shift @_;
	my $cmd = shift @_ ;
	(my @cmd_line) = split / /,$cmd;
	my $group = $cmd_line[-2];
	my $host = $cmd_line[-1];
	my $string;

	my $machine_id = &machine_ip2id($sock_handle,$host);
	return unless $machine_id;

	my $group_id = $dbc->enum_get_id('group',$group);
	unless( $group_id )
	{
		print $sock_handle "'$group' is not a known group.\n";
		return;
	}
	&TRANSACTION( 'group_machine' );
	my $ret=&group_machine_new( $group_id, $machine_id );
	&TRANSACTION_END;

	if( $ret==0 )
	{	print $sock_handle "'$host' is already member of '$group'\n";	}
	elsif( $ret==1 )
	{	print $sock_handle "ADDED '$host' to '$group'\n";		}
	else
	{	print $sock_handle "ERROR adding '$host' to '$group'\n";	}
}

sub group_delete_host() {
	my $sock_handle = shift @_;
	my $cmd = shift @_ ;
	(my @cmd_line) = split / /,$cmd;
	my $group = $cmd_line[-2];
	my $host = $cmd_line[-1];

	my $machine_id = &machine_ip2id($sock_handle,$host);
	return unless $machine_id;
	my $group_id = $dbc->enum_get_id('group',$group);
	unless( $group_id )
	{
		print $sock_handle "'$group' is not a known group.\n";
		return;
	}

	&TRANSACTION( 'group_machine' );
	my $ret=&group_machine_delete($group_id,$machine_id);
	&TRANSACTION_END;

	if( $ret==0 )
	{	print $sock_handle "'$host' not a member of '$group'\n";	}
	elsif( $ret==1 )
	{	print $sock_handle "DELETED '$host' from '$group'\n";		}
	else
	{	print $sock_handle "ERROR deleting '$host' from '$group'\n";	}
}

sub create_group() {
	my $sock_handle = shift @_;
	my $cmd = shift @_ ;
	(my @cmd_line) = split / /,$cmd;
	my $group = $cmd_line[-1];
	my $group_id = $dbc->enum_get_id('group',$group);
	if( $group_id>0 )
	{	print $sock_handle "Group $group already exists \n";	}
	else
	{
		&TRANSACTION( 'group' );
		$dbc->enum_insert('group',$group);
		&TRANSACTION_END;

		print $sock_handle "ADDED $group \n";
	}
}

sub delete_group() {
	my $sock_handle = shift @_;
	my $cmd = shift @_ ;
	(my @cmd_line) = split / /,$cmd;
	my $group = $cmd_line[-1];
	my $group_id = $dbc->enum_get_id('group',$group);
	if( $group_id > 0 )
	{
		&TRANSACTION( 'group' );
		$dbc->enum_delete_id('group',$group_id);
		&TRANSACTION_END;

		print $sock_handle "DELETED $group \n";
	}
	else
	{	print $sock_handle "Group $group does not exist! \n";	}
}

sub list_testcases() {

    my $sock_handle = shift @_;
    #jobtype:
    #1 for pre-define
    #2 for qa_package
    #3 for autotest.
    #4 for multi_machie.
    my $jobtype = shift @_;
    my @jobtype = split /\s+/,$jobtype;
    $jobtype=$jobtype[2];

    if($jobtype !~ /^[1-4]$/) {
      print $sock_handle "not support for the type * $jobtype *\n";
      return;
    }

    my $return="";
    if($jobtype==1) {
    #for predefine job
    print $sock_handle "----pre-define job list----\n";
    my @precases=glob("/usr/share/hamsta/xml_files/*.xml");
    my $rs=0;
    map { $rs++;s/\.xml//;s/.*\///;$return.="$_ ";$return.="\n" if($rs%4==0) } @precases;
    print $sock_handle $return;
    return;
    }

    if ($jobtype==2) {
	#for qa package job
	print $sock_handle "----QA package job list----\n";
	my $rs=0;
	# Read Hamsta front-end config file
	my $cfg = Config::IniFiles->new ( -file => $config_file_path, -default => "production" );
	print $sock_handle "Command not completed.\nUnable to read config file '$config_file_path'.\n" and return unless $cfg;
	# Get list of packages
	my $tslist = $cfg->val ('production', 'lists.tslist');
	# Make it nicer for printing
	map { $rs++; $return.="$_ "; $return.="\n" if($rs % 4 == 0) } split /\s+/, $tslist;
	print $sock_handle $return;
	return;
    }

    if($jobtype==3) {
	#for autotest job
	print $sock_handle "----Autotest job list----\n";
	my $rs=0;
	# Read Hamsta front-end config file
	my $cfg = Config::IniFiles->new ( -file => $config_file_path, -default => "production" );
	print $sock_handle "Command not completed.\nUnable to read config file '$config_file_path'.\n" and return unless $cfg;
	# Get list of packages
	my $atlist = $cfg->val ('production', 'lists.atlist');
	map { $rs++; $return.="$_ "; $return.="\n" if($rs % 4 == 0) } split /\s+/, $atlist;
	print $sock_handle $return;
	return;
    }

   if($jobtype==4) {
    #for multi-machine job
    print $sock_handle "----Multi_machine job list----\n";
    my @mulcases=glob("/usr/share/hamsta/xml_files/multimachine/*.xml");
    map {
      open my $rfh,"$_" || ($return.="$_ can't open\n");
      my @xml_cont = <$rfh>;
      close $rfh;
      my $roles = grep(/role id=/ ,@xml_cont);
      s/\.xml//;s/.*\///;
      $return.=$_."(roles number): $roles\n" } @mulcases;
    print $sock_handle $return;
    return;
    }
}

sub send_predefine_job_to_host() {
    my $sock_handle = shift @_;
    my $cmd = shift @_ ;
    &log(LOG_NOTICE, "cmd = $cmd");

    (my @cmd_line) = split / /,$cmd;
    my $file = $cmd_line[4];
    my $host = $cmd_line[3];
    my $email = "";
    $email = $cmd_line[5] if(@cmd_line >= 6);

    return if &handle_can_not_send_job_to_machine($host, $sock_handle, $user_id);

    print $sock_handle "Pre-define job:$file \n\n";


    my $ffile="/usr/share/hamsta/xml_files/".$file.".xml";

    if (not (-e $ffile)) {
        &log(LOG_ERR, "file $file does not exist");
        print $sock_handle "file $file does not exist\n";
        return;
    }
    #modify email xml file
    open my $pre_ori,$ffile || (print $sock_handle "can't open xml file\n" and return);
    my $v=time;
    my $ofile="/tmp/command_line_pre_def_${host}_${file}_$v.xml";
    open my $pre_tmp,'>',$ofile || (print $sock_handle "can't write xml file\n" and return);
    while(my $line = <$pre_ori>){
	$line =~ s#</mail>#$email$&# if($line =~ /\/mail/);
        print $pre_tmp $line;
    }
    close $pre_ori;
    close $pre_tmp;

    my $ref = &parse_xml($sock_handle, $ofile);
    return if( not defined $ref );
    # set the default values
    my $job_id = &transaction($ref,$host,$ofile);

    &log(LOG_INFO,"MASTER::FUNCTIONS cmdline Pre-define Job $file send to scheduler, at $host internal id: $job_id");
    print $sock_handle "MASTER::FUNCTIONS cmdline Pre-define Job $file send to scheduler, at $host internal id: $job_id\n";
    return;
}

sub send_autotest_job_to_host() {
    my $sock_handle = shift @_;
    my $cmd = shift @_ ;

    &log(LOG_NOTICE, "cmd = $cmd");
    (my @cmd_line) = split / /,$cmd;
    #Autotest . at
    my $at_tag = "";
    $at_tag = $cmd_line[6] if(@cmd_line >= 7);
    $at_tag = "with tag ".$at_tag if($at_tag);
    my $at_email = "";
    $at_email = $cmd_line[5] if(@cmd_line >= 6);
    my $at_name = $cmd_line[4];
    $at_name =~ s/#/ /g;
    my $host = $cmd_line[3];

    print $sock_handle "Autotest job:$at_name \n";


    #modify the custom autotest file
    open(my $at_template,"/usr/share/hamsta/xml_files/templates/autotest-template.xml") or ( print $sock_handle "can open Autotest job template\n" and return);
    my $v=time;
    my $at_xml="/tmp/command_line_at_${host}_$v.xml";
    open(my $template_tmp,">","$at_xml") or ( print $sock_handle "can not write Autotest job template\n" and return);
    my $shotname=substr($at_name,0,20);
    while(<$at_template>){

	s#AT_LIST_SHORT#Autotest job : $shotname $at_tag  #;
	s#DEBUGLEVEL#4#;
	s#</mail>#$at_email$&#;
	s#AT_LIST#$at_name#;
	print $template_tmp $_;

    }
    close $at_template;
    close $template_tmp;

    my $ref = &parse_xml($sock_handle, $at_xml);
    return if( not defined $ref );
    # set the default values
    my $job_id = &transaction($ref,$host,$at_xml);

    &log(LOG_INFO,"MASTER::FUNCTIONS cmdline Autotest Job $at_name send to scheduler, at $host internal id: $job_id");
    print $sock_handle "MASTER::FUNCTIONS cmdline Autotest Job $at_name send to scheduler, at $host internal id: $job_id\n";
    return;
}

sub send_multi_job_to_host () {

    my $sock_handle = shift @_;
    my $cmd = shift @_ ;

    &log(LOG_NOTICE, "cmd = $cmd");
    (my @cmd_line) = split / /,$cmd;
    my $mul_email = "";
    $mul_email = $cmd_line[4] if(@cmd_line >= 5);
    my $mul_name = $cmd_line[2];
    my $parser = $cmd_line[3];
    my @hosts;
    my @roles = split /;/,$parser;

    #get all host
    map {
      my $h =$_;
      $h =~ s/.*://;
      my @tmphosts = split /,/,$h;
      map { push @hosts,$_; } @tmphosts;
    } @roles;

    #check host live
    for my $host (@hosts) {
      return if &handle_can_not_send_job_to_machine($host, $sock_handle, $user_id);

    }

    print $sock_handle "Multi_machine job:$mul_name \n";

    my $mfile="/usr/share/hamsta/xml_files/multimachine/".$mul_name.".xml";
    my $v=time;
    my $mul_xml="/tmp/command_line_mul_$v.xml";

    #modify xml file , add role to machine.
    my $machine =  qq#<machine name="x" ip="y"/>#;
    my %machine;
    for my $sub_role (@roles) {
      my @r = split /:/,$sub_role;
      $r[0] =~ s/r//;
      #get role number:
      my $rn = $r[0];
      my @rhosts = split /,/,$r[1];
      #get role host ip
      my @rips;
      map { push @rips,&nitoi($_) } @rhosts;

      $machine{$rn}="";
      foreach(@rips){
        my $tp=$machine;
        my $hostname=&machine_search('fields'=>['name'],'ip'=>$_);
        $tp =~ s/y/$_/;
        $tp =~ s/x/$hostname/;
        $machine{$rn}.=$tp;
      }
    }

    open my $m_ori,$mfile || (print $sock_handle "can open Multi-machine xml file\n" and return);
    open my $m_tmp,'>',$mul_xml || (print $sock_handle "can open Multi-machine xml file\n" and return);
    while(<$m_ori>){
      if(/role id=\"(\d)/){
        chomp;
        $_.=$machine{$1} ;
        $_=~s#/##;
        $_.="</role>\n";
      }
      print $m_tmp $_;
    }
    close $m_tmp;
    close $m_ori;

    my $ref = &parse_xml($sock_handle, $mul_xml);
    return if( not defined $ref );
    # set the default values
    my $hosts;
    $hosts = join(',', @hosts);
    for my $host (@hosts) {
      my $job_sid = &transaction($ref,$host,$mul_xml);
      &log(LOG_INFO,"MASTER::FUNCTIONS cmdline Multi_Machine Job $mul_name send to scheduler, at $host internal id: $job_sid");
      print $sock_handle "MASTER::FUNCTIONS cmdline Multi_Machine Job $mul_name send to scheduler, at $host internal id: $job_sid\n";
    }
    return;
}

sub send_job_to_host () {
    my $sock_handle = shift @_;
    my $cmd = shift @_ ;

    &log(LOG_NOTICE, "cmd = $cmd");
    (my @cmd_line) = split / /,$cmd;
    my $file = $cmd_line[-1];
    my $host = $cmd_line[-2];

    return if &handle_can_not_send_job_to_machine($host, $sock_handle, $user_id);


    if (not (-e $file)) {
        &log(LOG_ERR, "file $file does not exist");
        print $sock_handle "file $file does not exist\n";
        return;
    }

    my $ref = &parse_xml($sock_handle, $file);
    return if( not defined $ref );
    # set the default values

    my $job_id = &transaction($ref,$host,$file);

    &log(LOG_INFO,"MASTER::FUNCTIONS Job send to scheduler, at $host internal id: $job_id");
    print $sock_handle "MASTER::FUNCTIONS Job send to scheduler, at $host internal id: $job_id\n";
}



sub send_re_job_to_host () {
    my $sock_handle = shift @_;
    my $cmd = shift @_ ;

    &log(LOG_NOTICE, "cmd = $cmd");
    (my @cmd_line) = split / /,$cmd;
    my $reinstall_tag = "";
    $reinstall_tag = $cmd_line[6] if(@cmd_line >= 7);
    my $reinstall_email = "";
    $reinstall_email = $cmd_line[5] if(@cmd_line >= 6);
    my $reinstall_opt = $cmd_line[4];
    $reinstall_opt =~ s/#/ /g;
    my $host = $cmd_line[3];

    return if &handle_can_not_send_job_to_machine($host, $sock_handle, $user_id);

    #modify the reinstall xml file
    open(my $template_re,"/usr/share/hamsta/xml_files/templates/reinstall-template.xml") or ( print $sock_handle "can open reinstall template\n" and return);
    my $v=time;
    my $cmd_reinstall_xml="/tmp/command_line_reinstall_${host}_$v.xml";
    open(my $template_tmp,">","$cmd_reinstall_xml") or ( print $sock_handle "can not write reinstall template\n" and return);
    while(<$template_re>){
	s#reinstall from REPOURL#$reinstall_tag Reinstall Job from cmdline#;
	s#Reinstalls the machine from REPOURL#The reinstall opt is $reinstall_opt #g;
	s#ARGS# $reinstall_opt #g;
	s#</mail>#$reinstall_email$&#;
	print $template_tmp $_;
    }
    close $template_re;
    close $template_tmp;



    if (not (-e $cmd_reinstall_xml)) {
        &log(LOG_ERR, "file $cmd_reinstall_xml does not exist");
        print $sock_handle "file $cmd_reinstall_xml does not exist\n";
        return;
    }

    my $ref = &parse_xml($sock_handle, $cmd_reinstall_xml);
    return if( not defined $ref );
    # set the default values

    my $job_id = &transaction($ref,$host,$cmd_reinstall_xml);

    &log(LOG_INFO,"MASTER::FUNCTIONS cmdline Reinstall Job send to scheduler, at $host internal id: $job_id");
    print $sock_handle "MASTER::FUNCTIONS cmdline Reinstall Job send to scheduler, at $host internal id: $job_id\n";


}


sub send_line_job_to_host () {
    my $sock_handle = shift @_;
    my $cmd = shift @_ ;

    &log(LOG_NOTICE, "cmd = $cmd");
    (my @cmd_line) = split / /,$cmd;
    my $ol_tag = "";
    $ol_tag = $cmd_line[8] if(@cmd_line >= 9);
    $ol_tag="with tag $ol_tag" if($ol_tag);
    my $ol_email = "" ;
    $ol_email = $cmd_line[7] if(@cmd_line >= 8);
    my $one_line_cmd = $cmd_line[6];
    $one_line_cmd =~ s/#/ /g;
    my $host = $cmd_line[5];

    return if &handle_can_not_send_job_to_machine($host, $sock_handle, $user_id);

    #modify the custom xml file
    open(my $c_step1,"/usr/share/hamsta/xml_files/templates/customjob-template1.xml") or ( print $sock_handle "can open custom job step1 template\n" and return);
    open(my $c_step2,"/usr/share/hamsta/xml_files/templates/customjob-template2.xml") or ( print $sock_handle "can open custom job step2  template\n" and return);
    my $v = time;
    my $one_line_xml="/tmp/one_line_job_${host}_$v.xml";
    open(my $template_tmp,">","$one_line_xml") or ( print $sock_handle "can not write custom job template\n" and return);

    while(<$c_step1>){

	s#JOBNAME#command job $ol_tag from cmdline #;
	s#DEBUGLEVEL#4#;
	s#MAILTO#$ol_email#;
	s#RPMLIST##;
	s#MOTDMSG# one line job was running#;
	print $template_tmp $_;

    }
    #add command
    print $template_tmp $one_line_cmd,"\n";

    while(<$c_step2>){
	print $template_tmp $_;
    }

    close $c_step1;
    close $c_step2;
    close $template_tmp;



    if (not (-e $one_line_xml)) {
        &log(LOG_ERR, "file $one_line_xml does not exist");
        print $sock_handle "file $one_line_xml does not exist\n";
        return;
    }else {
	system("/usr/share/qa/tools/xml_convert.pl","$one_line_xml","$one_line_xml.c");
	system("mv","$one_line_xml.c","$one_line_xml");

    }

    my $ref = &parse_xml($sock_handle, "$one_line_xml");
    return if( not defined $ref );
    # set the default values

    my $job_id = &transaction($ref,$host,"$one_line_xml");

    &log(LOG_INFO,"MASTER::FUNCTIONS cmdline one line Job send to scheduler, at $host internal id: $job_id");
    print $sock_handle "MASTER::FUNCTIONS cmdline one line Job send to scheduler, at $host internal id: $job_id\n";
}

sub send_xen_set_to_host () {
    my $sock_handle = shift @_;
    my $cmd = shift @_ ;

    &log(LOG_NOTICE, "cmd = $cmd");
    (my @cmd_line) = split / /,$cmd;
    my $xen_set_tag = $cmd_line[-1];
    my $host = $cmd_line[-2];


    #modify the custom xml file
    open(my $xen_set,"/usr/share/hamsta/xml_files/set_xen_default.xml") or ( print $sock_handle "can open set xen xml file\n" and return);
    my $xen_set_xml="/tmp/xen_set_$xen_set_tag.xml";
    open(my $template_tmp,">","$xen_set_xml") or ( print $sock_handle "can not write set xen template\n" and return);

    while(<$xen_set>){

	s#DefaultXENGrub#set xen with tag $xen_set_tag  #;
	print $template_tmp $_;

    }
    close $xen_set;
    close $template_tmp;



    if (not (-e $xen_set_xml)) {
        &log(LOG_ERR, "file $xen_set_xml does not exist");
        print $sock_handle "file $xen_set_xml does not exist\n";
        return;
    }

    my $ref = &parse_xml($sock_handle, $xen_set_xml);
    return if( not defined $ref );
    # set the default values

    my $job_id = &transaction($ref,$host,$xen_set_xml);

    &log(LOG_INFO,"MASTER::FUNCTIONS cmdline xen set Job send to scheduler, at $host internal id: $job_id");
    print $sock_handle "MASTER::FUNCTIONS cmdline xen set Job send to scheduler, at $host internal id: $job_id\n";
}

sub send_qa_package_job_to_host () {
    my $sock_handle = shift @_;
    my $cmd = shift @_ ;

    &log(LOG_NOTICE, "cmd = $cmd");
    (my @cmd_line) = split / /,$cmd;
    #qa package test . qpt
    my $qpt_tag = "";
    $qpt_tag = $cmd_line[6] if(@cmd_line >= 7);
    $qpt_tag = "with tag ".$qpt_tag if($qpt_tag);
    my $qpt_email = "";
    $qpt_email = $cmd_line[5] if(@cmd_line >= 6);
    my $qpt_name = $cmd_line[4];
    $qpt_name =~ s/#/ /g;
    my $host = $cmd_line[3];

    return if &handle_can_not_send_job_to_machine($host, $sock_handle, $user_id);

    print $sock_handle "qa package job:$qpt_name \n";


    #modify the custom xml file
    open(my $qpt_template,"/usr/share/hamsta/xml_files/templates/qapackagejob-template.xml") or ( print $sock_handle "can open QA package job template\n" and return);
    my $v=time;
    my $qpt_xml="/tmp/qpt_$qpt_tag$v.xml";
    open(my $template_tmp,">","$qpt_xml") or ( print $sock_handle "can not write custom job template\n" and return);
    my $shotname = substr($qpt_name,0,20);
    while(<$qpt_template>){

	s#TS_LIST_SHORT#QA package job : $shotname $qpt_tag  #;
	s#DEBUGLEVEL#4#;
	s#</mail>#$qpt_email$&#;
	s#TS_LIST#$qpt_name#;
	print $template_tmp $_;

    }
    close $qpt_template;
    close $template_tmp;



    if (not (-e $qpt_xml)) {
        &log(LOG_ERR, "file $qpt_xml does not exist");
        print $sock_handle "file $qpt_xml does not exist\n";
        return;
    }

    my $ref = &parse_xml($sock_handle, $qpt_xml);
    return if( not defined $ref );
    # set the default values

    my $job_id = &transaction($ref,$host,$qpt_xml);
    &log(LOG_INFO,"MASTER::FUNCTIONS cmdline QA package Job send to scheduler, at $host internal id: $job_id");
    print $sock_handle "MASTER::FUNCTIONS cmdline QA package Job send to scheduler, at $host internal id: $job_id\n";
}

sub send_job_to_group() {

	die "Not implemented";
    my $sock_handle = shift @_;
    my $cmd = shift @_ ;
    (my @cmd_line) = split / /,$cmd;
    my $group = $cmd_line[-2];
    my $file = $cmd_line[-1];

    # file check
    if ( ! -e $file) {
        print $sock_handle "file $file does not exist!\n";
        return;
    }
    my $group_id = $dbc->enum_get_id('group',$group);
    if( !$group_id )
    {	print $sock_handle "Group $group does not exist!\n";	}
    else
    {
        my $ref = &parse_xml($sock_handle, $file);
        return if( not defined $ref );

        my $group_job_id = &group_job_insert(
            $ref->{'config'}->{'name'}->{'content'},
            $file,
            $ref->{'config'}->{'description'}->{'content'} || '',
            $ref->{'config'}->{'mail'}->{'content'} || $group,
            0,
            $group_id
        );
    }
}

sub transaction(){
    my $ref=shift;
    my $host=shift;
    my $xml=shift;

    &TRANSACTION( 'job', 'user' );
    my $email = $ref->{'config'}->{'description'}->{'content'};
    my $default_user_id = &user_get_default_id;
    my $user_id = (defined $email)? &user_get_id_by_email($email): $default_user_id;
    $user_id = $default_user_id if not defined $user_id;
        
    my $job_id = &job_insert(
        $ref->{'config'}->{'name'}->{'content'}, # short_name
        $xml, # xml_file
        $ref->{'config'}->{'description'}->{'content'} || '', # description
        #$ref->{'config'}->{'mail'}->{'content'} || $host, # job_owner
        $user_id, #user_id
        JS_NEW, # job_status_id
        $host ne "none" ? $host : undef # aimed_host
    );
    &TRANSACTION_END;
    return $job_id;
}

sub nitoi(){
    my $host = shift;
    unless( $host =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ )
    {
      my @hostinfo = gethostbyname($host);
      $host = join( '.', unpack( "C4", $hostinfo[4] )) if( @hostinfo > 4 );
    }
    return $host;
}

# Checks the user exists in Hamsta and provides correct password.
sub log_in ($$) # socket handle, command line
{
	my $sock_handle = shift;
	# log in <login> [<passwd>]
	my @cmd = split ' ', shift (@_);
	my $use_auth = use_master_authentication ();

	my $login;
	my $passwd;

	if ($use_auth) {
		unless (@cmd > 3) {
			print $sock_handle "Not enough parameters. Try `help'.\n";
			return 0;
		} else {
			$passwd = $cmd[3];
		}
	} else {
		unless (@cmd > 2) {
			print $sock_handle "Not enough parameters. Try `help'.\n";
			return 0;
		}
	}

	$login = $cmd[2];

	if (my $local_user_id = user_get_id ($login)) {
		if ($use_auth) {
			if ($passwd) {
				my $db_passwd = user_get_password ($login);
				# The password can be hashed (Hamsta web) or plain
				# text
				if ($db_passwd && (sha1_hex ($passwd) eq $db_passwd
								   || $passwd eq $db_passwd)) {
					$user_id = $local_user_id;
				}
			}
		} else {
			# Authentication is disabled and the user can log in
			# without password
			$user_id = $local_user_id;
		}
	}

	if ($user_id) {
		print $sock_handle "You were authenticated as '${login}'."
			. " Send your commands.\n";
		return 1;
	}

	print $sock_handle "Could not authenticate. Check your credentials.\n";
	return 0;
}

# Print status of current user, reserved machines and possibly other
# information
sub print_status ($) # socket
{
    my $sock_handle = shift;
    if (get_logged_status ()) {
	print $sock_handle "You are logged in as '"
	    . user_get_login ($user_id) . "'.\n";
	if (defined ($user_id)) {
	    my @res_machines = user_get_reserved_machines ($user_id);
	    local $" = "', '";
	    if ( scalar @res_machines ) {
		print $sock_handle "You have reserved machines '@res_machines'.\n";
	    } else {
		print $sock_handle "You have no reserved machines.\n";
	    }
	}
    } else {
	print $sock_handle "You have to be logged in to print your status.\n";
    }
}

# With parameter prints only roles of the user, all roles otherwise
sub print_roles ($$) # socket handle, [user_login]
{
    my $sock_handle = shift;
    my @cmd = split ' ', shift (@_);
    my $login;
    if (@cmd > 2) {
	$login = $cmd[2];
    }
    local $" = "', '";
    if (defined ($login)) {
	my $user_id = user_get_id ($login);
	if (defined($user_id)) {
	    my @user_roles = user_get_roles ($user_id);
	    print $sock_handle
		"Roles available to user '${login}': '@user_roles'.\n";
	} else {
	    print $sock_handle "Unknown user '${login}'.\n";
	}
    } else {
	my @all_roles = role_list_all ();
	print $sock_handle "Available roles: '@all_roles'.\n";
    }
}

sub log_out () {
    my $sock_handle = shift;
    undef $user_id;
    print $sock_handle "You have been succesfully logged out.\n";
    return 1;
}

### Support functions for user authentication

# Returns 1 when user is logged in, 0 otherwise.
sub get_logged_status ()
{
    return defined ($user_id);
}

# Prints list of user privileges
sub print_privileges ($) # socket handle
{
    my $sock_handle = shift;
    if (get_logged_status ()) {
	local $" = ", ";
	my @privileges = user_get_privileges ($user_id);
	print $sock_handle "@privileges";
    } else {
	print $sock_handle "You have to be logged in to print your privileges.";
    }
}

sub print_can_user ($) # action
{
    my $sock_handle = shift;
    my @cmd = split ' ', shift (@_);
    if (get_logged_status()) {
	print $sock_handle "You are "
	    . (is_allowed ($user_id, $cmd[2]) ? "" : "not ")
	    . "allowed to do that.";
    } else {
	print $sock_handle "You are not logged in.";
    }
}

# Returns 1 if the user has access to all privileges, 0 otherwise.
sub is_allowed ($@) # user_id, privilege[s]
{
    my $loc_user_id = shift;
    my @privilege_names = shift;
    my @user_privileges = user_get_privileges ($loc_user_id);
    my $privileged = 0;

    foreach (@privilege_names) {
	my $name = $_;
	$privileged++ if scalar (grep /$name/, @user_privileges);
    }
    return $privileged == scalar @privilege_names;
}

sub user_is_allowed ($@) {
    my $local_user_id = shift;
    my @privilege_names = shift;

    return 1 unless use_master_authentication();

    if (get_logged_status()) {
	return is_allowed ($local_user_id, @privilege_names);
    }

    return 0;
}

# Logs and prints information that user does not have privileges.
sub notify_about_no_privileges ($$$) # socket, user_id, host
{
    my $socket_handle = shift;
    my $user_id = shift;
    my $host = shift;
    my $login = user_get_login ($user_id);
    &log (LOG_NOTICE, "User '${login}' does not have privileges to send a job to '${host}'");
    print $socket_handle "You do not have privileges to send a job to '${host}'.\n"
	. "Please provide your Hamsta password. You can set it at the Hamsta frontend (user page).\n";
}

sub print_user_can_send_jobs ($)
{
    my $sock_handle = shift;
    my @cmd = split ' ', shift (@_);
    my $m_ip = $cmd[2];

    my $conf = use_master_authentication ();
    my $my_machine = machine_get_id_by_ip_user_id ($m_ip, $user_id);
    my $msj = is_allowed ($user_id, 'machine_send_job');
    my $msjr = is_allowed ($user_id, 'machine_send_job_reserved');

    print $sock_handle "You can "
	. (can_send_job_to_machine ($m_ip) ? "" : "not ")
	. "send jobs to machine '${m_ip}'.";
}

sub can_send_job_to_machine ($) # machine ip
{
    return 1 unless use_master_authentication ();
    my $m_ip = shift;
    return 0 unless (defined ($m_ip) && defined ($user_id));
    my $my_machine = machine_get_id_by_ip_user_id ($m_ip, $user_id);
    if ((is_allowed ($user_id, 'machine_send_job') && defined ($my_machine))
	    || is_allowed ($user_id, 'machine_send_job_reserved')
	    || is_allowed ($user_id, 'admin')) {
	return 1;
    }
    return 0;
}

sub handle_can_not_send_job_to_machine ()
{
    my $host = shift;
    my $sock_handle = shift;
    my $user_id = shift;

    if (! &can_send_job_to_machine ($host)) {
	    $dbc->commit();
	    &notify_about_no_privileges ($sock_handle, $user_id, $host);
	    return 1;
    }
    $dbc->commit();
    return 0;
}

sub cmd_print_all_machines ($) # socket
{
    my $sock_handle = shift;
    my @cmd = shift;
    my $machinesref = machine_list_all ();
    print $sock_handle "List of all available machines.\n";
    printf $sock_handle "%15s : %15s : %s\n", "MACHINE", "IP ADDRESS", "STATUS";
    foreach (@{$machinesref}) {
	printf $sock_handle "%15s : %15s : %s\n", ${$_}[0], ${$_}[1], ${$_}[2];
    }
}

#Log to log file and send to sock given message
sub log_and_send_sock_msg(){
    my $log_sevirity = shift;
    my $sock = shift;
    my $log_message = shift;
    &log($log_sevirity, $log_message);
    print $sock $log_message."\n" if (defined $sock);
}


#This function deals with reservation from master.
#Supports both reserve and release SUT from both master CLI and jobs.
#Return value is only useful to jobs, return 0 means failure, return 1 means success.
sub process_hamsta_reservation () {
    # For reserve or release from CLI, sock_handle is the socket between CLI and frontend
    # Or it is from job, sock_handle is undef
    my $sock_handle = shift @_;
    my $action = shift;
    my $host = shift;

    $| =1;
    $sock_handle->autoflush(1) if (defined $sock_handle);

    &log(LOG_DETAIL, "Input is: action => $action, host => $host");

    if (! $action or ! $host){
	&log_and_send_sock_msg(LOG_ERR, $sock_handle, "MASTER::CMDLINE Invalid input received: action => $action, host => $host .");
	return 0;
    }

    return if &handle_can_not_send_job_to_machine($host, $sock_handle, $user_id);


    my $port = $qaconf{hamsta_client_port};
    my $sock;

    eval {
	$sock = IO::Socket::INET->new(
	PeerAddr => "$host",
	PeerPort => $port,
	Proto   => 'tcp'
	);
    };
    if(!$sock || $@) {
	&log_and_send_sock_msg(LOG_ERR, $sock_handle, "Can not connect to ip port $port for $action :$@ $!");
	return 0;
    }

    $sock->autoflush(1);

    eval {
	$sock->send("$action\n");
    };
    if($@) {
	&log_and_send_sock_msg(LOG_ERR, $sock_handle, "Error happened when sending $action to SUT:$@");
	return 0;
    }

    log(LOG_DETAIL,"MASTER::CMDLINE Send $action to SUT");
    my $response = '';
    my $line;
    log(LOG_DETAIL,"MASTER::CMDLINE The opened socket to SUT for rsv/rls is $sock");
    while($line=<$sock>){
	chomp($line);
	$response .= $line;
    }
    $sock->close();

    print $sock_handle "MASTER::CMDLINE $response\n" if (defined $sock_handle);
    log(LOG_DETAIL,"MASTER::CMDLINE get complete response:$response");

    return 0 unless ($response =~ /succeeded/);

    my $machine_id = &machine_get_by_ip($host);
    my $new_reserved_hamsta_master_ip = '';
    $new_reserved_hamsta_master_ip = &get_my_ip_addr if ($action eq 'reserve');
    log(LOG_DETAIL, "MASTER::CMDLINE is updating the reserved hamsta master of the machine #$machine_id to $new_reserved_hamsta_master_ip...");
    &update_machine_hamsta_master_reservation($machine_id, $new_reserved_hamsta_master_ip);
    log(LOG_DETAIL, "MASTER::CMDLINE finishes updating the reserved hamsta master of the machine #$machine_id!");
    return 1;
}

# Parameters
# socket
# string reserve or release
# machine id
# user login
# machine identification (hostname or IP address) for printing
#
# Returns:
# 0 - for error (aka false)
# 1 - for successfull reservation
# 2 - for successfull release
sub process_user_reservation ($$$$$)
{
    my $sock_handle = shift;
    my ($action, $machine_id, $login, $identifier) = @_;
    my $res = 0;

    # Translate from login to user id
    my $local_user_id = user_get_id ($login);
    unless ($local_user_id) {
	print $sock_handle "User $login does not exist.\n";
	return $res;
    }

    if ($local_user_id) {
	my $logged_user_has_reservation = user_has_reservation ($machine_id, $user_id);
	my $user_has_reservation = user_has_reservation ($machine_id, $local_user_id);

	switch ($action) {
	    case 'reserve' {
		log(LOG_INFO, "User $login requests reservation for machine $identifier");
		# Allow reserving if the machine has no reservations
		# or user is allowed to reserve already reserved
		# machines
		unless ((user_is_allowed ($user_id, 'machine_edit')
			 and ($logged_user_has_reservation or not machine_reservations ($machine_id)))
			or user_is_allowed ($user_id, 'machine_edit_reserved')) {
		    print $sock_handle "You do not have privilege to reserve this machine.\n";
		    return $res;
		}

		if ($user_has_reservation) {
		    my $output = "User $login has machine $identifier reserved already.";
		    log(LOG_INFO, $output);
		    print $sock_handle "$output\n";
		    return $res;
		}

		TRANSACTION('user_machine');
		# TODO Add support for user notes and expire time
		if (user_machine_insert ($machine_id, $local_user_id, '', undef)) {
		    $res = 1;
		    my $output = "Reserved machine $identifier for user $login.";
		    log (LOG_INFO, $output);
		    print $sock_handle "$output\n";
		}
		TRANSACTION_END();
	    }

	    case 'release' {
		log(LOG_INFO, "User $login requests release of machine $identifier");
		unless ((user_is_allowed ($user_id, 'machine_free')
			 and ($logged_user_has_reservation)) 
			or user_is_allowed ($user_id, 'machine_free_reserved')) {
		    print $sock_handle "You do not have privileges to release (free) this machine.\n";
		    return $res;
		}

		unless ($user_has_reservation) {
		    my $output = "User $login has no reservation on machine $identifier.";
		    log(LOG_INFO, $output);
		    print $sock_handle "$output\n";
		    return $res;
		}

		TRANSACTION('user_machine');
		if (user_machine_delete ($machine_id, $local_user_id)) {
		    $res = 2;
		    my $output = "Released machine $login for user $login.";
		    log (LOG_INFO, $output);
		    print $sock_handle "$output\n";
		}
		TRANSACTION_END();
	    }
	}
    }
    return $res;
}

# Params: socket, command
#
# Expected commmand syntax:
# (reserve|release) ([\w\d.-]+) for (user|master) ([\w\d.-]+)
#
# The second capture group contains machine hostname or IP
# The last capture group is only for the user reservation.
#
sub reserve_release
{
    # The $cmd should contain
    # 0 - 'reserve|release'
    # 1 - hostname or IP address
    # 2 - string 'for'
    # 3 - 'user|master'
    # 4 - user login or empty
    my $sock_handle = shift;
    my @cmd = split ' ', shift (@_);
    my $output = '';

    # Check we have at least the values we need
    if (not @cmd or (@cmd < 4)) {
	print $sock_handle 'Bad command syntax. Please fix your command and send it again.\n';
	return;
    }

    my $machines = mih ();
    # Translate from hostname or IP address to machine ID.
    my $machine_ip = $machines->{$cmd[1]} ?
	$machines->{$cmd[1]} : $cmd[1];
    my $machine_id = machine_get_by_ip ($machine_ip);

    unless ($machine_id) {
	print $sock_handle, "Could not find the machine $cmd[1]\n";
	return;
    }

    switch ($cmd[3]) {
	case 'user' {
	    if ($cmd[4]) {
		process_user_reservation ($sock_handle, $cmd[0],
					  $machine_id, $cmd[4],
					  $cmd[1]);
	    } else {
		$output = "You have to specify the user.";
	    }
	}
	case 'master' {
	    &process_hamsta_reservation ($sock_handle, $cmd[0], $machine_ip);
	}
	else {
	    $output = 'Reservation target can be only "user" or "master".'
	}
    }
    print $sock_handle "$output\n" if $output;
}

1;
