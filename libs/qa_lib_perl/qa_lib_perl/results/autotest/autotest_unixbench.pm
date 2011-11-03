#!/usr/bin/perl
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

package results::autotest::autotest_unixbench;

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
	my ($test_case_name);
	#testsuite_name was required by parent
	$self->{testsuite_name} = $testsuite_name;
	open $self->{FILE_HANDLE}, $self->path()."/$testsuite_name/results/report" or die("Cannot open file $testsuite_name/results/report :$!");
	my @allcontent=readline($self->{FILE_HANDLE});
	close $self->{FILE_HANDLE};
	$self->{dic}{"Dhrystone 2 using register variables"}=1;
	$self->{dic}{"Double-Precision Whetstone"}=1;
	$self->{dic}{"System Call Overhead"}=1;
	$self->{dic}{"Pipe Throughput"}=1;
	$self->{dic}{"Pipe-based Context Switching"}=1;
	$self->{dic}{"Process Creation"}=1;
	$self->{dic}{"Execl Throughput"}=1;
	$self->{dic}{"File Read 1024 bufsize 2000 maxblocks"}=1;
	$self->{dic}{"File Write 1024 bufsize 2000 maxblocks"}=1;
	$self->{dic}{"File Copy 1024 bufsize 2000 maxblocks"}=1;
	$self->{dic}{"File Read 256 bufsize 500 maxblocks"}=1;
	$self->{dic}{"File Write 256 bufsize 500 maxblocks"}=1;
	$self->{dic}{"File Copy 256 bufsize 500 maxblocks"}=1;
	$self->{dic}{"File Read 4096 bufsize 8000 maxblocks"}=1;
	$self->{dic}{"File Write 4096 bufsize 8000 maxblocks"}=1;
	$self->{dic}{"File Copy 4096 bufsize 8000 maxblocks"}=1;
	$self->{dic}{"Shell Scripts (1 concurrent)"}=1;
	$self->{dic}{"Shell Scripts (8 concurrent)"}=1;
	$self->{dic}{"Shell Scripts (16 concurrent)"}=1;
	$self->{dic}{"Arithmetic Test (type = short)"}=1;
	$self->{dic}{"Arithmetic Test (type = int)"}=1;
	$self->{dic}{"Arithmetic Test (type = long)"}=1;
	$self->{dic}{"Arithmetic Test (type = float)"}=1;
	$self->{dic}{"Arithmetic Test (type = double)"}=1;
	$self->{dic}{"Arithoh"}=1;
	$self->{dic}{"C Compiler Throughput"}=1;
	$self->{dic}{"Dc: sqrt(2) to 99 decimal places"}=1;
	$self->{dic}{"Recursion Test--Tower of Hanoi"}=1;
	foreach my $line (@allcontent){
		chomp $line;
		if($line =~ /^[^ ]/){
			my @tmplist = split(/\s+/,$line);
			my $time = $tmplist[-4];
			$time =~ s/\(//;$time =~ s/..$//;
			$line =~ s/\s+\d+\..*//;
			$test_case_name = $line;
			$self->{res}{$test_case_name}=$time;
			last if($test_case_name eq "Recursion Test--Tower of Hanoi");
		}
	}
	1;

}


sub testsuite_next
{	
	my ($self) = @_;
	my ($tc_name,$tmpk,$tmpv,$res);
	($tmpk,$tmpv) = each %{$self->{dic}};
	return () if(! $tmpk);
	$tc_name = $tmpk;
	$res->{succeeded}=0;
	$res->{failed}=0;
	$res->{test_time}=0;
	if (exists $self->{res}{$tc_name}){
		$res->{succeeded}=1;
		$res->{test_time}=$self->{res}{$tc_name}
	}else{
		$res->{failed}=1;
	}
	delete($self->{dic}{$tmpk});
	$res->{times_run}=1;
	$res->{int_errors}=0;
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

