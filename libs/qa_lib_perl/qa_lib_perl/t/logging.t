#!/usr/bin/perl -I/usr/share/qa/lib
# logging.t --- Example Perl test
# Author: Pavel Kačer <pkacer@suse.com>
# Created: 06 Jan 2014

use warnings;
use strict;

# Always change this when adding or removing test cases
use Test::More tests => 6;

# Add to check for library availability
BEGIN {
    use_ok('log');
}

use log ( qw( $logtime) );

$log::logtime = 1;

my $logpath = '/tmp/testing.log';
my $output = '';

log_set_output( path		=> $logpath,
		gzip		=> 1,
		overwrite	=> 1,
		gzip		=> 0,
		close		=> 1
	    );

log (LOG_INFO, 'This is info message');
log (LOG_CRIT, 'This is critical message');
log (LOG_CRITICAL, 'This is another critical message');
log (LOG_ERR, 'This is error message');

{
  local $/=undef;
  if (open (my $fh, '<', $logpath)) {
      $output = <$fh>;
      close $fh;
  }
}

note($output);

my @lines = split (/\n/, $output);

like ($lines[0], qr/INFO\s+This is info message/,
      'Log info output is correct');

like ($lines[1], qr/CRITICAL\s+This is critical message/,
      'Log critical output is correct');

like ($lines[2], qr/CRITICAL\s+This is another critical message/,
      'Log critical output is correct');

like ($lines[3], qr/ERROR\s+This is error message/,
      'Log error output is correct');

like ($lines[0], qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [+-]\d{4}/, 'Log time format and timezone info');

unlink $logpath;

__END__

=head1 NAME

logging.t - Tests the log perl module for QA tools

=head1 SYNOPSIS

prove logging.t

=head1 DESCRIPTION

This testsuite tests the 'log' module for QA tools.

It checks the output in the logs is in correct order and the messages
contain correct data.

=head1 AUTHOR

Pavel Kacer, E<lt>pkacer@suse.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.

THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
LIABILITY.

SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.

=head1 BUGS

None reported... yet.

=cut
