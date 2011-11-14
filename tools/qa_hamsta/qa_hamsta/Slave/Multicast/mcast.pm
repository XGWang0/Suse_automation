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

# This module is used for the announcement of this slave to the master
# and of changes to the hardware configuration of this slave.
# It continuously sends messages to the master through the multicast
# address specified in the config_slave

package Slave::Multicast;
use strict;
use warnings;

BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;

use IO::Socket::Multicast;
use Slave::Multicast::hwinfo_unique;

require 'Slave/config_slave';

# hal_devices_have_changed() : boolean
# Checks if some devices have been attached or removed since the last call
# of this function. This function calls HAL via dbus.
#
# TODO This function currently relies on the number of devices to change
# Maybe we should better use a proper Perl binding for dbus and then
# handle the HAL DeviceAdded/DeviceRemoved signals

# Number of lines returned by HAL (= number of attached devices)
my $num_hal_devices = 0;	

sub hal_devices_have_changed() {
	return 0 if (! (-e "/usr/bin/dbus-send" or -e "/bin/dbus-send" ));
	my @hal_answer = `dbus-send --system --dest=org.freedesktop.Hal --print-reply /org/freedesktop/Hal/Manager org.freedesktop.Hal.Manager.GetAllDevices | tail +2`;
	if ($num_hal_devices != $#hal_answer) {
		# hardware changed
		&log(LOG_NOTICE, "MCAST: DBUS_HWINFO_CHANGE ".$#hal_answer);
		$num_hal_devices = $#hal_answer;
		return 1;
	} else {	
		&log(LOG_DEBUG, "MCAST: No DBUS_HWINFO_CHANGE");
		$num_hal_devices = $#hal_answer;
		return 0;
	}
}



# main:
# Bind to a multicast socket and then loop forever sending messages with
# the current configuration to the master every 10 seconds
sub run() {

	&log(LOG_INFO, "MCAST: Binding to multicast address $Slave::multicast_address:$Slave::multicast_port");

	my $sock = IO::Socket::Multicast->new(Proto=>'udp',PeerAddr=>"$Slave::multicast_address:$Slave::multicast_port");
	if (!$sock) {
		# TODO Some sensible error handling
	    &log(LOG_CRIT, "MCAST: Bind to multicast address $Slave::multicast_address:$Slave::multicast_port failed!");
	}
	&log(LOG_DETAIL, "MCAST: Bound.");

	# set TTL to make the packet pass the first router
	$sock->mcast_ttl(2);

	my $stats_version = 0;
	unlink '/var/lib/hamsta/stats_changed'; # Initial stats will be queried, no need to change now
	while (1) {
	    my $slave_ip;

	    my $message = 
			# An ID (hopefully) unique to this configuration (from hwinfo_unique.pm)
			&unique_id()."\n".

			# Description of this slave to display, e.g. uname output 
			# (from hwinfo_unique.pm)	
			&get_slave_description($stats_version)."\n".

			# IP address of this slave (from hwinfo_unique.pm)	
			($slave_ip = &get_slave_ip($Slave::multicast_address))."\n".

			# Reserved for transmitting some client dependent options to the 
			# master (from hwinfo_unique.pm)	
			&konfiguration()."\n".

			# Whether the hardware configuration has changed since the last message
			(&hal_devices_have_changed() ? "HWINFO_CHANGE" : "");

	    &log(LOG_DEBUG, "-->>$message<<--");

	    if ($slave_ip =~ /127.0.0./) {
		&log(LOG_CRIT, "ERROR in getting IP address, $slave_ip contains '127.0.0.', wait another round to correct it!");
		next;
	    }

	    eval {
		$sock->send($message);
	    }; 
	    if ($@) {
		&log(LOG_ERR, "MCAST: No message could be send: $@");
	    }

	    &log(LOG_DEBUG, "MCAST: identifier send $message");
	} continue {
	    sleep 10;
	    # Increase stats version if somethying changed
	    $stats_version++ if unlink '/var/lib/hamsta/stats_changed';
	}

} 

1;
