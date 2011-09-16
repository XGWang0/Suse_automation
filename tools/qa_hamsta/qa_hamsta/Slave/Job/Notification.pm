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
