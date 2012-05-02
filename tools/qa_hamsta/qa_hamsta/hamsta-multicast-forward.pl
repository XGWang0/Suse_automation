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

# Hamsta UDP multicast router
# use on subnets that are separated from the master by a router
# NOTE1: only run this script once per subnet
# NOTE2: first set up in config-multicast-forward
# Author: Vilem Marsik <vmarsik@suse.cz>

BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }

use strict;
use Socket;
use IO::Socket::Multicast;
use qaconfig;

# configuration 
$forward::route = $qaconf{hamsta_master_ip};
$forward::group = $qaconf{hamsta_multicast_address};
$forward::port  = $qaconf{hamsta_multicast_port};

@forward::alt_routes = ();
for my $entry (split(/\s+/, $qaconf{hamsta_forward_alt_routes})) {
	my ($src, $dst) = split /:/, $entry;
	push @forward::alt_routes, [ $src => $dst ];
}

$forward::verbosity = $qaconf{hamsta_forward_verbosity};


# prepare the routing tables
my (@rt_bases,@rt_masks,@rt_routes,%rt_socks);
foreach my $r (@forward::alt_routes)
{
	my ($src,$dst)=@$r;
	die "Wrong IP format: $src" unless $src =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)(?:\/(\d{1,2}))?/;
	my $mask = ($5 ? ((0xffffffff << (32-$5)) & 0xffffffff) : 0xffffffff);
	push @rt_bases, (($1<<24)|($2<<16)|($3<<8)|$4) & $mask;
	push @rt_masks, $mask;
	push @rt_routes, $dst;
	$rt_socks{$dst} = IO::Socket::INET->new(PeerPort=>$forward::port,Proto=>'udp',PeerAddr=>$dst) unless $rt_socks{$dst};
}

# prepare multicast catching & default route
my $sock = IO::Socket::Multicast->new(Proto=>'udp',LocalPort=>$forward::port) || die "Couldn't bind on local port:".$forward::port." $!\n";
$sock->mcast_add($forward::group) || die "Couldn't set group $forward::group: $!\n";
my $route = IO::Socket::INET->new(PeerPort=>$forward::port,Proto=>'udp',PeerAddr=>$forward::route);

#run
MAIN: while (1) {
	my $data;
	my $src = $sock->recv($data,65535);
	($_,$src) = &sockaddr_in( $src );
	my @src=unpack('C4',$src);
	my $src_printable = join '.',@src;
	$src=($src[0]<<24)|($src[1]<<16)|($src[2]<<8)|$src[3];
	foreach my $i( 0 .. (@rt_bases-1) )
	{
		if( ($src & $rt_masks[$i]) == $rt_bases[$i] )
		{
			my $rt = $rt_routes[$i];
			print "\n$src_printable -> $rt\n" if $forward::verbosity;
			print $data if $forward::verbosity>1;
			$rt_socks{$rt}->send($data);
			next MAIN;
		}
	}
	print "\n$src_printable -> $forward::route (default)\n" if $forward::verbosity;
	print $data if $forward::verbosity>1;
	$route->send($data);
}


