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

results::ctcs2 - reader of the ctcs2 test results

=head1 AUTHOR

Vilem Marsik <vmarsik@suse.cz>
Lukas Lipavsky <llipavsky@suse.cz>

=head1 EXPORTS

Nothing

=head1 SYNOPSIS

use results::ctcs2; 

# create instance
my $r = results::ctcs2->new("/var/log/qa/ctcs2");

=head1 SEE ALSO

results

=head1 DESCRIPTION

This class in an implementation of results class, it adds no public methods.

=cut 

BEGIN {
	# extend the include path to get our modules found
	push @INC,"/usr/share/qa/lib",'.';
}

package results::ctcs2;

use results;
@ISA = qw(results);

use benchxml;

use strict;
use warnings;
use log;



sub new
{
	my ($proto, $results_path) = @_;
	my $class = ref($proto) || $proto;

	-d "$results_path" or die "ctcs2 directory $results_path is not a directory!";
	my $self = $class->SUPER::new($results_path);
	
	$self->{DIR} = undef;
	$self->{TCF} = undef;
	$self->{TC_NAME} = undef;
	
	bless($self, $class);
	return $self;
}



sub _rpmlist_get
{
	my ($self,$tcf)=@_;
	return $self->path()."/$tcf/rpmlist";
}


sub _hwinfo_get
{
	my ($self,$tcf)=@_;
	return $self->path()."/$tcf/hwinfo";
}

sub _kernel_get
{
	my ($self,$tcf)=@_;
	return $self->path()."/$tcf/kernel";
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

# TODO
# stores a hash of machine attributes
sub set_options
{
	my ($self,$data)=@_;
	my $fname=$self->path().'/options';
	open FILE, ">$fname" or die "Cannot open $fname for writing: $!";
	foreach my $key ( keys %$data )
	{	printf FILE "%s\t%s\n",$key,$data->{$key};	}
	close FILE;
}

# TODO
# reads a hash of machine attributes
sub get_options
{
	my ($self,$data)=@_;
	my $fname=$self->path().'/options';
	open FILE, $fname or return undef;
	my $ret={};
	while( my $row=<FILE> )
	{	$ret->{$1}=$2 if $row =~ /([^\t]+)\t(.*)$/;	}
	close FILE;
	return $ret;
}

sub testsuite_list_open
{	
	&__dir_open(@_);	
}


sub testsuite_list_next
{
	my ($self)=@_;
	while(my $entry = readdir( $self->{DIR} ))
	{
		if( $entry !~ /^(\.|\.\.|oldlogs|_REMOTE)$/ and -r $self->path()."/$entry/test_results" )
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

# private method for opening file using its kept handle
# arg: $file - path to file to open
#     [$key - key to access the file] 
sub __file_open
{
	my ($self,$file,$key)=@_;
	$key=$file unless $key;
	return 0 unless -r $file;
	return 1 if open $self->{$key}, $file;
	&log(LOG_ERR,"Cannot open file $file : $!");
}

# private method for reading file using its kept handle
# arg: $key - key of file
sub __file_read
{
	my ($self,$key)=@_;
	my $line = readline ${$self}{$key};
	chomp $line if $line;
	return $line;
}


# private method for closing file using its kept handle
# arg: $key - key of file
sub __file_close
{
	my ($self,$key)=@_;
	close $self->{$key};
	delete $self->{$key};
}


sub testsuite_open
{	
	my ($self, $tcf)=@_;
	$self->{TCF} = $tcf;
	$self->__file_open($self->path()."/$tcf/test_results",$tcf);
}


sub testsuite_next
{	
	my ($self) = @_;
	my $tcname = $self->__file_read($self->{TCF});
	return () unless $tcname;
	$_ = $self->__file_read($self->{TCF});
	my @p = split;
	&log(LOG_ERR, "Wrong format of $tcname from testsuite ".$self->{TCF}) unless(0+@p>=5); # 5 for old, 6 for those which support skipped
	$p[5] = 0 unless defined $p[5];
	my $res = { 
		times_run => $p[2], 
		succeeded => $p[1], 
		failed => $p[0], 
		int_errors => $p[4], 
		test_time => $p[3],
		skipped => $p[5]
	};

	# add benchmark resutlst if any
	my $benchres_file = $self->path().'/'.$self->{TCF} .'/'.$tcname .'.bench.xml';
	$res->{bench_data} = bench_data_from_xml($benchres_file) if -r $benchres_file;
		
	$self->{'TC_NAME'} = $tcname;
	
	return ($tcname, $res);
}


sub testsuite_close
{	
	my ($self) = @_;
	$self->__file_close($self->{TCF});
	$self->{TCF} = undef;
	$self->{TC_NAME} = undef;
}

# is the currently opened testsuite already finished (true) or still running(false)?
sub testsuite_complete 
{ 
	my ($self) = @_;
	return -r ($self->path().'/'.$self->{TCF}."/done");
}

# return list of currently running testcases in the opened testsuite
sub testsuite_running_testcases 
{ 
	my ($self) = @_;
	my @testcases = ();
	open PROCESS_STATE, '<', $self->path() . '/' . $self->{TCF} . "/process_state";
	my $i = 0;
	for (<PROCESS_STATE>) {
		chomp;
		next unless $i++ % 2 == 0;
		push @testcases, $_;
	}
	close PROCESS_STATE;
	return @testcases; 
}

sub testsuite_tc_output_rel_url
{
	my ($self) = @_;
	return $self->{TC_NAME};
}

1;
