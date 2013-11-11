# ****************************************************************************
# Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
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

=head1 NAME

results::xfstests - reader of xfstests test results

=head1 AUTHOR

Jan Kara <jack@suse.cz>

=head1 EXPORTS

Nothing

=head1 SYNOPSIS

 #in ctor of subclass
 new {
	my ($proto, $results_path) = @_;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new($results_path);
	
	bless($self, $class); # bless to the subclass
	return $self;
 }


 #General usage

 # results is abstract
 use results::<subclass>;

 # create instance
 my $r = results::<subclass>->new("/path/to/results");

 # open each result-set (testsuite-run)
 $r->testsuite_list_open();
 while (my $tcf = $r->testsuite_list_next()) 
 {
	# get name and datetime when the testsuite run
	my $testsuite = $r->testsuite_name($tcf);
	my $testdate = $r->testsuite_date($tcf);
	
	# open each testcase-run in the testsuite-run
	$r->testsuite_open($tcf);
	while( my ($tc_name, $result) = $r->testsuite_next())
	{
		print "Testcase $tc_name\n";
		print "-------------------------\n";
		print "output file:  "$r->testsuite_tc_output()."\n";
		print "rpmlist file: ".r->rpmlist()."\n";
		print "hwinfo file:  ".r->hwinfo()."\n";
	}
	$r->testsuite_close();
 }
 $r->testsuite_list_close();

=head1 METHODS

=head2 Creation

=over 4

=item new results, path_to_results 

Creates and returns a new results object for reading results from 
path_to_results argument.

=back

=head2 Access

=over 4

=item $results->path

Returns the path to results (the argument which were passed to the new call).

=item $results->hwinfo

Returns the path to the file which contains hwinfo for the current 
testsuite-run.

If the file does't exist, the new one is created with actual hwinfo.

The file is guaranteed to exist only until the end of results object lifecycle!

=item $results->rpmlist

Returns the path to the file which contains list of installed RPMs for the 
current testsuite-run.

If the file does't exist, the new one is created with actual rpmlist.

The file is guaranteed to exist only until the end of results object lifecycle!

=item $results->testsuite_list_open

Opens results and prepares itself for reading (iteration over testsuite-runs).

=item $results->testsuite_list_next

Reads next testsuite-run. Returns the ID of the testsuite-run (human-readable, 
must be name of file/directory in the path()).

=item $results->testsuite_name $tcf

Returns name of currently testsuite $tcf.

=item $results->testsuite_date $tcf

Returns date and time (in format 2010-02-15-17-35-07) of testsuite $tcf.

=item $results->testsuite_list_close

Closes results.

=item $results->testsuite_open $tcf

Start reading of testaces in the currently testsuite identified by $tcf.

=item $results->testsuite_next()

Open next testcase.

Returns ($testcase_name, $testcase_results) pair, where $testcase_results
contains following hash:

 $testcase_results = {
	times_run     => <number>, 
	succeeded     => <number>, 
	failed        => <number>, 
	int_errors    => <number>, 
	test_time     => <string>,
	skipped       => <number>,
	bench_data     => <benchmark results reference>
 }

Key bench_data is defined only for benchmark testcases.

Structure of bench_data is:

 $bench_data => {
     attrs => { # attributes (what can be on graph axis)
         id_of_attribute_1 => {
             id           => 'id_of_attribute_1', # MUST BE SAME AS KEY
             label        => 'label to show in graph',
             desc         => 'description of attr',
             type         => 'linear', # enum, linear or logaritmic
             unit         => 'unit the attribute is measured in',
         },
         id_of_attribute_2 => {
             ...
         },
         ...
     },
     graphs => [
         {   # how should default graphs look like
    	     label        => 'graph label',
             desc         => 'graph description',
             result       => 'id_of_attribute' (y axis),
             axis_1       => 'id of attribute (x axis)'
    	     # Optional -> 3D graphs - axis 'z'
             axis_2       => 'id of attribute (z axis)'
         }
         ...
     ],
     values => [
         { 
	     # not all attributes must be here!!!
             id_of_attribute_1 => value_of_attribute_1,
             id_of_attribute_2 => value_of_attribute_2,
	     ...
	 }
	 ...
     ]
 }


=item $results->testsuite_tc_output

Returns the path to the file which contains output of the currently opened 
testcase-run.

If the file does't exist, the new one is created.

The file is guaranteed to exist only until the end of results object lifecycle!

=item $results->testsuite_close

Closes testsuite.

=back

=head1 DESCRIPTION

The class is an implementation of results class which parse results of
xfstests testsuite. It doesn't add any public methods.

=cut

BEGIN {
        # extend the include path to get our modules found
        push @INC,"/usr/share/qa/lib",'.';
}

package results::xfstests;

use results;
@ISA = qw(results);

use strict;
use warnings;
use log;

use File::Temp qw/tmpnam/;

sub new 
{
	my ($proto, $results_path) = @_;
	my $class = ref($proto) || $proto;

	-d "$results_path" or die("Results $results_path is not a directory!");
	my $self = $class->SUPER::new($results_path);

	$self->{DIR} = undef;
	$self->{TC_NAME} = undef;

	bless($self, $class);
	return $self;
}

