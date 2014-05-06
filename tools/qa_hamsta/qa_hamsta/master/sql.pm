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

package Master;


use strict;
use warnings;

BEGIN	{
	push @INC, '.', '/usr/share/hamsta/master', '/usr/share/qa/lib';
}


use db_common('$dbc');
use base 'db_common';

%db_common::enums = (
	'arch'			=>	[ 'arch_id', 'arch' ],
	'cpu_vendor'		=>	[ 'cpu_vendor_id', 'cpu_vendor' ],
	'group'			=>	[ 'group_id', 'group' ],
	'job_status'		=>	[ 'job_status_id', 'job_status' ],
	'machine'		=>	[ 'machine_id', 'name' ],
	'machine_status'	=>	[ 'machine_status_id', 'machine_status' ],
	'module_name'		=>	[ 'module_name_id', 'module_name' ],
	'product'		=>	[ 'product_id', 'product' ],
	'release'		=>	[ 'release_id', 'release' ],
);

our @ISA = ('db_common');


### machine functions

sub machine_get_status($) # machine_id
{	return $dbc->scalar_query('SELECT machine_status_id FROM machine WHERE machine_id=?',$_[0]);	}

sub machine_set_status($$) # machine_id, status
{	return $dbc->update_query('UPDATE machine SET machine_status_id=? WHERE machine_id=?',$_[1],$_[0]);	}

sub machine_set_update_status($$) # machine_id, status
{	return $dbc->update_query('UPDATE machine SET update_status=? WHERE machine_id=?',$_[1],$_[0]);	}

sub machine_set_description($$) # machine_id, description
{	return $dbc->update_query('UPDATE machine SET description=? WHERE machine_id=?',$_[1],$_[0]);	}

sub machine_set_product($$$$) # $machine_id, product, release, product_arch
{
	my ($machine_id,$prod,$rel,$arch)=@_;
	$arch =~ s/i[346]86/i586/;
	my $prod_id = $dbc->enum_get_id_or_insert('product',$prod);
	my $rel_id  = $dbc->enum_get_id_or_insert('release',$rel);
	my $arch_id = $dbc->enum_get_id_or_insert('arch',$arch);
	return $dbc->update_query('UPDATE machine SET product_id=?,release_id=?,product_arch_id=? WHERE machine_id=?',$prod_id,$rel_id,$arch_id,$machine_id);
}

sub machine_get_by_ip($) # IP address
{	return $dbc->scalar_query('SELECT machine_id FROM machine WHERE ip=?',$_[0]);	}

sub machine_get_ip($) # machine_id
{	return $dbc->scalar_query('SELECT ip FROM machine WHERE machine_id=?',$_[0]);	}

sub machine_get_info($) # ip
{
	my $sql = 'SELECT m.usage, group_concat(DISTINCT u.name SEPARATOR \', \'), m.maintainer_id '
	    . 'FROM `machine` m INNER JOIN user_machine um ON (m.machine_id = um.machine_id) '
	    . 'INNER JOIN `user` u ON (um.user_id = u.user_id) WHERE m.ip = ? GROUP BY m.ip';
    return $dbc->row_query($sql, $_[0]);
}

# 0 = free, 1 = busy, 2 = blocked manually)
sub machine_get_busy($) # machine_id
{	return $dbc->scalar_query('SELECT busy FROM machine WHERE machine_id=?',$_[0]);	}

sub machine_set_busy($$) # machine_id, busy
{	return $dbc->update_query('UPDATE machine SET busy=?, last_used=NOW() WHERE machine_id=?',$_[1],$_[0]);	}

sub machine_has_perm($$) # machine_id, perm_str
{    return $dbc->scalar_query('SELECT FIND_IN_SET(?,perm) FROM machine WHERE machine_id=?',$_[1],$_[0]);    }

sub machine_set_all_unknown(){
     $dbc->update_query('UPDATE job_on_machine SET job_status_id=4 WHERE job_status_id=6');
     $dbc->update_query('UPDATE job SET job_status_id=4 WHERE job_status_id=6');
     $dbc->update_query('UPDATE machine SET machine_status_id=6');
}

