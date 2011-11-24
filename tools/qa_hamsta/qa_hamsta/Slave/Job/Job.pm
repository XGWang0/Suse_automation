# ***************************************************************************
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

package Slave::Job;

use strict;
use warnings;

use XML::Simple;
use threads;
use MIME::Base64;

use Slave::Job::UserLogging;

use Slave::Job::Command;
use Slave::Job::Worker;
use Slave::Job::Monitor;
use Slave::Job::Logger;
use Slave::Job::Notification;
use Slave::functions;

BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;

# Job->new($xmlfile)
#
# Creates a new Job instance using a XML job description. A Job instance has
# the following structure:
#
# * $self
#   * data              The XML job (result) description, XMLin-ed
#   * command_objects   Array of all Commands (i.e. workers, loggers, monitors) 
#                       of the Job. Initialised by Job->run()
#   * motd_id           Unique ID for the job. Is used to mark the lines in
#                       /etc/motd by this job, so we can clean up properly.
#   * user_logging      Thread which monitors logged in users
#
# $xmlfile:     Filename of the XML job description.
#
# Return:       New Job instance
sub new {
    my $classname = shift @_;
	my $xmlfile = shift @_;
    
	# Create the object
    my $self = {};
    bless($self, $classname);
    
    # Read the XML file
    &log( LOG_INFO, "Reading XML file $xmlfile" );
    $self->{'data'} = &read_xml($xmlfile,1);

# Initialize log verbosity
    $log::loglevel = $self->{'data'}->{'config'}->{'debuglevel'}->{'content'} || LOG_INFO;

# TODO Make this optional
    $self->start_user_logging();

	return $self;
}

# Job->destroy()
#
# Stops all running commands (i.e. waits for the workers to terminate and
# then kills loggers and monitors (this relies on @$self->command_objects being
# populated correctly (workers first (Yeah, we really should port the slave
# to LISP, I just start with the comments)))) and cleans up MOTD.
#
# Return:       XML job result
sub destroy {
    my $self = shift @_;

    # Gather the result of all commands
    foreach my $command (@{$self->{'command_objects'}}) {
        &log(LOG_DETAIL, "Stopping command ".$command->{'data'}->{'name'}->{'content'});
        $command->stop();
    }
    
    &log(LOG_DETAIL, "Stopping UserLogging");
    Slave::Job::UserLogging::stop($self->{'user_logging'});

    # Kill all remaining threads
    my @threads = threads->list();
    foreach my $thread (@threads) {
        $thread->kill('KILL') if threads->can("kill");
        $thread->detach();
    }

    # TODO Kill all subprocesses
    
    # Clean up /etc/motd
    if (defined($self->{'motd_id'})) {
        $self->clear_motd();
    }
    
    return $self->get_xml_log();
}

# Job->clear_motd
# clears /etc/motd, should keep the lines before Hamsta messages
sub clear_motd
{
    my $self = shift @_;
    &log(LOG_DETAIL, "Cleaning up MOTD");

    open(MOTD, "<", "/etc/motd");
    my @motd_lines = <MOTD>;
    close(MOTD);

    open(MOTD, ">", "/etc/motd");
    my $my_motd_message = 0;
    foreach my $line (@motd_lines) {
        if ($line eq "HAMSTA (HArdware Maintenance and Shared Test Automation) is using this host. See http://qa.suse.de/hamsta and look for JobID at 'List jobs' \n") {
            $my_motd_message = 1;
            next;
        }
        next if $my_motd_message;
        print MOTD $line;
    }
    close(MOTD);

}

