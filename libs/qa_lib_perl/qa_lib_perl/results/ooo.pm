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

=head1 NAME

results::ooo - reader of the OpenOffice.org test results

=head1 AUTHOR

Lukas Lipavsky <llipavsky@suse.cz>
Yi Fan Jiang <yfjiang@novell.com>

=head1 EXPORTS

Nothing

=head1 SYNOPSIS

use results::ooo; 

# create instance
my $r = results::ooo->new("/var/log/qa/ooo");

=head1 SEE ALSO

results

=head1 DESCRIPTION

This class in an implementation of results class, it adds no public methods.

IMPORTANT: presence of tool test-ooo-analyze is required!

=cut 

package results::ooo;

use results;
@ISA = qw(results);


use strict;
use warnings;
use log;

our $ooo_analyzer="/usr/share/qa/lib/utils/test-ooo-analyze";

sub new
{
	my ($proto, $results_path) = @_;
	my $class = ref($proto) || $proto;

	-d "$results_path" or die "ooo directory $results_path is not a directory!";
	my $self = $class->SUPER::new($results_path);
	
	$self->{DIR} = undef;
	$self->{TCF} = undef;
	$self->{TC_NAME} = undef;
	
	bless($self, $class);
	return $self;
}



sub _rpmlist_get
{
	my ($self, $tcf)=@_;
	my $rpmlist = $self->path(). "/$tcf/rpmlist";
	return -r $rpmlist ? $rpmlist : '';
}


sub _hwinfo_get
{
	my ($self, $tcf)=@_;
	my $hwinfo = $self->path(). "/$tcf/hwinfo";
        return -r $hwinfo ? $hwinfo : '';
}

# private method for opening directory path() and keeping its handle
sub __dir_open
{
	my ($self)=@_;
	return 1 if opendir $self->{DIR}, $self->path();
	&log(LOG_ERR,"Cannot open directory " . $self->path().": $!");
}

# private method for closing directory using its kept handle
sub __dir_close
{
	my ($self)=@_;
	closedir $self->{DIR};
	delete $self->{DIR};
}

## TODO
## stores a hash of machine attributes
#sub set_options
#{
#	my ($self,$data)=@_;
#	my $fname=$self->path().'/options';
#	open FILE, ">$fname" or die "Cannot open $fname for writing: $!";
#	foreach my $key ( keys %$data )
#	{	printf FILE "%s\t%s\n",$key,$data->{$key};	}
#	close FILE;
#}
#
## TODO
## reads a hash of machine attributes
#sub get_options
#{
#	my ($self,$data)=@_;
#	my $fname=$self->path().'/options';
#	open FILE, $fname or return undef;
#	my $ret={};
#	while( my $row=<FILE> )
#	{	$ret->{$1}=$2 if $row =~ /([^\t]+)\t(.*)$/;	}
#	close FILE;
#	return $ret;
#}

sub testsuite_list_open
{	
	&__dir_open(@_);	
}


sub testsuite_list_next
{
	my ($self)=@_;
	while(my $entry = readdir( $self->{DIR} ))
	{
		if( $entry =~ /-[[:digit:]]{4}(-[[:digit:]]{2}){5}$/ )
		{	return "$entry";	}
	}
}


sub testsuite_list_close
{
	&__dir_close(@_);	
}


sub testsuite_name 
{ 
	my ($self, $tcf)=@_;
	$tcf =~ /^(.*)-([[:digit:]]{4}(-[[:digit:]]{2}){5})$/;
	return $1;
}


sub testsuite_date 
{ 
	my ($self, $tcf)=@_;
	$tcf =~ /^(.*)-([[:digit:]]{4}(-[[:digit:]]{2}){5})$/;
	return $2;
}


sub testsuite_open
{	
	my ($self, $tcf)=@_;
	$self->{TCF} = $tcf;
	$self->{testcases} = {};
	$self->{tc_names} = ();

	opendir(DIR, $self->path(). "/$tcf");

	# For every .res file
	for my $resfile (grep(/\.res$/,readdir(DIR))) {
		chomp($resfile);
		$resfile =~ /(.*)\.res$/;
		my $prefix = $1;	# name of resfile

		# FIXME error reporting
		open TESTCASES, "$ooo_analyzer --stat-test-case " . $self->path(). "/$tcf/$resfile | tail --lines +5 | awk '{ print \$2; }'|";
		for my $tc (<TESTCASES>) {
			chomp ($tc);
			$tc = "$prefix:$tc";
			# write as passed, will fix in a moment
			push @{$self->{tc_names}}, $tc;
			$self->{testcases}->{$tc} = {
				times_run => 1,
				succeeded => 1,
				failed => 0,
				int_errors => 0,
				test_time => 0,
				skipped => 0 };
		}
		close TESTCASES;

		# failed testcases
		# FIXME error reporting
		open FAILED, "$ooo_analyzer --stat-test-case --entry=Error " . $self->path()."/$tcf/$resfile  | tail --lines +5 | awk '{ print \$2; }'|";
		for my $tc (<FAILED>) {
			chomp ($tc);
			$tc = "$prefix:$tc";
			$self->{testcases}->{$tc}->{failed} = 1;
			$self->{testcases}->{$tc}->{succeeded} = 0;
		}
		close FAILED;

		# interr testcases
		# FIXME error reporting
		open ERRORED, "$ooo_analyzer --stat-test-case --entry=QAError " . $self->path()."/$tcf/$resfile  | tail --lines +5 | awk '{ print \$2; }'|";
		for my $tc (<ERRORED>) {
			chomp ($tc);
			$tc = "$prefix:$tc";
			$self->{testcases}->{$tc}->{int_errors} = 1;
			$self->{testcases}->{$tc}->{failed} = 0; #int error can cause failure
			$self->{testcases}->{$tc}->{succeeded} = 0;
		}
		close ERRORED;
	}
	closedir(DIR);
}


sub testsuite_next
{	
	my ($self) = @_;
	my $tcname = pop @{$self->{tc_names}};
	return () unless $tcname;
	$self->{'TC_NAME'} = $tcname;

	return ($tcname, $self->{testcases}->{$tcname});
}


sub testsuite_close
{	
	my ($self) = @_;
	$self->{testcases} = undef;
	$self->{tc_names} = undef;
	$self->{TCF} = undef;
	$self->{TC_NAME} = undef;
}

## is the currently opened testsuite already finished (true) or still running(false)?
#sub testsuite_complete 
#{ 
#	my ($self) = @_;
#	return -r ($self->path().'/'.$self->{TCF}."/done");
#}

## return list of currently running testcases in the opened testsuite
#sub testsuite_running_testcases 
#{ 
#	my ($self) = @_;
#	my @testcases = ();
#	open PROCESS_STATE, '<', $self->path() . '/' . $self->{TCF} . "/process_state";
#	my $i = 0;
#	for (<PROCESS_STATE>) {
#		chomp;
#		next unless $i++ % 2 == 0;
#		push @testcases, $_;
#	}
#	close PROCESS_STATE;
#	return @testcases; 
#}

sub testsuite_tc_output_rel_url
{
	my ($self) = @_;
	# so far we have no way to prepare it
	return '';
}

1;
