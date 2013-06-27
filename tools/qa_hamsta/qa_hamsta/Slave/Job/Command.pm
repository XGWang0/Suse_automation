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

package Slave::Job::Command;

# Command is the class that represents a single subelement of <commands>
# in the XML job description. Thus, it is the superclass of Worker, Logger
# and Monitor.
#
# The behaviour of the class currently is exactly what you'll expect for
# Worker, so the implementation of Worker is really empty for now.
#
# This may change in the future, so DON'T CREATE INSTANCES from this class!

use strict;
use warnings;

use File::Path;
use File::Temp;

use IPC::Open3;
use IO::Select;
use IO::Pipe;
use Proc::Fork;
use POSIX;

use Slave::Job::Notification;
BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;


# Command->new($job)
#
# Creates a new Command object. $job is a reference to a hash with the
# structure created by XML::Simple when reading in a valid XML job
# description.
sub new {
    my $classname = shift @_;
    my $type = shift @_;
    my $data = shift @_;
    my $job = shift @_;
    
	# Create the object
    my $self = {
        'job' => $job,
        'data' => $data,
	'type' => $type
    };
    bless($self, $classname);


    # Set the name of the job. If none is specified in the XML file, use
    # the command instead.
    if (!$self->{'data'}->{'name'}->{'content'}) {
        $self->{'data'}->{'name'}->{'content'} = $self->{'data'}->{'command'}->{'content'};
    }
    $self->{'data'}->{'name'}->{'content'} =~ s/\n[ \t]+/ /g;

    # Check if the command data is sensible
    if (!$self->{'data'}->{'command'}->{'content'}) {
        $self->{'data'}->{'command'}->{'content'} = "/bin/false";
        &log(LOG_ERROR, "No specified <command>");
    }
    
    if (!$self->{'data'}->{'command'}->{'execution'})	{
        $self->{'data'}->{'command'}->{'execution'} = 'threaded';
    }
    elsif (!($self->{'data'}->{'command'}->{'execution'} =~ /^(threaded|forked)$/)) {
        &log(LOG_WARNING, "Execution parameter of <command> must be 'threaded' or 'forked', got '".$self->{'data'}->{'command'}->{'execution'}."'. Defaulting to threaded.");
        $self->{'data'}->{'command'}->{'execution'} = 'threaded';
    }
    
	return $self;
}


# Command->run()
#
# Runs the command. This does not do the real work (this is done by
# do_execution) but starts either a thread or a forked process which
# calls do_execution.
#
# For forked execution the outpipe, errpipe and exitcodepipe attribute
# of the Command are initialised with pipes to which the child process
# writes and from which the parent can get the results of the
# execution.
#
# For threaded execution do_execution is called in list context, so
# when joining the thread you can get the (exitcode, stdout, stderr)
# return value of do_execution.
sub run {
    $log::loginfo='job';
    my $self = shift;

    if ($self->{'data'}->{'command'}->{'execution'} eq 'forked') {
        # Forked execution
        my $exitcodepipe = new IO::Pipe;
        my $outpipe = new IO::Pipe;
        my $errpipe = new IO::Pipe;
        
        child {
            # Don't maintain the inherited threads, the parent will
            # care for them
            my @threads = threads->list();
            foreach my $thread (@threads) {
                $thread->detach();
            }
            
            # Run the command and put the output on the pipe
            $outpipe->writer();
            $errpipe->writer();
            $exitcodepipe->writer();

            (my $exitcode, my $stdout, my $stderr) = $self->do_execution();

            print $exitcodepipe $exitcode;
            print $outpipe $stdout;
            print $errpipe $stderr;
           
            exit;
        }
        parent
        {
            local $SIG{CHLD} = 'IGNORE';
            my $pid = shift;
            $self->{'pid'} = $pid;

            $outpipe->reader();
            $errpipe->reader();
            $exitcodepipe->reader();
            
            $self->{'outpipe'} = $outpipe;
            $self->{'errpipe'} = $errpipe;
            $self->{'exitcodepipe'} = $exitcodepipe;
	    waitpid $pid ,0;
        }
        error {
            &log(LOG_ERROR, "Forking ".$self->{'data'}->{'name'}->{'content'}." has a problem"); 
        };


    } else {
        # Threaded execution
        my ($thread) = threads->new(sub { $self->do_execution(); });
        $self->{'thread'} = $thread;
    }
}

