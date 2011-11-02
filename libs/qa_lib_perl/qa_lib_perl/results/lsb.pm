#!/usr/bin/perl
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


package results::lsb;

use results;
@ISA = qw(results);

use strict;
use warnings;
use log;
use IO::File;
use IO::Dir;
use Digest::MD5 qw(md5_hex);



# Names of journals that are written by the test suite (some may be missing
# if a reduced suite was run, or when the suite is still running).
# Each journal is stored in a separate file with extension ".journal".
#
my @JOURNALS = (
	"cmdchk", "core", "cpp-t2c",
	"desktop_cairo", "desktop_fontconfig", "desktop_freetype",
	"desktop_gtkvts", "desktop_libpng", "desktop_qt3",
	"desktop_qt4", "desktop_xft", "desktop_xml", "desktop_xrender",
	"desktop-t2c",
	"libchk", "libstdcpp",
	"olver", "perl", "printing", "python", "qt3-azov", "qt4-azov",
	"xml2-azov", "xts5"
);

# Codes for testpoint results used in TET journals which are used
# in LSB tests.
#
my %TP_RESULT_CODES = (
	'0' => 'passed',
	'1' => 'failed',
	'2' => 'unresolved',
	'3' => 'not in use',
	'4' => 'unsupported',
	'5' => 'untested',
	'6' => 'uninitiated',
	'7' => 'no result',
	'65' => 'timeout',
	'101' => 'warning',
	'102' => 'fip'
);



# Returns the name of the current journal, or journal that will be open next.
# Returns an empty string when all journals were already read.
sub get_journal_name
{
	my ($self) = @_;

	my $name = $JOURNALS[$self->{JournalIndex}];
	if ($name) { return $name; }
	return '';
}

# Returns the directory where journals for the current test suite
# can be found. The same directory also contains .info files
# and various other files related to the journals.
# The returned string always ends with '/'.
sub get_journals_dir
{
	my ($self) = @_;

	if (not $self->{TCF}) {
		die("No test suite selected");
	}

	return $self->path() . "/" . $self->{TCF} . "/results/";
}

# Returns the path to the current journal, or an empty string if all journals
# were already iterated over.
sub get_journal_path
{
	my ($self) = @_;

	return '' unless $self->get_journal_name();
	return $self->get_journals_dir() . $self->get_journal_name() . ".journal";
}

# Returns the current location in the file.
sub get_location
{
	my ($self) = @_;

	return $self->get_journal_name() . '.journal:' . $self->{LineNumber};
}

# Opens the currently selected journal and prepares it for reading.
# This can fail if the journal file is missing (i.e. the given test set
# was not run); in this case, the 'File' property will be left on 'undef'
# and 0 is returned.
# Returns 1 on success.
sub __open_journal
{
	my ($self) = @_;

	if ($self->{File}) {
		die("Attempted to open a new journal when not done with the old one");
	}
	if (not $self->get_journal_name()) {
		die("No more journals to open");
	}

	$self->{File} = IO::File->new($self->get_journal_path(), 'r')
		or return 0;

	&log(LOG_NOTICE, "Reading: " . $self->get_journal_path());

	$self->{LineNumber} = 0;
	return 1;
}

# Moves to the next journal.
# Journals that are not present are automatically skipped.
# Returns 1 on success, 0 on failure (when there are no more journals left).
sub __next_journal
{
	my ($self) = @_;

	&log(LOG_NOTICE, "Trying: " . $self->get_journal_path());

	if ($self->{File}) {
		die("Attempt to advance to next journal when the current one is still open");
	}

	while (1) {
		$self->{JournalIndex}++;
		last unless $self->get_journal_name();
		return 1 if $self->__open_journal();
		&log(LOG_NOTICE, "Not available: " . $self->get_journal_path());
	}

	return 0;
}

# Reads a line from the current journal file and returns it as a string.
# When done with the current journal, automatically passes to the next,
# and skips missing ones.
# Returns an empty string if all journals were already read.
sub __read_line
{
	my ($self) = @_;

	if (not $self->{File} and not $self->get_journal_name()) {
		die("Nothing to read, and no more journals");
	}

	if ($self->{File} and $self->{File}->eof()) {
		$self->{File}->close();
		$self->{File} = undef;
	}

	while (not $self->{File}) {
		$self->__next_journal() or return '';
	}

	my $line = readline($self->{File});
	chomp($line);
	$self->{LineNumber}++;

	return $line;
}

