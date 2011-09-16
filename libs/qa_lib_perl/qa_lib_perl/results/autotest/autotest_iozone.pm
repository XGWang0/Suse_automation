#!/usr/bin/perl
package results::autotest::autotest_iozone;

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
	return 1 if open $self->{FILE_HANDLE}, $self->path()."/$testsuite_name/results/raw_output_1";
	&log(LOG_ERR,"Cannot open file $testsuite_name/debug/iozone.DEBUG : $!");
}


sub testsuite_next
{	
	my ($self) = @_;
	my $tmpfh = $self->{FILE_HANDLE};
	return () if eof($tmpfh);
	my($res,$line,$test_time,$stime,$etime);
	while(my $li=<$tmpfh>){
	$line = $li;
	chomp($line);
	}
	open my $timefh,$self->path()."/".$self->{testsuite_name} ."/status" or die("open time file handle failed");
	my @time_file = <$timefh>;
	close $timefh;
	foreach my $tline (@time_file){
		$stime = $1 if($tline =~ /START\s+.*\s+timestamp=(\d+)\s+/);
		$etime = $1 if($tline =~ /END\s+.*\s+timestamp=(\d+)\s+/);
		}
	$test_time = $etime - $stime;
	$res->{times_run}=1;
	$res->{succeeded}=0;
	$res->{failed}=0;
	$res->{int_errors}=0;
	$res->{test_time}=$test_time;
	$res->{skipped}=0;
	if($line =~ /iozone test complete\.$/){
		$res->{succeeded}++ ;
	}else{
		$res->{failed}++;
	}
	return ($self->{testsuite_name},$res);

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
