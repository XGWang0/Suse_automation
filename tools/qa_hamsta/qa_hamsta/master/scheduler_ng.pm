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

# This module implements the job scheduling.
# 
# HAMSTA jobs have a life cycle as follows:
# 
# 1. The job is created, e.g. by the web frontend or the feed_hamsta script.
#    It will be entered into the jobs table of the database in status "new".
#    The field aimed_host may or may not contain a certain host to which the
#    job should be send.
#
# 2. Jobs which are in status "new" and have no defined aimed_host are
#    distributed to free hosts in the function distribute_hosts(). If no
#    free host is found, the jobs remains in the status "new" until a free
#    machine is found.
#
# 3. All jobs in status "new" are entered into the table job_on_machine and
#    set to status "queued". This is also done by distribute_jobs().
#    Jobs in the status "queued" alway have a defined target host. If
#    a single job is to be sent to multiple hosts (not yet supported), for
#    each host a entry in the job_on_machine table is created.
#
# 4. The function schedule_jobs() processes all jobs in the status "queued"
#    and launches them when their associated host gets free (i.e. the running
#    job finishes or a manually blocked machine is unblocked). The status is
#    set to "running". The real connection to the slave to start the job is
#    done by the process_job.pl script called by schedule_jobs()
#
# 5. The slave sends a "Job ist fertig" message to process_jobs.pl which
#    sets the status to "finished".
#
# 2a / 3a
#    A job in the status "new" or "queued" can be cancelled by setting the
#    status to "deleted". delete_cancelled_jobs() deletes the entry in
#    job_on_machine if the job already is in the status "queued" and
#    removes it from the jobs table if no associated entries in
#    job_on_machine remain (at the moment, no entries will remain as jobs
#    have only a single target for now)

package Master;

use strict;
use warnings;

use functions;

require qaconfig;

require sql;
our $dbc;

# schedule_jobs()
#
# Sends queued jobs to the hosts (using the process_job.pl script).
# A job is sent to a machine only if it is in the status "queued" and the
# assigned machine is free. If there are more than one job queued for one
# machine, one of them is arbitrarily chosen and sent to the host.
#
# The process_jobs.pl script is started in its own process context, so that
# the master can be shut down and the processing of the job continues.
# 
sub schedule_jobs() {
    my $jobs = &job_on_machine_get_by_status(JS_QUEUED);
    foreach my $job (@$jobs) {
        my ($job_on_machine_id,$machine_id,$job_id)=@$job;
        my ($job_file, $job_owner, $job_name) = &job_get_details($job_id);
        if ($machine_id) {
	    my @has_connecting = &job_on_machine_get_by_machineid_status($machine_id,JS_CONNECTING);
	    my @has_running = &job_on_machine_get_by_machineid_status($machine_id,JS_RUNNING);
            my $busy_status = &machine_get_busy($machine_id);
	    my $machine_status_id = &machine_get_status($machine_id);
            if( !@has_connecting && !@has_running && !$busy_status && &machine_has_perm($machine_id,'job') && ( $job_file !~ /reinstall/ || &machine_has_perm($machine_id,'install') ) ) {
                &TRANSACTION( 'machine', 'job_on_machine', 'job' );
                &machine_set_busy($machine_id,1);
                &job_on_machine_start($job_on_machine_id);
		&job_set_status($job_id,JS_CONNECTING);
                &TRANSACTION_END;
                &log(LOG_NOTICE,"MASTER::SCHEDULER send $job->[0] to machine $machine_id");
                child {
                    system("/usr/bin/perl process_job.pl ".$job->[2]);
                    if( &sql_get_connection() )	{
			&TRANSACTION( 'machine' );
                        &machine_set_busy($machine_id,0);
			&TRANSACTION_END;
                    }
                    exit;
                }
                parent {
                    &log(LOG_DETAIL,"Processing job in PID ".(shift));
                };
            } else {
                &log(LOG_DETAIL,"MASTER::SCHEDULER machine ".$job->[1]." is busy, job $job->[0] waiting");
            }
        } else {
            &log(LOG_WARNING,"MASTER::SCHEDULER job $job->[0] has no defined destination");
        }
    }
}

