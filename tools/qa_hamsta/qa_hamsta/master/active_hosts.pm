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

package Master;

use strict;
use warnings; 

use XML::Dumper;
use URI::Escape;
use IO::Select;
use IO::Socket;
use IO::Socket::Multicast;

use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);

use hwinfo_xml_sql;
use functions;

require qaconfig;
require sql;
our $dbc;

# Ggost is Vm (reported from VH), which is not yet controlled by hamsta, so is not created in machines table
my %ghosts_by_mac;
my %ghosts_by_vh;

# Master->active_hosts()
#
# This sub periodicly (while(1)) checks if 
# a) new slaves are available => query them for their hwinfo data
# b) active host are still sending multicast. If not, set them
#    to "not responding" or "down" after a timeout.
# 
sub active_hosts() {

# Contains all active hosts
	my $thread_shared={};

# All open sockets are managed by $selector. These sockets are one 
# multicast socket to receive the mcast messages from all slaves and
# another socket for each hwinfo query on a slave.
	my $selector = new IO::Select();

# Contains a mapping from each hwinfo request socket managed by $selector 
# to the corresponding host to which the query has been sent.
	my $selector_host = {};


# Initialize the multicast socket. This socket has to be in non-blocking
# mode, otherwise the main loop will hang.
	my $mcast_sock = new IO::Socket::Multicast(
			Proto       => 'udp',
			LocalPort   => $qaconf{hamsta_multicast_port},
			);

	#try to map IP address with network interface name

	if($qaconf{hamsta_multicast_dev}) {
		open(my $_tmp_ifo,"/usr/bin/ifconfig2ip|") || &log(LOG_CRIT,"MASTER_MULTICAST: Can not find IP address ");
		my @if_output = <$_tmp_ifo>;
		close $_tmp_ifo;
		foreach my $if_dev (split /,/,$qaconf{hamsta_multicast_dev}) {
			my $net_addr;
			for(my $i=0;$i<@if_output;$i++){
				if($if_output[$i] =~ /^$if_dev/){
				$if_output[++$i] =~ /inet (addr:)?([^\s]+)\s/ ;
				$net_addr = $2 ;
				last ;

				}
			}

			eval {
				$mcast_sock->mcast_add($qaconf{hamsta_multicast_address},$net_addr) 
			};
			if ($@) {
				&log(LOG_CRIT,"MASTER_MULTICAST: Bind to multicast address $if_dev:$net_addr ".
						$qaconf{hamsta_multicast_address}.':'.$qaconf{hamsta_multicast_port}.": $!\n" );
			}

		}
	}else {
		eval {
                                $mcast_sock->mcast_add($qaconf{hamsta_multicast_address})
                        };
			if ($@) {
                                &log(LOG_CRIT,"MASTER_MULTICAST: Bind to multicast address ".
                                                $qaconf{hamsta_multicast_address}.':'.$qaconf{hamsta_multicast_port}.": $!\n" );
                        }

	}

        my $flags = fcntl($mcast_sock, F_GETFL, 0);
        fcntl($mcast_sock, F_SETFL, $flags | O_NONBLOCK);
        $selector->add($mcast_sock);
	# Set machines to unknown. This was only done in destructor, but there 
	# it sometimes failed, e.g. due to lost DB connection, resulting in 
	# non-existing machines being still up. Fixed by vmarsik.

	&TRANSACTION( 'machine','job_part_on_machine','job' );
	&machine_set_all_unknown();
	&TRANSACTION_END;


	# Main loop:
	# Read from whatever socket is ready for reading and process the input
	while (1) {
		# global time, used for one run
		my $sync_time = time;
		check_host_timeouts($thread_shared);
		# Check for incoming hwinfo and mcast
		my @ready;
		$| = 1;
		while ((@ready = $selector->can_read(1)) && (time - $sync_time < 10)) {
			foreach my $sock (@ready) {
				my $line;
				if (defined($selector_host->{$sock})) {
					# All sockets which are defined in $selector_hosts belong
					# to a info query. So we got a info response here.
					&log(LOG_DEBUG,"Received a multicast from socked IN selector_host");
					
					my $host = $selector_host->{$sock};
					my $what = $host->{'query'}->{'now'};
					
					$sock->recv($line, 65536);
					if (!defined($line) || ($line eq "")) {
						if (eof($sock)) {
							delete $host->{$what};
							delete $selector_host->{$sock};
							$selector->remove($sock);
							$sock->close;


							$host->{'query'}->{'now'} = undef;
							$what = shift @{$host->{'query'}->{'queue'}};
							if ($what) {
								# start next query
								eval {
									my $sock = &query_info($host, $what);
									if( $sock )	{
										$selector->add($sock);
										$selector_host->{$sock} = $host;
										$host->{'query'}->{'now'} = $what;
									}
								};
								&log(LOG_ERR, "ACTIVE_MCAST Error during call of query_info($what): $@") if ($@);
							} 
						}
						next;
					}
					# Add the received line to the info attribute of the
					# host. </perldata> signals the end of the info
					# response (URL encoded!)
					$host->{$what} .= $line;
					if ($line =~/%3C%2Fperldata%3E/i) {
						# complete info
						&log(LOG_INFO,"Got complete $what for ".$host->{'hostname'});
						eval {
							if ($what eq 'hwinfo' ) {
								&process_hwinfo_response($host);
							
							}elsif ($what eq 'stats' ) {
								&process_stats_response($host);
							}
							
						};
						if ($@) {
							&log(LOG_ERR,"ACTIVE_MCAST -- Error processing $what: $@");
						}
						delete $host->{$what}; 
						delete $selector_host->{$sock};
						$selector->remove($sock);
						$sock->close;
						
						$host->{'query'}->{'now'} = undef;
						$what = shift @{$host->{'query'}->{'queue'}};
						if ($what) {
							# start next query
							eval {
								my $sock = &query_info($host, $what);
								if( $sock )	{
									$selector->add($sock);
									$selector_host->{$sock} = $host;
									$host->{'query'}->{'now'} = $what;
								}
							};
							&log(LOG_ERR, "ACTIVE_MCAST Error during call of query_info($what): $@") if ($@);
						} 
					}

				} elsif (fileno($sock) == fileno($mcast_sock)) {
					# This is a mcast message. Decode the message into usable
					# host information and send a hwinfo query if necessary
					next unless $sock->recv($line, 1024);
					my $host = &decode_mcast_message($line);
					&log(LOG_DEBUG,"MCAST: $line");
					&log(LOG_INFO,"MCAST: $host->{'hostname'}");
					
					for my $info ( &process_mcast($thread_shared, $host) ) {
						if ($host->{'query'}->{'now'}) {
							# something is being queried already, add this request to the queue
							push @{$host->{'query'}->{'queue'}}, $info;
							&log(LOG_DEBUG,"MCAST: query for $info was added to the queue, since now querying ".$host->{'query'}->{'now'}.".");
						} else {
							# nothing is being queried now - start the query
							eval {
								my $sock = &query_info($host, $info);
								if( $sock )	{
									$selector->add($sock);
									$selector_host->{$sock} = $host;
									$host->{'query'}->{'now'} = $info;
								}
							};
							&log(LOG_ERR, "ACTIVE_MCAST Error during call of query_info($info): $@") if ($@);
						}
					}

				} else {
					# A line is received that is neither a mcast message nor 
					# is it sent by a host in $select_host - this should never
					# happen.
					&log(LOG_ERR, "Got hwinfo or stats data without request!");
				}
			} # end of foreach
		} # end of while @ready
		sleep 1;
	} # end of while(1), end of main loop
} # end active_mcast threads