sub machine_get_ip_hostname($) # machine_id
{	return $dbc->row_query('SELECT ip,name FROM machine WHERE machine_id=?',$_[0]);	}

sub machine_get_by_unique_id($) # machine_id
{   return $dbc->scalar_query('SELECT machine_id FROM machine WHERE unique_id=?',$_[0]); }

sub machine_get_ipname($) # machine_id
{   return $dbc->row_query('SELECT ip,name FROM machine WHERE unique_id=?',$_[0]); }

sub machine_get_role_type($) # machine_id
{   return $dbc->row_query('SELECT role,type FROM machine WHERE machine_id=?',$_[0]); }

sub machine_get_id_by_ip_user_id ($$) # ip, user_id
{
    my $sql = 'SELECT m.machine_id FROM `machine` m INNER JOIN user_machine um ON '
	. '(m.machine_id = um.machine_id) WHERE m.ip = ? AND um.user_id = ?';
    return $dbc->scalar_query ($sql, $_[0], $_[1]);
}

sub machine_get_known_unique_ids(@) # list of mac addresses
{
	my @unique_ids = @_;
	my $fmt = join ',', map { '?' } @unique_ids;

	return @unique_ids ? $dbc->vector_query("SELECT unique_id FROM machine WHERE unique_id in ($fmt)", @unique_ids) : ();
}

sub machine_search
{
	my %args = (
		'fields'=>['machine_id'],
		'return'=>'scalar',
		@_
	);
	my @fields = @{$args{'fields'}};
	my $ret=$args{'return'};
	delete $args{'fields'};
	delete $args{'return'};
	my $where = join ' AND ', map {"$_=?"} keys %args;
	my @args=('SELECT '.join(',',@fields).' FROM machine'.($where ? " WHERE $where":''),values(%args));
	return  ( $ret eq 'scalar' ? $dbc->scalar_query(@args) :
		( $ret eq 'row' ? $dbc->row_query(@args) :
		( $ret eq 'vector' ? $dbc->vector_query(@args) :
		$dbc->matrix_query(@args))));
}

sub machine_insert($$$$$$$$$$$$) # unique_id, arch_id, hostname, IP, description, kernel, cpu_nr, cpu_vendor_id, memsize, disksize, machine_status_id
{	return $dbc->insert_query("INSERT INTO machine (unique_id,arch_id,name,ip,description,kernel,cpu_nr,cpu_vendor_id,memsize,disksize,machine_status_id,last_used,affiliation,`usage`,anomaly) VALUES(?,?,?,?,?,?,?,?,?,?,?,NOW(),'','','')",@_);	}

sub machine_update($$$$$$$$$$$$) # machine_id, unique_id, arch_id, hostname, IP, description, kernel, cpu_nr, cpu_vendor_id, memsize, disksize, machine_status_id
{	
	my $machine_id = shift;
	return $dbc->update_query('UPDATE machine SET unique_id=?,arch_id=?,name=?,ip=?,description=?,kernel=?,cpu_nr=?,cpu_vendor_id=?,memsize=?,disksize=?,machine_status_id=? WHERE machine_id=?',@_,$machine_id);
}


sub machine_update_hostnameip($$$) # unique_id, hostname, IP
{   return $dbc->update_query('UPDATE machine SET name=?,ip=? WHERE unique_id=?',@_[1,2,0]);    }

sub machine_update_role_type($$$) # machine_id, role, type
{ return $dbc->update_query('UPDATE machine SET role=?,type=? WHERE machine_id=?',@_[1,2,0]);    }

sub machine_blocked($) # machine_id
{
	my $s = &machine_get_status($_[0]);
	return ! ( $s==1 or $s==2 or $s==5 );
}

sub machine_list_free()
{	return $dbc->vector_query("SELECT machine_id FROM machine WHERE busy=0 AND machine_status_id=1");	}

