#!/usr/bin/perl

# PERL MODULE
use DBI;
use DBD::mysql;

# CONFIG VARIABLES
$host = "bender.suse.cz";
$database = "qadb";
$user = "qadb";
$pw = "qadb";

$dsn="dbi:mysql:$database:$host:3306";

# PERL MYSQL CONNECT
$con = DBI->connect($dsn, $user, $pw) or die "Cannot connect: $!";

$res_q = $con->prepare('select test_result.resultsID from test_result join tcf_results on test_result.resultsID=tcf_results.resultsID where tcf_results.tcfID=?') or die $DBI::errstr;
$mod_q = $con->prepare('update bench_data set resultsID=? where tcfID=?') or die $DBI::errstr;



$con->do('alter table bench_data add column resultsID integer') or die $DBI::errstr;
$tcf_q = $con->prepare('select distinct(tcfID) from bench_data') or die $DBI::errstr;
$tcf_q->execute() or die $DBI::errstr;
$tcf_q->bind_col(1,\$tcfID);

while ($tcf_q->fetch())
{
    print "tcfID = $tcfID\n";
    $res_q->execute($tcfID);
    $res = $res_q->fetchall_arrayref();
    unless( @$res==1 )
    {
        warn ((0+@$res)." records associated") unless @$res==1;
        die if @$res>1;
    }
    my $resultsID = $res->[0]->[0];
    print "   -> $resultsID\n";
    $mod_q->execute( $resultsID, $tcfID ) or die $DBI::errstr;
}

# wrongly commited data that are not linked cannot be migrated - should be deleted
$con->do('delete from bench_data where resultsID is null') or die $DBI::errstr;

$con->do('ALTER TABLE `bench_data` DROP PRIMARY KEY, ADD PRIMARY KEY(resultsID,partID)') or die $DBI::errstr;

$con->do('alter table bench_data drop column tcfID') or die $DBI::errstr;

$con->do('alter table tcf_results add index resultsID( resultsID )') or die $DBI::errstr;

$con->disconnect() or die $DBI::errstr;

