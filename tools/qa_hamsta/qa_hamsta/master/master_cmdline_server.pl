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
#

# This is the Master.
#
 
package Master;

use warnings; 
use strict;

use IO::File;
use File::Path; 
use XML::Dumper;
use Proc::Fork;

BEGIN { push @INC, '.', '/usr/share/hamsta/master', '/usr/share/qa/lib'; }
use log;
require sql;
use functions; 	
use cmdline;
use db_common;

# this hash holds the whole information (thats why backbone) about the master and of the slaves
our $backbone = { } ;

# load the configuration 
use qaconfig('%qaconf','&get_qa_config');
%qaconf = ( %qaconf, &get_qa_config('hamsta_master') );


# Master->deconstruct()
#
# this function should be used for deconstructing the HAMSTA
# furthermore for bringing the system in a defined state
#
sub deconstruct() {
    &log(LOG_NOTICE,"MASTER->DECONSTRUCT: exit-wish received, doing clean up");

# TODO Close these links in the cmdline destructor
#    foreach my $socket (@commandline_clients) {
#        print "MASTER->DECONSTRUCT: destroy commandline user connection \n";
#        eval {
#            close ${$socket};
#        };
#        print "MASTER->DECONSTRUCT: WARNING: termination on socket: $@ \n" if ($@);
#    }
    
    # empty the machine table, so we have to initialize and fill them later again
    &sql_get_connection();

    &TRANSACTION( 'machine','job_on_machine','job' );
    &machine_set_all_unknown();
    &TRANSACTION_END;

    exit -1;	
    # TODO: write log information into file or database, that master has gone
}

# Master->load_config()
#
# sets the configured values from qaconfig file
# eg. root-directory, port for command line server, for slaves
# important is, that it deletes the temporary files
#
sub load_config() {
    if ($qaconf{'hamsta_master_root'}) {
        $backbone->{'master_root'} = $qaconf{'hamsta_master_root'};
    } else {
        &log(LOG_WARNING,"No master_root set, defaulting to /tmp/master");
        $backbone->{'master_root'} = "/tmp/master/";
    }

    if (!($qaconf{hamsta_master_cli_port}) || !($qaconf{hamsta_master_max_cli_connections})) {
        $qaconf{hamsta_master_cli_port} = 18431;
        $qaconf{hamsta_master_max_cli_connections} = 1024;
    }	

    if (!($qaconf{hamsta_client_port})) {
        $qaconf{hamsta_client_port} = 2222;
    }

}

#################################
# the startup sequence
#################################
$SIG{'HUP'} = sub { exit (0); };
$SIG{'CHLD'} = 'IGNORE';

# configuration:
# set a default layout of the variable backbone
$backbone->{'active'} = { };


# load configuration 
&load_config();
sleep 1;

our $respawn_delay = $qaconf{'hamsta_master_respawn_delay'};

$0 = $log::loginfo = 'master';
$log::loglevel = $qaconf{hamsta_master_loglevel_main} if $qaconf{hamsta_master_loglevel_main};
&log_add_output( path=>$qaconf{'hamsta_master_root'}.'/error.log', level=>LOG_ERROR );
# Initialisation
&log(LOG_INFO, "Starting multicast server");
child {
	# MULTICAST SERVER
	use active_hosts;

	$0 = $log::loginfo = 'active_hosts';
	$log::loglevel = $qaconf{hamsta_master_loglevel_multicast} if $qaconf{hamsta_master_loglevel_multicast};
	if( &sql_get_connection() )	{
		while(1)	{
			eval { &active_hosts(); };
			&log(LOG_ERROR, "active_hosts died (restarting in $respawn_delay s): $@");
			sleep $respawn_delay;
		}
	}
	exit;
}
parent {
    &log(LOG_DETAIL, "active_hosts is PID ".(shift));
};

&log(LOG_INFO, "Starting scheduler");
child {
	# SCHEDULER
	use scheduler_ng;

	$0 = $log::loginfo = 'scheduler';
	$log::loglevel = $qaconf{hamsta_master_loglevel_scheduler} if $qaconf{hamsta_master_loglevel_scheduler};
	&log_add_output( path=>$qaconf{'hamsta_master_root'}.'/scheduler.log' );
	if( &sql_get_connection() )	{
		while(1)	{
			eval { &scheduler(); };
			&log(LOG_ERROR, "scheduler died (restarting in $respawn_delay s): $@");
			sleep $respawn_delay;
		}
	}
	exit;
}
parent {
	&log(LOG_DETAIL, "scheduler is PID ".(shift));
};    

# command-Interface 
&log_add_output( path=>$qaconf{'hamsta_master_root'}.'/master.log' );


# initialize the destroy functions
$SIG{KILL} = \&deconstruct;
$SIG{INT} = \&deconstruct;
$SIG{TERM} = \&deconstruct;
while(1) {
	&log(LOG_INFO, "Starting command interface, Port: ".$qaconf{hamsta_master_cli_port});
	eval { &command_line_server(); };
	&log(LOG_WARNING, "Command line server died (restarting in $respawn_delay s): $@");
	sleep $respawn_delay;
}

