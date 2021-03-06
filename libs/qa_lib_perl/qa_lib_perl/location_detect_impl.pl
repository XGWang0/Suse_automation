#!/usr/bin/perl

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

use strict;
use warnings;

BEGIN {
	push @INC,"/usr/share/qa/lib",'.';
}

# gets the system location (cz|de|cn|us) from ifconfig output
# returns: cz|de|cn|us
# Only use this directly if you really know what you're doing!!
# NORMALLY, you want to use location.pl
my $loc = undef;

open USE_GATE, "route -n|awk '\$4~/UG|GU/{print \$2}'|";
while( my $row=<USE_GATE> )
{
#		print $row;
	if( $row =~ /^(\d+)\.(\d+)\./ )
	{
		if( $1==10 )
		{
			if( $2==10 or $2==11 or $2==0 or $2==120 or $2==121 or $2==122 or $2=~/^16/ )
			{   $loc='de'; }
			elsif( $2==100 )
			{   $loc='cz'; }
		}
		elsif( $1==147 ) 
		{   $loc='cn'; }
		elsif( $1==137 or $1==151 ) 
		{   $loc='us'; }
	}
}
close USE_GATE;

my $ret=0;
if ($loc) {
	print "$loc\n";
} else {
	$ret=1;
}

exit $ret;