# Master->decode_mcast_message()
#
# this function takes the identification-string of the multicast slave and
# the multicast-available hosts and
# the current working directory
# 
# the function compares the transmitted identification and compare if this
# host is already listed (in hash mcast_hosts)
# 
sub decode_mcast_message {

	my $data = shift @_ ;

	my $hash;

	# data : Unique-id, hostspezifics(++), IP; seperator is \n 
	if ((my $host_id, my $host_description, my $host_ip, my $konfiguration, my $notify,my $update,my $host_status,my $host_master_ip) = split (/\n/,$data)) {
		my $mac = (split(/\./, $host_id))[-1];
		$hash->{'id'} = $mac;
		$host_ip =~ s/ //g; 
		$hash->{'ip'} = $host_ip;
		$hash->{'konfiguration'} = $konfiguration;
		$hash->{'description'} = $host_description;
		$hash->{'notify'} = $notify;
		$hash->{'update'} = $update;
		#when the sut has no reserved master, $host_master_ip is undefined,use empty string.
		$hash->{'host_master_ip'} = '';
		$hash->{'host_master_ip'} = $host_master_ip if (defined $host_master_ip);

		if (defined($hash->{'description'})) {
			($hash->{'hostname'}, $hash->{'kernel'}, my $arch, my $stats_version, my @rest) = split / /, $hash->{'description'}; 

			if ($stats_version =~ /^[0-9]+$/) {
				$hash->{'stats_version'} = $stats_version;
			} else {
				# for backward compatibility DEPRECATED
				unless ($stats_version eq '-' or $stats_version =~ /^[\w]+#([0-9A-F]{2}(:[0-9A-F]{2}){5}_[\w]+;?)*$/ ) {
					# for backward backward compatibility
					$hash->{'description'} = join ' ', $hash->{'hostname'}, $hash->{'kernel'}, $arch, '-', $stats_version, @rest;
					($hash->{'hostname'}, $hash->{'kernel'}, $arch, $stats_version, @rest) = split / /, $hash->{'description'};
				}

				($hash->{'vh'}, $hash->{'vms'}) = split('#', $stats_version) unless $stats_version eq '-';
			}
			undef @rest;
		}
	}

	return $hash;

}


