package Slave::Job::Monitor;

# This class implements a <monitor> command. It is a subclass of Command.
#
# Monitor commands are short-running commands that are called periodically
# to record the current state of the machine.
#
# When their stop() method is called, monitors exit either immediately or
# when the currently executing command has finished, so they will exit
# when all workers have returned.

use strict;
use warnings;

use vars '@ISA';
@ISA = ('Slave::Job::Command');

BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;

# Monitor->stop()
#
# Overrides Job->stop(). A mointor sends SIGTERM to the monitor thread 
# before waiting for it to join.
sub stop() {
    my $self = shift;

    &log(LOG_DETAIL, "Stopping monitor ".$self->{'data'}->{'name'}->{'content'});
   
    if (defined($self->{'thread'})) {
        $self->{'thread'}->kill('TERM');
    }

    if (defined($self->{'pid'})) {
        kill 15, $self->{'pid'};
    }

    return $self->SUPER::stop();
}

# Monitor->do_execution()
#
# Overrides Job->do_execution(). A monitor calls Job->do_execution not only 
# once, but in a loop. The monitoring stops when the maximum number of cycles
# as defined in the job description is reached or the monitor thread catches
# a SIGTERM as sent by the stop() method.
sub do_execution {
    my $self = shift;

    my @stdout = ();
    my @stderr = ();
    
    &log(LOG_DETAIL, "Starting monitor ".$self->{'data'}->{'name'}->{'content'});
    $self->{'stop'} = 0;
    $SIG{'TERM'} = sub {
        $self->{'stop'} = 1;
    };

    # cycle_count == 0 means no restriction
    if (!defined($self->{'data'}->{'cycle_count'})) {
        $self->{'data'}->{'cycle_count'} = 0;
    }

    for (my $i = 1; ($i <= $self->{'data'}->{'cycle_count'}) || ($self->{'data'}->{'cycle_count'} == 0); $i++) {
        last if ($self->{'stop'});

        push @stdout, "\n--- Monitor cycle $i (".localtime().")";
        push @stderr, "\n--- Monitor cycle $i (".localtime().")";
        
        (my $exitcode, my $stdout, my $stderr) = $self->SUPER::do_execution();
        push @stdout, $stdout;
        push @stderr, $stderr;
        
        foreach (1 .. $self->{'data'}->{'cycle_sec'}) {
            last if ($self->{'stop'});
            sleep 1;
        }
    }    
    
    return (
        0,
        join("\n", @stdout),
        join("\n", @stderr)
    );
}

1;
