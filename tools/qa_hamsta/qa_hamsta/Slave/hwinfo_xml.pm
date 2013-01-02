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

# This modul query hardware information, step by step and creates a full tree of
# available hardware (in XML), it's a pity that hwinfo cannot print xml out.

package Slave;

use strict;
use warnings;

BEGIN { push @INC, '.', '/usr/share/hamsta', '/usr/share/qa/lib'; }
use log;

use XML::Dumper;
use IO::Select;
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);

require 'Slave/config_slave.pm';

my  $dumper = new XML::Dumper;

#my @modules = ('bios', 'block', 'bluetooth', 'braille', 'bridge', 'camera', 'cdrom', 'chipcard', 'cpu', 'disk', 'dsl', 'dvb', 'floppy', 'framebuffer', 'gfxcard', 'hub', 'ide', 'isapnp', 'isdn',  'pcmcia', 'joystick', 'keyboard', 'memory', 'modem', 'monitor', 'mouse', 'netcard', 'network', 'partition', 'pci', 'pppoe', 'printer', 'scanner', 'scsi', 'smp', 'sound', 'storage-ctrl', 'sys', 'tape', 'tv', 'usb', 'usb-ctrl', 'vbe', 'wlan', 'zip');
my @modules = ('bios', 'bridge', 'cpu', 'disk', 'gfxcard', 'ide', 'memory', 'network', 'partition', 'scsi', 'smp', 'storage-ctrl', 'sys', 'swap', 'system_partition', 'devel_tools', 'rpm_list', 'ishwvirt');

my $ret;
$ret = system("which virsh > /dev/null 2>&1");
push @modules, 'vmusedmemory', 'avaivmdisk' if ($ret == 0);

