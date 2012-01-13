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

use Switch;
use XML::Simple;

use hwinfo_xml_sql;
use threads;

use qaconfig;
require sql;

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
# when the command line client sends data to master, this data is parsed here
sub parse_cmd() {
    my $cmd = shift @_;
    my $sock_handle = shift @_;

    switch ($cmd) {
        case /^print active/ 	    { &cmd_print_active($sock_handle); }
#        case /^which job where/		{ &which_job_where(); }
#        case /^search hardware/		{ &which_hardware_where($sock_handle, $cmd); }
        case /^print groups/	 	{ &cmd_print_groups($sock_handle, $cmd); }
#        case /^group add host/		{ &group_add_host($sock_handle, $cmd); } 
#        case /^group del host/		{ &group_delete_host($sock_handle, $cmd); }
#        case /^group_add/			{ &create_group($sock_handle, $cmd); }
#        case /^group_del/			{ &delete_group($sock_handle, $cmd); }
#        case /^send job group/		{ &send_job_to_group($sock_handle, $cmd); }
        case /^send job ip/			{ &send_job_to_host($sock_handle, $cmd); }
        case /^send qa_predefine_job/			{ &send_predefine_job_to_host($sock_handle, $cmd); }
        case /^send qa_package_job ip/			{ &send_qa_package_job_to_host($sock_handle, $cmd); }
        case /^send autotest_job ip/			{ &send_autotest_job_to_host($sock_handle, $cmd); }
        case /^send xen set ip/			{ &send_xen_set_to_host($sock_handle, $cmd); }
        case /^send reinstall ip/		{ &send_re_job_to_host($sock_handle, $cmd); }
        case /^send one line cmd ip/		{ &send_line_job_to_host($sock_handle, $cmd); }
        case /^send job anywhere/	{ $cmd =~ s/anywhere/ip none/; &send_job_to_host($sock_handle, $cmd); }
	case /^list jobtype/		{ &list_testcases($sock_handle,$cmd); }


        case /^help/			    { &cmd_help($sock_handle); }
        else 			{ 
            if ($cmd eq '') {
                print $sock_handle "no command entered, try >help< \n"; 
            } else {
                print $sock_handle "command not found, try >help< \n"; 

            }
        }
    } 
}

# Master->cmd_help()
#
# Prints the command line interface help
sub cmd_help() {
    my $sock_handle = shift @_;
    select ($sock_handle);

    print "Following commands are implemented: \n";
    print "syntax = 'command' : explaination \n ";
    print "\t 'print active' : prints all reachable hosts \n";
    print "\t 'search hardware <perl-pattern (Regular Expression) oder string>' : prints all hosts which hwinfo-output matches the desired string/pattern \n";
    print "\t 'save groups to </path/file>' : save (dumps) the groups as XML in the specific file (relativ to Master root-directory) \n";
    print "\t 'load groups from </path/file>' : loads the specified XML-groups-file \n";
    print "\t 'print groups' : prints groups (from SQL) \n";
    print "\t 'group_add <name>' : creates a new group \n";
    print "\t 'group_del <name>' : be aware, deletes group (with all members)  \n";
    print "\t 'group add host <group> <IP>' : adds <IP> to the group, no wildcards (atm.) \n";
    print "\t 'group del host <group> <IP>' : removes <IP> from the group, no wildcards (atm.) \n";
    print "\t 'send job group <group> <file>' : submits the job to all members in the group  \n";
    print "\t 'send job ip <IP> <file>' : submits the job to the IP  \n";
    print "\t 'send qa_package_job ip <IP> <PACKAGE NAME> <Email> <Tag>' : submits the job to the IP  \n";
    print "\t 'send xen set ip <IP> <Tag>' : submits the job to the IP  \n";
    print "\t 'send reinstall ip <IP> <Reinstall_repo> <Email> <Tag> ' : submits the reinstall job to the IP  \n";
    print "\t 'send one line cmd ip <IP> <cmd> <Email> <Tag>' : submits the one line job to the IP (replace space with # in cmd)  \n";
    print "\n end of help \n";

}