# Parses a single line of the TET journal, and returns the resulting data
# fields as a hashtable with members 'ControlCode', 'Flags' and 'Extra'.
# If the line is empty, or ill-formed, 'undef' is returned.
sub __parse_line
{
	my ($self, $line) = @_;

	# Empty line?
	return undef unless $line;

	# There should be 3 fields separated by '|'. The last field can also
	# contain '|' characters.
	my @fields = split(/\|/, $line, 3);
	if (@fields < 3) {

		# Bad line structure.
		return undef;
	}

	# The fields are, respectively: 1) numeric control code;
	# 2) set of whitespace-separated flags; 3) an optional extra string.
	my %result = (
		ControlCode => $fields[0],
		Flags => [ split(/ +/, $fields[1]) ],
		FlagsAsString => $fields[1],
		Extra => $fields[2]
	);

	if ($result{ControlCode} !~ /[0-9]+/) {

		# Invalid (non-numeric) control code.
		return undef;
	}

	return %result;
}

# Translates the numeric testpoint result code into a string.
sub _translate_testpoint_result
{
	my ($self, $tp_result) = @_;

	if (defined $TP_RESULT_CODES{$tp_result}) {
		return $TP_RESULT_CODES{$tp_result};
	}

	return "???"
}

sub __daytime_from_string()
{
	my ($self, $tstr) = @_;

	if ($tstr =~ /^\s*([0-9]+):([0-9]+):([0-9]+)\s*$/) {
		my $hour = int($1);
		my $min = int($2);
		my $sec = int($3);
		return 3600*$hour + 60*$min + $sec;
	}

	# Bad time format.
	return 0;
}

sub __daytime_diff()
{
	my ($self, $daytime1, $daytime2) = @_;

	my $diff = $daytime2 - $daytime1;
	if ($diff < 0) {
		$diff = $diff + 86400;		# midnight
	}
	return $diff;
}

# Loads the results of the next test case from the current journal file.
sub __next_testcase
{
	my ($self) = @_;

	my $success_count = 0;
	my $fail_count = 0;
	my $skip_count = 0;
	my $error_count = 0;

	my $tp_start_time = 0;

	for (;;) {

		# Stop if we are at the end of the journal list.
		last unless $self->get_journal_name();

		# Read the next line, skipping empty ones.
		my $line = $self->__read_line() or next;

		# Parse the line. Ill-formed lines are skipped.
		my %fields = $self->__parse_line($line);
		if (not %fields) {
			&log(LOG_WARNING, "Syntax error in " . $self->get_location());
			next;
		}

		my $control = $fields{'ControlCode'};
		my @flags = @{$fields{'Flags'}};
		my $extra = $fields{'Extra'};

		if ($control == "0") {				# "Controller Start"
		}
		elsif ($control == "10") {			# "Test Case Start"
			$self->{TestCaseName} = $flags[1];
			$self->{TestCaseCount}++;
		}
		elsif ($control == "200") {			# "Test Point Start"
			$tp_start_time = $self->__daytime_from_string($flags[2]);
			$self->{TestPointNumber} = int($flags[1]);
		}
		elsif ($control == "220") {			# "Test Point End"

			if (not $self->{TestCaseName}) {
				&log(LOG_WARNING,
					"Result without a test case in "
					. $self->get_location());
				next;
			}

			# What is the result...
			my $result_success = 0;
			my $result_fail = 0;
			my $result_skip = 0;
			my $result_error = 0;

			my $tp_end_time = $self->__daytime_from_string($flags[3]);
			my $tp_duration = $self->__daytime_diff($tp_start_time, $tp_end_time);

			my $tp_result = $self->_translate_testpoint_result($flags[2]);
			if ($tp_result eq "passed" or $tp_result eq "warning"
				or $tp_result eq "fip") {

				$result_success = 1;
			}
			elsif ($tp_result eq "not in use" or $tp_result eq "unsupported"
				or $tp_result eq "untested") {

				$result_skip = 1;
			}
			elsif ($tp_result eq "failed" or $tp_result eq "unresolved"
				or $tp_result eq "uninitiated" or $tp_result eq "timeout"
				or $tp_result eq "no result") {

				$result_fail = 1;
			}
			else {
				$result_error = 1;
			}

			# Give each testpoint a unique name.
			my $tp_number = $flags[1];
			my $tp_name = $self->get_journal_name()
				. ':' . $self->{TestCaseName}
				. ':' . $tp_number;

			# For each test point, return a result structure.
			my $result = {
				'succeeded' => $result_success,
				'failed' => $result_fail,
				'int_errors' => $result_error,
				'skipped' => $result_skip,
				'times_run' => 1,
				'test_time' => $tp_duration
			};

			return ($tp_name, $result);

		}
		elsif ($control == "80") {			# "Test Case End"
			$self->{TestCaseName} = '';
		}
		elsif ($control == "900") {			# "Test Controller End"
		}
	}

	# No more results available.
	return ();
}

