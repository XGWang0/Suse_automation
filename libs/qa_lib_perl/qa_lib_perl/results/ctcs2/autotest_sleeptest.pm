#!/usr/bin/perl

#template for subparser
#every subparser should have 5 methods.
#1 testsuite_open
#2 testsuite_next
#3 testsuite_tc_output_rel_url
#4 testsuite_close
#5 testsuite_complete
package results::ctcs2::autotest_sleeptest;

@ISA = qw(results::ctcs2);
use strict;
use warnings;
use log;

sub new
{
        my ($proto, $testsuite_path) = @_;
        my $class = ref($proto) || $proto;
	my $self;
        -d "$testsuite_path" or die "ctcs2 sub_directory $testsuite_path is not a directory!";


        $self->{PATH} = $testsuite_path; 		#used by path() mechod from parent
	$self->{LOGFILE} = undef;
	$self->{testsuite_dirname} = undef;

        bless($self, $class);
        return $self;
}
	
sub testsuite_open
{
	my($self,$testsuite_dirname) = @_;
	$self->{testsuite_dirname} = $testsuite_dirname;
	return undef unless open $self->{LOGFILE},$self->{PATH} . "/$testsuite_dirname/test_results";
	return 1;
}


sub testsuite_next
{
	#this is ctcs2 format .write your own code here

	my ($self) = @_;
        my $testsuite_name = readline $self->{LOGFILE};
        return () unless $testsuite_name;
        $_ = readline $self->{LOGFILE};
	chomp $_;
        my @p = split;
        &log(LOG_ERR, "Wrong format of $testsuite_name from testsuite ".$self->{testsuite_dirname}) unless(0+@p>=5); # 5 for old, 6 for those which support skipped
        $p[5] = 0 unless defined $p[5];

        my $res = {
                times_run => $p[2],
                succeeded => $p[1],
                failed => $p[0],
                int_errors => $p[4],
                test_time => $p[3],
                skipped => $p[5]
        };


        return ($testsuite_name, $res);

}

sub testsuite_tc_output_rel_url

{
	return "sleeptest";
	#the file that link to log in qadb webpage
}


sub testsuite_close

{

	my $self = shift;
	close $self->{LOGFILE};
	$self->{LOGFILE} = undef;

}

sub testsuite_complete 
{ 
        my ($self) = @_; 
        return 1 if -r ($self->path() . '/' . $self->{testsuite_dirname} . "/done");
}

1;