# process_mcast(thread_shared, host)
#
# Processes a message received from a slave on the multicast socket.
# If the host already was active, update the last_active date. If it
# is new or the hardware configuration of an active host has changed, 
# trigger a hwinfo request.
#
# $thread_shared    Hash containing all active hosts
# $host             Host information from the mcast
#
# Returns:          (hwinfo_changed, stats_changed)
#                   1 if hwinfo/stats has to be triggered, 0 if the host has
#                   already been active and the configuration is
#                   unchanged.
#
sub process_mcast() {
	my $thread_shared = shift;
	my $host = shift;
	my $hwinfo_changed = 0;
	my $stats_changed = 0;
	my $unique_id = $host->{'id'};
	my $hostname = $host->{'hostname'};
	my $host_master_ip = $host->{'host_master_ip'};
	my $new_machine = 0;

	# FIXME TRANSACTION?
	my $machine_id = &machine_get_by_unique_id($unique_id);
#	my $machine_id = $dbc->enum_get_id('machine',$host->{'hostname'});
	if(!$machine_id && exists($thread_shared->{$unique_id}))	{
		delete($thread_shared->{$unique_id});
	}
	if (!$machine_id) {
		# There's no unique_id record matched in mysql DB. New machine!
		$new_machine = 1;
		$hwinfo_changed = 1;
		$stats_changed = 1 if defined $host->{'stats_version'}; # condition is for backward compatibility with hamsta prior 2.2.0
		&log(LOG_NOTICE, "ACTIVE_MCAST: new slave $host->{'hostname'} IP:$host->{'ip'} with ID: $unique_id"); 
		$thread_shared->{$unique_id} = $host; 
		$thread_shared->{$unique_id}->{'hwinfo'} = "";
	}
	elsif ($host->{'notify'} =~ /HWINFO_CHANGE/g) {
		# This is Old machine, but hardware info changed. Need refresh hwinfo!
		$hwinfo_changed = 1;
		&log(LOG_NOTICE, "ACTIVE_MCAST: $host->{'hostname'} has updated it hardware info");
		$thread_shared->{$unique_id}->{'hwinfo'} = "";
		$thread_shared->{$unique_id}->{'hwinfo_fresh'} = 1;
	}
	else {
		# Old machine, but no hwinfo changed. Check if hostname or IP changed.
		my ($ip, $hostname) = &machine_get_ipname($unique_id);
		if ($ip ne $host->{'ip'} or $hostname ne $host->{'hostname'}) {
			# Update hostname and IP if either of them changed.
			&log(LOG_NOTICE, $host->{'ip'}." begin to use the hostname: ".$host->{'hostname'});

			&TRANSACTION( 'machine' );
			&machine_update_hostnameip($unique_id, $host->{'hostname'}, $host->{'ip'});
			&TRANSACTION_END;
		}
#		following code won't work, because $thread_shared->{$unique_id}->{'cid'} not defined
#		&TRANSACTION( 'config' );
#		&config_touch($thread_shared->{$unique_id}->{'cid'});
#		&TRANSACTION_END;

		$thread_shared->{$unique_id}->{'hostname'} = $host->{'hostname'};
		$thread_shared->{$unique_id}->{'ip'} = $host->{'ip'};
	}

	$thread_shared->{$unique_id}->{'now'} = time;
	
	&TRANSACTION('machine');
	&machine_set_status( $machine_id, MS_UP );
	$host->{'update'}=0 if(! defined $host->{'update'});
	&machine_set_update_status($machine_id,$host->{'update'}) if($host->{'update'} ne 'skip');
	&TRANSACTION_END;

	&update_machine_hamsta_master_reservation($machine_id, $host_master_ip);

	&TRANSACTION('machine');
	if (defined $host->{'stats_version'}) {

		# host has been upgraded to 2.2.0 (from version that did not use stats)
		# or machine has appeared after master restart
		$thread_shared->{$unique_id}->{'stats_version'} = -1 if not defined $thread_shared->{$unique_id}->{'stats_version'};

		# Did stats changed?
		if ( $thread_shared->{$unique_id}->{'stats_version'} < $host->{'stats_version'}) {
			$stats_changed = 1;
			$thread_shared->{$unique_id}->{'stats_version'} = $host->{'stats_version'};
		}	
		
	} elsif ($machine_id) {

		# For backward compatibility only! DEPRECATED
		#
		# FIXME: this belongs to somewhere else!
		# we run it on every multicast, which is not good
		my($role, $type) = &machine_get_role_type($machine_id);
		if ($host->{'vh'}) {
			# this is a virtual host
			&machine_update_role_type($machine_id, 'VH', $host->{'vh'}) unless $role eq 'VH' and $host->{'vh'} eq $type;
		} else {
			# VH reinstalled to SUT - set VH back to SUT hw (vm cannot become VH, so we know it was hw)
			&machine_update_role_type($machine_id, 'SUT', 'hw') if $role and $role eq 'VH';
		}

		# update virtual machines
		if ($host->{'vms'}) {
			my %vmtypes;

			for (split(';', $host->{'vms'})) {
				my ($mac, $type) = split '_', $_;
				push @{$vmtypes{$type}}, $mac;
#				$macs{$mac} = $type;
			}
			for (keys %vmtypes) {
				my $type = $_;
				&machine_update_vhids($machine_id, "vm/".$host->{'vh'}."/$type", @{$vmtypes{$type}});
			}

		}
	}
	&TRANSACTION_END;

	my @result = ();
	push @result, 'hwinfo' if $hwinfo_changed;
	push @result, 'stats' if $stats_changed;
	return @result;
}

