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

package qadb;
use base 'db_common';
# See man 1 perlmod for the perl module template used here

BEGIN { push @INC, '/usr/share/qa/lib'; }

use strict;
use POSIX qw/ :termios_h strftime /;
use File::Temp qw/ tempfile tempdir /;
use File::Basename qw/basename dirname/;
use warnings;
# Perl mySQL API
use DBI;
use log;
use qaconfig('get_qa_config','%qaconf');
use db_common;

$db_common::delete_on_failure=1;	# &die_cleanly() will delete inserted data

sub new
{
	my ($proto) = @_;
	my $class = ref($proto) || $proto;
	my $self = db_common->new(@_);
	bless($self,$class);
	map { $self->{$_}=[] } qw(open_submissions inserted_configs inserted_hwinfo);
	return $self;
}

$db_common::cleanup_callback = sub	
{
	my $self=shift;
	$self->TRANSACTION('submission','rpm_config','hwinfo');
	$self->delete_open_submissions();
	$self->undo_rpm_info();
	$self->undo_hwinfo();
	$self->TRANSACTION_END;
};

%db_common::enums = (
	'arch'		=> ['arch_id','arch'],
	'product'	=> ['product_id','product'],
	'release'	=> ['release_id','release'],
	'kernel_branch'	=> ['kernel_branch_id','kernel_branch'],
	'kernel_flavor'	=> ['kernel_flavor_id','kernel_flavor'],
	'kernel_version'=> ['kernel_version_id','kernel_version'],
	'testsuite'	=> ['testsuite_id','testsuite'],
	'testcase'	=> ['testcase_id','testcase'],
	'tester'	=> ['tester_id','tester'],
	'rpm_basename'	=> ['rpm_basename_id','rpm_basename'],
	'rpm_version'	=> ['rpm_version_id','rpm_version'],
	'rpm_config'	=> ['rpm_config_id','md5sum'],
	'host'		=> ['host_id','host']
	);

###############################################################################
# manipulating QADB records
###############################################################################

sub submission_create # type, tester_id, host_id, comment, arch_id, product_id, release_id, config_id, hwinfo_id
{
	my ($self,$type);
	($self,$type,@_)=@_;
	my $type_short='prod';
	$type_short='kotd' if $type =~ /^kotd/;
	$type_short='maint' if $type=~ /^patch/;
	&log(LOG_DEBUG,"Inserting into submissions");
	my $submission_id=$self->insert_query("INSERT INTO submission (type,tester_id,host_id,comment,arch_id,product_id,release_id,rpm_config_id,hwinfo_id) VALUES (?,?,?,?,?,?,?,?,?)",$type_short,@_);
	&log(LOG_DEBUG,"New ID is $submission_id");
	push @{$self->{'open_submissions'}}, $submission_id if $submission_id;
	return $submission_id;
}

sub submission_delete # submission_id
{	return $_[0]->update_query('DELETE FROM submission WHERE submission_id=? LIMIT 1',$_[1]);	}

sub delete_open_submissions
{
	my $self=shift;
	&log( LOG_INFO, 'Deleting '.(0+@{$self->{'open_submissions'}}).' open submissions' );
	foreach my $submission_id (@{$self->{'open_submissions'}})
	{	$self->submission_delete($submission_id);	}
}

sub create_tcf # testsuite_id, submission_id, log_url, test_date
{
	my $self=shift;
	return $self->insert_query( 'INSERT INTO tcf_group(testsuite_id,submission_id,log_url,test_date) VALUES(?,?,?,?)', @_ );
}


# Checks for a matching RPM configuration, makes a new if not exists, returns rpm_config_id
sub rpmlist_put # $rpmlist_path
{
	my ($self,$rpmlist_path)=@_;
	return undef unless -r $rpmlist_path;
	my $md5sum=$self->md5sum($rpmlist_path);
	my $rpm_config_id = $self->enum_get_id('rpm_config',$md5sum);
	return $rpm_config_id if defined $rpm_config_id;
	$rpm_config_id = $self->enum_insert_id('rpm_config',$md5sum);
	push @{$self->{'inserted_configs'}},$rpm_config_id;
	open RPMLIST, $rpmlist_path or $self->die_cleanly("Cannot open $rpmlist_path: $!");
	while( <RPMLIST> )
	{
		my ($rpm_basename,$rpm_version) = split;
		my $rpm_id = $self->get_rpm_id( $rpm_basename, $rpm_version, 1 );
		$self->update_query('INSERT INTO software_config(rpm_config_id,rpm_id) VALUES(?,?)',$rpm_config_id,$rpm_id);
	}
	close RPMLIST;
	return $rpm_config_id;
}

sub get_rpm_id	# rpm_basename, rpm_version, insert?
{
	my ($self,$rpm_basename,$rpm_version,$insert)=@_;
	my ($rpm_basename_id,$rpm_version_id,$rpm_id);
	$rpm_basename_id=$self->enum_get_id_cond('rpm_basename',$rpm_basename, $insert);
	$rpm_version_id =$self->enum_get_id_cond('rpm_version' ,$rpm_version,  $insert);
	$rpm_id=$self->scalar_query('SELECT rpm_id FROM rpm WHERE rpm_basename_id=? AND rpm_version_id=? LIMIT 1',$rpm_basename_id,$rpm_version_id) if $rpm_basename_id and $rpm_version_id;
	if( !$rpm_id and $insert )	{
		$rpm_id=$self->insert_query('INSERT INTO rpm(rpm_basename_id,rpm_version_id) VALUES(?,?)',$rpm_basename_id,$rpm_version_id);
	}
	return $rpm_id;
}

