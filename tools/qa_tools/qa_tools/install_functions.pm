#!/usr/bin/perl -w
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

package install_functions;
use strict;
use warnings;
use qaconfig;

BEGIN	{
	push @INC, '/usr/share/qa/lib', '.';
	use Exporter();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	@ISA	= qw(Exporter);
	@EXPORT	= qw(
		&parse_source_url
		&command
		&patch_file
		&get_patterns
		&get_packages
		&get_profile
		&make_modfile
	);
	%EXPORT_TAGS	= ();
	@EXPORT_OK	= ();
}
our @EXPORT_OK;

use File::Basename;

# gets distro info from the install URL
sub parse_source_url
{
	my $name=$_[0] or return ();
	my ( $type, $ver, $sub, $arch);

	if( $name =~ /(os|opensuse|suse-linux|suse)-?(\d+)\.(\d+)/i  or
			$name =~ /(full)-(\d+).(\d+)-(\w+)/i) {
		($type,$ver,$sub) = ( 'opensuse', $2, $3 );
	} elsif(  $name =~ /(sles?|sled)-?(\d+)(.*?-?sp-?(\d+))?/i or
			$name =~ /full-(sles?)(\d+)(-sp(\d+))?/i ) {
		($type,$ver,$sub) = ( 'sles', $2, $4 );
		$type=lc($1) if lc($1) eq 'sled';
		$type = 'slert' if $name =~ /-(slert|rt)-/i;
		$type = 'slepos' if $name =~ /-slepos-/i;
		$sub = 0 unless $sub;
	}
	if ($name =~ /(i\d86|ppc(64)?|s390x?|ia64|x86[_-]64)/i) {
		$arch = lc $1;
		$arch =~ s/-/_/g;
	}
	return ($type, $ver, $sub, $arch) if wantarray;
	return { type=>$type, version=>$ver, subversion=>$sub, arch=>$arch };
}

# runs a command
sub command
{
	my $cmd=$_[0];
	print $cmd,"\n";
	my $ret = system $cmd;
	die "Command '$cmd' failed with code $ret" if $ret>0;
}

# patches a file
## define in reinstall.pl but never get used.
sub patch_file
{
	my ($file,$patch) = @_;
	print "patching file '$file'\n";
	my $patchfile = "/tmp/patch_$$";
	open my $handle, ">$patchfile" or die "Cannot create temporary file '$patchfile': $!";
	print $handle $patch;
	close $handle;
	&command( "patch \"$file\" \"$patchfile\"" );
}

# returns true if the products maps IDE discs to /dev/sd\w
sub _has_libsata
{
	my ($type,$version,$subversion,$arch)=@_;
	return 1 if `hwinfo --disk | grep VMware`;
	return 1 if $version >= 11;
	return 0 if $version == 10 and $subversion > 2 and $arch =~ /i.86/; #Work around for BZ647130, but this behavior is definetly wrong!
	return 1 if $version == 10 and $subversion > 2;
	return 0;
}

# converts device path to (device,num), converts libsata name changes
sub disk_stats
{
	my ($partition,$libsata)=@_;
	my ($dev,$num);
	if( $partition =~ /^(.*\w+)(\d+)$/ ) {
		($dev,$num)=($1,$2);
	} else {
		return undef;
	}
	$dev = $1 if ($dev =~ /^(.*c\dd\d)p$/);
	if ( $dev =~ /dev\/hd/ or ( $dev =~ /dev\/sd/ and `hwinfo --disk | grep "pata_via"` ) ) {
		my $short=substr($dev,-1,1);
		if( $libsata ) {
			$dev="/dev/sd".$short;  
		} else {
			$dev="/dev/hd".$short;
		}
	}
	chomp($dev);
	return ($dev,$num);
}

# reads root and swap partition info
sub _read_partitions
{
	my $args=shift;
	my $libsata=&_has_libsata(map {$args->{$_}} qw(to_type to_version to_subversion to_arch));
	my $swappart=`cat /proc/swaps | tail -n 1 | cut -f1 -d' '`;
	my $swapsize = `cat /proc/swaps | tail -n 1 |awk {'print \$3'}`;
	my $rootpart=`df /|tail -n1 | cut -f1 -d' '`;
	$rootpart=$args->{'root_pt'} if($args->{'root_pt'});
	my $abuildpart=`df | grep "abuild" |tail -n1 | cut -f1 -d' '`;
	my $abuildsize=`df -m |grep "abuild" |tail -n1 |awk {'print \$2'} | cut -f1 -d' '`;
	my $bootpart;
	my $bootsize = `df -m |grep "/boot/efi" |tail -n1 |awk {'print \$2'} | cut -f1 -d' '`;
	my $abuildid;
	my $abuildnum;
	chomp($swapsize);
	chomp($abuildsize);
	chomp($bootsize);
	if ($args->{'to_arch'} eq 'ppc64' or $args->{'to_arch'} eq 'ppc') {
		$bootpart="/dev/" . `ls -l \$(grep ^boot /etc/lilo.conf | cut -d \" \" -f3) \| awk -F/ {'print \$NF'}`;
	} else {
		$bootpart=`df /boot/efi 2>/dev/null | tail -n1 | cut -f1 -d' '`;
	}
	my ($rootid,$rootnum) = &disk_stats($rootpart,$libsata);
	if ($abuildpart) {
		($abuildid,$abuildnum) = &disk_stats($abuildpart,$libsata);
	}
	my ($swapid,$swapnum) = &disk_stats($swappart,$libsata);
	my ($bootid,$bootnum) = &disk_stats($bootpart,$libsata);
	return ($rootid,$rootnum,$swapid,$swapnum,$bootid,$bootnum,$bootsize,$abuildid,$abuildnum,$abuildsize,$swapsize);
	# TODO: check for undefined results
	# TODO: sanitize output, maybe integrate into _print_profile_partitions
}