sub get_hwinfo_module($) {
	my $module_name = shift;
	my @result = ();

	&log(LOG_DETAIL, "Module $module_name...");

	#add some information besize hwinfo

	if($module_name eq 'swap'){
		my $module = {};
		$module->{'Description'} = "swap partition";
		$module->{'Partition_path'} = `cat /proc/swaps |awk '{a=\$1}END{print a}'`;
		push @result, $module;
		return \@result;
	}

	$ret = system("which virsh > /dev/null 2>&1");
	if($module_name eq 'avaivmdisk') {
		my $module = {};
		my $tmpstr = "";
		my @res = `df -h`;
		shift @res;

		$module->{'Description'} = "available vmdisk";
		grep(/\/var/, @res) ? (($tmpstr) = grep(/\/var/, @res)) : (($tmpstr) = grep(/\/$/, @res));
		my @tmparr = split " ", $tmpstr;
		$module->{'AvaiVMDisk'} = $tmparr[3];
		push @result, $module;
		return \@result;
	}

	if($module_name eq 'vmusedmemory') {
		my $module = {};
		my $i;
		my $tmpstr = `uname -a`;
		my @tmparr = `virsh list`;
		my @vmlistarr;
		my $vmusedmem = 0;
		pop @tmparr;

		$tmpstr =~ tr/[A-Z]/[a-z/;
		grep /xen/,$tmpstr ? $i=3 : $i=2;

		@tmparr = @tmparr[$i..@tmparr-1];

		foreach $tmpstr(@tmparr) {
		    chomp $tmpstr;
		    $tmpstr=~/\s+(\d+)/; 
		    push @vmlistarr, $1;
		}   

		foreach $i(@vmlistarr) {
		    $tmpstr = `export LANG=C; virsh dominfo $i | grep -i "Used memory:"`;
		    chomp($tmpstr);
		    $tmpstr =~ /(\d+)/;
		    $vmusedmem += $1;
		}

		$module->{'Description'} = "vmused memory";
		$module->{'VMUsedMemory'} = sprintf("%.0f",$vmusedmem/1024);
		push @result, $module;
		return \@result;
	}

	if($module_name eq 'memory') {
		my $module = {};
		$module->{'Description'} = "Main Memory";
		my $memory;
		if ( $memory = `xm info 2> /dev/null | awk '/total_memory/'`) {
			$memory = substr($memory, index($memory, ":") + 2)/1024;
		} else {
			$memory = `/usr/sbin/hwinfo --memory | awk /'Memory Size'/`;
			$memory = substr($memory, index($memory, ":") + 2);
			my @memory_list = split(/\+/, $memory);
			$memory = 0;
			foreach my $value (@memory_list) {
				my @sstring = split(" ",$value);
				if ($value =~ /TB/) {
					$memory += $sstring[0]*1024;
				} elsif ($value =~ /GB/) {
					$memory += $sstring[0];
				} elsif ($value =~ /MB/) {
					$memory += $sstring[0]/1024;
				} else {
					$memory = "unknown";
				}
			}
		}
		$memory = sprintf('%.1f', $memory).' GB';
		$module->{'Memory Size'} = $memory;
		push @result, $module;
		return \@result;
	}

	if($module_name eq 'devel_tools'){
		my $module = {};
		$module->{'Description'} = "devel tools";
		if (`zypper lr -u` =~ m/ibs\/QA(:|%3[aA])\/Head(:|%3[aA])\/Devel/) {
			$module->{'DevelTools'} = 1;
		} else {
			$module->{'DevelTools'} = 0;
		}
		push @result, $module;
		return \@result;
	}

	if($module_name eq 'rpm_list'){
		my $module = {};
		$module->{'Description'} = "rpm list";
		$module->{'RPMList'} = `rpm -qa --qf \"%{NAME} %{VERSION}-%{RELEASE}\n\" | sort`;
		push @result, $module;
		return \@result;
	}

	if($module_name eq 'system_partition'){
	my $block_disk_name = `awk '{a=\$1}END{gsub("[0-9]","",a);print a}' /proc/swaps`;
	chomp($block_disk_name);
	my $root_pt_name = `df /|awk '{a=\$1}END{print a}'`;
	chomp($root_pt_name);
	my $pt_n_s = `parted $block_disk_name print | awk -v p=$block_disk_name '\$1~/[0-9]/ && \$5!~/extend/{ print p""\$1"("\$4")" }'`;
	chomp($pt_n_s);
	my @pt_n_s = split (/\n/,$pt_n_s);
	map { $_ = $_ ." [current_root / ]" if($_ =~ /$root_pt_name/)} @pt_n_s;
	foreach my $i (@pt_n_s) {
		my $module = {};
		$module->{'Description'} = "System partition name and size :$i";
		$module->{'pt_ns'}= $i;
		push @result, $module;
		}
	return \@result;
   }

    if($module_name eq 'ishwvirt'){
        my $module = {};
        $module->{'Description'} = "Does CPU support HW Virt";
		if (`uname -a | grep -i xen && xm info | grep virt_caps |grep -i hvm || egrep '(vmx|svm)' /proc/cpuinfo`) {
			$module->{'IsHWVirt'} = 1;
		} else {
			$module->{'IsHWVirt'} = 0;
		}
        push @result, $module;
        return \@result;
    }
	
	my $pid = open (FH,"/usr/sbin/hwinfo --$module_name | grep -iv 'IRQ:' | ");
	if (not $pid) {
		&log(LOG_ERR, "ERROR: Could not start hwinfo");
		return \@result;
	}


	eval {
		local $SIG{'ALRM'} = sub { die "timeout"; };
		alarm(30);

		my $element_name = "";
		my $module;
	
		$| = 1;
		while (!eof(FH)) {
			# Read in a line from the hwinfo output and determine the indentation.
			# Ignore empty lines.

			my $line = <FH>;
		chomp $line;

			&log(LOG_DEBUG, "hwinfo: $line");
			$line =~ /^( *)[^ ]/;
			
			if (length($1) == 0) {
			
				# No indent means that a new module is starting here. We can take the
				# line as description.
				$module = {};
				push @result, $module;

				$module->{'Description'} = $line;
				$element_name = "";
				
			} elsif (length($1) == 2) {
			
				# An indent of 2 characters means that a new element is starting
				# here. If the same key is used already append the lines to the
				# existing element.
				if( $line =~ /^  ([^:]+):(?: (.*))?$/ )
		{
			$element_name = $1;

			if (exists($module->{$element_name})) {
			$module->{$element_name} .= ", $2";
			} else {
			$module->{$element_name} = $2;
			}
		}
				
			} elsif ((length($1) % 2 == 0) && ($element_name)) {
			
				# An indent of >2 characters mean that the line belongs to the element
				# started before
				$line =~ s/^ +//;
				$module->{$element_name} .= "\n".$line;
				 
			} else {
			
				# Odd number of indentation characters or large indent without having
				# an element name defined befor - that's not an expected hwinfo output
				&log(LOG_WARN, "Unexpected hwinfo output line");
			}
			
		}


		alarm(0);
	};
	if ($@) {
		use POSIX ":sys_wait_h";
		&log(LOG_ERR, "hwinfo read timeout");
		&log(LOG_NOTICE, "Killing hwinfo (PID $pid)");
		system("pkill -9 -f -P $pid hwinfo");
		kill 15, $pid;
		sleep 1;
		waitpid $pid, WNOHANG;
		@result = ();
	}
	close(FH);

	return \@result;
}


sub get_hwinfo_xml() {
	# Make sure we're not running two hwinfos at the same time (causes hangs)
	while (my @data = `pgrep -f /usr/sbin/hwinfo`) {
		&log(LOG_INFO, "Waiting for previous hwinfo to terminate.");
		sleep 10;
	}

	# Iterate through all modules
	my %result = ();
	foreach my $module (@modules) {
		my $result = get_hwinfo_module($module);
		next if (!@$result);
		$result{$module} = $result;
	}

	# Convert to XML string and write to debugging file
	my $xml = $dumper->pl2xml(\%result);
	if ($Slave::debug > 1 && open (FH, ">/tmp/debug_hwinfo.xml")) {
		print FH $xml;
		close (FH);
	} elsif ($Slave::debug > 1) {
		&log(LOG_ERR,"Could not open /tmp/debug_hwinfo.xml");
	}

	$xml =~ tr/\x00-\x07\x0b-\x19\x80-\xFF//d; # remove non-ASCII characters
	return $xml;
	
}

1;
