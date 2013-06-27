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

package Slave::Job::Notification;

use strict;
use warnings;

BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;

BEGIN {
	my $count_notifications = 0;
	my $hostname = `hostname|cut -d. -f1`; 
	chomp $hostname;

	sub check_notification {
		my $job = shift;
		my $command = shift;
		my $line = shift;

		return if ($count_notifications > 5);
		return if (!defined($command->{'data'}->{'notify'}));

		my $rules;
		if (ref($command->{'data'}->{'notify'}) eq 'ARRAY') {
			$rules = $command->{'data'}->{'notify'};
		} else {
			$rules = [$command->{'data'}->{'notify'}];
		}

		foreach my $rule (@$rules) {
			my $pattern = $rule->{'pattern'};
			if ($line =~ /$pattern/) {
				&log(LOG_NOTICE, "%s\t%s\t%s",
				       $rule->{'mail'}, 
				       'HAMSTA Job Notification: '.$job->{'data'}->{'config'}->{'name'}->{'content'}.' on '.$hostname, 
				       'You requested to be notified when the output of the command "'.$command->{'data'}->{'name'}->{'content'}.
					       '" matches the pattern /'.$pattern."/. The following line was output right now on $hostname:\n".$line);
				if( ++$count_notifications > 5 )
				{	&log(LOG_NOTICE, "This is the 5th notification for this job. You will receive no more notifications from this job to avoid spamming.");	}
				return;
			}
		}

	}
}

1;
