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

package Slave::functions;

use strict;
BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;
use detect;
use XML::Simple;

BEGIN {
	use Exporter ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

# Here: RCS; the q$...$ from RCS act as a quote here(!)
	$VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ /(\d+)/g;

	@ISA	= qw(Exporter);
	@EXPORT	= qw(
		&command
		&install_rpms
		&read_xml
                &section_run
                &add_repos
	);
	%EXPORT_TAGS	= ();
	@EXPORT_OK	= qw(
		@force_array
		@file_array
	);
}

# runs a command, dies if it fails
sub command
{
	my $cmd=$_[0];
	&log(LOG_INFO,$cmd."\n");
	my $ret = system $cmd;
	&log(LOG_ERROR,"Command '$cmd' failed with code $ret") if $ret>0;
	return $ret;
}

# installs missing RPMs using zypper
# $to_install is a list of packages to be installed when missing
# $to_upgrade should also be upgraded when possible
sub install_rpms # $upgrade_flag, @basenames
{
	my ($to_install,$to_upgrade)=@_;
	
	# Ugly hack - $@to_upgrade is array of strings, each string can have multiple packages in
	# THerefore the flattening map {}...
	# This must be fixed in a way that the arguments are already parsed, than whole this 
	# function can be simplified
	# my %upgrade_flag = map {$_=>1} @$to_upgrade;
	my %upgrade_flag = map {$_=>1} map { split / +/ } @$to_upgrade;
	my (@install,@upgrade,@suites);


	#before perform the install/upgrade, make sure that y2base won't lock the zypper process
	&log(LOG_INFO,"process info:". `ps -ef|grep [y]2base`);
	system("ps -ef|grep [y]2base|awk '{print \$2}'|xargs -i kill -9 {}");

	foreach my $rpms (@$to_install, @$to_upgrade )
	{
		foreach my $rpm (split / /, $rpms)
		{
			print "RPM: " . $rpm."\n";
			my $ret=(system("rpm -q '$rpm' > /dev/null"))>>8;
			if( $ret==0 )
			{       push @upgrade,$rpm if $upgrade_flag{$rpm};      }
			elsif( $ret==1 )
			{       push @install,$rpm;     }
			else # error
			{       die "RPM failed with exitcode $ret: $!";        }
		}
	}

	@suites=@install if @install;
	@suites=(@suites, @upgrade) if @upgrade; # Since zypper install can update package as well, and it can do better on SLES10
	#make sure that zypper database is updated.
	#3 times try if there is another zypper process running.
	my $update_try = 3;
	while ($update_try > 0){
		my $run_ck = `ps -ef|grep "[z]ypper"|tail -1`;
		chomp $run_ck;
		if(not $run_ck){
			system('zypper -n --gpg-auto-import-keys ref &>/dev/null' ) ;
			last;
		}
		sleep 60;
		$update_try --;
	}

	my $ret = 0;
	foreach my $suite(@suites) {
		$ret += &command("zypper -n install -l $suite 2>/tmp/sut_rpm_stderr_tmp") >> 8;
		my $rpm_stderr = `cat /tmp/sut_rpm_stderr_tmp`;
		chomp($rpm_stderr);
		&log(LOG_ERROR,"ERROR:RPM $suite install/update error: $rpm_stderr\n") if ( $rpm_stderr ne "" );
	}
	return $ret;
}

# add_repos: add repositories by zypper
# input: @url - array which composed by repo urls
# return: integer 
#    0 - all success
#    1 - some repos failed
sub add_repos
{
    my @url = @_;

    my $ret = 0;
    foreach my $u (@url) {
        my $exists = `zypper lr -u |grep "$u"`;
        next if ( $exists ne "" );

        my $rand = int(rand(100000));
        $ret += &command("zypper ar $u jobrepo_$rand 2>/tmp/sut_repo_stderr_tmp") >> 8;
        my $repo_stderr = `cat /tmp/sut_repo_stderr_tmp`;
        chomp($repo_stderr);
        &log(LOG_ERROR,"ERROR:REPO $u install/update error: $repo_stderr\n") if ( $repo_stderr ne "" );
    }
    return $ret;
}

# returns $pid and PIDs of all its subprocesses
sub get_process_tree	# $pid
{
	my $pid=shift;
	my $cmd="ps -eo ppid,pid,cmd --sort ppid";
	open PS, "$cmd|" or warn "Cannot run '$cmd': $!";
	my %child;
	while( my $row=<PS> )
	{
		next unless $row =~ /^\s*(\d+)\s+(\d+)\s+(.+)$/;
		push @{$child{$1}},$2;
	}
	my @ret=($pid);
	foreach $pid(@ret)
	{	push @ret, @{$child{$pid}} if $child{$pid};	}
	return @ret;
}

