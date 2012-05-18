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

=head1 NAME

results - Abstract reader of the test results (ctcs2/junit/...)

=head1 AUTHOR

Vilem Marsik <vmarsik@suse.cz>
Lukas Lipavsky <llipavsky@suse.cz>

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
	bench_results => <benchmark results reference>
 }

Key bench_results is defined only for benchmark testcases.

Structure of bench_results is:

 $bench_results => {
     schema => {    # result semantics
         attributes => {
             name_of_attribute_1 => {
                 name         => 'name_of_attribute_1', # MUST BE SAME AS KEY
                 label        => 'label to show in graph',
                 description  => 'description of attr',
                 type         => 'linear', # discrete, linear or logaritmic
                 unit         => 'unit the attribute is measured in',
             },
             name_of_attribute_2 => {
	         ...
             },
	     ...
	 },
         graphs => [
             {   # how should default graphs look like
		 label        => 'graph label',
                 description  => 'graph description',
    	         result       => 'name_of_attribute',
	         axis         => { 
 	             # Axis 'x' (1st axis)
                     1 => {
		         attribute => 'name_of_attribute'
		     }

		     # Optional -> 3D graphs - axis 'z'
                     2 => {
		         attribute => 'name_of_attribute'
                     }

		     # Theoretically, we can have more, but it will be hard to
		     # display ;-)
                 }
	     }
	     ...
	 ]
     },
     values => [
         { 
             name_off_attribute_1 => value_of_attribute_1,
             name_off_attribute_2 => value_of_attribute_2,
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

The class results it an abstract class used to read results of executed 
test(suite)s. The class has been designed to allow unified reading of 
results from different test systems (ctcs2, junit, etc.) 

=cut

package results;

use strict;
use warnings;
use log;

use File::Temp qw/tmpnam/;

sub new 
{
	my ($proto, $results_path) = @_;
	my $class = ref($proto) || $proto;
	my $self = {};

	$self->{PATH} = $results_path;
	$self->{TEMP_FILES} = ();
	
	bless($self, $class);
	return $self;
}

# Do not overload this in subclass!
sub hwinfo
{
	my ($self, $tcf)=@_;
	my $hw = $self->_hwinfo_get($tcf);
	
	# remote submit?
	$hw = $self->path().'/../_REMOTE/hwinfo' unless -r $hw;
	
	# local submit, get local
	$hw = $self->__tmp_list('hwinfo') unless -r $hw;
	
	return $hw;
}

# Do not overload this in subclass!
sub rpmlist
{
	my ($self, $tcf)=@_;
	my $rpms = $self->_rpmlist_get($tcf);
	
	# remote submit?
	$rpms = $self->path().'/../_REMOTE/rpmlist' unless -r $rpms;
	
	# locat submit, get local
	$rpms = $self->__tmp_list('rpmlist') unless -r $rpms;

	return $rpms;
}

# Do not overload this in subclass!
sub path
{
	my $self = shift;
	return $self->{PATH};
}

# protected _hwinfo_get
# returns tha path of the file that contains hwinfo. Needs open testsuite.
# Used by hwinfo() only!
sub _hwinfo_get  { die "Called abstract method of class " . __PACKAGE__; }

# protected _rpmlist_get
# returns tha path of the file that contains rpmlist, which lists packages 
# that were installed during the testsuite-run. 
# Needs open testsuite.
# Used by rpmlist() only!
sub _rpmlist_get  { die "Called abstract method of class " . __PACKAGE__; }

#public
sub testsuite_list_open  { die "Called abstract method of class " . __PACKAGE__; }
sub testsuite_list_next  { die "Called abstract method of class " . __PACKAGE__; }
sub testsuite_list_close { die "Called abstract method of class " . __PACKAGE__; }
sub testsuite_name { die "Called abstract method of class " . __PACKAGE__; }
sub testsuite_date { die "Called abstract method of class " . __PACKAGE__; }

sub testsuite_open  { die "Called abstract method of class " . __PACKAGE__; }
sub testsuite_next  { die "Called abstract method of class " . __PACKAGE__; }
sub testsuite_close { die "Called abstract method of class " . __PACKAGE__; }

# is the currently opened testsuite already finished (true) or still running(false)?
# do not overload if testsuite results are moved to /var/log/qa/<parser> only after
# whole testsuite run finishes
sub testsuite_complete { my ($self) = @_; return 1; }

# return list of currently running testcases in the opened testsuite
# do not overload if testsuite results are moved to /var/log/qa/<parser> only after
# whole testsuite run finishes or if your parser does not provide this functionality
sub testsuite_running_testcases { my ($self) = @_; return (); }

# returns relative url of the start of testcase log. This can either be a path to file 
# relative to the testsuite directory or url with html anchor specified (also relative
# to the testsuite directory)
#
# Examples:
# 1. output is in <testustsuite-dir>/testcase_1 ... returns "testcase_1"
# 2. output starts at <testustsuite-dir>/html/results.html#testcase_1 ... returns "html/results.html#testcase_1"
sub testsuite_tc_output_rel_url { die "Called abstract method of class " . __PACKAGE__; } 


# private method!
# make a temporary rpmlist / hwinfo for the case that none is found
# Do not overload this in subclass!
sub __tmp_list # type
{
	my ($self,$type)=@_;
	my $fname=$self->{TEMP_FILES}{$type};
	return $fname if $fname;

	$fname = tmpnam(); 
	$self->_register_temp_file($type, $fname);
	
	&log(LOG_WARNING,"No $type info found, generating one using the current machine");
	if( $type eq 'rpmlist' )
	{   
		# If you change this, you must also change it in ctcs2/tools/run!!!   
		system('rpm -qa --qf "%{NAME} %{VERSION}-%{RELEASE}\n" | sort >'.$fname);      
	}
	else
	{       		
		# No need to filter it anymore, it will be fitered automatically during
		# result submission by qa_db_report
		system("/usr/sbin/hwinfo --all > $fname");   
	}
	return $fname;
}

# protected method
# arguments: $key - whatever
#            $file - filename
# the $file will be automatically deleted when the object is destroyed
sub _register_temp_file
{
	my ($self, $key, $file) = @_;
	$self->{TEMP_FILES}{$key} = $file;
}

# Called automatically by perl
# destructor - deletes registered temp files
sub DESTROY
{
	my $self = shift;
	
	# delete my temp files
	foreach (values %{$self->{'tmp'}}) {
		unlink $_ if -f $_; 
	}
	$self->{TEMP_FILES} = ();
}

1;

