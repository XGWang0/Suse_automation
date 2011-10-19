# ****************************************************************************
# Copyright © 2011 Unpublished Work of SUSE. All Rights Reserved.
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
		&get_slave_ip
	);
	%EXPORT_TAGS	= ();
	@EXPORT_OK	= qw(
		@force_array
	);
}

# runs a command, dies if it fails
sub command
{
	my $cmd=$_[0];
	&log(LOG_INFO,$cmd."\n");
	my $ret = system $cmd;
	warn "Command '$cmd' failed with code $ret\n" if $ret>0;
}

# installs missing RPMs using zypper
# $to_install is a list of packages to be installed when missing
# $to_upgrade should also be upgraded when possible
sub install_rpms # $upgrade_flag, @basenames
{
	my ($to_install,$to_upgrade)=@_;
	my %upgrade_flag = map {$_=>1} @$to_upgrade;
	my (@install,@upgrade);
	foreach my $rpm( @$to_install, @$to_upgrade )
	{
		my $ret=(system("rpm -q '$rpm' > /dev/null"))>>8;
		if( $ret==0 )
		{	push @upgrade,$rpm if $upgrade_flag{$rpm};	}
		elsif( $ret==1 )
		{	push @install,$rpm;	}
		else # error
		{	die "RPM failed with exitcode $ret: $!";	}
	}
    &command('zypper -n install -l '.join(' ',@install)) if @install;
    &command('zypper -n install -l '.join(' ',@upgrade)) if @upgrade; # Since zypper install can update package as well, and it can do better on SLES10
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

our @force_array = qw(rpm attachment worker logger monitor role machine);
our %force_array = map {$_=>1} @force_array;

# get_slave_ip() : string
# Returns the IP address of this slave
sub get_slave_ip() {
   my $hint_ip=&ip_to_number($_[0]);
   my $ip;
   my $ret=undef;
   my $hint_match=-1;

   my $dev=(split /\s/, `route -n | grep "^0.0.0.0"`)[-1]; #get the main communication device
   open(CMDFH, "ifconfig $dev |") || die "error: $?";
   foreach (<CMDFH>) {
      if ($_=~/inet (\w+):(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/) {
         $ip = "$2.$3.$4.$5";
         my $ip_num=($2<<24) | ($3<<16) | ($4<<8) | $5;
         my $match=defined $hint_ip ? ($hint_ip & $ip_num) : 0;
         if( $match>=$hint_match ) {
             $ret=$ip;
             $hint_match=$match;
         }
      }
   }
   close(CMDFH);
   return $ret;
}

sub ip_to_number()
{
    my $text=$_[0];
    return undef unless defined $text and $text =~ /(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/;
    return ($1<<24) | ($2<<16) | ($3<<8) | $4;
}

#


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
	{	$role_id = &get_role_id( $ret );	}

	$ret = &process_xml( $ret, $role_id, 'job' );
	return $ret;
}

# scans parsed XML and returns role ID from machine with matching IP address, if there is such a one
# also sets $ENV{'ROLE<n>'}
sub get_role_id($) # XML_tree
{
	my $xml = shift;
	my $ip = &get_slave_ip();
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


1;