# update_machine_hamsta_master_reservation($machine_id, $host_master_ip)
# Checks the original reserved hamsta master ip of the machine and only updates machine table 
# when it is a valid and necessary reservation update
sub update_machine_hamsta_master_reservation() {
    my $machine_id = shift;
    my $host_master_ip = shift;
	if ($machine_id){
	    &TRANSACTION( 'machine','hamsta_master' );
	    my $host_master_ip_db = &machine_get_master_ip_by_machine_id($machine_id);
	    if ($host_master_ip and (! $host_master_ip_db or ($host_master_ip ne $host_master_ip_db))){
	        my $hamsta_master_id = &hamsta_master_get_id_by_ip($host_master_ip);
	        if ( ! $hamsta_master_id ){
	            #Reverse DNS to get hostname, if resolve nothing, use ip for hostname.
	            my $host_name = gethostbyaddr(inet_aton($host_master_ip), AF_INET);
	            #TODO: consider more DNS return result of host_name, other than undef and timeout issue
	            $host_name = $host_master_ip if (! defined $host_name);
	            $hamsta_master_id = &hamsta_master_insert($host_name,$host_master_ip);
                log(LOG_DETAIL,"A new hamsta master is stored into hamsta_master table!")
	        }
	        &machine_update_master($machine_id,$hamsta_master_id);
            log(LOG_DETAIL, "The reserved hamsta_master of machine #$machine_id is updated to hamsta master #$hamsta_master_id.");
	    }elsif($host_master_ip_db and ! $host_master_ip){
	        &machine_update_master($machine_id,undef);
            log(LOG_DETAIL, "The machine #$machine_id is released!");
	    }
        &TRANSACTION_END;
	}
}

