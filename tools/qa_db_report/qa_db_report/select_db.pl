#!/usr/bin/perl -w
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


use strict;

BEGIN {
	# extend the include path to get our modules found
	push @INC,"/usr/share/qa/lib";
}

use qaconfig;

our $filename = $ENV{'HOME'}.'/.mysql_loc.rc';

#our %data = (
#	'db' => [ 'qadb', 'qadb', 'qadb', 'qadb', 'qadb' ],
#	'host' => [ 'qadb.suse.de', 'bender.suse.cz', 'marge.suse.cz', 'qauto-testqadb.sled.lab.novell.com', 'vm-auto-devel.qa.suse.cz' ],
#	'user' => [ 'hamsta-default', 'qadb', 'qadb', 'qadb', 'qadb' ],
#	'pwd' => [ '', 'qadb', 'qadb', 'qadb', 'qadb' ]
#);

print STDERR "Warning: *** select_db.pl is not supported anymore ***\n";
print STDERR "Warning: Use the standard QA configuration files instead.\n";
print STDERR "Warning: Note: For user-specific configuration, ~/.qarc can be used.\n";
print STDERR "\n";

if ( -f $filename ) {
	print STDERR "Warning: File $filename exists. This might mean that the deprecated\n";
	print STDERR "         configuration exists. This confiduration will *not* be used\n";
	print STDERR "         Following configuration is a new form of the configuration\n";
	print STDERR "         in $filename:\n";
	print STDERR "\n";
	print STDERR "var qadb_db_host '".`. $filename ; echo -n \$sql_host`."'\n";
	print STDERR "var qadb_db_name '".`. $filename ; echo -n \$sql_db`."'\n";
	print STDERR "var qa_db_report_login '".`. $filename ; echo -n \$sql_user`."'\n";
	print STDERR "var qa_db_report_password '".`. $filename ; echo -n \$sql_pwd`."'\n";
	print STDERR "\n";
}

print "Current configuration:\n";
print "var qadb_db_host '".$qaconf{qadb_db_host}."'\n";
print "var qadb_db_name '".$qaconf{qadb_db_name}."'\n";
print "var qa_db_report_login '".$qaconf{qa_db_report_login}."'\n";
print "# qa_db_report_password **undisclosed**\n";

#our @k = qw(host db user pwd);
#
#our $num1=@{$data{'db'}};
#
#sub list
#{
#	my $selected = shift;
#	foreach my $i (0 .. $num1-1)
#	{
#		print "[$i]".($i==$selected ? ' *':'')."\n",(map {"\t$_:\t'".${$data{$_}}[$i]."'\n"} qw(host db user)),"\n";
#	}
#}
#
#sub check_config
#{
#	my $i;
#	my $num2=@k;
#	my @match = map {0} (0 .. $num1-1);
#	unless( open CONFIG, $filename )
#	{
#		print STDERR "Cannot read $filename: $!";
#		return -1;
#	}
#	while( my $row=<CONFIG> )
#	{
#		if( $row =~ /^\s*sql_(host|db|user|pwd)\s*=\s*(.*)$/ )
#		{
#			for( $i=0; $i<$num1; $i++ )
#			{
#				if( $data{$1}[$i] eq $2 )
#				{	$match[$i]++;	}
#			}
#		}
#	}
#	close CONFIG;
#	for( $i=0; $i<$num1; $i++ )
#	{
#		return $i if $match[$i]==$num2;
#	}
#	return -1;
#}
#
#sub set
#{
#	my $selected = shift;
#	open CONFIG, ">$filename" or die "Cannot write $filename: $!";
#	foreach my $key (@k)
#	{
#		print CONFIG "sql_$key=".${$data{$key}}[$selected]."\n";
#	}
#	close CONFIG;
#}
#
#if( @ARGV==0 )
#{	&list(&check_config);	}
#elsif( @ARGV==1 and $ARGV[0] =~ /\d+/ and $ARGV[0]>=0 and $ARGV[0]<$num1 )
#{
#	&set($ARGV[0]);
#}
#else
#{
#	print $0,"[<number>] - displays/switches QA database\n";
#	1;
#}
#
#my $selected = &check_config;
#&list($selected);

