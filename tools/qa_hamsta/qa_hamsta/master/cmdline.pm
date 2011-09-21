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
        case /^send reinstall ip/		{ &send_re_job_to_host($sock_handle, $cmd); }
        case /^send one line cmd ip/		{ &send_line_job_to_host($sock_handle, $cmd); }
        case /^send job anywhere/	{ $cmd =~ s/anywhere/ip none/; &send_job_to_host($sock_handle, $cmd); }

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


sub send_job_to_host () {
    my $sock_handle = shift @_;
    my $cmd = shift @_ ;

    &log(LOG_NOTICE, "cmd = $cmd");
    (my @cmd_line) = split / /,$cmd;
    my $file = $cmd_line[-1]; 
    my $host = $cmd_line[-2]; 

    #my $ref_backbone = &read_latest_backbone();

    unless ($host eq "none") {
        #while ((my $key, my $value) = each %{$ref_backbone->{'active'}}){ 
        #    my $tmp = $value->{'ip'};
        #    $tmp =~ s/ //g;
        #    $legal_ip{$tmp} = $key;
        #}
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
        if (not exists($legal_ip{"$host"})) { 
            &log(LOG_WARNING, "$host is not active, maybe IP address misspelled"); 
            print $sock_handle "$host is not active, maybe IP address misspelled\n"; 
            return; 
        }
    }
    
    if (not (-e $file)) {
        &log(LOG_ERR, "file $file does not exist"); 
        print $sock_handle "file $file does not exist\n"; 
        return;
    }

    my $ref = &parse_xml($sock_handle, $file);
    return if( not defined $ref );
    # set the default values 

    &TRANSACTION( 'job' );
    my $job_id = &job_insert(
        $ref->{'config'}->{'name'}->{'content'}, # short_name
        $file, # xml_file
        $ref->{'config'}->{'description'}->{'content'} || '', # description
        $ref->{'config'}->{'mail'}->{'content'} || $host, # job_owner
        $ref->{'config'}->{'logdir'}->{'content'}, # slave directory
        JS_NEW, # job_status_id
        $host ne "none" ? $host : undef # aimed_host
    );
    &TRANSACTION_END;

    &log(LOG_INFO,"MASTER::FUNCTIONS Job send to scheduler, at $host internal id: $job_id");
    print $sock_handle "MASTER::FUNCTIONS Job send to scheduler, at $host internal id: $job_id\n";


}


sub send_re_job_to_host () {
    my $sock_handle = shift @_;
    my $cmd = shift @_ ;

    &log(LOG_NOTICE, "cmd = $cmd");
    (my @cmd_line) = split / /,$cmd;
    my $reinstall_tag = $cmd_line[-1];
    my $reinstall_email = $cmd_line[-2];
    my $reinstall_url = $cmd_line[-3]; 
    my $host = $cmd_line[-4]; 

    #my $ref_backbone = &read_latest_backbone();

    unless ($host eq "none") {
        #while ((my $key, my $value) = each %{$ref_backbone->{'active'}}){ 
        #    my $tmp = $value->{'ip'};
        #    $tmp =~ s/ //g;
        #    $legal_ip{$tmp} = $key;
        #}
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
        if (not exists($legal_ip{"$host"})) { 
            &log(LOG_WARNING, "$host is not active, maybe IP address misspelled"); 
            print $sock_handle "$host is not active, maybe IP address misspelled\n"; 
            return; 
        }
    }
    
    #modify the reinstall xml file
    open(my $template_re,"/usr/share/hamsta/xml_files/templates/reinstall-template.xml") or ( print $sock_handle "can open reinstall template\n" && return);
    my $cmd_reinstall_xml="/tmp/command_line_reinstall_$reinstall_tag.xml";
    open(my $template_tmp,">","$cmd_reinstall_xml") or ( print $sock_handle "can write reinstall template\n" && return);
    while(<$template_re>){
	s#REPOURL#$reinstall_tag $reinstall_url #g;
	s#ARGS#-p $reinstall_url #g;
	s#llwang\@novell.com#$reinstall_email#;
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

    &TRANSACTION( 'job' );
    my $job_id = &job_insert(
        $ref->{'config'}->{'name'}->{'content'}, # short_name
        $cmd_reinstall_xml, # xml_file
        $ref->{'config'}->{'description'}->{'content'} || '', # description
        $ref->{'config'}->{'mail'}->{'content'} || $host, # job_owner
        $ref->{'config'}->{'logdir'}->{'content'}, # slave directory
        JS_NEW, # job_status_id
        $host ne "none" ? $host : undef # aimed_host
    );
    &TRANSACTION_END;

    &log(LOG_INFO,"MASTER::FUNCTIONS Reinstall Job send to scheduler, at $host internal id: $job_id");
    print $sock_handle "MASTER::FUNCTIONS Reinstall Job send to scheduler, at $host internal id: $job_id\n";


}


sub send_line_job_to_host () {
    my $sock_handle = shift @_;
    my $cmd = shift @_ ;

    &log(LOG_NOTICE, "cmd = $cmd");
    (my @cmd_line) = split / /,$cmd;
    my $ol_tag = $cmd_line[-1];
    my $ol_email = $cmd_line[-2]; 
    my $one_line_cmd = $cmd_line[-3]; 
    $one_line_cmd =~ s/#/ /g;
    my $host = $cmd_line[-4]; 

    #my $ref_backbone = &read_latest_backbone();

    unless ($host eq "none") {
        #while ((my $key, my $value) = each %{$ref_backbone->{'active'}}){ 
        #    my $tmp = $value->{'ip'};
        #    $tmp =~ s/ //g;
        #    $legal_ip{$tmp} = $key;
        #}
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
        if (not exists($legal_ip{"$host"})) { 
            &log(LOG_WARNING, "$host is not active, maybe IP address misspelled"); 
            print $sock_handle "$host is not active, maybe IP address misspelled\n"; 
            return; 
        }
    }

    #modify the custom xml file
    open(my $c_step1,"/usr/share/hamsta/xml_files/templates/customjob-template1.xml") or ( print $sock_handle "can open custom job step1 template\n" && return);
    open(my $c_step2,"/usr/share/hamsta/xml_files/templates/customjob-template2.xml") or ( print $sock_handle "can open custom job step2  template\n" && return);
    my $one_line_xml="/tmp/one_line_job_$ol_tag.xml";
    open(my $template_tmp,">","$one_line_xml") or ( print $sock_handle "can write custom job template\n" && return);
 
    while(<$c_step1>){

	s#JOBNAME#oneline job with tag $ol_tag  #;
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

    &TRANSACTION( 'job' );
    my $job_id = &job_insert(
        $ref->{'config'}->{'name'}->{'content'}, # short_name
        $one_line_xml, # xml_file
        $ref->{'config'}->{'description'}->{'content'} || '', # description
        $ref->{'config'}->{'mail'}->{'content'} || $host, # job_owner
        $ref->{'config'}->{'logdir'}->{'content'}, # slave directory
        JS_NEW, # job_status_id
        $host ne "none" ? $host : undef # aimed_host
    );
    &TRANSACTION_END;

    &log(LOG_INFO,"MASTER::FUNCTIONS one line Job send to scheduler, at $host internal id: $job_id");
    print $sock_handle "MASTER::FUNCTIONS one line Job send to scheduler, at $host internal id: $job_id\n";


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


1;