# check_host_timeouts($thread_shared)
#
# Checks if a currently active machine has sent no mcast message for some
# time and sets its status to "not responding" or "down" if necessary.
#
# $thread_shared    Reference to the hash containing all active machines.
sub check_host_timeouts($) {
	my $thread_shared = shift;
	while ( (my $id, my $v) = each %{$thread_shared}) {

		# Calculate time difference between now and the last mcast message
		my $time_diff = time - $thread_shared->{$id}->{'now'};
		my $change_status = undef;

		if ($time_diff > 45) {

			# Timeout - print a message and set the thread to down
			&log(LOG_NOTICE, "ACTIVE_MCAST_THREADS: Host ($v->{'hostname'}) does not ".
				"respond since $time_diff sec, is down.");
			$change_status=MS_DOWN;
			delete ($thread_shared->{$id});
		} elsif ($time_diff > 20) {

			# Print warnings and set status "not responding"
			&log(LOG_DETAIL, "ACTIVE_MCAST_THREADS: Host $v->{'hostname'} does not respond since $time_diff sec.");
			$change_status=MS_NOT_RESPONDING;
		}
		if( $change_status )
		{
			my $machine_id = &machine_search('unique_id'=>$id);
			if( $machine_id )
			{
				if( ! &machine_blocked($machine_id) )
				{
					&TRANSACTION( 'machine' );
					&machine_set_status($machine_id,$change_status);
					&TRANSACTION_END;
				}
			}
		}
	}
}


# Master->query_info(host)
#
# Send special command to slave which is answered with XML-based hwinfo 
# response. Furthermore send the master time to the slave for time 
# synchronisation.
# 
# $host             Hash representing the host to which the info query is to
#                   be sent. If $host->{'hwinfo_fresh'} is defined and $what is 
#                   set to hwinfo, a fresh hwinfo is queried from the slave 
#                   (it must not answer "already sent") and 
#                   $host->{'hwinfo_fresh'} is deleted.
#
# $what             What should be queried. Fossible values are:
#                   - hwinfo
#                   - stats
#
# Return:           Open socket from which the client response can be read or
#                   undef if an error occurred.
# 
sub query_info () {
	my ($host, $what) = @_;

	&log(LOG_DETAIL, "ACTIVE_MCAST_THREADS_EACH: Starting $what query");


# Open a socket to the slave. It is important to open the socket in
# nonblocking mode, otherwise the active_hosts main loop will hang
# waiting for a incoming message of a single host instead of using
# whatever socket is ready for reading.
	&log(LOG_DETAIL, "Connection to host '$host->{'ip'}'");
	my $sock = IO::Socket::INET->new(
			PeerAddr => $host->{'ip'},
			PeerPort => $qaconf{hamsta_client_port},
			Proto    => 'tcp',
			Timeout  => 5,
			); # &log(LOG_ERR, "Can't bind : $@");
	if ($!) {
		&log( ($! =~/illeg/ ? LOG_WARNING : LOG_ERR),
				"QUERY_INFO($what) ".$host->{'hostname'}." : $!" );
	}

	# Set non-blocking flag
	my $flags;
	if (!$sock || !($flags = fcntl($sock, F_GETFL, 0))) {
		&log(LOG_WARNING, "QUERY_INFO($what): Could not connect to slave, aborting $what request");
		if ($sock) {
			$sock->close;
		}
		return undef;
	}
	&log(LOG_DETAIL, "Socket: $sock");
	$flags = fcntl($sock, F_SETFL, $flags | O_NONBLOCK);

	# Synchronize time 
	# This part gets the master time and sends it to the slave
	my $time_utc;
	$time_utc = gmtime;
	my @temp = split / /, $time_utc;
	my $year = pop @temp;
	push @temp, "UTC";
	push @temp, $year;

	$time_utc = join ' ', @temp;

	&log(LOG_DETAIL, "QUERY_INFO($what): time $time_utc send to $host->{'ip'}");
	$sock->send("set_time:$time_utc\n");


	# Send request for hwinfo 
	# If the field hwinfo_fresh is set, require the slave to send a new hwinfo
	if ($what eq 'hwinfo' and defined($host->{'hwinfo_fresh'})) {
		&log(LOG_INFO, "QUERY_INFO($what): send fresh hwinfo query to  $host->{'ip'}");
		$sock->send("get_hwinfo fresh\n");
		delete $host->{'hwinfo_fresh'};
	} else {
		&log(LOG_INFO, "QUERY_INFO($what): send $what query to  $host->{'ip'}");
		$sock->send("get_$what\n");
	}

	return ($sock);
}