sub _rpmlist_get
{
	return '';
}

sub _hwinfo_get
{
	return '';
}

sub _kernel_get
{
	return '';
}

sub testsuite_list_open
{
	my ($self) = @_;

	if (!opendir($self->{DIR}, $self->path())) {
		&log(LOG_ERR, "Cannot open directory " . $self->path().": $!");
		return 0;
	}
	return 1;
}

sub testsuite_list_next
{
	my ($self) = @_;
	my $entry;

	while ($entry = readdir($self->{DIR})) {
		if ($entry !~ /^(\.|\.\.|oldlogs|_REMOTE)$/ && -r $self->path()."/$entry/xfstests_output") {
			return "$entry";
		}
	}
}

sub testsuite_list_close
{
	my ($self) = @_;

	closedir($self->{DIR});
	delete($self->{DIR});
}

sub testsuite_name 
{
	my ($self, $tcf)=@_;
	$tcf =~ /^(.*)-([[:digit:]]{4}(-[[:digit:]]{2}){5})$/;
	return $1;
}

sub testsuite_date 
{
	my ($self, $tcf) = @_;
	$tcf =~ /^(.*)-([[:digit:]]{4}(-[[:digit:]]{2}){5})$/;
	return $2;
}

sub testsuite_open
{
	my ($self, $tcf) = @_;

	if (!open($self->{TCF}, $self->path."/$tcf/xfstests_output")) {
		&log(LOG_ERR,"Cannot open file ".$self->path."/$tcf/xfstests_output: $!");
		return 0;
	}
	$self->{TCF_NAME} = $tcf;
	# Skip lines until empty line. There should start test results
	while (readline($self->{TCF})) {
#		&log(LOG_INFO,"Skipping line: ".$_);
		if (/^$/) {
			return 1;
		}
	}
	# No tests found? Whatever...
	return 1;
}

# Private function to skip lines not describing test result
sub __skip_error_lines
{
	my ($self) = @_;
	my $fpos;
	my $skipped = 0;
	my $line;

	do {
		$fpos = tell($self->{TCF});
		$line = readline($self->{TCF});
		$skipped++;
	} until ($line =~ /^([a-z0-9]+\/[a-z0-9]+[ 	]+(-?[0-9]+s \.\.\. )?(\[not run\]|\[expunged\]|- output mismatch|\[dumped core\]|\[failed|- no qualified output|[0-9]+s))|Ran: /);
	seek($self->{TCF}, $fpos, 0);
	return $skipped - 1;
}

sub testsuite_next
{
	my ($self) = @_;
	my $name;
	my $result;
	my $rest;
	my $line;
	my $ret = {
		times_run => 1,
		int_errors => 0,
		succeeded => 0,
		failed => 0,
		skipped => 0,
		test_time => 0
	};

	$line = readline($self->{TCF});
#	&log(LOG_INFO,"Parsing line: ".$line);
	# Are we done?
	if ($line =~ /^Ran: /) {
		return ();
	}

	($name, $rest) = split(/[ 	]+/, $line, 2);

	$self->{TC_NAME} = $name;
	# Remove possible previous test result time
	$rest =~ s/^-?[0-9]+s \.\.\. //;
	if ($rest =~ /^- output mismatch|\[dumped core\]|\[failed|- no qualified output/) {
#		&log(LOG_INFO,"Matched error return");
		$ret->{failed} = 1;
		__skip_error_lines($self);
	} elsif ($rest =~ /^\[not run\]|\[expunged\]/) {
#		&log(LOG_INFO,"Matched skipped return");
		$ret->{skipped} = 1;
	} elsif ($rest =~ /^([0-9]+)s$/) {
		my $orig_time;
		my $dots;
		my $time;

#		&log(LOG_INFO,"Matched OK return");
		# If there are some errors despite successful output comparison
		# (e.g. errors from fsck or umount), declare the testcase as
		# failed.
		if (!__skip_error_lines($self)) {
			$ret->{succeeded} = 1;
			$ret->{test_time} = $1;
		} else {
			$ret->{failed} = 1;
		}
	} else {
		&log(LOG_ERR, "Wrong format of $name from testsuite ".$self->{TCF_NAME});
		return ();
	}

	return ($name, $ret);
}

sub testsuite_close
{
	my ($self) = @_;

	close($self->{TCF});
	$self->{TCF} = undef;
	$self->{TCF_NAME} = undef;
	$self->{TC_NAME} = undef;
}

# returns relative url of the start of testcase log. This can either be a path
# to file relative to the testsuite directory or url with html anchor specified
# (also relative to the testsuite directory)
#
# Examples:
# 1. output is in <testustsuite-dir>/testcase_1 ... returns "testcase_1"
# 2. output starts at <testustsuite-dir>/html/results.html#testcase_1 ... returns "html/results.html#testcase_1"
sub testsuite_tc_output_rel_url
{
	my ($self) = @_;

	return $self->{TC_NAME};
} 

1;
