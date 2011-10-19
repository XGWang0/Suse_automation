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

package Slave::Job::Logger;

# This class implements a <logger> command. It is a subclass of Command.
#
# Loggers terminate immediately when their stop() method is called. They
# can record actions while workers are running but when all workers have
# finished, they won't keep the whole job from completing.
#
# The commands executed as Loggers will get a SIGTERM when stop() is
# called.

use strict;
use warnings;

use vars '@ISA';
@ISA = ('Slave::Job::Command');

BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;

# Logger->stop()
#
# Overrides Job->stop(). A logger sends SIGTERM to the logger process 
# or thread before waiting for it to terminate or join.
sub stop() {
    my $self = shift;

    &log(LOG_DETAIL, "Stopping logger ".$self->{'data'}->{'name'}->{'content'});
   
    if (defined($self->{'thread'})) {
        $self->{'thread'}->kill('TERM');
    }

    if (defined($self->{'pid'})) {
        kill 15, $self->{'pid'};
    }

    return $self->SUPER::stop();
}

# Logger->set_command_pid($pid)
#
# Overrides Job->set_command_pid. Saves the PID of the process or thread
# for the execution of the logger command, so it can be terminated by
# Logger->stop()
sub set_command_pid {
    my $self = shift;
    my $pid = shift;
    
    &log(LOG_DETAIL, "Set Logger PID = $pid");
    $self->{'command_pid'} = $pid;
    $SIG{'TERM'} = sub {
        &log(LOG_INFO,"Terminating PID ".$self->{'command_pid'});
        kill 15, -($self->{'command_pid'});
    };
}

1;