# Master->process_hwinfo_response()
#
# used collecting and integration new/known slaves
# it calls the hwinfo query and sets the database (table machine),
# it logs some special information
#
sub process_hwinfo_response($) {
	my $host = shift;

	# Split the slave description up
	my ($name, $description, $arch, $vms, @rest) = split / /, $host->{'description'}; 
	$description = $description.$_ foreach (@rest);
	undef @rest;
	$host->{'hostname'} = $name;
	$host->{'arch'} = $arch;
	$host->{'description'} = $description;
	my $prod = &process_product($description);
	($host->{'product'}, $host->{'release'}, $host->{'product_arch'}) = @$prod;
	# Bug 864874 - hamsta master doesn't show up added SUT
	# if the length of product  is more than 50 which means the regex pattern is failed
	# to match the product, release and product_arch will be null.
	if (length($host->{'product'}) >50 ) {
		$host->{'product'} = "unknown";
		$host->{'release'} = "unknown";
		$host->{'product_arch'} = "unknown";
		$prod = [ "unknown" , "unknown" , "unknown"];
	}


	# If hwinfo has been sent, process it
	if ($host->{'hwinfo'}) {
		$host->{'hwinfo'} = uri_unescape($host->{'hwinfo'});

		# TODO: optimize, too much obsolete data
		&write_to_file('ip',$host->{'ip'});
		&write_to_file('id',$host->{'id'});
		&write_to_file('description',$host->{'description'});
		&write_to_file('konfiguration',$host->{'konfiguration'});
		my $write_hwinfo_time =  &write_to_file('hwinfo',$host->{'hwinfo'});
		$host->{'hwinfo_time'} = $write_hwinfo_time;

		# return the perl data structure from xml
		my $dump = new XML::Dumper;
		my $hwinfo_hash = $dump->xml2pl($host->{'hwinfo'});
		undef $dump;

		# create_sql_backbone can check if this is a new machine or old machine,
		# and it will add a new config entry if hwinfo md5 is changed.
		$host->{'cid'} = &create_sql_backbone($host->{'id'}, $host, $hwinfo_hash);

		undef $hwinfo_hash;
	}

	# Set the machine status to up, and the description
	my $machine_id = &machine_get_by_ip($host->{'ip'});
	if( $machine_id )
	{
		&TRANSACTION( 'machine', 'arch', 'product', 'release' );
		&machine_set_description( $machine_id, $description );
		&machine_set_product( $machine_id, @$prod );
		&TRANSACTION_END;
	}
}