# detects patterns
sub get_patterns 
{
	my $args = shift;
	my $ret = 'base';
	if( !defined $args->{'patterns'} )	{
		# case 1: patterns not set, return detected
	} elsif( $args->{'patterns'} =~ s/^\+// )	{
		# FIXME: it won't come here because of Getopt::Long, reconfiguring needed
		# case 2: patterns preceeded by '+', append them to detected
		$ret .= ",".$args->{'patterns'};
	} else	{
		# case 3: patterns set without '+', use instead of detected
		return $args->{'patterns'};
	}
	if($args->{'to_type'} eq 'sled') { 
		# this won't work for older SLEDs, but does anyone really use them?
		$ret =~ s/(^|,)base($|,)/$1desktop-base$2/g;
		$ret =~ s/(^|,)kde($|,)/$1desktop-kde$2/g;
		$ret =~ s/(^|,)gnome($|,)/$1desktop-gnome$2/g;
	}
	$args->{'patterns'} = join(',', sort split(',',$ret));
	return $args->{'patterns'};
}

sub get_packages
{
	my $args = shift;
	my $ret='qa_tools,qa_hamsta,autoyast2,vim,mc,iputils,less,screen,lsof,pciutils,tcpdump,telnet,zip,yast2-runlevel,SuSEfirewall2,curl,wget,perl,openssh';
	if( $args->{'to_type'} eq 'opensuse' or $args->{'to_type'} eq 'sled') {
		$ret .= ',nfs-client';	
	} else {	
		$ret .= ',nfs-utils';	
	}
	if( $args->{'virthosttype'} )	{
		$ret .= ",libvirt,libvirt-python,xen-libs,vm-install,virt-manager,virt-viewer";
		$ret .= ($args->{'virthosttype'} eq 'xen') ? ",xen,xen-tools,kernel-xen" : ",kvm"; 
	}	
	#$ret .= ",pam-modules-64bit,resmgr-64bit" if $to_arch eq 'ppc64'; #BZ706671
	$ret .= ",qa_setvncserver" if ($args->{'patterns'} =~ /gnome|kde/ );
	$ret .= ",atk-devel,at-spi,gconf2" if $args->{'setupfordesktoptest'};
	$ret .= ",".$args->{'additionalrpms'} if (defined $args->{'additionalrpms'});
	$ret .= ','.$qaconf{install_additional_rpms}  if $qaconf{install_additional_rpms};
	$args->{'packages'} = $ret;
}

sub get_profile
{
	my $args = shift;
	my $profiledir = shift;
	return "$profiledir/".($args->{'to_version'} < 10 ? 'sles9' : 'default').'.xml'; 
}

sub _get_buildservice_repo
{
# TODO
# SLES_9, SLE_10_SP1_Head, SLE_10_SP2_Head, SLE_Factory, openSUSE_11.0, openSUSE_Factory
	my ($type,$version,$subversion) = @_;
	if( $type eq 'opensuse' ) {
		return "openSUSE_11.4" if $version==11 and $subversion==4;
		return "openSUSE_12.1" if $version==12 and $subversion==1;
		return 'openSUSE_Factory';
	} else {
		return 'SLES_9' if $version==9;
		return 'SLE_10_SP1_Head' if $version==10 and $subversion<=1;
		return 'SLE_10_SP2_Head' if $version==10 and $subversion==2;
		return 'SLE_10_SP3' if $version==10 and $subversion==3;
		return 'SLE_10_SP4' if $version==10;
		return 'SUSE_SLE-11_GA' if $version==11 and $subversion==0;
		return 'SUSE_SLE-11-SP1_GA' if $version==11 and $subversion==1;
		return 'SUSE_SLE-11-SP2_GA' if $version==11 and $subversion==2;
		return 'SUSE_SLE-11-SP3_GA' if $version==11 and $subversion==3;
		return 'SLE_Factory' if $version>11;
	}
	return undef;
}

