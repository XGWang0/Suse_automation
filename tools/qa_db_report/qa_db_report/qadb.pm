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
	$self->TRANSACTION('submissions','rpmConfig','hwinfo');
	$self->delete_open_submissions();
	$self->undo_rpm_info();
	$self->undo_hwinfo();
	$self->TRANSACTION_END;
};

%db_common::enums = (
	'architectures'		=> ['archID','arch'],
	'products'		=> ['productID','product'],
	'releases'		=> ['releaseID','release'],
	'kernel_branches'	=> ['branchID','branch'],
	'kernel_flavors'	=> ['flavorID','flavor'],
	'testsuites'		=> ['testsuiteID','testsuite'],
	'testcases'		=> ['testcaseID','testcase'],
	'testers'		=> ['testerID','tester'],
	'bench_parts'		=> ['partID','part'],
	'rpm_basenames'		=> ['basenameID','basename'],
	'rpm_versions'		=> ['versionID','version'],
	'rpmConfig'		=> ['configID','md5sum'],
	'hosts'			=> ['hostID','host']
	);

###############################################################################
# manipulating QADB records
###############################################################################

sub submission_create # type, testerID, hostID, comment, archID, productID, releaseID, configID, hwinfoID
{
	my ($self,$type);
	($self,$type,@_)=@_;
	my $type_short='prod';
	$type_short='kotd' if $type =~ /^kotd/;
	$type_short='maint' if $type=~ /^patch/;
	&log(LOG_DEBUG,"Inserting into submissions");
	$self->update_query("INSERT INTO submissions (type,testerID,hostID,comment,archID,productID,releaseID,configID,hwinfoID) VALUES (?,?,?,?,?,?,?,?,?)",$type_short,@_);
	&log(LOG_DEBUG,"Getting ID of the new submission");
	my $submissionID=$self->get_new_id();
	&log(LOG_DEBUG,"New ID is $submissionID");
	push @{$self->{'open_submissions'}}, $submissionID if $submissionID;
	return $submissionID;
}

sub submission_delete # submissionID
{	return $_[0]->update_query('DELETE FROM submissions WHERE submissionID=? LIMIT 1',$_[1]);	}

sub delete_open_submissions
{
	my $self=shift;
	&log( LOG_INFO, 'Deleting '.(0+@{$self->{'open_submissions'}}).' open submissions' );
	foreach my $submissionID (@{$self->{'open_submissions'}})
	{	$self->submission_delete($submissionID);	}
}

sub create_tcf # testsuiteID, submissionID, logs_url, test_date
{
	my $self=shift;
	$self->update_query( 'INSERT INTO tcf_group(testsuiteID,submissionID,logs_url,test_date) VALUES(?,?,?,?)', @_ );
	return $self->get_new_id();
}


# Checks for a matching RPM configuration, makes a new if not exists, returns configID
sub rpmlist_put # $rpmlist_path
{
	my ($self,$rpmlist_path)=@_;
	return undef unless -r $rpmlist_path;
	my $md5sum=$self->md5sum($rpmlist_path);
	my $configID = $self->enum_get_id('rpmConfig',$md5sum);
	return $configID if defined $configID;
	$configID = $self->enum_insert_id('rpmConfig',$md5sum);
	push @{$self->{'inserted_configs'}},$configID;
	open RPMLIST, $rpmlist_path or $self->die_cleanly("Cannot open $rpmlist_path: $!");
	while( <RPMLIST> )
	{
		my ($basename,$version) = split;
		my $rpmID = $self->get_rpm_id( $basename, $version, 1 );
		$self->update_query('INSERT INTO softwareConfig(configID,rpmID) VALUES(?,?)',$configID,$rpmID);
	}
	close RPMLIST;
	return $configID;
}

sub get_rpm_id	# basename, version, insert?
{
	my ($self,$basename,$version,$insert)=@_;
	my ($basenameID,$versionID,$rpmID);
	$basenameID=$self->enum_get_id_cond('rpm_basenames',$basename, $insert);
	$versionID =$self->enum_get_id_cond('rpm_versions' ,$version,  $insert);
	$rpmID=$self->scalar_query('SELECT rpmID FROM rpms WHERE basenameID=? AND versionID=? LIMIT 1',$basenameID,$versionID) if $basenameID and $versionID;
	if( !$rpmID and $insert )
	{
		$self->update_query('INSERT INTO rpms(basenameID,versionID) VALUES(?,?)',$basenameID,$versionID);
		$rpmID=$self->get_new_id();
	}
	return $rpmID;
}

sub get_rpm_versions # configID, basenameID
{	
	my $self=shift;
	return $self->vector_query('SELECT DISTINCT versionID FROM softwareConfig JOIN rpms USING(rpmID) WHERE configID=? AND basenameID=?',@_);	
}