# Job->run()
#
# Starts the whole thing up.
#   * Write some lines to /etc/motd if requested by the job description
#   * Create the Command objects
#   * Run the commands (loggers and monitors first, then workers)
#   * Append the Command objects to $self->command_objects, ensuring
#     workers are first in the list (otherwise, loggers and monitors will be 
#     terminated while a worker is still running)
sub run {
    my $self = shift;
    my @workers = ();

    $self->clear_motd();
    # Add lines to /etc/motd if requested
    if (defined($self->{'data'}->{'config'}->{'motd'}->{'content'})) {
        if (open(MOTD, ">>", "/etc/motd")) {
            &log(LOG_DETAIL, "Writing to MOTD");
            $self->{'motd_id'} = time;
            print MOTD "HAMSTA (HArdware Maintenance and Shared Test Automation) is using this host. See http://qa.suse.de/hamsta and look for JobID at 'List jobs' \n"; 
	    print MOTD "HAMSTA (ID from running Job: ".$self->{'motd_id'}."): Job '".$self->{'data'}->{'config'}->{'name'}->{'content'}."' running\n";
            print MOTD $self->{'data'}->{'config'}->{'motd'}->{'content'}."\n";
            print MOTD " contact ".$self->{'data'}->{'config'}->{'mail'}->{'content'}."!\n" if defined ($self->{'data'}->{'config'}->{'mail'}->{'content'});
            print MOTD "HAMSTA (".$self->{'motd_id'}."): End of MOTD message\n\n";
            close(MOTD);
        }
    }
    #Check rpms and install/upgrade rpms
    if( $self->{'data'}->{'config'}->{'rpm'} )	{
	my @names=@{$self->{'data'}->{'config'}->{'rpm'}};
	my $install=[];
	my $upgrade=[];
	foreach my $rpm(@names)
	{
		next unless $rpm->{'content'};
		if( $rpm->{'noupgrade'} or $rpm->{'noupdate'} )
		{	push @$install, $rpm->{'content'};	}
		else
		{	push @$upgrade, $rpm->{'content'};	}
	}
	&log(LOG_INFO, "RPMs to install if missing: %s\tRPMs to install/upgrade: %s", join(',',@$install ), join(',',@$upgrade));
	if( &install_rpms($install,$upgrade) )	{
		&log(LOG_ERROR, "RPM install/upgrade failed, aborting");
		return;
	}
	&log(LOG_INFO, "RPM install finished.");
    }

    # Create the Command objects
    @{$self->{'command_objects'}} = ();

    while ((my $type, my $commandstrings) = each(%{$self->{'data'}->{'commands'}})) {

        # We want to have a list of commands we can iterate over
        if (ref($commandstrings) ne 'ARRAY') {
            $commandstrings = [$commandstrings];
        }

        foreach my $commandstring (@$commandstrings) {
            
            # Loggers and monitors are started immediately,
            # workers are queued and started when all loggers and
            # monitors are running

            my $command;

            if ($type eq 'worker') {
                
                $command = Slave::Job::Worker->new($type, $commandstring, $self);
                push @workers, $command;
                
            } elsif ($type eq 'logger') {
                
                $command = Slave::Job::Logger->new($type, $commandstring, $self);
                push @{$self->{'command_objects'}}, $command;
                $command->run();
                
            } elsif ($type eq 'monitor') {
                
                $command = Slave::Job::Monitor->new($type, $commandstring, $self);
                push @{$self->{'command_objects'}}, $command;
                $command->run();
                
            } else {
                die "Unknown command type: $type";
            }

        }
        
    }

    foreach my $worker (@workers) {
        unshift @{$self->{'command_objects'}}, $worker;
        $worker->run();
    }
}

# Job->start_user_logging()
# 
# Starts a thread to monitor the logged in users
sub start_user_logging() {
    my $self = shift @_;
    $self->{'user_logging'} = threads->new(\&Slave::Job::UserLogging::run); 
}

# Job->get_xml_log()
# 
# Returns a XML string describing the result of the job execution, i.e. the
# whole $self->data tree converted to XML.
sub get_xml_log() {
    my $self = shift @_;
    if( $self->{'data'}->{'config'}->{'attachment'} )
    {
	    foreach my $att( @{ $self->{'data'}->{'config'}->{'attachment'} } )
	    {	# TODO: error handling
		    if( defined $att->{'path'} and open(ATT, $att->{'path'}) )
		    {
			    local($/) = undef;  # slurp
			    $att->{'content'}=encode_base64(<ATT>);
			    close ATT;
		    }
	    }
    }
    my $xml = XMLout($self->{'data'}, RootName=>'job', NoAttr=>0, KeyAttr=>[]);
    $xml =~ tr/\x00-\x07\x0b-\x19\x80-\xFF//d; # remove non-ASCII characters
    return $xml;
}

1;