sub machine_list_all()
{
	return $dbc->matrix_query ('SELECT m.name, m.ip, ms.machine_status FROM machine m INNER JOIN machine_status ms on (m.machine_status_id = ms.machine_status_id)');
}

sub busy_machines_without_jobs()	{
	return $dbc->vector_query("SELECT machine_id FROM machine WHERE busy=1 AND NOT EXISTS(SELECT * FROM job_on_machine WHERE machine.machine_id=job_on_machine.machine_id AND (job_status_id=2 OR job_status_id=6))");
}

### virtual machines functions

sub machine_update_vhids($$@) # machine_id_of_VH, type, unique_id_list
{
	my ($vh_id, $type, @unique_ids) = @_;
	my $result;

	my $fmt = join ',', map { '?' } @unique_ids;
	my $cond = @unique_ids ? " AND unique_id NOT IN ($fmt)" : '';

	# remove guests of given type that are not here anymore
	$result = $dbc->update_query("UPDATE machine SET vh_id=NULL WHERE vh_id=? AND type=?$cond", $vh_id, $type, @unique_ids);
	
	# add guests to the host that were reported in the last message
	$result += $dbc->update_query("UPDATE machine SET vh_id=?, type=? where unique_id IN ($fmt)", $vh_id, $type, @unique_ids) if @unique_ids;
	
	return $result
}

### job functions

sub job_set_status($$) # job_id, job_status_id
{	
    $dbc->update_query('UPDATE job_on_machine SET job_status_id=? WHERE job_id=?',$_[1],$_[0]);
    return $dbc->update_query('UPDATE job SET job_status_id=? WHERE job_id=?',$_[1],$_[0]);
}

sub job_get_status($) # job_id
{	return $dbc->scalar_query('SELECT job_status_id FROM job_on_machine WHERE job_id=?',$_[0]);	}

sub job_get_aimed_host($) # job_id
{	return $dbc->scalar_query('SELECT aimed_host FROM job WHERE job_id=?',$_[0]);	}

sub job_set_aimed_host($$) # job_id, aimed_host
{	return $dbc->update_query('UPDATE job SET aimed_host=? WHERE job_id=?',$_[1],$_[0]);	}

sub job_get_details($) # job_id
{	return $dbc->row_query('SELECT xml_file,job_owner,short_name FROM job WHERE job_id=?',$_[0]);	}

sub job_delete($) # job_id
{	return $dbc->update_query('DELETE FROM job WHERE job_id=?',$_[0]);	}

sub job_insert($$$$$$$) # short_name, xml_file, description, job_owner, slave_directory, job_status_id, aimed_host)
{	return $dbc->insert_query('INSERT INTO job(short_name,xml_file,description,job_owner,slave_directory,job_status_id,aimed_host) VALUES(?,?,?,?,?,?,?)',@_);	}

sub job_stop_all($) # machine_id
{	return $dbc->update_query('UPDATE job SET job_status_id=3 WHERE aimed_host=?',$_[0]);	}

sub job_list_by_status($) # job_status_id
{	return $dbc->vector_query('SELECT job_id FROM job WHERE job_status_id=?',$_[0]);	}

### job_on_machine_functions

sub job_on_machine_list($) # job_id
{	return $dbc->vector_query("SELECT job_on_machine_id FROM job_on_machine WHERE job_id=?",$_[0]);	}

sub job_on_machine_set_status($$) # job_on_machine_id, job_status_id
{	return $dbc->update_query("UPDATE job_on_machine SET job_status_id=? WHERE job_on_machine_id=?",$_[1],$_[0]);	}

sub job_on_machine_delete_by_job_id($) # job_id
{	return $dbc->update_query('DELETE FROM job_on_machine WHERE job_on_machine_id=?',$_[0]);	}

sub job_on_machine_set_return($$$) # job_on_machine_id, return_status, return_xml
{	return $dbc->update_query('UPDATE job_on_machine SET return_status=?,return_xml=? WHERE job_on_machine_id=?',$_[1],$_[2],$_[0]);	}

