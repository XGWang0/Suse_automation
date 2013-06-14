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
            my $thread = threads->new(\&thread_auswertung, $new_sock);
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

# Master->thread_auswertung()
#
# this function is the first after a client connect (user connection)
# so it checks (asks for) user/password and after holds the connection and loops
# in the interaction between master und client
# TODO more debug information needed eg who is connected from where

sub thread_auswertung () {
    my $sock_handle = shift @_;

    local $SIG{'PIPE'} = 'IGNORE';

    print $sock_handle "Welcome to HAMSTA (hardware maintenance and shared testautomation), console. \n";
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
    }

    close $sock_handle;
}

# Master->parse_cmd()
#
# when the command line client sends data to master, this data is
# parsed here and appropriate handler is executed.
sub parse_cmd() {
    my $cmd = shift @_;
    my $sock_handle = shift @_;
    
    #verify the hostname & ip
    if ($cmd =~ / ip ([^ ]+) /) {
        my $host = $1;
        my $mihash = &mih;
	if (defined($mihash->{$host})) {
	    my $ip = $mihash->{$host};
	    $cmd =~ s/ ip [^ ]+ / ip $ip /;
	} else {
	    print $sock_handle "Hostname Not Available\n";
	    goto SWSW;
	}
    }

    switch ($cmd) {
	case /^(print|list) all/	{ cmd_print_all_machines ($sock_handle); }
        case /^(print|list) active/     { cmd_print_active($sock_handle); }
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

# Master->cmd_help()
#
# Prints the command line interface help
sub cmd_help() {
    my $sock_handle = shift @_;
    select ($sock_handle);

    print "Following commands are available. 'list' can be used instead of 'print'.\n";
    print "syntax = 'command' : explanation \n";
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
    print "\n end of help \n";
}

# Master->cmd_print_active
#
# Print the IP address, hostname and description of all hosts in status "up"
sub cmd_print_active()  {
    my $sock_handle = shift @_;

    my $machines = &machine_search('fields'=>[qw(ip name description)],'return'=>'matrix','machine_status_id'=>MS_UP);
    print $sock_handle "List of active machines (status up).\n";
    printf $sock_handle "%15s : %15s : %s\n", "MACHINE", "IP ADDRESS", "DESCRIPTION";
    foreach my $machine (@$machines) {
        printf $sock_handle "%15s : %15s : %s\n", $machine->[1], $machine->[0], $machine->[2];
    }
}

#build machine ip hash
sub mih() {
  my $miref = {};
  my $machines = &machine_search('fields'=>[qw(ip name)],'return'=>'matrix','machine_status_id'=>MS_UP);
  foreach my $machine (@$machines) {
    $miref->{$machine->[1]} = $machine->[0];
    $miref->{$machine->[0]} = $machine->[0];
  }
  return $miref;
}

sub cmd_print_groups() {
    my $sock_handle = shift @_;
    my @groups = $dbc->enum_list_vals ('group');
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
		$dbc->enum_insert_id('group',$group);
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

    if (! can_send_job_to_machine ($host)) {
	notify_about_no_privileges ($sock_handle, $user_id, $host);
	return;
    }

    print $sock_handle "Pre-define job:$file \n\n";

    if( not &check_host($host)){
      &log(LOG_WARNING, "$host is not active, maybe IP address misspelled");
      print $sock_handle "$host is not active, maybe IP address misspelled\n";
      return;
    }

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

    if( not &check_host($host)){
      &log(LOG_WARNING, "$host is not active, maybe IP address misspelled");
      print $sock_handle "$host is not active, maybe IP address misspelled\n";
      return;
    }

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
      if (! can_send_job_to_machine ($host)) {
	  notify_about_no_privileges ($sock_handle, $user_id, $host);
	  return;
      }

      if( not &check_host($host)){
        &log(LOG_WARNING, "$host is not active, maybe IP address misspelled");
        print $sock_handle "$host is not active, maybe IP address misspelled\n";
        return;
      }
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

    if (! can_send_job_to_machine ($host)) {
	notify_about_no_privileges ($sock_handle, $user_id, $host);
	return;
    }

    if( not &check_host($host)){
      &log(LOG_WARNING, "$host is not active, maybe IP address misspelled");
      print $sock_handle "$host is not active, maybe IP address misspelled\n";
      return;
    }

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

    if (! can_send_job_to_machine ($host)) {
	notify_about_no_privileges ($sock_handle, $user_id, $host);
	return;
    }

    if( not &check_host($host)){
      &log(LOG_WARNING, "$host is not active, maybe IP address misspelled");
      print $sock_handle "$host is not active, maybe IP address misspelled\n";
      return;
    }

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

    if (! can_send_job_to_machine ($host)) {
	notify_about_no_privileges ($sock_handle, $user_id, $host);
	return;
    }

    if( not &check_host($host)){
      &log(LOG_WARNING, "$host is not active, maybe IP address misspelled");
      print $sock_handle "$host is not active, maybe IP address misspelled\n";
      return;
    }

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
    }

    my $ref = &parse_xml($sock_handle, $one_line_xml);
    return if( not defined $ref );
    # set the default values

    my $job_id = &transaction($ref,$host,$one_line_xml);

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

    if( not &check_host($host)){
      &log(LOG_WARNING, "$host is not active, maybe IP address misspelled");
      print $sock_handle "$host is not active, maybe IP address misspelled\n";
      return;
    }

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

    if (! can_send_job_to_machine ($host)) {
	notify_about_no_privileges ($sock_handle, $user_id, $host);
	return;
    }

    print $sock_handle "qa package job:$qpt_name \n";

    if( not &check_host($host)){
      &log(LOG_WARNING, "$host is not active, maybe IP address misspelled");
      print $sock_handle "$host is not active, maybe IP address misspelled\n";
      return;
    }

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

sub check_host() {
    my $host = shift;
    unless ($host eq "none") {
        my @tmp_hosts = &machine_search('fields'=>['ip'], 'return'=>'vector');
        &log(LOG_DETAIL, "MASTER:: IPs ARE ".join(',',@tmp_hosts));
        my %legal_ip = map {$_=>$_} @tmp_hosts;

        # convert hostname => IP address
	unless( $host =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ )
        {
            my @hostinfo = gethostbyname($host);
            $host = join( '.', unpack( "C4", $hostinfo[4] )) if( @hostinfo > 4 );
        }

        # checks
        return 1 if(exists($legal_ip{"$host"}));
        return 0;
    }
}

sub transaction(){
    my $ref=shift;
    my $host=shift;
    my $xml=shift;

    &TRANSACTION( 'job' );
    my $job_id = &job_insert(
        $ref->{'config'}->{'name'}->{'content'}, # short_name
        $xml, # xml_file
        $ref->{'config'}->{'description'}->{'content'} || '', # description
        $ref->{'config'}->{'mail'}->{'content'} || $host, # job_owner
        $ref->{'config'}->{'logdir'}->{'content'}, # slave directory
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
    # log in <login> <passwd>
    my @cmd = split ' ', shift (@_);
    unless (@cmd > 3) {
	print $sock_handle "Not enough parameters. Try `help'.\n";
	return 0;
    }
    my $login = $cmd[2];
    my $passwd = $cmd[3];
    my $local_user_id = user_get_id ($login);

    if ( defined ($local_user_id) ) {
	my $db_passwd = user_get_password ($login);
	# Sometimes we get the password sent already hashed (like from
	# the Hamsta web)
	if ( defined ($db_passwd)
		 && (sha1_hex ($passwd) eq $db_passwd
			 || $passwd eq $db_passwd) ) {
	    $user_id = $local_user_id;
	    print $sock_handle "You were authenticated as '${login}'."
		. " Send your commands.\n";
	    return 1;
	} else {
	    print $sock_handle "Wrong password. Try again.\n";
	}
    } else {
	print $sock_handle "Unknown Hamsta user '${login}'. Try again.\n";
    }
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

sub use_master_authentication ()
{
    return $qaconf{'hamsta_master_authentication'};
}

sub print_user_can_send_jobs ($)
{
    my $sock_handle = shift;
    my @cmd = split ' ', shift (@_);
    my $m_ip = $cmd[2];

    my $conf = use_master_authentication ();
    my $my_machine = machine_get_id_by_ip_usedby ($m_ip, $user_id);
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

1;