# delete configs, foreign key constraints should do the rest
sub undo_rpm_info 
{
	my $self=shift;
	&log( LOG_INFO, 'Deleting '.(0+@{$self->{'inserted_configs'}}).' newly inserted RPM configurations' );
	foreach my $configID ( @{$self->{'inserted_configs'}} )
	{	$self->update_query( 'DELETE IGNORE FROM rpmConfig WHERE configID=?',$configID );	}
}

sub hwinfo_put # $hwinfo_path
{
	my ($self,$hwinfo_path) = @_;
	return undef unless -r $hwinfo_path;
	my $md5sum = $self->md5sum($hwinfo_path);
	my $hwinfoID = $self->scalar_query('SELECT hwinfoID FROM hwinfo WHERE md5sum=?',$md5sum);
	return $hwinfoID if defined $hwinfoID;
	my $hwinfo_bz2 = `bzip2 -c "$hwinfo_path"`;
	$self->update_query('INSERT INTO hwinfo(md5sum,hwinfo_bz2) VALUES(?,?)',$md5sum,$hwinfo_bz2);
	$hwinfoID = $self->get_new_id();
	push @{$self->{'inserted_hwinfo'}},$hwinfoID;
	return $hwinfoID;
}

sub undo_hwinfo
{
	my $self=shift;
	&log( LOG_INFO, 'Deleting '.(0+@{$self->{'inserted_hwinfo'}}).' newly inserted hwinfos' );
	foreach my $hwinfoID( @{$self->{'inserted_hwinfo'}} )
	{	$self->update_query( 'DELETE FROM hwinfo WHERE hwinfoID=?',$hwinfoID );	}
}

sub submit_results # $times_run, $succeeded, $failed, $int_err, $skipped, $test_time, $testcaseID, $tcfID
{
	my $self=shift;
	$self->update_query('INSERT INTO results(times_run,succeeded,failed,internal_error,skipped,test_time,testcaseID,tcfID) VALUES(?,?,?,?,?,?,?,?)',@_);
	return $self->get_new_id();
}

sub insert_benchmark_data # $resultsID, $part, $value
{
	my ($self,$resultsID,$part,$value)=@_;
	my $partID = $self->enum_get_id_or_insert('bench_parts',$part);
	$self->update_query('INSERT INTO bench_data(resultsID,partID,result) VALUES(?,?,?)',$resultsID,$partID,$value);
	return $self->get_new_id();
}

sub kotd_testing_insert # submissionID, branchID, flavorID, release, version
{	
	my $self=shift;
	$self->update_query('INSERT INTO kotd_testing(submissionID,branchID,flavorID,`release`,version) VALUES(?,?,?,?,?)',@_);	
}

sub product_testing_insert # submissionID
{	
	my $self=shift;
	$self->update_query('INSERT INTO product_testing(submissionID) VALUES(?)',$_[0]);	
}

sub maintenance_testing_insert # submissionID, patchID, md5sum
{	
	my $self=shift;
	$self->update_query("INSERT INTO maintenance_testing(submissionID,patchID,md5sum,status) VALUES(?,?,?,'wip')",@_);	
}

sub released_rpms_insert # submissionID, basenameID, versionID
{	
	my $self=shift;
	$self->update_query('INSERT INTO released_rpms(submissionID,basenameID,versionID) VALUES(?,?,?)',@_);	
}

# testcases table is enum, but also have additional information relative_url
sub testcase_get_id_or_insert_with_rel_url # testcase_name, relative_url
{
	my ($self, $name, $url) = @_;
	my $id = $self->enum_get_id_or_insert('testcases', $name);
	if (defined $id) {
		my $known_url = $self->scalar_query('SELECT relative_url FROM testcases WHERE testcaseID=?' ,$id);
		$self->update_query("UPDATE testcases SET relative_url='" . $url . "' WHERE testcaseID=?", $id) unless $url eq $known_url;
	}
	return $id;
}

sub tests_stat_update # testsuiteID, testcaseID, is_bench
{
	my ($self, $testsuiteID, $testcaseID, $is_bench) = @_;
	my $bench = $self->scalar_query('SELECT is_bench FROM tests WHERE testsuiteID=? AND testcaseID=?', $testsuiteID, $testcaseID );
	if( !defined $bench )	{
		return $self->insert_query('INSERT INTO tests(testsuiteID,testcaseID,is_bench) VALUES(?,?,?)', $testsuiteID, $testcaseID, $is_bench);
	} elsif( !$bench and $is_bench )	{
		return $self->update_query('UPDATE tests SET is_bench=1 WHERE testsuiteID=? AND testcaseID=?', $testsuiteID, $testcaseID);
	}
	1;
}

1;
# EOF