# Master->process_stats_response()
#
# used collecting and integration new/knwon slaves
# it calls the stats query and sets the database (table machine),
# it logs some special information
#
sub process_stats_response($) {
	my $host = shift;

	# If stats has been sent, process it
	if ($host->{'stats'}) {
		$host->{'stats'} = uri_unescape($host->{'stats'});

		# return the perl data structure from xml
		my $dump = new XML::Dumper;
		my $stats_hash = $dump->xml2pl($host->{'stats'});
		undef $dump;

		# Update the DB
		my $unique_id = $host->{'id'};

		&TRANSACTION( 'machine' );
		my $machine_id = &machine_get_by_unique_id($unique_id);
		my($role, $type) = &machine_get_role_type($machine_id);
		if($stats_hash->{'role'} eq 'VH') {
			&machine_update_role_type($machine_id, $stats_hash->{'role'}, $stats_hash->{'type'}) unless $role eq $stats_hash->{'role'} and $type eq $stats_hash->{'type'};

			my %vmtypes;
			my %macs;

			# make sure we have empty lists for fv and pv
			$vmtypes{'fv'} = ();
			$vmtypes{'pv'} = ();
			for my $vm (@{$stats_hash->{'vms'}}) {
				push @{$vmtypes{$vm->{'type'}}}, $vm->{'mac'};
				$macs{$vm->{'mac'}} = $vm->{'type'};
			}
			for (keys %vmtypes) {
				my $type = $_;
				&machine_update_vhids($machine_id, "vm/".$stats_hash->{'type'}."/$type", @{$vmtypes{$type}});
			}


			# Delete ghosts that no longer exist and create new
			my @assigned_macs = &machine_get_known_unique_ids(keys %macs);
			my @unassigned_macs = grep!${{map{$_,1}@assigned_macs}}{$_},keys %macs; #TODO CHECKME
			my @ghosts = ();
			
			# process already known ghosts
			for my $ghost (@{$ghosts_by_vh{$machine_id}}) {
				if (grep { $_ eq $ghost->{'mac'}} @unassigned_macs) {
					# keep it - and we already have it in %ghosts_by_mac
					push @ghosts, $ghost;
				} else {
					# delete it from %ghosts_by_mac and do not add it to new @ghosts
					delete $ghosts_by_mac{$ghost->{'mac'}};
				}
			}

			# now add new if any
			for my $ghostmac (@unassigned_macs) {
				next if $ghosts_by_mac{$ghostmac};
				my $ghost = { 'mac' => $ghostmac, 'vh' => $machine_id, 'type' => "vm/".$stats_hash->{'type'}."/".$macs{$ghostmac}};
                                $ghosts_by_mac{$ghostmac} = $ghost;
				push @ghosts, $ghost;
			}

			# replace in hash
			$ghosts_by_vh{$machine_id} = \@ghosts;
			&log(LOG_DEBUG, $host->{'hostname'}." has following ghosts:\n".join("\n", map {$_->{'mac'}." ".$_->{'type'}} @ghosts));

		} elsif ($role ne $stats_hash->{'role'}) {
			# VH -> SUT conversion
			# set to default non-VH, we know it is type=hw, since VM couldn't become VH
			&machine_update_role_type($machine_id, $stats_hash->{'role'}, 'hw');

			# If there were any VM ghosts adsigned to (in past) VH, remove them - not VH anymore
			if (exists $ghosts_by_vh{$machine_id}) {
				for my $g (@{$ghosts_by_vh{$machine_id}}) {
					delete $ghosts_by_mac{$g->{'mac'}};
				}
				delete $ghosts_by_vh{$machine_id};
			}

			# TODO check and delete? VMs in DB
		} elsif ($role eq 'SUT' and exists $ghosts_by_mac{$unique_id}) {
			# This is SUT and it is also a ghost 
			# -> Therefore it must be newly created virtual machine!!!
			# We set it's type and VH to values from ghosts and remove it 
			# from ghosts, so this will never trigger again
			my $ghost = $ghosts_by_mac{$unique_id};
			&machine_update_vhids($ghost->{'vh'}, $ghost->{'type'}, $ghost->{'mac'});
			
			# delete it from ghosts			
			delete $ghosts_by_mac{$unique_id};
			my $index = 0;
			$index++ until $ghosts_by_vh{$ghost->{'vh'}}->[$index]->{'mac'} eq $ghost->{'mac'};
			splice(@{$ghosts_by_vh{$ghost->{'vh'}}}, $index, 1);
			delete $ghosts_by_vh{$ghost->{'vh'}} unless @{$ghosts_by_vh{$ghost->{'vh'}}}; # No more ghosts for this VH
			&log(LOG_DEBUG, $host->{'hostname'}." has been constructed from ghost as virtual machine" );
		}

		&TRANSACTION_END;

		undef $stats_hash;
	}
}

1;
