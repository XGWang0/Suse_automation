#! /usr/bin/perl
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
# use warnings;

use Term::ReadLine;
use threads;
use threads::shared;
use Thread::Queue;
use IO::Socket ;
use Term::ReadPassword;

my $master;
my $port;
# handle HUP INT PIPE TERM ABRT QUIT with die, so the END block is executed
# This is important, because this client gets an ^D (EOF) and then it (transfer and) exits the Master and himself.
#
use sigtrap qw(handler my_handler any normal-signals error-signals);

sub my_handler() {
    print "Exiting normally.\n";
    exit 0;
}

# catch arguments, or set default values
if (@ARGV < 1 || $ARGV[0] =~ /-h|--help/) {
    print "Distributed Test Automation and Hardware Maintenance, client-console.\n";
    print "\t Usage: $0 MASTER_SERVER_IP [MASTER_SERVER_PORT]\n";
    exit(0);
} else {
    $master = $ARGV[0];
}

if ($ARGV[1]) {
    $port = $ARGV[1];
} else {
    $port = "18431";
}

my $DataQueue = Thread::Queue->new;
my $term = new Term::ReadLine 'cmdline_interface';
my $OUT = $term->OUT || *STDOUT{IO};

# the job is done by a thread
my $stop : shared = 0;
my @arr_ref : shared;
my $thr = threads->new(\&com_netcat,\@arr_ref);

my $latest = \@arr_ref;
sub com_netcat() {
    my $arr_ref = shift @_ ;
    my $sock;
    eval {
        $sock = IO::Socket::INET->new(PeerAddr => $master,
        PeerPort => $port,
        Proto    => 'tcp');
    };
    if (($@ =~ /Illegal seek/)) {		# do not know why this error is thrown
        # in perl -d the situation is thrown near split
	print "\n Error: $! \n";
	#exit(-1);
    }

    while (!$stop) {
        if (!$DataQueue->pending()) {
            threads->yield();
            next;
        }

        my $cmd = $DataQueue->dequeue;

        if ($cmd) {
            $sock->autoflush(1);			# we do not need
            $cmd = $cmd."\n"; 			# \n => execute !
            eval {
                $sock->send($cmd);
            };
            if ($@) {
                print "Message could not be sent. Reason: $@\n"
		    . "Aborting now.\n";
                exit(-1);
            }
        }

        while (1) {
            my $line = "";

            while (($_ = $sock->getc()) ne "") {
                $line .= $_;
                last if ($_ eq "\n");
                if ($line =~ /\$>/) {
                    unshift @{$arr_ref}, "EOM.";
                    goto OUT;
                }
            }

            $_ = $line;

            if ($_ eq '') {
                print "Master $master probably terminated our session.\n"
		    . "Aborting now.\n";
                exit(-1);
            }
            push @{$arr_ref}, $_;
        }
        OUT:
    }
}

# main
my $line = 0;
print "Welcome to distributed test automation and hardware maintenance, client-console. Master $master at $port\n";

# Get the welcome string
$DataQueue->enqueue("");

1 while (!(pop @{$latest}));
1 while ($$latest[0] ne "EOM.");
@{$latest} = ();

while (defined($_ = $term->readline("$line> ")) ) {
    my $cmd = $_;
    $cmd =~ s/^\s+|\s+$//g;
    if (lc($cmd) eq 'quit' || lc($cmd) eq 'exit') {
        $stop = 1;
        last;
    } else {
        if ($cmd eq '') {
            print "try 'help' \n";
            goto NEXT;
        }	# to help the user

        $DataQueue->enqueue($cmd);

        threads->yield() while ($$latest[0] ne "EOM.");
        shift @{$latest};

        if (${$latest}[0] eq '') {
            print "Message could not be send, possibly Master on $master terminated.\n (Guess: Try reconnect to $master) \nAborting ! \n";
            exit(-1);
        }
        my $string;
        while (my $text = pop @{$latest})
        {
            $string = $text.$string;
        }
        print $string;
    }
    NEXT:
    $line++;
}

$thr->join();