sub job_on_machine_get_by_job_id($) # job_id
{	return $dbc->matrix_query('SELECT job_on_machine_id,machine_id FROM job_on_machine WHERE job_id=?',$_[0]);	}

sub job_on_machine_get_by_status($) # status_id
{	return $dbc->matrix_query('SELECT job_on_machine_id,machine_id,job_id FROM job_on_machine WHERE job_status_id=?',$_[0]);	}

sub job_on_machine_get_by_machineid_status($$) # machine_id status_id
{	return $dbc->vector_query('SELECT machine_id FROM job_on_machine WHERE machine_id=? AND job_status_id=?',$_[0],$_[1]);	}

sub job_on_machine_start($) # job_on_machine_id
{	return $dbc->update_query('UPDATE job_on_machine SET start=NOW(), job_status_id=2 WHERE job_on_machine_id=?',$_[0]);	}

sub job_on_machine_stop($) # job_on_machine_id
{	return $dbc->update_query('UPDATE job_on_machine SET stop=NOW(), job_status_id=4 WHERE job_on_machine_id=?',$_[0]);	}

sub job_on_machine_stop_all($) # machine_id
{	return $dbc->update_query('UPDATE job_on_machine SET stop=NOW(), job_status_id=3 WHERE machine_id=?',$_[0]);	}

sub job_on_machine_set_last_log($$) # job_on_machine_id, last_log
{	return $dbc->update_query('UPDATE job_on_machine SET last_log=? WHERE job_on_machine_id=?',$_[1],$_[0]);	}

sub job_on_machine_insert($$$$) # job_id, machine_id, config_id, job_status_id
{	return $dbc->insert_query('INSERT INTO job_on_machine(job_id,machine_id,config_id,timestamp,job_status_id) VALUES(?,?,?,NOW(),?)',@_);	}


### group_machine functions

sub group_machine_new($$) # group_id, machine_id
{	return $dbc->insert_query('INSERT IGNORE INTO group_machine(group_id,machine_id) VALUES(?,?)',$_[0],$_[1]);	}

sub group_machine_delete($$) # group_id, machine_id
{	return $dbc->update_query('DELETE IGNORE FROM group_machine WHERE group_id=? AND machine_id=?',$_[0],$_[1]);	}

### module functions

sub module_search_md5($$) # module_name_id, module_md5
{	return $dbc->scalar_query('SELECT module_id FROM module WHERE module_name_id=? AND module_md5=?',@_);	}

sub module_insert($$$) # module_name_id, module_version, module_md5
{	return $dbc->insert_query('INSERT INTO module(module_name_id,module_version,module_md5) VALUES(?,?,?)',@_);	}

### module_part functions

sub module_part_insert($$$$) # module_id, element, value, part
{	return $dbc->insert_query('INSERT INTO module_part(module_id,element,value,part) VALUES(?,?,?,?)',@_);	}

sub module_part_get_max_version($) # module_name_id
{	return $dbc->scalar_query('SELECT MAX(module_version) FROM module WHERE module_name_id=?',$_[0]);	}


### config_module functions

sub config_module_insert($$) # config_id, module_id
{	return $dbc->insert_query('INSERT INTO config_module(config_id,module_id) VALUES(?,?)',@_);	}

sub config_module_get_version($$) # module_name_id, md5
{	return $dbc->scalar_query('SELECT module_version FROM config_module WHERE module_name_id=? AND module_md5=?',@_);	}


### config functions
sub config_insert($) # machine_id, md5
{	return $dbc->insert_query('INSERT INTO config (timestamp_created, timestamp_last_active, machine_id,config_md5) VALUES (NOW(),NOW(),?,?)',@_);	}

sub config_touch($) # config_id
{	return $dbc->update_query('UPDATE config SET timestamp_last_active = NOW() WHERE config_id=?',$_[0]);	}

sub config_search_md5($) # config_md5
{	return $dbc->scalar_query('SELECT config_id FROM config WHERE config_md5=?',$_[0]);	}

