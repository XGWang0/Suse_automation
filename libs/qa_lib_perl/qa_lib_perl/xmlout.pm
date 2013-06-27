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

package xmlout;
# See man 1 perlmod for the perl module template used here

BEGIN { push @INC, '/usr/share/qa/lib'; }

use strict;
use POSIX qw/ :termios_h strftime /;
use File::Temp qw/ tempfile tempdir /;
use File::Basename qw/basename dirname/;
use warnings;
use log;
use qaconfig('get_qa_config','%qaconf');
use XML::Simple;
use MIME::Base64 qw(encode_base64);

sub new
{
	my ($proto) = @_;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self,$class);
	return $self;
}

sub TRANSACTION
{
1;
}

sub TRANSACTION_END
{
1;
}

sub set_user
{
1;
}

sub enum_get_id
{
	my($self,$e_key,$e_value) = @_;
	$self->{'submission'}->{$e_key} = $e_value;
	if($e_key eq "rpm_basename") {
		push @{$self->{'submission'}->{'release_rpms'}},{'name' => ,$e_value};
		delete $self->{'submission'}->{"rpm_basename"};	
	}
	return $e_value;


}

sub enum_get_id_or_insert
{
my($self,$e_key,$e_value) = @_;
$self->{'submission'}->{$e_key} = $e_value;
}

sub md5sum # filename
{
        my ($self,$fname) = @_;
        return undef unless -r $fname;
        my $md5sum = `md5sum "$fname" | cut -d\\  -f1`;
        chomp $md5sum;
        return $md5sum;
}  

sub get_promote_release_id
{
0;
}



sub submission_create # type, tester_id, host_id, comment, arch_id, product_id, release_id, config_id, hwinfo_id, build_nr
{
	my ($self,$type,$tester_id,$host_id,$comment,$arch_id,$product_id,$release_id,$rpm_config_id,$hwinfo_id,$build_nr)=@_;
	my $type_short='prod';
	$type_short='kotd' if $type =~ /^kotd/;
	$type_short='maint' if $type=~ /^patch/;
	return 0 if $#_ < 9;
	&log(LOG_DEBUG,"Create submissions");
	$self->{'submission'}->{'type'} = $type_short;
	$self->{'submission'}->{'tester_id'} = $tester_id;
	$self->{'submission'}->{'host_id'} = $host_id;
	$self->{'submission'}->{'comment'} = $comment;
	$self->{'submission'}->{'arch_id'} = $arch_id;
	$self->{'submission'}->{'product_id'} = $product_id;
	$self->{'submission'}->{'release_id'} = $release_id;
	$self->{'submission'}->{'rpm_config_id'} = $rpm_config_id;
	$self->{'submission'}->{'hwinfo_id'} = $hwinfo_id;
	$self->{'submission'}->{'build_nr'} = $build_nr;
	@{$self->{'submission'}->{'test_suite'}} = ();
	return 1;
}


sub create_tcf # testsuite_id, submission_id, log_url, test_date
{
	my ($self,$testsuite_id,$sumission_id,$log_url,$test_date,$path) =@_;

	
	if(defined($self->{'tmp_name'})) {
		my $test_suite;
		$test_suite->{'name'} = $self->{'tmp_name'};
		$test_suite->{'test_date'} = $self->{'tmp_date'};

		my $ts_logdir = $self->{'log_path'};
		my $ts_raw;
		if( -d $ts_logdir ) {

			open(my $log_stdin,"tar cf - $ts_logdir 2>/dev/null|") or $self->die_cleanly("Cannot open $ts_logdir: $!");
			{ 
       	         	local $/=undef;
       	         	$ts_raw = <$log_stdin>;
       		 	}
		close $log_stdin;
		$test_suite->{'logs'}->{'type'} = "tar/mime64";
		$test_suite->{'logs'}->{'content'} = &encode_base64($ts_raw);
		}



		@{$test_suite->{'result'}} = ();
		map { push @{$test_suite->{'result'}},$_} @{$self->{'tmp_result'}}; 
		push @{$self->{'submission'}->{'test_suite'}},$test_suite ;
	}
	
	$self->{'tmp_name'} = $testsuite_id ;
	$self->{'tmp_date'} = $test_date ;
	$self->{'tmp_url'} =  $log_url;
	$self->{'log_path'} = $path;
	@{$self->{'tmp_result'}} = () ;
	return $testsuite_id ;
}


# Checks for a matching RPM configuration, makes a new if not exists, returns rpm_config_id
sub rpmlist_put # $rpmlist_path
{
	my ($self,$rpmlist_path)=@_;
	return undef unless -r $rpmlist_path;
	my $md5sum=$self->md5sum($rpmlist_path);
	$self->{'submission'}->{'software_config'}->{'rpm'}=();
	$self->{'submission'}->{'software_config'}->{'md5sum'}=$md5sum;
	open RPMLIST, $rpmlist_path or $self->die_cleanly("Cannot open $rpmlist_path: $!");
	while( <RPMLIST> )
	{
		my ($rpm_basename,$rpm_version) = split;
		push @{$self->{'submission'}->{'software_config'}->{'rpm'}},{ "name" => $rpm_basename , "version" => $rpm_version };

	}
	close RPMLIST;
	#return $self->{'submission'}->{'software_config'}->{'rpm'};
	1;
}

sub get_rpm_versions 
{
 0;
}



