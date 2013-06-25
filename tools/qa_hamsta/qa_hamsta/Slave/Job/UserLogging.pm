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

# This modul checks for manual user login on the local host
#
# complexity: x^2 = x*ln(x)*2 + 3*x - 1; max. columnsrun
# profiable at least 7 entrys

package Slave::Job::UserLogging;

use strict;
use warnings;

use threads::shared;

require 'Slave/config_slave.pm';
BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;

my $debug = $Slave::debug;
my $stop : shared = 0;

# UserLogging->run()
# Starts the checking for user logins/logouts on this slave.
#
sub run() {
	$log::loginfo='user_intervention';
	&log(LOG_INFO,"User intervention will be logged"); 
	my $firstrun=1;
	my %users=();

	while (!$stop) {

		# watch for logouts
		foreach my $pty( keys %users ) {
			$users{$pty}->{'touched'}=0;
		}
		my @events=();
		my @users = `/usr/bin/who -u`;
		foreach my $row( @users ) {
			# find info about users
			my $from='';
			chomp $row;
			$from=$1 if $row =~ s/\(([^\)]+)\)\s*$//;
			next unless $row =~ /^\s*(\w+)\s*([\w\/]+).+?(\d+)\s*$/;
			my ($who,$pty,$pid) = ($1,$2,$3);
			
			# check for new, update list
			unless( defined $users{$pty} ) {
				my ($cmd,$file)=('',"/proc/$pid/cmdline");
				if( $pid and -r $file ) {
					$cmd=$1 if `cat $file`=~/^([^\s\x00]+)/;
					$cmd=$1 if $cmd=~/([^\/]+$)/;
					$cmd =~ s/:$//;
				}
				my $text=$who.($from ? "@".$from : '')." $pty $pid $cmd";
				&log(LOG_NOTICE,"Active user $text") if $firstrun;
				$users{$pty}={'who'=>$who,'pid'=>$pid,'text'=>$text};
				push @events,"Login  $text";
			}
			$users{$pty}->{'touched'}=1;
		}

		# check for logouts
		foreach my $pty( keys %users ) {
			next if $users{$pty}->{'touched'};
			push @events, "Logout ".$users{$pty}->{'text'};
			delete $users{$pty};
		} 

		# print changes
		map {&log(LOG_NOTICE,$_)} @events unless $firstrun;

		$firstrun=0;
		sleep 1;
	}
}

# UserLogging->stop()
#
# Stops the monitoring of logged in users
sub stop {
    my $thread = shift;
    
    $stop = 1;
    $thread->join();
}

1;