# Command->do_execution()
#
# This method does the real execution of the command. It takes care of 
# scripts which will be executed in a temporary file.
#
# Returns a list (exitcode, stdout, stderr), where exitcode contains the
# real exitcode of the command ($? >> 8) and stdout and stderr are strings
# containing the ouput of the command.
sub do_execution {
    my $self = shift;
    my $job = $self->{'job'};

    my $script_name;
    
    # First of all, change to the right directory
    $self->change_working_dir($self->{'data'}->{'directory'}->{'content'});

    # Check if the command is a script or a single line
    # Scripts are written to a temporary file before execution
    if ($self->{'data'}->{'command'}->{'content'} =~ /^(\#\!)/) {
    
        (my $fh, $script_name) = File::Temp::tempfile();
        
		if ($fh) {
			print $fh $self->{'data'}->{'command'}->{'content'};
			close ($fh);

            chmod oct('0755'), $script_name;
        } else {
            &log(LOG_ERROR, "Script wrapper could not be created, $!");
            return;
        }
    }

    # Run it
    my $stdin;
    
    $| = 1;
    my $process_end = 0;
    local $SIG{'CHLD'} = sub {
        &log(LOG_DETAIL, "Child process terminated.");
        $process_end = 1;
    };
    my $pid = open3($stdin, *CATCH_STDOUT, *CATCH_STDERR, "-");
    if ($pid == 0) {
        POSIX::setpgid(0, 0);
        exec $script_name ? $script_name : $self->{'data'}->{'command'}->{'content'};
        die("Could not exec $script_name");
    }

    $self->set_command_pid($pid);
    
    $self->{'data'}->{'stdout'} = [];
    $self->{'data'}->{'stderr'} = [];

    close($stdin);

    my $selector = IO::Select->new();
    $selector->add(*CATCH_STDOUT, *CATCH_STDERR);

    my $deadline = 0;
    if (defined($self->{'data'}->{'timeout'}->{'content'})) {
        $deadline = time + $self->{'data'}->{'timeout'}->{'content'};
    }
    
    while ($selector->count() > 0) {

        # Check if the command has timed out
        if ($deadline && (time > $deadline)) {
            push  @{$self->{'data'}->{'stderr'}}, {'content'=>"Timed out."};
            &log(LOG_WARN, "Command timed out.");
            last;
        }
        
        # Need a timeout specified for can_read, otherwise the thread will be 
        # blocked by the select and cannot handle a TERM signal
        my @ready_handles = $selector->can_read(1);
        last unless @ready_handles || ((kill 0, $pid) && (!$process_end));
        next unless @ready_handles;
        
        foreach my $fh (@ready_handles) {
        
            my $line = <$fh>;
            if (!defined($line)) {
                $selector->remove($fh);
                next;
            }
            chomp $line;
            next if $line =~ /Running for:|\[2A|^tar:/;
	    $line =~ s/[^[:ascii:]]//g;
	    $line =~ s/\x1b(?:\[\d+m)?//g;
	    my @is_log = &parse_log($line);
            if (fileno($fh) == fileno(CATCH_STDOUT)) {
                push  @{$self->{'data'}->{'stdout'}}, {'content'=>$line};
                $self->process_stdout($line);
                &log(LOG_STDOUT, (@is_log ? ():'%s'), $line);	
            } else {            
                push  @{$self->{'data'}->{'stderr'}}, {'content'=>$line};
                $self->process_stderr($line);
	        &log(LOG_STDERR, (@is_log ? ():'%s'), $line);
            }
            $selector->remove($fh) if eof($fh);
        }
    }
    close(CATCH_STDOUT);
    close(CATCH_STDERR);

    waitpid $pid, 0;
    if ($self->{'type'} eq 'worker') {
	my $return_value = $? ;
        &log(LOG_RETURN, $return_value?"$return_value (".$self->{'data'}->{'name'}->{'content'}.')':"$return_value");
    }

    # Clean up temporary script file
    if ($script_name) {
        unlink $script_name;
    }

    return (
        $?,
        join("\n", map {$_->{'content'}} @{$self->{'data'}->{'stdout'}}),
        join("\n", map {$_->{'content'}} @{$self->{'data'}->{'stderr'}})
    );
}

# Command->stop()
#
# This method is called to stop the process. This implementation waits
# just for the command to exit (which is the right behaviour for workers).
# It must be overridden if special actions should be taken, e.g. monitors
# and loggers will terminate immediately.
#
# It provides the correct values to the stdout, stderr and exitcode
# attributes of the Command which were previously unknown to the parent
# process and only available within the child process or thread which
# did the real execution of the command.
sub stop {
    my $self = shift;
    
    if (defined($self->{'pid'})) {
        &log(LOG_DETAIL, "Waiting for process: ".$self->{'data'}->{'name'}->{'content'});
        waitpid($self->{'pid'}, 0);

        $self->{'data'}->{'stdout'}->{'content'} = "";
        $self->{'data'}->{'stderr'}->{'content'} = "";

        my $outpipe = $self->{'outpipe'};
        while (my $line = <$outpipe>) {
            $self->{'data'}->{'stdout'}->{'content'} .= $line;
        }

        my $errpipe = $self->{'errpipe'};
        while (my $line = <$errpipe>) {
            $self->{'data'}->{'stderr'}->{'content'} .= $line;
        }
        
        my $exitcodepipe = $self->{'exitcodepipe'};
        while (my $line = <$exitcodepipe>) {
            $self->{'data'}->{'exitcode'}->{'content'} = ($line >> 8);
            $self->{'data'}->{'kill_signal'}->{'content'} = ($line & 0xFF) if ($line & 0xFF);
        }
    }

    if (defined($self->{'thread'})) {
        &log(LOG_DETAIL, "Joining thread: ".$self->{'data'}->{'name'}->{'content'});
        (my $exitcode, my $stdout, my $stderr) = $self->{'thread'}->join();
        &log(LOG_DETAIL, "Joined.");


        $self->{'data'}->{'kill_signal'}->{'content'} = ($exitcode & 0xFF) if ($exitcode & 0xFF);
        $self->{'data'}->{'exitcode'}->{'content'} = ($exitcode >> 8);
        $self->{'data'}->{'stdout'}->{'content'} = $stdout;
        $self->{'data'}->{'stderr'}->{'content'} = $stderr;
    }
    
}


# Command->change_working_dir($dir)
#
# Changes the current working directory. If the directory does not
# exist, it is created.
sub change_working_dir($) {
    my $self = shift @_;
    my $dir = shift @_;

    if ($dir) {
        eval { 
            # use File::Path to create recursive paths
            mkpath($dir,0,0755);
        };
        if ($@) {
            &log(LOG_ERROR, "Creation of working directory ($dir) failed: $@");
            &log(LOG_INFO,  "Using /tmp as working directory.");
            $dir = '/tmp';
        }
        chdir $dir;

    } else {
        chdir "/tmp";
    }
}

# Command->set_command_pid($pid)
#
# This method is called when a command (or script) is started and gets
# the PID of the command as parameter. Subclasses can override it
# e.g. to terminate them when stop is called (as Logger and Monitor do)
sub set_command_pid($) {
    # To be overridden
}

# Command->process_stdout($line)
#
# This method is called when the command outputs a line on stdout. It
# checks if notifications have to be generated. Subclasses can override it 
# to do additional actions.
sub process_stdout($) {
    my $self = shift;
    my $line = shift;
    
    Slave::Job::Notification::check_notification($self->{'job'}, $self, $line);
}

# Command->process_stderr($line)
#
# This method is called when the command outputs a line on stderr. It
# checks if notifications have to be generated. Subclasses can override it 
# to do additional actions.
sub process_stderr($) {
    my $self = shift;
    my $line = shift;
    
    Slave::Job::Notification::check_notification($self->{'job'}, $self, $line);
}

1;
