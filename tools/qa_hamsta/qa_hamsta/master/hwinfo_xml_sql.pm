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
#


package Master;

use strict;
use warnings;

use DBI;
use XML::Dumper;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use functions;
require sql;
our $dbc;

use constant {
    MS_UP => 1,
    MS_DOWN => 2,
    MS_NOT_RESPONDING => 5,
};

use constant {
    JS_NEW => 0,
    JS_QUEUED => 1,
    JS_RUNNING => 2,
    JS_PASSED => 3,
    JS_FAILED => 4,
    JS_CANCELED => 5,
    JS_CONNECTING => 6,
};

require qaconfig;


# create_sql_backbone(unique_id, machine, hwinfo)
#
# Adds a machine and its configuration to the database if it is new or the
# configuration has changed.
#
# $unique_id        Unique ID of the machine
# $machine          Machine represented by a hash
# $hwinfo           hwinfo represented by an hash (module_name => \@module)
# 
sub create_sql_backbone() {
	my $unique_id = shift;
	my $machine = shift;
	my $hwinfo = shift;

	# parse main HWinfo fields
	# CPU number
	my $cpu_nr = 0+@{$hwinfo->{'cpu'}};

	# CPU vendor detection, see http://en.wikipedia.org/wiki/CPUID for known strings
	my $cpu_vendor = '';
	$cpu_vendor = $1 if $hwinfo->{'cpu'}->[0]->{'Vendor'} =~ /(Intel|AMD|Centaur|Cyrix|Transmeta|TM|NSC|NexGen|Rise|SiS|UMC|VIA|Vortex)/;
	$cpu_vendor =~ s/TM/Transmeta/;

	# memory size
	my $memsize = $hwinfo->{'memory'}->[0]->{'Memory Size'};

	# disk size
	my @disks=();
	foreach my $disk( @{$hwinfo->{'disk'}} )	{
		push @disks, (($1*$2)>>30) if $disk->{'Size'} =~ /(\d+) sectors a (\d+) bytes/;
	}
	my $disksize = join(" + ", map { $_."G" } @disks);

	# rpm list
	my $rpm_list = $hwinfo->{'rpm_list'}->[0]->{'RPMList'};

	# devel tools
	my $devel_tools = $hwinfo->{'devel_tools'}->[0]->{'DevelTools'};

# If there is already a entry for the machine (compare by hostname) use 
# that and just set its status to up. Otherwise create a new entry.
# Update the record if something changed.

	# create a new machine record, or update existing one

	&TRANSACTION( 'machine', 'arch', 'cpu_vendor', 'product', 'release');
	my $machine_id = &machine_search('unique_id'=>$machine->{'id'});
	my $arch_id = $dbc->enum_get_id_or_insert('arch',$machine->{'arch'});
	my $cpu_vendor_id = $dbc->enum_get_id_or_insert('cpu_vendor',$cpu_vendor);
	my @args = ( 
		$unique_id, $arch_id, 
		(map {$machine->{$_}} qw(hostname ip description kernel)), 
		$rpm_list, $cpu_nr, $cpu_vendor_id, $memsize, $disksize, 
		MS_UP );
	
	if (!$machine_id) {
		$machine_id = &machine_insert( @args );
		&log(LOG_INFO,"MASTER->CREATE_SQL_BACKBONE Create machine $machine_id");
	} else {
		&machine_update($machine_id, @args);
		&log(LOG_INFO,"MASTER->CREATE_SQL_BACKBONE Use machine $machine_id");
	}
	&machine_set_product($machine_id, (map {$machine->{$_}} qw(product release product_arch)) );
	&TRANSACTION_END;

	# update membership of 'devel' group
	&TRANSACTION( 'group', 'group_machine' );
	my $devel_group_id=$dbc->enum_get_id('group','devel');
	if( !defined($devel_group_id) )	{
		$devel_group_id=&group_devel_create();
	}
	if( $devel_tools )	{
		&group_machine_new($devel_group_id,$machine_id);
	}
	else	{
		&group_machine_delete($devel_group_id,$machine_id);
	}
	&TRANSACTION_END;

	# count MD5 of hwinfo and its sections
	&log(LOG_DETAIL,"MASTER->CREATE_SQL_BACKBONE Modules:");
	my ( $md5_hwinfo, $md5_modules ) = &hwinfo_md5($hwinfo);
	return -1 unless $md5_hwinfo; # broken hwinfo structure

	# check for existing configuration, exit if found
	my $config_id = &config_search_md5( $md5_hwinfo );
	return $config_id if $config_id;

	&TRANSACTION( 'module', 'module_name', 'module_part', 'config', 'config_module' );
	# create new configuration record
	$config_id = &config_insert( $machine_id, $md5_hwinfo );

	# process all the hwinfo modules
	while ((my $module_name, my $module) = each(%$hwinfo)) 
	{
		my $md5 = $md5_modules->{$module_name};
		next if (!$md5) or ($md5 eq md5_base64(""));
		&log(LOG_DETAIL,"MASTER->CREATE_SQL_BACKBONE Module $module_name\t = $md5");
		my $module_name_id = $dbc->enum_get_id_or_insert('module_name',$module_name);

		# either find a matching hwinfo module, or create a new one
		my $module_id = &module_search_md5( $module_name_id, $md5 );
		if( !$module_id )
		{	$module_id = &create_module_entry($module_name_id,$module,$md5);		}

		# link the hwinfo module to our configuration
		&config_module_insert($config_id,$module_id);
	}
	&TRANSACTION_END;

	return $config_id;
}

