#!/usr/bin/perl -w
# script to fill the table 'stats' from scratch

BEGIN { push @INC, '/usr/share/qa/lib'; }
use db_common;
use log;
use qaconfig('%qaconf','&get_qa_config');
#use qaconfig;
%qaconf = ( %qaconf, &get_qa_config('qa_db_report') );

our $dst = db_common->new();
$dst->set_user();

my $count = $dst->scalar_query('SELECT COUNT(*) FROM tests');
if( $count>0 )	{
	print STDERR "Table 'tests' not empty, please purge before running this script.\n";
	exit;
}

my %suites=();
my %submissions=();

my $data = $dst->matrix_query('SELECT submissionID,tcfID,testsuiteID FROM tcf_group');
foreach my $row (@$data)	{
	my ($submissionID,$tcfID,$testsuiteID)=@$row;
	unless(defined $submissions{$submissionID})	{
		print STDERR "$submissionID,";
		$submissions{$submissionID}=1;
	}
#	$dst->rollback();
#	print STDERR "submissionID=$submissionID, tcfID=$tcfID, testsuiteID=$testsuiteID\n";
#	print STDERR "\tquery in\n";
	$tcfID=0+$tcfID;
	my $data2 = $dst->matrix_query("SELECT resultsID, testcaseID, EXISTS(SELECT * FROM bench_data WHERE bench_data.resultsID=results.resultsID) as is_bench FROM results WHERE tcfID=$tcfID");
#	print STDERR "\tquery out\n";
	foreach my $row2 (@$data2)	{
		my ($resultsID,$testcaseID,$is_bench)=@$row2;
		my $bench = ( defined $suites{$testsuiteID}->{$testcaseID} ? $suites{$testsuiteID}->{$testcaseID} : 0 );
		print STDERR "\tNew bench $testsuiteID/$testcaseID" if $is_bench and !$bench;
		$bench++ if $is_bench;
		$suites{$testsuiteID}->{$testcaseID} = $bench;
#		print STDERR "\tresultsID=$resultsID, is_bench=$is_bench\n";
	}

}

foreach my $testsuiteID ( sort {$a<=>$b} keys %suites )	{
	foreach my $testcaseID ( sort {$a<=>$b} keys %{$suites{$testsuiteID}}	)	{
		my $is_bench = ($suites{$testsuiteID}->{$testcaseID} ? 1:0);
		print "$testsuiteID, $testcaseID, $is_bench ... ";
		my $ret = $dst->insert_query("INSERT INTO tests(testsuiteID,testcaseID,is_bench) VALUES(?,?,?)",$testsuiteID,$testcaseID,$is_bench);
		die "Query failed" unless defined $ret;
		print "$ret\n";
	}
	$dst->commit();
}