sub hwinfo_put # $hwinfo_path
{
	my ($self,$hwinfo_path) = @_;
	return undef unless -r $hwinfo_path;
	my $md5sum = $self->md5sum($hwinfo_path);
	$self->{'submission'}->{'hwinfo'}->{'md5sum'} = $md5sum;
	my $hwinfo_raw;
	open(my $hw_file,"$hwinfo_path") or $self->die_cleanly("Cannot open $hwinfo_path: $!");
	{ 
		local $/=undef;
		$hwinfo_raw = <$hw_file>;
	}
	close($hw_file);
	$self->{'submission'}->{'hwinfo'}->{'content'} = &encode_base64($hwinfo_raw);
	$self->{'submission'}->{'hwinfo'}->{'type'} = "mime64";
	1;
}


sub submit_results # $times_run, $succeeded, $failed, $int_err, $skipped, $test_time, $testcase_id, $tcf_id
{
	my ($self,$times_run,$succeeded,$failed,$internal_error,$skipped,$test_time,$testcase_id,$tcf_id) = @_;
	my $result;
	$result->{'testcase'} = $testcase_id ;
	$result->{'times_run'} = $times_run ;
	$result->{'succeeded'} = $succeeded;
	$result->{'failed'} = $failed ;
	$result->{'internal_error'} = $internal_error ;
	$result->{'skipped'} = $skipped;
	$result->{'test_time'} = $test_time ;
	$result->{'log_url'} = $testcase_id ;

	
	push @{$self->{'tmp_result'}} , $result;
	

}

sub insert_benchmark_data # $result_id, $bench_part, $value
{
	return 1;
}

sub submission_set_kernel_values # submission_id, kernel_branch_id, kernel_flavor_id, md5sum, kernel_version_id
{	

	my ($self,$submission_id,$kernel_branch,$kernel_flavor,$md5sum,$kernel_version)=@_;
	$self->{'submission'}->{'kernel_info'}->{'md5sum'} = $md5sum;
	$self->{'submission'}->{'kernel_info'}->{'kernel_branch'} = $kernel_branch;
	$self->{'submission'}->{'kernel_info'}->{'kernel_flavor'} = $kernel_flavor;
	$self->{'submission'}->{'kernel_info'}->{'kernel_version'} = $kernel_version; 
	1;
	
}

sub submission_set_maintenance_values # submission_id, patch_id, md5sum
{	
	my ($self,$patch_id,$md5sum,$status_id)=@_;
	#$self->update_query("UPDATE submission SET patch_id=?,md5sum=?,status_id=1 WHERE submission_id=?",$_[1],$_[2],$_[0]); # status_id=1 means 'wip'
}


# testcase table is enum, but also have additional information relative_url
sub testcase_get_id_or_insert_with_rel_url # testcase_name, relative_url
{
	my ($self, $name, $url) = @_;
	return $url;
	#my $id = $self->enum_get_id_or_insert('testcase', $name);
	#if (defined $id) {
	#	my $known_url = $self->scalar_query('SELECT relative_url FROM testcase WHERE testcase_id=?' ,$id);
	#	$self->update_query("UPDATE testcase SET relative_url='" . $url . "' WHERE testcase_id=?", $id) unless $url eq $known_url;
	#}
	#return $id;
}

sub tests_stat_update # testsuite_id, testcase_id, is_bench
{
	my ($self, $testsuite_id, $testcase_id, $is_bench) = @_;
	return 1;
}
sub die_cleanly
{
        my $self=shift;
        &log(LOG_CRIT,@_) if @_;
	die;
}

sub commit
{

	my $self = shift;
	my $test_suite;

	$test_suite->{'name'} = $self->{'tmp_name'};
	$test_suite->{'test_date'} = $self->{'tmp_date'};
	my $ts_logdir = $self->{'log_path'};
	my $ts_raw;
	if( -d $ts_logdir ) {
		open(my $log_stdin,"tar cf - $ts_logdir 2>/dev/null|") or $self->die_cleanly("Cannot open $ts_logdir: $!");
		{ 
                	local $/=undef;
                	$ts_raw = <$log_stdin>;
       	 	}
		close $log_stdin;
		$test_suite->{'logs'}->{'type'} = "tar/mime64";
		$test_suite->{'logs'}->{'content'} = &encode_base64($ts_raw);
	}
	map { push @{$test_suite->{'result'}},$_} @{$self->{'tmp_result'}}; 
	push @{$self->{'submission'}->{'test_suite'}},$test_suite;

	my $host_name =$self->{'submission'}->{'host_id'};

	delete $self->{'submission'}->{'rpm_config_id'};
	delete $self->{'submission'}->{'testsuite'};
	delete $self->{'submission'}->{'hwinfo_id'};
	delete $self->{'submission'}->{'arch_id'};
	delete $self->{'submission'}->{'host_id'};
	delete $self->{'submission'}->{'release_id'};
	delete $self->{'submission'}->{'product_id'};
	delete $self->{'submission'}->{'tester_id'};
	
	my ($o_sec,$o_min,$o_hour,$o_mday,$o_mon,$o_year,$o_wday,$o_yday,$o_isdst) = localtime(time);
	my $result_xml = "/tmp/$host_name-".($o_year+1900)."$o_mon$o_mday$o_hour$o_min$o_sec.result.xml";
	open(my $xml_res,">",$result_xml) or $self->die_cleanly("Cannot open $result_xml: $!");
	print $xml_res XMLout($self->{'submission'},RootName => 'submission');
	close $xml_res;
	$result_xml;




	#print XMLout($self->{'submission'},RootName => 'submission');

}

sub tidy_up
{
1;
}

1;
# EOF
