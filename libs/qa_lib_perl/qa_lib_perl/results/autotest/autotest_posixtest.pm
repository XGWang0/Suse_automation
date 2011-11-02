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

package results::autotest::autotest_posixtest;

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
	return 1 if open $self->{FILE_HANDLE}, $self->path()."/$testsuite_name/debug/posixtest.DEBUG";
	&log(LOG_ERR,"Cannot open file $testsuite_name/debug/posixtest.DEBUG : $!");
}


sub testsuite_next
{	
	my ($self) = @_;
	my $tmpfh = $self->{FILE_HANDLE};
	return () if eof($tmpfh);
	my($res,@line,$line,$test_time,$tc_name);
	while(my $li=<$tmpfh>){
	$line = $li;
	chomp($line);
	@line = split(/\s+/,$line);
	last if((scalar(@line)==8) && $line[5]=~/\//);
	}
	# ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
	my (@start_time) = $line =~/^(..)\/(..)\s+(..):(..):(..)/;
	my ($non,$year);
	($non,$non,$non,$non,$non,$year)=localtime;
	my $tc_time = timelocal($start_time[4],$start_time[3],$start_time[2],$start_time[1],$start_time[0]-1,$year);
	if($self->{time}){
	$test_time = ($tc_time - $self->{time});
	$self->{time} = $tc_time;
	}else{
	$test_time = 1;
	$self->{time} = $tc_time;
	} 
	$res->{times_run}=1;
	$res->{succeeded}=0;
	$res->{failed}=0;
	$res->{int_errors}=0;
	$res->{test_time}=$test_time;
	$res->{skipped}=0;
	if($line =~ /\s([^\s]+)\:\s+[^\s]+\:\s+(PASS|FAILED|UNSUPPORTED|INTERRUPTED|UNRESOLVED|UNTESTED|SKIP|HUNG)\s*$/){
		$res->{succeeded}++ if("$2" eq "PASS");
		$res->{failed}++ if("$2" eq "FAILED");
		$res->{failed}++ if("$2" eq "HUNG");
		$res->{int_errors}++ if("$2" eq "INTERRUPTED");
		$res->{skipped}++ if("$2" eq "SKIP" || "$2" eq "UNSUPPORTED" || "$2" eq "UNRESOLVED" || "$2" eq "UNTESTED");
		$tc_name = $1;
	}
	return () unless($line =~/(PASS|FAILED|UNSUPPORTED|INTERRUPTED|UNRESOLVED|UNTESTED|SKIP|HUNG)/);
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