# Master->cmd_print_active
# 
# Print the IP address, hostname and description of all hosts in status "up"
sub cmd_print_active()  {
    my $sock_handle = shift @_;

    my $machines = &machine_search('fields'=>[qw(ip name description)],'return'=>'matrix','machine_status_id'=>MS_UP);

    foreach my $machine (@$machines) {
        print $sock_handle "IP: ".$machine->[0]."\t".$machine->[1].":\t".$machine->[2]."\n";
    }
}

sub cmd_print_groups() {
    my $sock_handle = shift @_;
    
    my @groups = $dbc->enum_list_vals('group');
    foreach my $group (@groups) {
        print $sock_handle $group->[0] . ": ";

	my $group_id = $dbc->enum_get_id('group',$group->[0]);
	unless( $group_id )
	{	print $sock_handle "Unknown group ".$group->[0]."\n";	}
	else
	{
		my $data = &group_list_status($group->[0]);
		foreach my $row(@$data)
		{	print $sock_handle, join("\t",@$row);	}
        }

        print $sock_handle "\n";
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
    my $jobtype = shift @_;
    my @jobtype = split /\s+/,$jobtype;
    $jobtype=$jobtype[2];
    
    if($jobtype !~ /^[1-3]$/) {
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

    if($jobtype==2) {
    #for qa package job
    print $sock_handle "----QA package job list----\n";
    my $rs=0;
    open my $tmpfh,"/srv/www/htdocs/hamsta/config.php" || (print $sock_handle "can't open config file\n" and return);
    while(my $qa_p=<$tmpfh>){
      next unless($qa_p =~ /TSLIST/);
      $qa_p =~ s/.*,\s*\"//;
      $qa_p =~ s/\".*//;
      map { $rs++;$return.="$_ ";$return.="\n" if($rs%4==0) } split /\s+/,$qa_p;
      last;
    }
    close $tmpfh;
    print $sock_handle $return;
    return;
    


    }
    if($jobtype==3) {
    #for autotest job
    print $sock_handle "----Autotest job list----\n";
    my $rs=0;
    open my $tmpfh,"/srv/www/htdocs/hamsta/config.php" || (print $sock_handle "can't open config file\n" and return);
    while(my $qa_p=<$tmpfh>){
      next unless($qa_p =~ /ATLIST/);
      $qa_p =~ s/.*,\s*\"//;
      $qa_p =~ s/\".*//;
      map { $rs++;$return.="$_ ";$return.="\n" if($rs%4==0) } split /\s+/,$qa_p;
      last;
    }
    close $tmpfh;
    print $sock_handle $return;
    return;

    }
	


}
sub send_predefine_job_to_host() {
    my $sock_handle = shift @_; 
    my $cmd = shift @_ ;
    &log(LOG_NOTICE, "cmd = $cmd");
    
    (my @cmd_line) = split / /,$cmd;
    my $file = $cmd_line[3]; 
    my $host = $cmd_line[2]; 
    my $email = "";
    $email = $cmd_line[4] if(@cmd_line >= 5);

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
    my $ofile="/tmp/command_line_pre_def_${host}_$v.xml";
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
    my $job_id = &transation($ref,$host,$ofile);

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
    my $job_id = &transation($ref,$host,$at_xml);

    &log(LOG_INFO,"MASTER::FUNCTIONS cmdline Autotest Job $at_name send to scheduler, at $host internal id: $job_id");
    print $sock_handle "MASTER::FUNCTIONS cmdline Autotest Job $at_name send to scheduler, at $host internal id: $job_id\n";
    return;



}
sub send_job_to_host () {
    my $sock_handle = shift @_;
    my $cmd = shift @_ ;

    &log(LOG_NOTICE, "cmd = $cmd");
    (my @cmd_line) = split / /,$cmd;
    my $file = $cmd_line[-1]; 
    my $host = $cmd_line[-2]; 

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

    my $job_id = &transation($ref,$host,$file);

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

    my $job_id = &transation($ref,$host,$cmd_reinstall_xml);

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
   
    my $job_id = &transation($ref,$host,$one_line_xml);

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

    my $job_id = &transation($ref,$host,$xen_set_xml);

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

    my $job_id = &transation($ref,$host,$qpt_xml);
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

sub transation(){
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

1;
