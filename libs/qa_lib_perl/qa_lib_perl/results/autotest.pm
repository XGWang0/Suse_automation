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

package results::autotest;

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
	
	$self->{DIR_HANDLE} = undef;
	$self->{FILE_HANDLE} = undef;
	$self->{case_name} = undef;
	$self->{testsuite_name} = undef;	
	bless($self, $class);
	return $self;
}



sub _rpmlist_get
{
	my ($self,$key)=@_;
	return $self->path()."/$key/rpmlist";
}


sub _hwinfo_get
{
	my ($self,$key)=@_;
	return $self->path()."/$key/hwinfo";
}

sub _kernel_get
{
	my ($self,$key)=@_;
	return $self->path()."/$key/kernel";
}

sub testsuite_list_open
{	
	my ($self)=@_;
	return 1 if opendir $self->{DIR_HANDLE}, $self->path();
	&log(LOG_ERR,"Cannot open directory " . $self->path().": $!");
}


sub testsuite_list_next
{
	my ($self)=@_;
	while(my $entry = readdir( $self->{DIR_HANDLE} ))
	{
		if( $entry !~ /^(\.|\.\.|analysis|debug|sysinfo|control|\w+\.state|sequence|status)$/ and -r $self->path()."/$entry/status" )
		{	return "$entry";	}
	}
}


sub testsuite_list_close
{
	my ($self)=@_;
	closedir $self->{DIR_HANDLE};
	delete $self->{DIR_HANDLE};
}


sub testsuite_name 
{ 
	my ($self, $key)=@_;
	$self->{testsuite_name} = $key;
	$self->{case_name} = "autotest_".$key;
	return "autotest_".$key;
}


sub testsuite_date 
{ 

	my ($self, $key)=@_;

	open my $ele_status,$self->path()."/$key/status" or return "xxxx-xx-xx-xx-xx-xx";
	my $timeline = <$ele_status>;
	close $ele_status;

	(my $timestamp) = $timeline =~ /timestamp=(\d+)/;
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



sub testsuite_open
{	
	my ($self,$testsuite_name)=@_;
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
	# we need to know the instructor of DB.
	# And modify the reference $ res .
	# here is using the same structure as ctcs2

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
	return "status";
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
