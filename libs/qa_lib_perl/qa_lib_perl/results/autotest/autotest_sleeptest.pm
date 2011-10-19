#!/usr/bin/perl
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
#

package results::autotest::autotest_sleeptest;

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
	return 1 if open $self->{FILE_HANDLE}, $self->path()."/$testsuite_name/status";
	&log(LOG_ERR,"Cannot open file $testsuite_name/status : $!");
}


sub testsuite_next
{	
	my ($self) = @_;
	my $tmpfh = $self->{FILE_HANDLE};
	return () if eof($tmpfh);
	my @allline = <$tmpfh>;
	my $content = \@allline;


	#programming here
	# And modify the reference $ res .

	my ($resref,$tmp_testsuit,$start_time,$end_time);
	for (@{$content}){

		if(/START\s+(\S+).*?timestamp=(\d+)/){
		$tmp_testsuit=$1;
		$resref->{$tmp_testsuit}->{status}="$tmp_testsuit\tstarted";
		$start_time=$2;
		}

		if(/END\s+(\S+)\s+(\S+).*?timestamp=(\d+)/){
			if($tmp_testsuit eq $2) {
				$end_time=$3;
				$resref->{$tmp_testsuit}->{times_run}++;
				$resref->{$tmp_testsuit}->{test_time} = ($end_time - $start_time);
				$resref->{$tmp_testsuit}->{succeeded}++ if $1 eq "GOOD";
				$resref->{$tmp_testsuit}->{failed}++ if $1 eq "FAIL";
				$resref->{$tmp_testsuit}->{int_errors}++ if $1 eq "ERROR";
				$resref->{$tmp_testsuit}->{skipped}++ if $1 eq "ABORT";
				$resref->{$tmp_testsuit}->{status}="$tmp_testsuit\tfinished";

				#del the warning

				$resref->{$tmp_testsuit}->{succeeded} = 0 unless $resref->{$tmp_testsuit}->{succeeded};
				$resref->{$tmp_testsuit}->{failed} = 0 unless $resref->{$tmp_testsuit}->{failed};
				$resref->{$tmp_testsuit}->{int_errors} = 0 unless $resref->{$tmp_testsuit}->{int_errors};
				$resref->{$tmp_testsuit}->{skipped} = 0 unless $resref->{$tmp_testsuit}->{skipped};
			}
		}
	}


	my($sum_t,$sum_dt,$sum_s,$sum_f,$sum_e,$sum_k);
	foreach my $key (keys %{$resref}) {
		        $sum_s += $resref->{$key}->{succeeded};
		        $sum_t += $resref->{$key}->{times_run};
		        $sum_dt += $resref->{$key}->{test_time};
		        $sum_f += $resref->{$key}->{failed};
		        $sum_e += $resref->{$key}->{int_errors};
		        $sum_k += $resref->{$key}->{skipped};
	}
	#del the warning
	$sum_s = 0 unless defined $sum_s;
        $sum_t = 0 unless defined $sum_t;
        $sum_dt = 0 unless defined $sum_dt;
        $sum_f = 0 unless defined $sum_f;
        $sum_e = 0 unless defined $sum_e;
        $sum_k = 0 unless defined $sum_k;
	#&log(LOG_ERR, "Wrong format of $tcname from testsuite ".$self->{CURRENT_FILE}) unless(0+@p>=5); # 5 for old, 6 for those which support skipped
	my $res = { 
		times_run => $sum_t, 
		succeeded => $sum_s, 
		failed => $sum_f, 
		int_errors => $sum_e, 
		test_time => $sum_dt,
		skipped => $sum_k
	};
		
	return ($self->{case_name},$res);
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
	return "keyval";
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