sub new
{
	my ($proto, $results_path) = @_;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new($results_path);

	if (not -d "$results_path") {
		die("Path not found, or not a directory: $results_path");
	}

	$self->{Dir} = undef;
	$self->{TCF} = undef;
	$self->{File} = undef;
	$self->{JournalIndex} = -1;
	$self->{LineNumber} = 0;
	$self->{TestCaseName} = '';
	$self->{TestPointNumber} = 0;
	$self->{TestCaseCount} = 0;

	bless($self, $class);
	return $self;
}

sub testsuite_list_open
{
	my ($self) = @_;

	$self->{Dir} = IO::Dir->new($self->path())
		or die("Could not open directory: " . $self->path() . ": $!");
}

sub testsuite_list_next
{
	my ($self) = @_; 

	return '' unless $self->{Dir};

	while (my $entry = $self->{Dir}->read()) {
		if ($self->_parse_testsuite_filename($entry)) {
			return $entry;
		}
	}
	return '';
}

sub testsuite_list_close
{
	my ($self) = @_;

	if ($self->{Dir}) {
		$self->{Dir}->close();
		$self->{Dir} = undef;
	}
}

# Parses the file name of the results directory and returns the gathered
# information: the architecture of the machine, hostname, date and time
# when the test suite was run.
sub _parse_testsuite_filename
{
	my ($self, $filename) = @_;

	if ($filename =~ /^qa_lsb-([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{2})h-([0-9]{2})m-([0-9]{2})s$/) {
		my %fields = (
			year => $1,
			month => $2,
			day => $3,
			hour => $4,
			minute => $5,
			second => $6
		);
		return %fields;
	}

	return undef;
}

sub testsuite_name
{
	my ($self, $filename) = @_;

	if ($self->_parse_testsuite_filename($filename)) {
		return 'qa_lsb';
	}

	return '';
}

# Returns the date of the testsuite run as a single string in form
# "yyyy-mm-dd-hh-MM-SS".
sub testsuite_date
{
	my ($self, $filename) = @_;

	my %fields = $self->_parse_testsuite_filename($filename)
		or return '';

	if (not defined $fields{'year'}) {
		die("Missing date in parsed filename: $filename");
	}

	return $fields{'year'} . '-'
		. $fields{'month'} . '-'
		. $fields{'day'} . '-'
		. $fields{'hour'} . '-'
		. $fields{'minute'} . '-'
		. $fields{'second'};
}

sub testsuite_open
{
	my ($self, $tcf) = @_;

	if (not $tcf) {
		die("No testsuite path specified");
	}

	$self->{TCF} = $tcf;
	return $self->__next_journal();
}

sub testsuite_next
{
	my ($self) = @_;

	return $self->__next_testcase();
}

sub testsuite_close
{
	my ($self) = @_;

	$self->{File}->close() if $self->{File};
	$self->{File} = undef;

	$self->{TCF} = undef;
	$self->{JournalIndex} = 0;
}

sub __protect_html
{
	my ($str) = @_;

	$str =~ s/&/&amp;/g;
	$str =~ s/</&lt;/g;
	$str =~ s/>/&gt;/g;
	return $str;
}

sub __print_html_prologue
{
	my ($self, $outfile) = @_;

	$outfile->print(<<EOT
<html>

<head>
<style>
.num { text-align:right; color:#007; }
.info { color:#444; font-style:italic; }
.config { color:#00f; font-style:italic; }
.tc { font-weight:bold; }           /* test case */
.tp { color:#090; }                 /* test point */
.result { color: #060; }            /* result of a test point */
.fail { background-color: #fcc; }
</style>
</head>

<body>
EOT
	);
}

sub __build_html_journal
{
	my ($self) = @_;

	my $journal_name = $self->get_journal_name();

	my $html_journal_path = $self->get_journals_dir() . "/$journal_name.html";

	my $outfile = IO::File->new($html_journal_path, 'w')
		or die "Could not write: $html_journal_path: $!";

	my $infile = IO::File->new($self->get_journal_path(), 'r')
		or die "Could not read: $html_journal_path: $!";

	my $tc_name;
	my $tp_number;

	$self->__print_html_prologue($outfile);

	$outfile->print("<pre>\n");

	while (not $infile->eof()) {
		my $line = readline($infile);
		chomp($line);

		my %fields = $self->__parse_line($line) or next;

		my $control = $fields{'ControlCode'};
		my @flags = @{$fields{'Flags'}};
		my $extra = $fields{'Extra'};

		if ($control == '10') {
			$outfile->print('<span class="tc">');
			$tc_name = $flags[1];
			$outfile->print(__protect_html($line));
			$outfile->print("</span>\n");

		} elsif ($control == '0' || $control == '5' || $control == '20'
			or $control == '30' || $control == '40' || $control == '70'){
			$outfile->print("<span class=\"config\">");
			$outfile->print(__protect_html($line));
			$outfile->print("</span>\n");

		} elsif ($control == '200') {
			$tp_number = int($flags[1]);
			my $anchor = $tc_name . '_' . $tp_number;
			$outfile->print("<span class=\"tp\" id=\"$anchor\">");
			$outfile->print(__protect_html($line));
			$outfile->print("</span>\n");

		} elsif ($control == '220') {
			my $tp_result = $flags[2];
			if ($tp_result eq '1' or $tp_result eq '2'
				or $tp_result eq '2' or $tp_result eq '7'
				or $tp_result eq '65') {
				$outfile->print("<span class=\"fail\">");
				$outfile->print(__protect_html($line));
				$outfile->print("</span>\n");
			} else {
				$outfile->print("<span class=\"result\">");
				$outfile->print(__protect_html($line));
				$outfile->print("</span>\n");
			}
		} else {
			$outfile->print(__protect_html($line) . "\n");
		}
	}

	$outfile->print("</pre>\n");

	$outfile->print("</body>\n</html>\n");

	$infile->close();
	$outfile->close();
}

sub testsuite_tc_output_rel_url
{
	my ($self) = @_;

	if (not $self->{TCF}) {
		die("No test suite selected");
	}
	if (not $self->{TestCaseName}) {
		die("No test case selected");
	}

	my $journal_name = $self->get_journal_name();

	my $html_journal_path = $self->path() . "/" . $self->{TCF}
		. "/results/$journal_name.html";
	
	if (not -r $html_journal_path) {
		&log(LOG_NOTICE, "Writing: " . $html_journal_path);
		$self->__build_html_journal();
	}

	my $tc_name = $self->{TestCaseName};
	my $tp_number = $self->{TestPointNumber};
	return "/results/$journal_name.html#$tc_name" . "_$tp_number";
}

# Collects a list of RPMs that were installed during the tests.
# The result is returned as an array of strings.
sub get_rpm_list
{
	my ($self) = @_;

	if (not $self->{TCF}) {
		die("No test suite selected");
	}

	my $journaldir = IO::Dir->new($self->get_journals_dir())
		or die("Could not open journal directory");

	my %rpms;

	# For each test that was run, there is an ".info" file
	# that contains various information about the test,
	# including the list of files that were used for it.
	while (my $entry = $journaldir->read()) {

		# Scan every ".info" file in the journals directory.
		if ($entry =~ /[a-zA-Z0-9_\-]+.info$/) {

			my $path = $self->get_journals_dir() . "/$entry";
			my $info = IO::File->new($path, 'r');
			if (not $info) {
				&log(LOG_WARNING, "Could not open info file: $entry");
				next;
			}

			my @testfiles = ();
			while (not $info->eof()) {
				my $line = readline($info);

				# The line starting with "FILES_: " contains a list
				# of files (RPMs and others) used for the test.
				if ($line =~ /^FILES_:\s+(.*)$/) {
					@testfiles = split(/,/, $1);
				}
			}
			if (not @testfiles) {
 				&log(LOG_WARNING, "FILES_ entry not found in info file: $entry");
			}

			# Sift through the file list to get only RPMs
			# and from these, only their names, not complete paths.
			for my $file (@testfiles) {
				if ($file =~ /([a-zA-Z0-9_\-\.]+\.rpm)$/) {
					$rpms{"$1"} = 1;
				}
			}
		}
	}

	return sort(keys(%rpms));
}

# rpmlist() and hwinfo() are inherited from superclass

# fake, we don't have a complete RPM list
sub _rpmlist_get
{
	return '';
}

# fake, we don't have a complete HW info
sub _hwinfo_get
{
	return '';
}

1;

