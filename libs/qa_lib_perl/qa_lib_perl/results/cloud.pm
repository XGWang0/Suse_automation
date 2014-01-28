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

=head1 NAME

results::cloud- reader of the suse cloud tempest test results

=head1 AUTHOR

Jia Yao <jyao@suse.com>

=head1 EXPORTS

Nothing

=head1 SYNOPSIS

use results::cloud; 

=head1 SEE ALSO

results

=head1 DESCRIPTION

This class in an implementation of results class, it adds no public methods.

=cut 

BEGIN {
	# extend the include path to get our modules found
	push @INC,"/usr/share/qa/lib",'.';
}

package results::cloud;

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

	-d "$results_path" or die "suse cloud tempest directory $results_path is not a directory!";
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

sub testsuite_list_open
{	
	&__dir_open(@_);	
}


sub testsuite_list_next
{
	my ($self)=@_;
	while(my $entry = readdir( $self->{DIR} ))
	{
		if( $entry =~ /^tempest(_[[:digit:]]{6}){2}$/ and -r $self->path()."/$entry/$entry.log")
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
	$tcf =~ /^(.*)(_[[:digit:]]{6}){2}/;
	return $1;
}


sub testsuite_date 
{ 
	my ($self, $tcf)=@_;
	$tcf =~ /^(.*)_([[:digit:]]{2})([[:digit:]]{2})([[:digit:]]{2})_([[:digit:]]{2})([[:digit:]]{2})([[:digit:]]{2})$/;
	return "20$2-$3-$4-$5-$6-$7";
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
	$self->__file_open($self->path()."/$tcf/$tcf.log", $tcf);
}


sub testsuite_next
{	
	my ($self) = @_;
	my $tcl = $self->__file_read($self->{TCF});

	return () unless $tcl;
	
	while($tcl !~ /^tempest\..*\.{3}/)
	{
		$tcl = $self->__file_read($self->{TCF});
		return () unless $tcl;
	}

	my($tcname, $result) = split(/\.\.\./, $tcl);

	$tcname =~ s/^\s+|\s+$//g;
	$result =~ s/^\s+|\s+$//g;

	return () unless $tcname;

	my ($times_run, $succeeded, $failed, $int_errors, $test_time, $skipped) = (1,0,0,0,30,0);

	if($result =~ /ok/)
	{
		$succeeded = 1;
	}
	elsif($result =~ /FAIL/)
	{
		$failed = 1;
	}
	elsif($result =~ /ERROR/)
	{
		$int_errors = 1;
	}
	elsif($result =~ /SKIP/)
	{
		$skipped= 1;
	}
	else
	{
		$times_run = 0;
		$skipped = 1;
		$test_time = 0;
	}
		


	my $res = { 
		times_run => $times_run, 
		succeeded => $succeeded, 
		failed => $failed, 
		int_errors => $int_errors, 
		test_time => $test_time,
		skipped => $skipped
	};

		
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
	open FILE_COMPLETE, $self->path().'/'.$self->{TCF}.'/'.$self->{TCF}.'.log' or die("It is not a valid test result!");
	

	while(<FILE_COMPLETE>)
	{
		if($_ =~ /^Ran\s\d+\stests\sin\s\d+\.\d+s/)
		{
			close FILE_COMPLETE;
			return 1;
		}
	}
	close FILE_COMPLETE;
	return 0;

}

sub testsuite_tc_output_rel_url
{
	return "";
}

1;
