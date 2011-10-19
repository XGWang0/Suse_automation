#!/usr/bin/perl -w
# ****************************************************************************
# Copyright © 2011 Unpublished Work of SUSE. All Rights Reserved.
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

# vim: set et ts=4 sw=4 ai si:

die "Usage: $0 <packages...>\n" unless @ARGV;
&check_installed( @ARGV );

sub check_installed
{
    my @build_needed=@_;
    my @install=();
    my ($cmd,$ret);

    print "checking the presence of ".(@build_needed)." packages\n";
    foreach my $package (@build_needed)
    {
        print "processing package $package\n";
        $ret = system("rpm -q \"$package\" >/dev/null") >>8;
        if( $ret == 0 ) {
            next;
        } elsif( $ret != 1 ) {
            die "rpm query failed with code $ret";
        }

        push @install, $package;
    }

    if( @install > 0 )
    {
        &command( "yast2 -i ".join ' ',@install );
    }
}


sub command
{
    my $cmd=$_[0];
    print $cmd,"\n";
    my $ret = system $cmd;
    die "Command failed with code $ret" if $ret>0;
}