sub config_get_last # machine_id
{	return $dbc->scalar_query('SELECT config_id FROM config WHERE machine_id=? ORDER BY timestamp_last_active DESC LIMIT 1',$_[0]);	}

### group functions

sub group_list_status($) # group_id
{	return $dbc->matrix_query('SELECT name, machine_status FROM machine NATURAL JOIN group_machine NATURAL JOIN machine_status WHERE group_id=?',$_[0]);	}

sub group_list_ip($) # group_id
{	return $dbc->vector_query('SELECT ip FROM machine JOIN group_machine USING(machine_id) WHERE group_id=?',$_[0]);	}

sub group_insert($$) # group, desc
{	return $dbc->insert_query('INSERT INTO `group`(`group`,description) VALUES(?,?)',@_);	}

sub group_devel_create()	{
	my $id=&group_insert('devel','Machines having devel tools installed.');
	$dbc->update_query('UPDATE `group` SET group_id=0 WHERE group_id=?',$id);
	return $dbc->enum_get_id('group','devel');
}

### user functions

sub user_get($) # user_id
{
	return $dbc->vector_query ('SELECT user_id, extern_id, login, name, email, password FROM user WHERE user_id = ?', $_[0]);
}

sub user_get_id($) # login
{
	return $dbc->scalar_query ('SELECT user_id FROM user WHERE login = ?', $_[0]);
}

sub user_get_login($) # user_id
{
	return $dbc->scalar_query ('SELECT login FROM user WHERE user_id = ?', $_[0]);
}

sub user_get_password($) # login
{
	return $dbc->scalar_query ('SELECT password FROM user WHERE login = ?', $_[0]);
}

sub user_get_roles($) # user_id
{
	return $dbc->vector_query ('SELECT `role` FROM `user_role` NATURAL JOIN `user_in_role` NATURAL JOIN `user` WHERE user_id = ?', $_[0]);
}

sub user_get_reserved_machines($) # user_id
{
	return $dbc->vector_query ('SELECT m.name FROM machine m INNER JOIN user_machine um ON (m.machine_id = um.machine_id) WHERE um.user_id = ?', $_[0]);
}

sub user_get_privileges($) # user_id
{
	return $dbc->vector_query ('SELECT p.privilege FROM user_in_role uir INNER JOIN user_role ur on (uir.role_id = ur.role_id) INNER JOIN role_privilege rp ON (ur.role_id = rp.role_id) INNER JOIN privilege p ON (rp.privilege_id = p.privilege_id) WHERE uir.user_id = ?', $_[0]);
}

### user role functions

sub role_get_id($) # role name
{
	return $dbc->scalar_query ('SELECT role_id FROM `user_role` WHERE `role` = ?', $_[0]);
}

sub role_list_all()
{
	return $dbc->vector_query ('SELECT `role` FROM `user_role`');
}	

sub role_get_privileges($) # role_id
{
	return $dbc->vector_query ('SELECT privilege FROM `privilege` p JOIN `role_privilege` rp ON (p.privilege_id = rp.privilege_id) WHERE rp.role_id = ? AND (rp.valid_until IS NULL OR rp.valid_until > NOW())', $_[0]);
}    

### user reservation functions

sub create_user_reservation ($$$$)
{
    return $dbc->update_query ('INSERT INTO user_machine (machine_id, user_id, user_note, expires)'
			       . ' VALUES (?,?,?,?)', @_);
}

sub remove_user_reservation ($$)
{
    return $dbc->update_query ('DELETE FROM user_machine WHERE machine_id = ? AND user_id = ?', @_);
}

### log functions

sub log_insert($$$$$$$) # machine_id, job_on_machine_id, log_time, log_type, log_user, log_what, log_text
{	return $dbc->insert_query('INSERT INTO `log`(machine_id,job_on_machine_id,log_time,log_type,log_user,log_what,log_text) VALUES(?,?,?,?,?,?,?)',@_);	}

### transaction functions wrappers

sub TRANSACTION
{	return $dbc->TRANSACTION(@_);	}

sub TRANSACTION_END
{	return $dbc->TRANSACTION_END;	}

1;