sub get_rpm_versions # rpm_config_id, rpm_basename_id
{	
	my $self=shift;
	return $self->vector_query('SELECT DISTINCT rpm_version_id FROM software_config JOIN rpms USING(rpm_id) WHERE rpm_config_id=? AND rpm_basename_id=?',@_);	
}

# delete configs, foreign key constraints should do the rest
sub undo_rpm_info 
{
	my $self=shift;
	&log( LOG_INFO, 'Deleting '.(0+@{$self->{'inserted_configs'}}).' newly inserted RPM configurations' );
	foreach my $rpm_config_id ( @{$self->{'inserted_configs'}} )
	{	$self->update_query( 'DELETE IGNORE FROM rpm_config WHERE rpm_config_id=?',$rpm_config_id );	}
}

sub hwinfo_put # $hwinfo_path
{
	my ($self,$hwinfo_path) = @_;
	return undef unless -r $hwinfo_path;
	my $md5sum = $self->md5sum($hwinfo_path);
	my $hwinfo_id = $self->scalar_query('SELECT hwinfo_id FROM hwinfo WHERE md5sum=?',$md5sum);
	return $hwinfo_id if defined $hwinfo_id;
	my $hwinfo_bz2 = `bzip2 -c "$hwinfo_path"`;
	$hwinfo_id = $self->insert_query('INSERT INTO hwinfo(md5sum,hwinfo_bz2) VALUES(?,?)',$md5sum,$hwinfo_bz2);
	push @{$self->{'inserted_hwinfo'}},$hwinfo_id;
	return $hwinfo_id;
}

sub undo_hwinfo
{
	my $self=shift;
	&log( LOG_INFO, 'Deleting '.(0+@{$self->{'inserted_hwinfo'}}).' newly inserted hwinfos' );
	foreach my $hwinfo_id( @{$self->{'inserted_hwinfo'}} )
	{	$self->update_query( 'DELETE FROM hwinfo WHERE hwinfo_id=?',$hwinfo_id );	}
}

sub submit_results # $times_run, $succeeded, $failed, $int_err, $skipped, $test_time, $testcase_id, $tcf_id
{
	my $self=shift;
	return $self->insert_query('INSERT INTO `result`(times_run,succeeded,failed,internal_error,skipped,test_time,testcase_id,tcf_id) VALUES(?,?,?,?,?,?,?,?)',@_);
}

sub insert_benchmark_data # $result_id, $bench_part, $value
{
	my ($self,$result_id,$bench_part,$value)=@_;
	return unless $bench_part =~ /^\s*([^;]+?)\s*;\s*(.*)\s*$/;
	my ($bench_part_x,$bench_part_z)=($1,$2);
	my $bench_part_id = $self->row_query('SELECT bench_part_id FROM bench_part WHERE bench_part_x=? AND bench_part_z=? LIMIT 1',$bench_part_x,$bench_part_z);
	unless( $bench_part_id )	{
		$bench_part_id = $self->insert_query('INSERT INTO bench_part(bench_part_x,bench_part_z) VALUES(?,?)',$bench_part_x,$bench_part_z);
	}
	return $self->insert_query('INSERT INTO bench_data(result_id,bench_part_id,result) VALUES(?,?,?)',$result_id,$bench_part_id,$value);
}

sub submission_set_kotd_values # submission_id, kernel_branch_id, kernel_flavor_id, md5sum, kernel_version_id
{	
	my $self=shift;
	$self->update_query('UPDATE submission SET kernel_branch_id=?,kernel_flavor_id=?,md5sum=?,kernel_version_id=? WHERE submission_id=?',$_[1],$_[2],$_[3],$_[4],$_[0]);
}

sub submission_set_maintenance_values # submission_id, patch_id, md5sum
{	
	my $self=shift;
	$self->update_query("UPDATE submission SET patch_id=?,md5sum=?,status='wip' WHERE submission_id=?",$_[1],$_[2],$_[0]);
}

sub released_rpms_insert # submission_id, rpm_basename_id, rpm_version_id
{	
	my $self=shift;
	$self->insert_query('INSERT INTO released_rpm(submission_id,rpm_basename_id,rpm_version_id) VALUES(?,?,?)',@_);
}

# testcase table is enum, but also have additional information relative_url
sub testcase_get_id_or_insert_with_rel_url # testcase_name, relative_url
{
	my ($self, $name, $url) = @_;
	my $id = $self->enum_get_id_or_insert('testcase', $name);
	if (defined $id) {
		my $known_url = $self->scalar_query('SELECT relative_url FROM testcase WHERE testcase_id=?' ,$id);
		$self->update_query("UPDATE testcase SET relative_url='" . $url . "' WHERE testcase_id=?", $id) unless $url eq $known_url;
	}
	return $id;
}

sub tests_stat_update # testsuite_id, testcase_id, is_bench
{
	my ($self, $testsuite_id, $testcase_id, $is_bench) = @_;
	my $bench = $self->scalar_query('SELECT is_bench FROM test WHERE testsuite_id=? AND testcase_id=?', $testsuite_id, $testcase_id );
	if( !defined $bench )	{
		return $self->insert_query('INSERT INTO test(testsuite_id,testcase_id,is_bench) VALUES(?,?,?)', $testsuite_id, $testcase_id, $is_bench);
	} elsif( !$bench and $is_bench )	{
		return $self->update_query('UPDATE test SET is_bench=1 WHERE testsuite_id=? AND testcase_id=?', $testsuite_id, $testcase_id);
	}
	1;
}

1;
# EOF
