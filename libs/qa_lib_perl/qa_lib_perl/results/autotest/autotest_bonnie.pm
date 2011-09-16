#!/usr/bin/perl
package results::autotest::autotest_bonnie;

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
	open $self->{FILE_HANDLE}, $self->path()."/$testsuite_name/debug/$testsuite_name.DEBUG" or die("Cannot open file $testsuite_name/debug/$testsuite_name.DEBUG :$!");
	my @allcontent=readline($self->{FILE_HANDLE});
	close $self->{FILE_HANDLE};
	$self->{tagn}=0;
	$self->{case_no}=12;
	my(@inittime,$inittime,@start_time,$tc_time,$non,$year);
        ($non,$non,$non,$non,$non,$year)=localtime;
	foreach my $line (@allcontent){
		chomp $line;
		if($line =~ /^(..)\/(..)\s+(..):(..):(..).*\[stderr\] Using uid:/){
			@inittime = ($1,$2,$3,$4,$5);
			$inittime = timelocal($inittime[4],$inittime[3],$inittime[2],$inittime[1],$inittime[0]-1,$year);
		}
        	@start_time = ($1,$2,$3,$4,$5) if($line =~/^(..)\/(..)\s+(..):(..):(..)/);
        	$tc_time = timelocal($start_time[4],$start_time[3],$start_time[2],$start_time[1],$start_time[0]-1,$year);
		if($line =~ /stderr\]\s+(.*)?\.\.\.(\w+)/){
			$self->{case_res}{$1} = $2;
			if($self->{tmptime}){
				$self->{case_time}{$1} = $tc_time - $self->{tmptime};
			}else{
				$self->{case_time}{$1} = $tc_time - $inittime;
			}
			$self->{tmptime} = $tc_time;
	
		}
	}
	1;

}


sub testsuite_next
{	
	my ($self) = @_;
	my ($tc_name,$tmpk,$tmpv,$res);
	$self->{tagn}++;
	$self->{case_no}--;
	return () if($self->{case_no} < 0);
	if( ($tmpk,$tmpv) = each %{$self->{case_res}} ){
		$tc_name = $tmpk;
		$res->{times_run}=1;
		$res->{failed}=0;
		if($self->{case_res}{$tmpk} eq "done"){
			$res->{succeeded}=1;
			$res->{failed}=0;
		}else{
			$res->{failed}=1 ;
			$res->{succeeded}=0;
		
		}	
		$res->{int_errors}=0;
		$res->{test_time}=$self->{case_time}{$tmpk};
		$res->{skipped}=0;
		delete($self->{case_res}{$tmpk});
		delete($self->{case_time}{$tmpk});
		return ($tc_name,$res);
	}else{
		$tc_name="test".$self->{tagn};
                $res->{times_run}=1;
                $res->{succeeded}=0;
                $res->{failed}=1;
                $res->{int_errors}=0;
                $res->{test_time}=0;
                $res->{skipped}=0;
                return ($tc_name,$res);

	}

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
