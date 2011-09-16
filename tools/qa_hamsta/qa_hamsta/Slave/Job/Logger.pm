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
