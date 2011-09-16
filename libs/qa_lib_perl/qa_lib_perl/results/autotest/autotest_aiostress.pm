#!/usr/bin/perl
package results::autotest::autotest_aiostress;

#template for subparser
#every subparser should have 5 methods.
#1 testsuite_open
#2 testsuite_next
#3 testsuite_tc_output_rel_url
#4 testsuite_close
#5 testsuite_complete


@ISA = qw(results::autotest);
use strict;
use warnings;
use log;
use Time::Local;

sub new
{
	my ($proto, $results_path) = @_;
	my $class = ref($proto) || $proto;

	-d "$results_path" or die "auto directory $results_path is not a directory!";
	my $self ;
	#path was required by parent
	$self->{PATH} = $results_path;
	$self->{FILE_HANDLE} = undef;
	bless($self, $class);
	return $self;
}


sub testsuite_open
{	
	my ($self,$testsuite_name)=@_;
	#testsuite_name was required by parent
	$self->{testsuite_name} = $testsuite_name;
	open $self->{FILE_HANDLE}, $self->path()."/$testsuite_name/debug/stderr" or die("Cannot open file $testsuite_name/debug/stderr :$!");
	my @allcontent=readline($self->{FILE_HANDLE});
	close $self->{FILE_HANDLE};
	foreach my $line (@allcontent){
		chomp $line;
		$self->{case_res}{$1} = $2 if($line =~ /(thread .* )totals.*\s+(\d+)\.\d+/);
	}
	1;

}


sub testsuite_next
{	
	my ($self) = @_;
	my ($tc_name,$tmpk,$tmpv,$res);
	return () unless( ($tmpk,$tmpv) = each %{$self->{case_res}} );
	$tc_name = $tmpk;
	delete $self->{case_res}{$tmpk};
	$res->{times_run}=1;
	$res->{succeeded}=1;
	$res->{failed}=0;
	$res->{int_errors}=0;
	$res->{test_time}=$tmpv;
	$res->{skipped}=0;
	return ($tc_name,$res);

	

}


sub testsuite_close
{	
	my ($self,$key)=@_;
	close $self->{FILE_HANDLE};
	$self->{FILE_HANDLE} = undef;
}


sub testsuite_tc_output_rel_url
{
	my ($self) = @_;
	return "debug/" . $self->{testsuite_name} . ".DEBUG";
}
sub testsuite_complete 
{
        my ($self) = @_;
	open my $m_end,($self->path() . "/" . $self->{testsuite_name} . "/status") or die ("open m_end file failed $!");
	my $last_line;
	$last_line = $_ while(<$m_end>);
        return 1 if $last_line =~ /END/;
}

1;