# delete_cancelled_jobs()
#
# Deletes jobs in the status "delete". A job is removed from job_on_machine 
# if the job already has been in the status "queued" and from the jobs table 
# if no associated entries in job_on_machine remain.
# 
sub delete_cancelled_jobs() {
    my @jobs = &job_list_by_status(JS_CANCELED); # list cancelled jobs
    foreach my $job_id (@jobs) {
	&log(LOG_INFO,"Deleting cancelled job $job_id");
	&TRANSACTION( 'job_on_machine', 'job' );
	&job_on_machine_delete_by_job_id($job_id);
	&job_delete($job_id);
	&TRANSACTION_END;
    }
}

# distribute_jobs()
#
# Processes all jobs in the status "new".
# 
# For jobs which have a defined target host, corresponding entries are created
# in the job_on_machine table.
#
# For jobs which don't have, a free host in status "up" is searched. If a host
# could be found, an entry into job_on_machine is created, again.
#
# All jobs for which an entry into job_on_machine has been created by this
# function are set to status "queued".
# 
sub distribute_jobs() {
    my @machines_free = &machine_list_free();
    my @jobs_idle = &job_list_by_status(JS_NEW); # list idle jobs
    my %machines_assigned = ();

    foreach my $job_id (@jobs_idle)
    {
	    my $host_orig=&job_get_aimed_host($job_id);
	    my $host_aimed=$host_orig;
	    my $machine_id;
	    if( not $host_aimed )
	    {	
		    next unless @machines_free; # skip job if no free machine
		    $machine_id = shift @machines_free;
		    $host_aimed = &machine_get_ip($machine_id);
	    }
	    else
	    {
		    $machine_id = &machine_get_by_ip($host_aimed);
		    next unless $machine_id;	# skip if the machine does not exist
	    }
	    
	    my $config_id = &config_get_last($machine_id);

	    &TRANSACTION( 'machine', 'job', 'job_on_machine' );
	    &job_set_aimed_host($job_id,$host_aimed) unless $host_orig;
	    &job_on_machine_insert( $job_id, $machine_id, $config_id, JS_QUEUED );
	    &job_set_status( $job_id, JS_QUEUED );
	    &TRANSACTION_END;
    }

}

# scheduler()
#
# Main function of the scheduler. Periodically calls the functions processing
# jobs.
#
sub scheduler() {

	while(1) {
		&fix_busy_machines_without_jobs(); # remove after BNC#714905 fixed
	#&delete_cancelled_jobs();
        &schedule_jobs();
        
        # distribute_jobs is the last action because schedule_jobs could
        # cause machines to be marked as busy. To these machines no jobs
        # should be distributed. (Typical observation with different order:
        # One job starts and another gets queued, possibly even if a
        # different machine is free in fact)
        &distribute_jobs();
	$dbc->commit(); # workaround to see new updates    
		sleep 3;
	}
}

# Workaround over machines that are busy, have no jobs, and cannot be brought to idle again
# See BNC#714905
our %last_busy_machines_without_jobs=();
sub fix_busy_machines_without_jobs()	{
	&TRANSACTION('machine','job_on_machine');
	my @ids = &busy_machines_without_jobs();
	foreach my $id (@ids) {
		next unless $last_busy_machines_without_jobs{$id};
		my ($ip,$name) = &machine_get_ip_hostname( $id );
		&log(LOG_ERROR, "Machine %s (%s) is busy without jobs, fixing", $name, $ip);
		&machine_set_busy($id,0);
	}
	%last_busy_machines_without_jobs = map {$_=>1} @ids;
	&TRANSACTION_END;
}

1;

