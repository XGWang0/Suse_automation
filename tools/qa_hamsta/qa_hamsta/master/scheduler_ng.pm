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
    my $jobs = &job_list_by_status(JS_QUEUED);
    foreach my $job (@$jobs) {
        #my ($job_on_machine_id,$machine_id,$job_id)=@$job;
        my ($job_file, $job_owner, $job_name,$job_id,$aimed_host) = @$job;
        #get machine_id from job and job_on_machine table
        my $unavailable_tag = 0;
        my @machine_ids;
        foreach( split(/\s*,\s*/,$aimed_host) ) {
            my $machine_id = &machine_get_by_ip($_);
            push @machine_ids,$machine_id;
            if ($machine_id) {
                my @has_connecting = &job_get_by_machineid_status($machine_id,JS_CONNECTING);
                my @has_running = &job_get_by_machineid_status($machine_id,JS_RUNNING);
                my $busy_status = &machine_get_busy($machine_id);
		my $machine_status = &machine_get_status($machine_id);
		$unavailable_tag++ if($machine_status != MS_UP);
                $unavailable_tag++ if( @has_connecting || @has_running || $busy_status || !&machine_has_perm($machine_id,'job') );
                $unavailable_tag++ if( $job_file =~ /reinstall/ && !&machine_has_perm($machine_id,'install') );
            }else{
                $unavailable_tag++;
                &log(LOG_WARNING,"MASTER::SCHEDULER job $job->[0] has no defined destination");
            }
        }
        if($unavailable_tag == 0){
            &TRANSACTION( 'machine', 'job_on_machine', 'job' );
            map { &machine_set_busy($_,1) } @machine_ids;
            &job_set_status($job_id,JS_RUNNING);
            &TRANSACTION_END;
            &log(LOG_NOTICE,"MASTER::SCHEDULER send $job->[3] to machine $aimed_host");
            child {
                system("/usr/bin/perl process_job.pl ".$job_id);
                if( &sql_get_connection() ) {
                    &TRANSACTION( 'machine' );
                    map { &machine_set_busy($_,0) } @machine_ids;
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
    }
}

# delete_cancelled_jobs()
#
# Deletes jobs in the status "delete". A job is removed from job_on_machine 
# if the job already has been in the status "queued" and from the jobs table 
# if no associated entries in job_on_machine remain.
# 
sub delete_cancelled_jobs() {

    my $jobs = &job_list_by_status(JS_CANCELED); # list cancelled jobs
    foreach my $job (@$jobs) {
        my ($job_file, $job_owner, $job_name,$job_id,$aimed_host) = @$job;
        &log(LOG_INFO,"Deleting cancelled job $job_id");
        foreach( split(/\s*,\s*/,$aimed_host) ) {
            &TRANSACTION( 'job_on_machine', 'job', 'job_part', 'job_part_on_machine' );
            &job_on_machine_delete_by_job_id($job_id);
            &job_delete($job_id);
            # DELETE CASCADE is used for foreign key about job_id and job_on_machine_id for 
            # table job_part and job_part_on_machine, so no need to delete those two here
            &TRANSACTION_END;
        }
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
    my $jobs_idle = &job_list_by_status(JS_NEW); # list idle jobs
    my %machines_assigned = ();

    foreach my $job_detail (@$jobs_idle)
    {
        my $job_id = $job_detail->[3];
        my $host_orig=&job_get_aimed_host($job_id);

        #how many machines does the job require
        my @host_aimed =  split(/\s*,\s*/,$host_orig);
        my $host_aimed;
        my @machine_id;

		#not enough free machine should not keep the scheduler from insert job
		#to job table;
        @machine_id = map {&machine_get_by_ip($_)} @host_aimed;
        my $id_config_ref;
        map{ $id_config_ref->{$_}=&config_get_last($_) } @machine_id;

        #ready to distribute this job
        #xml2part
        my $xml2part_script = "/usr/share/qa/tools/xml2part.pl";
        my $xml2part_output_dir = "/tmp/xml2part_output/$job_id";
        my $orig_job_xml = $job_detail->[0];
        &log(LOG_DETAIL,"Executing xml2part...");
        system("perl $xml2part_script -o $xml2part_output_dir $orig_job_xml >/dev/null");
        &log(LOG_INFO, "xml2part finished execution on job xml $orig_job_xml: return value is $?, output is stored in $xml2part_output_dir.");

        #get related job role and part info
        my $unique_roles = {};
        my $role_part_pairs = {};
        my @sorted_unique_parts=[];
        my $machine_role_map = {};
        my $role_machine_map = {};
	my %jom_ids = ();

	# find matching XMLs
	unless( open LIST, "find \"$xml2part_output_dir\" -name \*.xml |" )	{
		&log( LOG_ERROR, "Cannot start 'find' to list XMLs: $!" );
		return;
	}
	while( my $file=<LIST> )	{
		next unless $file =~ /\/(\d+)\/Role-([^\.]+).xml$/;
		my($part_num, $role) = ($1,$2);
		$unique_roles->{$role} = 1;
		$role_part_pairs->{$part_num}->{$role} = 1;
	}
	close LIST;


        &log(LOG_DETAIL, "Job parts-roles are: \n");
        while (my ($k,$v)=each %$role_part_pairs){&log(LOG_DETAIL,  "$k:". join(",", keys(%$v)));}
        @sorted_unique_parts = sort { $a <=> $b } keys(%$role_part_pairs);
        &log(LOG_DETAIL, "Job sorted unique parts are: @sorted_unique_parts");
        &log(LOG_DETAIL, "Job unique roless are: " . join(",", keys(%$unique_roles)));

        # machine and role mapping
        foreach my $role (keys(%$unique_roles)){
            foreach my $part (@sorted_unique_parts){
                if (exists $role_part_pairs->{$part}->{$role}){
                    $role_machine_map->{$role} = [];#one role can have multiple machines
                    if ( keys(%$unique_roles) > 1 ){
                        # multi-role jobs needs to have info about machine<>role mapping
                        my $matched = `egrep '<\\s*machine[^>]+/>' "$xml2part_output_dir/$part/Role-$role.xml"`;
                        &log(LOG_DEBUG, "Searched file is $xml2part_output_dir/$part/Role-$role.xml, matched lines are $matched");
                        foreach my $line (split "\n", $matched){
                            &log(LOG_DEBUG, "matched machine line is : $line");
                            $line =~ /machine\s+(ip\s*=\s*"([^\s]+)")?(\s+name\s*=\s*"([^\s\/]+)")?/;
                            my $machine_name = $4;
                            my $machine_ip = $2;
                            &log(LOG_DEBUG, "machine name is $machine_name, machine ip is $machine_ip");
                            my $machine_id;
                            if ($machine_ip){
                                $machine_id = &machine_get_by_ip($machine_ip);
                                $machine_role_map->{$machine_id} = $role;
                                push @{$role_machine_map->{$role}}, $machine_id;
                            }elsif($machine_name){
                                $machine_id = &machine_get_by_name($machine_name);
                                $machine_role_map->{$machine_id} = $role;
                                push @{$role_machine_map->{$role}}, $machine_id;
                            }else{
                                &log(LOG_ERROR, "This job xml is wrong for without role machine mapping info!");
                                goto NEXT_JOB;
                            }
                        }
                    }else{
                        #single role jobs does not have machine role mapping info, stored as aimed_host in table job
                        log(LOG_DETAIL, "machine id in id_config_ref is: ". join(",",keys(%$id_config_ref)));
                        my @machine_ids = keys(%$id_config_ref);
                        foreach (@machine_ids) {
                            $machine_role_map->{$_} = $role;
                            push @{$role_machine_map->{$role}}, $_;
                        }
                    }
                    last;
                }
            }
        }
        &log(LOG_DETAIL, "Job machine role map is:");
        while (my ($k,$v)=each %$machine_role_map){&log(LOG_DETAIL,  "$k:$v");}
        &log(LOG_DETAIL, "Job role machine map is:");
        while (my ($k,$v)=each %$role_machine_map){&log(LOG_DETAIL,  "$k:". join(",",@$v));}
        
        #insert mm_role
        foreach my $role (keys(%$unique_roles)){
            &TRANSACTION('mm_role');
            my $role_id;
            $role_id = $dbc->enum_get_id_or_insert('mm_role',$role);
            $unique_roles->{$role} = $role_id;
            &TRANSACTION_END;
        }
        &log(LOG_DETAIL, "mm_role table insertion is finished, and role id map is:");
        while (my ($k,$v)=each %$unique_roles){&log(LOG_DETAIL, "$k:$v");}

        #insert job_on_machine
        foreach my $machine_id (keys %$id_config_ref) {
            &TRANSACTION( 'job', 'job_on_machine' );
            &job_set_aimed_host($job_id,$host_aimed) unless $host_orig;
            my $job_on_machine_id = &job_on_machine_insert($job_id, $machine_id, $id_config_ref->{$machine_id}, $unique_roles->{$machine_role_map->{$machine_id}});
	    $jom_ids{$machine_id} = $job_on_machine_id;
            &log(LOG_DETAIL, "A new job_on_machine record is inserted as $job_on_machine_id for job_id $job_id, machine_id $machine_id.");
            &TRANSACTION_END;
        }
        &log(LOG_DETAIL, "job_on_machine insertion is finished.");

        #insert job_part, job_part_on_machine
        foreach my $part (@sorted_unique_parts){
            &TRANSACTION('job_part','job_part_on_machine');
            my $job_part_id = &job_part_insert($job_id);
            &log(LOG_DETAIL, "A new job_part record is inserted as $job_part_id.");
            foreach my $role (keys %{$role_part_pairs->{$part}}){
                #insert job_part_on_machine
                my $job_part_xml = "$xml2part_output_dir/$part/Role-$role.xml";
                my $does_reboot = &get_reboot($job_part_xml);
                foreach my $machine_id (@{$role_machine_map->{$role}}){
                    my $job_on_machine_id = $jom_ids{$machine_id};
                    &log(LOG_DEBUG, "Query result is $job_on_machine_id");
                    my $job_part_on_machine_id = &job_part_on_machine_insert($job_part_id,JS_QUEUED,$job_on_machine_id,$job_part_xml,$does_reboot);
                    &log(LOG_DETAIL, "A new job_part_on_machine is inserted as $job_part_on_machine_id for part $part role $role machine $machine_id.");
                }
            }
            &TRANSACTION_END;
        }
        &log(LOG_DETAIL, "job_part and job_part_on_machine insertion is finished.");

        #update job status
        &TRANSACTION( 'job' );
        &job_set_status( $job_id, JS_QUEUED );
        &TRANSACTION_END;

        NEXT_JOB:
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
sub fix_busy_machines_without_jobs()    {
    &TRANSACTION('machine','job_on_machine','job');
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