# creates a modification file for AutoYaST
sub make_modfile
{
	my $args=shift;
	my $patterns = &get_patterns($args);
	my $packages = &get_packages($args);
# put it all into one function,
# would return (undef,undef) if the partition does not exist
	my $QA_repo=$qaconf{install_qa_repository};
	my $testusr = $qaconf{install_testuser_login};
	my $testpass = $qaconf{install_testuser_password};
	my $testname = $qaconf{install_testuser_fullname};
	my $testhome = $qaconf{install_testuser_home};
	my $rootpass = $qaconf{install_root_password};

	# open modfile
	my $modfile="/tmp/modfile_$$.xml";
	open my $f, ">$modfile" or die "Cannot create patch file '$modfile' : $!";

	# header
	print $f '<profile xmlns="http://www.suse.com/1.0/yast2ns" xmlns:config="http://www.suse.com/1.0/configns">'."\n";
	print $f " <install>\n" if $args->{'to_version'}<10;

	# addon/SDK/... URLs
	print $f <<EOF;
	<add-on>
		<add_on_products config:type="list">
EOF
	my @urls=($QA_repo."/".&_get_buildservice_repo($args->{'to_type'}, $args->{'to_version'}, $args->{'to_subversion'}));
	push @urls, split(/,/,$args->{'url_addon'}) if $args->{'url_addon'};
	foreach my $url(@urls) {
		print $f <<EOF;
			<listentry>
				<media_url>$url</media_url>
				<product_dir>/</product_dir>
				<accept_unknown_gpg_key config:type="boolean">true</accept_unknown_gpg_key>
				<accept_unsigned_file config:type="boolean">true</accept_unsigned_file>
				<accept_file_without_checksum config:type="boolean">true</accept_file_without_checksum>
				<accept_verification_failed config:type="boolean">true</accept_verification_failed>
				<accept_non_trusted_gpg_key config:type="boolean">true</accept_non_trusted_gpg_key>
				<import_gpg_key config:type="boolean">true</import_gpg_key>
				<ask_on_error config:type="boolean">false</ask_on_error>
			</listentry>
EOF
	}
	if ( $args->{'opensuse_update'} ) {
		my $opensuse_update_url = "http://download.opensuse.org/update/".$args->{'to_version'}.'.'.$args->{'to_subversion'}.'/';
		my $opensuse_update_name = $args->{'to_version'}.'.'.$args->{'to_subversion'}." update";
		print $f <<EOF;
		<listentry>
			<media_url>$opensuse_update_url</media_url>
			<product>openSUSE Updates</product>
			<product_dir>/</product_dir>
			<ask_on_error config:type="boolean">true</ask_on_error>
			<name>$opensuse_update_name</name>
		</listentry>
EOF
	}
	print $f <<EOF;
	</add_on_products>
	</add-on>
EOF
	# partitions
	&_print_profile_partitions($args,$f);

	# patterns / packages
	my $pat='pattern';
	my $pats='patterns';
# TODO: since when it is patterns and not RPM groups ?
	if( $patterns or $packages ) {
		print $f "  <software>\n";
		if( $patterns ) {
			print $f "	<$pats config:type=\"list\">\n";
			print $f map {"	  <$pat>".$_."</$pat>\n"} split(/,/,$patterns);
			print $f "	</$pats>\n";
		}
		if( $packages ) {
			print $f "	<packages  config:type=\"list\">\n";
			print $f map {'	  <package>'.$_."</package>\n"} split(/,/,$packages);
			print $f "	</packages>\n";
		}
		print $f "	  <do_online_update config:type=\"boolean\">true</do_online_update>" if $args->{'install_update'};
		print $f "  </software>\n";
	}

	# upgrade
	if ($args->{'upgrade'}) { # Upgrade with autoyast
		print $f "  <upgrade>\n";
		print $f "	  <only_installed_packages config:type=\"boolean\">false</only_installed_packages>\n";
		print $f "	  <stop_on_solver_conflict config:type=\"boolean\">true</stop_on_solver_conflict>\n";
		print $f "  </upgrade>\n";
	}
	
	# bootloader
	&_print_profile_bootloader( $args, $f );

	# Start registration info
	my $updatetag='suse_register';
	$updatetag = "customer_center" if $args->{'to_version'}<11;
	if ( $args->{'install_update'} and $args->{'to_type'} ne "opensuse" ) {
		print $f "	<$updatetag>
	  <do_registration config:type=\"boolean\">true</do_registration>
	  <register_regularly config:type=\"boolean\">false</register_regularly>\n";
	}

	# Register NCC without SMT
	if ( $args->{'install_update'} and $args->{'ncc_email'} and $args->{'ncc_code'} and $args->{'to_type'} ne "opensuse" ) {
		print $f "\t  <registration_data>\n";
		print $f "\t    <email>".$args->{'ncc_email'}."</email>\n";
		foreach my $rcode (split(/,/, $args->{'ncc_code'})) {
			my $prname = "";
			# Possible regi-codes could be: WORKFORCEID@PRV-EXT-SLES-XXXXXXXXXX
			# or sles10XXXXXXXX
			if ($rcode =~ /^.+(-.+){3}.+$/) {
				$rcode =~ /^.*-([^-]+)-[^-]+$/;
				$prname = lc $1;
			} else {
				$rcode =~ /^([a-zA-Z]+)\d+.+$/;
				$prname = lc $1;
			}
			print $f "		<regcode-$prname>$rcode</regcode-$prname>";
		}
		print $f "	  </registration_data>\n";
	}

	# Register NCC from https://secure-www.novell.com/center/regsvc, we just update from local SMT server here.
	print $f "	<reg_server>$args->{'smt_server'}</reg_server>\n" if ( $args->{'install_update'} and $args->{'smt_server'} and $args->{'to_type'} ne "opensuse" );

	# Finish registration info
	if ( $args->{'install_update'} and $args->{'to_type'} ne "opensuse" ) {
		print $f "	  <submit_hwdata config:type=\"boolean\">true</submit_hwdata>
	  <submit_optional config:type=\"boolean\">true</submit_optional>
	</$updatetag>";
	}

	# Scripts section, we can add every command that we would like to run on the 1st boot here.
	# Especially useful for some work arounds of autoyast bug
	print $f "	<scripts>\n";
	print $f "	  <post-scripts config:type=\"list\">
		<script>
		  <filename>zzz_write_passwords</filename>
		  <interpreter>shell</interpreter>
		  <source>
		    mkdir -p /usr/share/qa/data/passwords ;
		    echo '$rootpass' > /usr/share/qa/data/passwords/root ;
		    echo '$testpass' > /usr/share/qa/data/passwords/$testusr
		  </source> 
		 </script>
           </post-scripts>\n";

	print $f "	 <init-scripts config:type=\"list\">
	  <script>
		<filename>yya_for_xorg</filename>
		<interpreter>shell</interpreter>
		<source>
		  rm -f /etc/X11/xorg.conf*;
		</source>
	  </script>";  # This is work around for BZ647296

	if (@urls) { # For BZ687770, install its product after add addon repo
		print $f "	  <script>
		<filename>yyb_install_product</filename>
		<interpreter>shell</interpreter>
		<source>";
		foreach my $url(@urls) {
			print $f "		  prod=`zypper se -t product -r $url | grep '^  |' | cut -d '|' -f2`;
		  zypper --non-interactive in --auto-agree-with-licenses -t product \$prod;";
		}
		print $f "		</source>
	  </script>";
	}

	if ( $args->{'install_update'} and $args->{'to_type'} ne "opensuse" ) { # This is work around for consistent reboot after upgrade
		print $f "	  <script>
		<filename>yyy_for_updates</filename>
		<interpreter>shell</interpreter>
		<source>
		  chkconfig autoyast off;
		  zypper -n --no-gpg-checks up -l;
		  rug ref;
		  rug up -y --agree-to-third-party-licences;
		</source>
	  </script>";
	}
	
	unless ($args->{'upgrade'}) {
		if ( $args->{'setupfordesktoptest'} ) { # Autoun asistive technologies and xhost + on gdm login
			print $f "      <script>
			<filename>zzz_setup_4_desktop_tests</filename>
			<interpreter>shell</interpreter>
			<source>
			  su $testusr -c 'gconftool-2  -s --type=Boolean /desktop/gnome/interface/accessibility True' ;
			  mkdir -p $testhome/.config/autostart ;
	
			  echo '[Desktop Entry]'                 > $testhome/.config/autostart/xhost.desktop ;
			  echo 'Type=Application'               >> $testhome/.config/autostart/xhost.desktop ;
			  echo 'Exec=xhost +'                   >> $testhome/.config/autostart/xhost.desktop ;
			  echo 'Hidden=false'                   >> $testhome/.config/autostart/xhost.desktop ;
			  echo 'X-Gnome-Autostart-enabled=true' >> $testhome/.config/autostart/xhost.desktop ;
			  echo 'Name=xhost'                     >> $testhome/.config/autostart/xhost.desktop ;
			  echo 'Comment=xhost + to allow hamsta run desktop tests' >> $testhome/.config/autostart/xhost.desktop ;
	
			  chown -R $testusr:users $testhome/.config 
			</source> 
			</script>";
	
		}
	
	        # write user config - if it is different
	        my $qarepo=$qaconf{install_qa_repository};
	        my $addrpms=$qaconf{install_additional_rpms};
	        print $f "      <script>
	          <filename>zzz_preserve_install_config</filename>
	          <interpreter>shell</interpreter>
	          <source>
		    source /usr/share/qa/lib/config '' ;
		    different=0 ;
		    file=/etc/qa/66-current_installation ;
		    [ '$rootpass' == \"\`get_qa_config install_root_password\`\" ]     || different=1 ;
		    [ '$testusr'  == \"\`get_qa_config install_testuser_login\`\" ]    || different=1 ;
		    [ '$testpass' == \"\`get_qa_config install_testuser_password\`\" ] || different=1 ;
		    [ '$testname' == \"\`get_qa_config install_testuser_fullname\`\" ] || different=1 ;
		    [ '$testhome' == \"\`get_qa_config install_testuser_home\`\" ]     || different=1 ;
		    [ '$qarepo'   == \"\`get_qa_config install_qa_repository\`\" ]     || different=1 ;
		    [ '$addrpms'  == \"\`get_qa_config install_additional_rpms\`\" ]   || different=1 ;
	
		    if [ \$different -eq 1 ] ; then
		      echo '# This file contains custom configuration, that has beed used to install'  > \$file;
		      echo '# this host. If you want to use default values for next installation, '   >> \$file;
		      echo '# please delete this file. If you want to customize next installation, '   >> \$file;
		      echo '# please write your configutation to higher priority config file  '        >> \$file;
		      echo '# please (see man qa_lib_config for details).'                             >> \$file;
		      echo                                                                            >> \$file;
		      [ '$rootpass' == \"\`get_qa_config install_root_password\`\" ]     || echo \"install_root_password='$rootpass'\" >> \$file;
		      [ '$testusr'  == \"\`get_qa_config install_testuser_login\`\" ] || echo \"install_testuser_login='$testusr'\" >> \$file;
		      [ '$testpass' == \"\`get_qa_config install_testuser_password\`\" ]    || echo \"install_testuser_password='$testpass'\" >> \$file;
		      [ '$testname' == \"\`get_qa_config install_testuser_fullname\`\" ] || echo \"install_testuser_fullname='$testname'\" >> \$file;
		      [ '$testhome' == \"\`get_qa_config install_testuser_home\`\" ]     || echo \"install_testuser_home='$testhome'\" >> \$file;
		      [ '$qarepo'   == \"\`get_qa_config install_qa_repository\`\" ]     || echo \"install_qa_repository='$qarepo'\" >> \$file;
		      [ '$addrpms'  == \"\`get_qa_config install_additional_rpms\`\" ]   || echo \"install_additional_rpms='$addrpms'\" >> \$file;
		    fi
	          </source> 
	        </script>";
	
		if ( $args->{'virthosttype'} ) { ## VH
			print $f "	<script>
				<filename>yyz_set_virthost</filename>
				<interpreter>shell</interpreter>
				<source>
				  echo $args->{'virthosttype'} > /var/lib/hamsta/VH;
				</source>
			  </script>";  # Set this host as virtualization host of correct type
	
			print $f "      <script>
				<filename>yyz_start_libvirtd</filename>
				<interpreter>shell</interpreter>
				<source><![CDATA[#!/bin/bash
				  which virsh >/dev/null 2>&1 && chkconfig -a libvirtd && rclibvirtd start
				  ]]>
				</source>
			  </script>";
			if ( $args->{'virthosttype'} eq 'kvm' ) {
			#FIXME: better detect and die if not supported
			my $module = system("grep -q 'vmx' /proc/cpuinfo") == 0 ? "kvm-intel" : "kvm-amd";
				print $f "	<script>
				<filename>yyz_load_kvm</filename>
				<interpreter>shell</interpreter>
				<source>
					sed -i 's/^MODULES_LOADED_ON_BOOT=\"/MODULES_LOADED_ON_BOOT=\"$module kvm /' /etc/sysconfig/kernel;
					modprobe $module; modprobe kvm;
				chkconfig -a libvirtd;
				rclibvirtd restart;
				  </source>
				</script>";  # Load KVM modules
			}
		}
	}
	print $f "	  </init-scripts>\n";
	
	# For upgrade, replace bootloader with original one before the installation
	if ($args->{'upgrade'}) {
		my ($bootpart, $bootparttype, $bootpath, $boothpathrel, $postcmd);

		if($args->{'to_arch'} =~ /^ppc(64)?$/) {
			$bootpath = '/etc/lilo.conf';
			$postcmd = '/sbin/lilo';
		} elsif ($args->{'to_arch'} eq 'ia64') {
			$bootpath = '/boot/efi/efi/SuSE/elilo.conf';
			$postcmd = ''; #nothing needed
		} elsif ($args->{'to_arch'} =~ /^(i[356]86)|(x86_64)$/) {
			$bootpath = '/boot/grub/menu.lst';
			$postcmd = ''; # nothing needed
		} else {
			# We should never reach this line!
			die "ERROR: Architecture $args->{'to_arch'} is not supported for upgrade!";
		}

		# Get boot partition, its type and rel path
		my $p=$bootpath;
		my $bootpathrel='';
		my $found=0;
		my @mount=split /\n/, `export LANG=C ; mount`;
		until($found) {
			$bootpathrel = '/'.basename($p).$bootpathrel;
			$p = dirname($p);
			my @lines = grep(/\s$p\s/, @mount);
			next unless @lines;
			die "Error: multiple mount lines match mountpoint $p." if @lines > 1;
			my $line = $lines[0];
			$line =~ /^(\S+)\s+on\s+$p\s+type\s+(\S+)\s+/;
			$bootpart = $1;
			$bootparttype = $2;
			$found=1;
		}

		my $bootconfig=`cat $bootpath`;
		print $f "        <pre-scripts config:type=\"list\">
	          <script>
		    <interpreter>shell</interpreter>
		    <filename>aaa_restore_bootloader</filename>
		    <source><![CDATA[#!/bin/bash
mkdir /qamnt
mount -t $bootparttype $bootpart /qamnt

cat << QAEOF > /qamnt$bootpathrel
$bootconfig
QAEOF

umount /qamnt 
rmdir /qamnt
		    
		      ]]>
		    </source>
	          </script>
	        </pre-scripts>\n";

		print $f "        <chroot-scripts config:type=\"list\">
	          <script>
		    <interpreter>shell</interpreter>
		    <filename>bbb_write_bootloader</filename>
		    <source><![CDATA[#!/bin/bash
$postcmd		 
		      ]]>
		    </source>
	          </script>
	        </chroot-scripts>\n" if $postcmd;


	}

	print $f "	</scripts>"; # End of the scripts section

	unless ($args->{'upgrade'}) {	
		my $dm;
		my $rl;
		# Assign display manager in /etc/sysconfig/displaymanager
		if ( $patterns =~ /gnome/ ) {
			$dm = "gdm";
			$rl = "5";
		} elsif ( $patterns =~ /kde/ ) {
			$dm = "kdm";
			$rl = "5";
		} else {
			$rl = "3";
		}
	
		### Conflicts between vhreinstall and this script
		print $f "	<sysconfig config:type=\"list\" >
			  <sysconfig_entry>
				<sysconfig_key>DISPLAYMANAGER</sysconfig_key>
				<sysconfig_path>/etc/sysconfig/displaymanager</sysconfig_path>
				<sysconfig_value>$dm</sysconfig_value>
			  </sysconfig_entry>
			  <sysconfig_entry>
			  	<sysconfig_key>DISPLAYMANAGER_AUTOLOGIN</sysconfig_key>
			  	<sysconfig_path>/etc/sysconfig/displaymanager</sysconfig_path>
			  	<sysconfig_value>".$qaconf{install_testuser_login}."</sysconfig_value>
			  </sysconfig_entry>
			</sysconfig>" if $dm;
		print $f "	<runlevel>
		  <default>$rl</default>;
		</runlevel>\n";
	
		print $f "  <networking>\n";
		my $dhcp_hostname = ( $args->{'virttype'} ? 'true' : 'false' );
		print $f "    <dns>
				<dhcp_hostname config:type=\"boolean\">$dhcp_hostname</dhcp_hostname>
				<resolv_conf_policy>auto</resolv_conf_policy>\n";

		if (!$args->{'newvm'}) { ## no need for VM
			print $f "	  <hostname>".$args->{'hostname'}."</hostname>\n";
			print $f "	  <domain>".$args->{'domainname'}."</domain>\n";
		}
		print $f "	</dns>\n";
		print $f "	<interfaces config:type=\"list\">\n";
		foreach my $if ( glob "/sys/class/net/*" )	{
			next unless $if =~ /(eth(\d+))/;
			my ($dev,$num) = ($1,$2);
			my $mac = `cat $if/address`;
			chomp $mac;
			my $ip = $1 if `ip -4 -o addr show $dev` =~ /inet ([\d\.]+)/;
			if (!$ip && !system('which brctl > /dev/null 2>&1')) {
				# Check, whether this interface is not part of some active bridge
				# If yes, than get the IP of the bridge
				my $bridgedev;
				$bridgedev = '';
				$bridgedev = $1 if `brctl show | grep $dev` =~ /^([\w]+)\s.*\s$dev$/;
				$ip = $1 if $bridgedev && `ip -4 -o addr show $bridgedev` =~ /inet ([\d\.]+)/;
			}
			my $dev2 = "eth-id-$mac"; # fix spontaneous renaming
			if( $args->{'virthosttype'} || $args->{'setup_bridge'} )	{ # VH
				print $f <<EOF;
			<interface>
				<bootproto>dhcp4</bootproto>
				<bridge>yes</bridge>
				<bridge_forwarddelay>0</bridge_forwarddelay>
				<bridge_ports>$dev</bridge_ports>
				<bridge_stp>off</bridge_stp>
				<device>br$num</device>
				<startmode>auto</startmode>
			</interface>
EOF
			} elsif($ip) { # phys + VM
				print $f <<EOF;
			<interface>
				<bootproto>dhcp</bootproto>
				<device>$dev2</device>
				<startmode>onboot</startmode>
			</interface>
EOF
			}
			$ip = '';
		}
		print $f "	</interfaces>\n";
		print $f "  </networking>\n";
		if ($qaconf{nis_domain}) {
			print $f	"  <nis>\n";
			print $f	"	<nis_broadcast config:type=\"boolean\">false</nis_broadcast>\n";
			print $f	"	<nis_broken_server config:type=\"boolean\">false</nis_broken_server>\n";
			print $f	"	<nis_by_dhcp config:type=\"boolean\">true</nis_by_dhcp>\n";
			print $f	"	<nis_domain>".$qaconf{nis_domain}."</nis_domain>\n";
			print $f	"	<nis_local_only config:type=\"boolean\">false</nis_local_only>\n";
			print $f	"	<nis_options></nis_options>\n";
			print $f	"	<nis_other_domains config:type=\"list\">\n";
			print $f	"	  <nis_other_domain>\n";
			print $f	"		<nis_broadcast config:type=\"boolean\">false</nis_broadcast>\n";
			print $f	"		<nis_domain>".$qaconf{nis_domain}."</nis_domain>\n";
			print $f	"		<nis_servers config:type=\"list\">\n";
			foreach my $server_ip (split(/ /, $qaconf{nis_server_list})) {
				print $f "<nis_server>".$server_ip."</nis_server>\n";
			}
			print $f	"		</nis_servers>\n";
			print $f	"	  </nis_other_domain>\n";
			print $f	"	</nis_other_domains>\n";
			print $f	"	<nis_servers config:type=\"list\"/>\n";
			print $f	"	<start_autofs config:type=\"boolean\">true</start_autofs>\n";
			print $f	"	<start_nis config:type=\"boolean\">true</start_nis>\n";
			print $f	"  </nis>\n";
		}
	
		print $f <<EOF;
  <users config:type="list">
    <user>
      <encrypted config:type="boolean">false</encrypted>
      <fullname>root</fullname>
      <gid>0</gid>
      <home>/root</home>
      <password_settings>
        <expire></expire>
        <flag></flag>
        <inact></inact>
        <max></max>
        <min></min>
        <warn></warn>
      </password_settings>
      <shell>/bin/bash</shell>
      <uid>0</uid>
      <user_password>$rootpass</user_password>
      <username>root</username>
    </user>
    <user>
      <encrypted config:type="boolean">false</encrypted>
      <fullname>$testname</fullname>
      <home>$testhome</home>
      <password_settings>
        <expire></expire>
        <flag></flag>
        <inact></inact>
        <max></max>
        <min></min>
        <warn></warn>
      </password_settings>
      <shell>/bin/bash</shell>
      <user_password>$testpass</user_password>
      <username>$testusr</username>
    </user>
  </users>
EOF
	} else {
		#upgrade specific
		print $f <<EOF;
  <backup>
    <sysconfig config:type="boolean">true</sysconfig>
    <modified config:type="boolean">true</modified>
    <remove_old config:type="boolean">false</remove_old>
  </backup>
  <networking>
    <keep_install_network config:type="boolean">true</keep_install_network>
    <start_immediately config:type="boolean">true</start_immediately>
  </networking>  
EOF
	}

	print $f " </install>\n" if $args->{'to_version'}<10;
	print $f "</profile>\n";
	close $f;
	return $modfile;
}

sub _print_profile_partitions
{
	my ($args, $f) = @_;
	unless ($args->{'upgrade'}) { #partitioning unless upgrade
		## non-VH, custom partitions
		unless ($args->{'virthosttype'} or $args->{'newvm'}) {
			my ($rootid,$rootnum,$swapid,$swapnum,$bootid,$bootnum,$bootsize,$abuildid,$abuildnum,$abuildsize,$swapsize) = &_read_partitions($args);
			my $drives={};
			$drives->{$rootid}->{$rootnum}='/' if defined $rootid;
			$drives->{$swapid}->{$swapnum}='swap' if defined $swapid;
			$drives->{$abuildid}->{$abuildnum}='/abuild' if defined $abuildid;
			$drives->{$bootid}->{$bootnum}='/boot/efi' if defined $bootid and $args->{'to_arch'} eq 'ia64';
			$drives->{$bootid}->{$bootnum}='NULL' if defined $bootid and ($args->{'to_arch'} eq 'ppc64' or $args->{'to_arch'} eq 'ppc');
			my $sizeunit = `fdisk -l |grep "\$drive" |grep Disk |awk {'print \$4'} | cut -f1 -d','`;
			my $disksize = `fdisk -l |grep "\$drive" |grep Disk |awk {'print \$3'} | cut -f1 -d'\n'`;
			chomp($sizeunit);
			chomp($disksize);
			if ( substr($sizeunit, 0, 2) =~ /GB/ ) {
				$disksize = int($disksize*1024);
			}
			$abuildsize = 0 if !$abuildid;
			$bootsize = 0 if !$bootid;
			my $sizepercent = $args->{'repartitiondisk'} ? $args->{'repartitiondisk'}*0.01 : 1;
			$swapsize = int($swapsize)/1024;
			my $rootusesize = int(($disksize - $abuildsize - $bootsize - $swapsize)*$sizepercent);

			my %fs = ( '/'=>$args->{'rootfstype'}, 'swap'=>'swap', '/boot/efi'=>'vfat', '/abuild'=>'ext3', 'NULL' => 'ext3');
			my %format = ( '/'=>'true', 'swap'=>'false', '/boot/efi'=>'true', '/abuild'=>'true','NULL' => 'false' );
			my %size = ( '/'=>$rootusesize, 'swap'=>$swapsize, '/boot/efi'=>$bootsize, '/abuild'=>$abuildsize,'NULL' => 'auto' );
	
			print $f "  <partitioning config:type=\"list\">\n";
			foreach my $drive ( keys %{$drives} ) {
				print $f "   <drive>\n";
				print $f "	<device>$drive</device>\n";
				if ( $args->{'repartitiondisk'} ) {
					print $f "	<initialize config:type=\"boolean\">true</initialize>\n";
				} else {
					print $f "	<use>".(join ',', keys %{$drives->{$drive}} )."</use>\n";
				}
				print $f "	<partitions config:type=\"list\">\n";
				foreach my $num ( keys %{$drives->{$drive}} ) {
					my $mnt=$drives->{$drive}->{$num};
					print $f "	 <partition>\n";
					print $f "	  <filesystem config:type=\"symbol\">".$fs{$mnt}."</filesystem>\n";
					if ( $args->{'repartitiondisk'} ) {
						print $f "	  <create config:type=\"boolean\">true</create>\n";
						print $f "	  <format config:type=\"boolean\">true</format>\n";
					} else {
						print $f "	  <create config:type=\"boolean\">false</create>\n";
						print $f "	  <format config:type=\"boolean\">".$format{$mnt}."</format>\n";
					}
					if ($mnt eq 'NULL') {
						print $f "	  <partition_id config:type=\"integer\">65</partition_id>\n"; #PPC pre-boot partition
					} else {
						print $f "	  <mount>$mnt</mount>\n";
					}
					if ( $args->{'repartitiondisk'} ) {
						print $f "	  <size>".$size{$mnt}."mb</size>\n";
					}
					# when repartitioning and 4 partitions in use, force creating an extended partition
					print $f "	  <partition_nr config:type=\"integer\">".(($args->{'repartitiondisk'} and $num>=4) ? $num+1 : $num)."</partition_nr>\n";
					print $f "	 </partition>\n";
				}
				print $f "	</partitions>\n";
				print $f "   </drive>\n";
			}
			print $f "  </partitioning>\n";
		} else { ## VH or newvm
		print $f <<EOF;
	  <partitioning config:type="list">
		<drive>
		  <use>all</use>
		</drive>
	  </partitioning>
EOF
		}
	}
}

sub _print_profile_bootloader
{
	my ($args,$f) = @_;
	unless ($args->{'upgrade'}) { # do not change bootloader in upgrade
		unless ($args->{'virthosttype'} or $args->{'newvm'}) { ## non-VH or VM
			my $bootpartition = `df /boot |tail -n1 |awk {'print \$6'}`;
			chomp($bootpartition);
			# if $args->{'defaultboot'} is set to 'root', we do not generate anything here, just use bootloader in root with active flag
			if( $args->{'defaultboot'} ne 'root' ) {
				print $f "  <bootloader>\n";
				print $f "    <global>\n";
				if ($args->{'defaultboot'} =~ /^MBR$/i or $args->{'repartitiondisk'}) {
					print $f "	<boot_mbr>true</boot_mbr>\n";
				}
				if ($args->{'to_arch'} eq 'ppc64' or $args->{'to_arch'} eq 'ppc') {
					my $bootpart = `fdisk -l | grep "PPC PReP Boot" | cut -d " " -f1`;
					print $f "	<activate>true</activate>\n";
					print $f "	<boot_chrp_custom>$bootpart</boot_chrp_custom>\n";
					print $f "	<timeout config:type=\"integer\">5</timeout>\n";
					print $f "  </global>\n";
					print $f "  <loader_type>ppc</loader_type>\n";
				} elsif ($args->{'to_arch'} eq 'ia64') {
		###  Do nothing here, see BZ687740
		#			print $f "	<boot_efilabel>SUSE Linux</boot_efilabel>\n";
		#			print $f "	<default>linux</default>\n";
		#			print $f "	<prompt>true</prompt>\n";
		#			print $f "	<relocatable>true</relocatable>\n";
		#			print $f "	<timeout config:type=\"integer\">5</timeout>\n";
					print $f "  </global>\n";
		#			print $f "  <loader_type>elilo</loader_type>\n";
				} else {
					print $f "	<activate>false</activate>\n";
					if ($bootpartition ne "\/") {
						print $f "	<boot_boot>true</boot_boot>\n";
					} else {
						print $f "	<boot_root>true</boot_root>\n";
					}
					print $f "	<boot_extended>false</boot_extended>\n";
					print $f "	<generic_mbr>false</generic_mbr>\n";
					print $f "	<timeout config:type=\"integer\">5</timeout>\n";
					print $f "    </global>\n";
					print $f "    <loader_type>grub</loader_type>\n";
				}
				print $f "  </bootloader>\n";
			}
		}
	}
}

1;