# create_module_entry(module_name, module)
#
# Creates new entries for the elements of the module in the database, i.e.
# fills the module table (but not config_modules, this is done by
# create_sql_backbone itself).
# 
# $module_name_id   Name ID of the hwinfo module (e.g. "netcard")
# $mode             Array representing the module (array consists of
#                   module parts which are represented by a hash
#                   where the keys are element names and values are
#                   element values)
# $md5		    MD5 of the module's hwinfo
#
# Returns:          Newly assigned module version
sub create_module_entry($\@) {
    my ($module_name_id,$module,$md5)=@_;

    my $module_version = &module_part_get_max_version($module_name_id);
    $module_version = defined($module_version) ? ($module_version + 1) : 1;
    
    my $module_id = &module_insert($module_name_id,$module_version,$md5);

    for (my $i = 0; $i <= $#$module; $i++) {
        my $part = $module->[$i];
        
        foreach my $element (sort keys %$part) {
                    
            my $tmp = "";
            if (ref($part->{$element}) eq 'HASH') {
            
                # If the element is a hash, the hwinfo output is deeper than
                # we can represent in the database, so we have to flatten it.
                
                while ((my $k, my $v) = each %{$part->{$element}}) {
                    next if !defined($v);
                    $tmp = $tmp . " " . $k . " = " . $v;
                }
                $tmp=~ s/HASH\(0x(.+?)\)//g;
                
            } elsif (defined($part->{$element})) {
                $tmp = $part->{$element};
            }
            next if ($tmp eq '');
            
            $element =~ s/^ +//g;
	    &module_part_insert($module_id,$element,$tmp,$i);
        }
    }
            
    return $module_id;
}

# counts md5sum of the whole hwinfo, and of each module
sub hwinfo_md5($) # hwinfo structure reference
{
	my $ret={};
	my $md5_hwinfo = Digest::MD5->new();
	my $md5_module = Digest::MD5->new();
	while( (my $module_name, my $module ) = each(%{$_[0]}))
	{
		if( ref($module) ne 'ARRAY' )
		{	# skip wrong data
			&log(LOG_ERR,"MASTER->CREATE_SQL_BACKBONE Error: hwinfo does not consist of arrays");
			return ();
		}
		$md5_hwinfo->add($module_name);
		$md5_module->reset();
		foreach my $part (@$module)
		{
			foreach my $element_name (sort keys %$part)
			{
				next if ref($part->{$element_name});
				my $element_value = $part->{$element_name};
				my $string = $element_name.'='.(defined($element_value) ? $element_value : '');
				$md5_hwinfo->add($string);
				$md5_module->add($string);
			}
		}
		$ret->{$module_name}=$md5_module->b64digest();
	}
	return ( $md5_hwinfo->b64digest(), $ret );
}

1;
