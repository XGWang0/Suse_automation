#!/usr/bin/perl
package results::autotest::autotest_tiobench;

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
	my ($uname_r_key,$test_case_name);
	#testsuite_name was required by parent
	$self->{testsuite_name} = $testsuite_name;
	open $self->{FILE_HANDLE}, $self->path()."/$testsuite_name/debug/$testsuite_name.DEBUG" or die("Cannot open file $testsuite_name/debug/$testsuite_name.DEBUG :$!");
	my @allcontent=readline($self->{FILE_HANDLE});
	close $self->{FILE_HANDLE};
	open my $uname_r, $self->path()."/$testsuite_name/keyval" or die("Cannot open file $testsuite_name/keyval :$!");
	my @all_uname_r = readline($uname_r);
	close $uname_r;
	foreach my $line (@all_uname_r){
		chomp $line;
		$uname_r_key = $1 if( $line =~ /ysinfo-uname=([^\s]+)\s/ );
	}
	foreach my $line (@allcontent){
		chomp $line;
		if($line =~ /Running \'\.\/tiobench\.pl --dir.*/){
			my(@tmplist,@testcaselist);
			@tmplist = split(/\s+/,$&);
			@testcaselist = grep { /--block=/ } @tmplist;	
			$self->{case_no} = scalar(@testcaselist);
		}

		$self->{case_res}{$1} = 0 if($line =~ /(Sequential Reads|Random Reads|Sequential Writes|Random Writes)/);

		if($line =~ /(Sequential Reads|Random Reads|Sequential Writes|Random Writes)/){
			$test_case_name =$1;
			$self->{case_res}{$test_case_name}=0;	
		}
		$self->{case_res}{$test_case_name}++ if($line =~ /$uname_r_key/);
	}
	1;

}


sub testsuite_next
{	
	my ($self) = @_;
	my ($tc_name,$tmpk,$tmpv,$res);
	($tmpk,$tmpv) = each %{$self->{case_res}};
	return () if(! $tmpk);
	$tc_name = $tmpk;
	$res->{succeeded}=0;
	$res->{failed}=0;
	if ( $tmpv == $self->{case_no}){
		$res->{succeeded}=1;
	}else{
		$res->{failed}=1;
	}
	delete($self->{case_res}{$tmpk});
	$res->{times_run}=1;
	$res->{int_errors}=0;
	$res->{test_time}=12;
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
