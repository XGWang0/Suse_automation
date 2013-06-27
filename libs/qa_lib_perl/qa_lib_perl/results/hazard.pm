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

results::hazard - reader of the hazard test results

=head1 AUTHOR

Vilem Marsik <vmarsik@suse.cz>
Lukas Lipavsky <llipavsky@suse.cz>

=head1 EXPORTS

Nothing

=head1 SYNOPSIS

use results::hazard; 

# create instance
my $r = results::hazard->new("/var/log/qa/hazard");

=head1 SEE ALSO

results

=head1 DESCRIPTION

This class in an implementation of results class, it adds no public methods.

=cut 

package results::hazard;

use results;
@ISA = qw(results);


use strict;
use warnings;
use log;



sub new
{
	my ($proto, $results_path) = @_;
	my $class = ref($proto) || $proto;
	-d "$results_path" or die "auto directory $results_path is not a directory!";

	my $self = $class->SUPER::new($results_path);
	
	$self->{LINE} = undef;
	$self->{LINE_result} = undef;
	bless($self, $class);
	return $self;
}



sub _rpmlist_get
{
	my ($self)=@_;
	return $self->path()."/rpmlist";
}


sub _hwinfo_get
{
	my ($self)=@_;
	return $self->path()."/hwinfo";
}

sub _kernel_get
{
	my $self = shift;
	return $self->path()."/kernel";
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
	my ($self) = @_;
	open $self->{LINE},$self->path().'/results' or die "Cannot open result file for reading:$!";
	$self->{CURRENT_FILE} = "hazard_stress";
}


sub testsuite_list_next
{
	my ($self) = @_ ;
	return () unless defined(my $result_text = readline $self->{LINE} ) ;
	$self->{LINE_result} = $result_text;
	return $self->{CURRENT_FILE} ;
}


sub testsuite_list_close
{
	my ($self) = @_;
	close($self->{LINE});	
}


sub testsuite_name 
{ 
	my ($self, $key) = @_;
#	$key =~ /^([\w_]+)$/;
	return "hazard";
}


sub testsuite_date 
{ 

	my ($self) = @_;

	#open the status file to get timestamp .
	#2 method to get value 
	#1) use perl open 
	#2) use system tools to prevent conflict with perl open file

	open my $ele_status,$self->path()."/time_se" or return "xxxx-xx-xx-xx-xx-xx";
	my $timeline = <$ele_status>;
	close $ele_status;

	#my $status_patch = $self->path()."/$key/status";
	#my $timeline = `head -1 $status_path`;

	(my $timestamp) = $timeline =~ /(\d+)/;
	my @time = localtime($timestamp);
	$time[5] += 1900;$time[4]++;
	$time[0] = (length($time[0])==2)?$time[0]:"0".$time[0];
	$time[1] = (length($time[1])==2)?$time[1]:"0".$time[1];
	$time[2] = (length($time[2])==2)?$time[2]:"0".$time[2];
	$time[3] = (length($time[3])==2)?$time[3]:"0".$time[3];
	$time[4] = (length($time[4])==2)?$time[4]:"0".$time[4];
#	$key =~ /^(.*)-([[:digit:]]{4}(-[[:digit:]]{2}){5})$/;
	return $time[5]."-".$time[4]."-".$time[3]."-".$time[2]."-".$time[1]."-".$time[0];
}



# private method for closing file using its kept handle
# arg: $key - key of file

sub testsuite_open
{	

	my ($self) = @_;
	$self->{LINE_result};
}


sub testsuite_next
{	
	my ($self) = @_;
	return () unless (my $line=$self->{LINE_result});
	$self->{LINE_result} = undef;
	my($time_dt,$result)=split /#/,$line;

	my($sum_s,$sum_t,$sum_dt,$sum_f,$sum_e,$sum_k);
	$sum_s += 1 if($result =~ /^pass/);
	$sum_f += 1 if($result =~ /^fail/);
	$sum_t = 1; 
	$sum_dt = $time_dt;
	$sum_t = 1;
	#$sum_s += $resref->{$key}->{succeeded};
	#$sum_t += $resref->{$key}->{times_run};
	#$sum_dt += $resref->{$key}->{test_time};
	#$sum_f += $resref->{$key}->{failed};
	#$sum_e += $resref->{$key}->{int_errors};
	#$sum_k += $resref->{$key}->{skipped};
	#del the warning
	$sum_s = 0 unless defined $sum_s;
        $sum_t = 0 unless defined $sum_t;
        $sum_dt = 0 unless defined $sum_dt;
        $sum_f = 0 unless defined $sum_f;
        $sum_e = 0 unless defined $sum_e;
        $sum_k = 0 unless defined $sum_k;
	my $res = { 
		times_run => $sum_t, 
		succeeded => $sum_s, 
		failed => $sum_f, 
		int_errors => $sum_e, 
		test_time => $sum_dt,
		skipped => $sum_k
	};
		
#	$self->{'TC_NAME'} = $tcname;
	
	return ($self->{CURRENT_FILE},$res);
}


sub testsuite_close
{	
	my ($self) = @_;
	$self->{LINE_result} = undef;
}


sub testsuite_tc_output_rel_url
{
	my ($self) = @_;
	#FIXME
	return "results";
}

1;