our @force_array = qw(rpm attachment worker logger monitor role machine parameter repository);
our %force_array = map {$_=>1} @force_array;
our @file_array = ();


# TODO: duplicite with Master
sub read_xml($$) # filename, map_roles
{
	my ($fname,$map_roles) = @_;
	my ($ret,$role_id);
	eval { $ret = XMLin( $fname, ForceContent=>1, ForceArray=>[@force_array], KeyAttr=>[] ); };
	unless($ret)
	{
		&log(LOG_ERROR,"ERROR: Parsing XML '$fname' : $@\n");
		return undef;
	}

	if( $map_roles )
	{	
#xml2part done this
#		$role_id = &get_role_id( $ret );
		&get_parameters($ret)
	}
	
	# do not use any more
	delete($ret->{'parameters'});

	$ret = &process_xml( $ret, $role_id, 'job' );
	return $ret;
}

# scans parsed XML and returns role ID from machine with matching IP address, if there is such a one
# also sets $ENV{'ROLE<n>'}
sub get_role_id($) # XML_tree
{
	my $xml = shift;
	my $ip = &get_my_ip_addr();
	my $my_role = undef;
	foreach my $role (@{$xml->{'roles'}->{'role'}})
	{
		my $role_id=$role->{'id'};
		next unless $role->{'machine'};

		my @role_ips=();
		my @role_dns=();
		foreach my $machine (@{$role->{'machine'}})
		{	
			push @role_ips, $machine->{'ip'};
			push @role_dns, $machine->{'name'};
			$my_role=$role_id if $machine->{'ip'} eq $ip;
		}
		$ENV{'ROLE_'.$role_id.'_IP'} = join(',', @role_ips);
		$ENV{'ROLE_'.$role_id.'_NAME'} = join(',', @role_dns);
	}
	return $my_role;
}

sub get_parameters($)
{
	my $xml = shift;
	
	foreach my $parameter (@{$xml->{'parameters'}->{'parameter'}})
	{
		my $param_name = $parameter->{'name'};
		my $param_file_flag = $parameter->{'file'};

		if( defined($param_file_flag) && (($param_file_flag == 1) || ($param_file_flag == "true")) )
		{
			my ($fh, $file_name) = File::Temp::tempfile();
			if($fh)
			{
				print $fh $parameter->{'content'};
				close($fh);
				$ENV{'param_' . $param_name} = $file_name;
				push(@file_array, $file_name);
			}
			else{
				&log(LOG_ERROR, "Can not open tempfile for $param_name");
			}
		}
		else{
			$ENV{'param_' . $param_name} = $parameter->{'content'};
		}
	}

}

# Omits elements that are assigned to another role_id.
# Keeps elements with role_id matching or missing
# Makes a stable XML tree structure by merging arrays NOT in @force_array.
# This way we should get a structure that is all the time the same, and can be used.
sub process_xml($$$) # XML, role_id, root_element_name
{
	my ($xml,$role_id,$root_element) = @_;
	my $type = ref $xml;
	if( $type eq '' )
	{	return $xml;	}
	elsif( $type eq 'HASH' )
	{
		# drop XML for nonmatching role_id
		if( defined($xml->{'role_id'}) and defined($role_id) and $xml->{'role_id'} != $role_id )
		{	return ();	}

		# process the rest
		return { map { $_=> &process_xml( $xml->{$_}, $role_id, $_ ) } keys %$xml };
	}
	elsif( $type eq 'ARRAY' )
	{
		# arrays are either recursed, or merged, depending on @force_array
		if( defined $force_array{$root_element} )
		{	return [ map { &process_xml( $_, $role_id, $root_element ) } @$xml ];	}
		else	
		{
			my $ret = {};
			foreach my $x (@$xml) 
			{
				next if( defined($x->{'role_id'}) and defined($role_id) and $x->{'role_id'}!=$role_id );
				foreach my $y (keys %$x) 
				{
					my $val = &process_xml( $x->{$y}, $role_id, $y );
					if( defined $force_array{$y} )
					{	push @{$ret->{$y}}, $val;	}
					else
					{	$ret->{$y} = $val;	}
				}
			}
			return $ret;
		}
	}
}

# Function for mm job
# Used to run one or multiple secions.
# possible sections may be finish, abort, kill derived from job xml.
sub section_run 
{
    foreach my $sec (@_) {
        if (-e $sec) {
            my $type = $1 if( $sec =~ /(finish|abort)/ );
            my $cmd = read_xml($sec,1);
            my $command = Slave::Job::Command->new($type, $cmd);
            unshift @{$command->{'command_objects'}}, $command;
            &log(LOG_INFO, "Run $type section: ".$cmd->{'command'}->{'content'});
            $command->run();
            unlink $sec;
        }
    }
}

1;
