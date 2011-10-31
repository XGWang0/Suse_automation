#!/usr/bin/perl -w
# ****************************************************************************
# Copyright © 2011 Unpublished Work of SUSE. All Rights Reserved.
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


use File::Basename;

# formats distro info
sub stats
{
	my ($type,$version,$subversion,$arch)=@_;
	my $out="  type\t\t$type\n  version\t$version\n  subversion\t$subversion\n";
	$out .= "  arch\t\t$arch\n" if $arch;
	return $out;
}

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
	return ($type, $ver, $sub, $arch);
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
sub has_libsata
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
	return ($dev,$num);
}

# reads root and swap partition info
sub read_partitions
{
	my ($new_type,$new_version,$new_subversion,$new_libsata,$arch,$root_pt)=@_;
	my $swappart=`cat /proc/swaps | tail -n 1 | cut -f1 -d' '`;
	my $swapsize = `cat /proc/swaps | tail -n 1 |awk {'print \$3'}`;
	my $rootpart=`df /|tail -n1 | cut -f1 -d' '`;
	$rootpart=$root_pt if($root_pt);
	my $abuildpart=`df | grep "abuild" |tail -n1 | cut -f1 -d' '`;
	my $abuildsize = `df -h |grep "abuild" |tail -n1 |awk {'print \$2'} | cut -f1 -d'M'`;
	my $bootpart;
	my $bootsize = `df -h |grep "/boot/efi" |tail -n1 |awk {'print \$2'} | cut -f1 -d'M'`;
	my $abuildid;
	my $abuildnum;
	chomp($swapsize);
	chomp($abuildsize);
	chomp($bootsize);
	if ($arch eq 'ppc64' or $arch eq 'ppc') {
		$bootpart="/dev/" . `ls -l \$(grep ^boot /etc/lilo.conf | cut -d \" \" -f3) \| awk -F/ {'print \$NF'}`;
	} else {
		$bootpart=`df /boot/efi 2>/dev/null | tail -n1 | cut -f1 -d' '`;
	}
	my ($rootid,$rootnum) = &disk_stats($rootpart,$new_libsata);
	if ($abuildpart) {
		($abuildid,$abuildnum) = &disk_stats($abuildpart,$new_libsata);
	}
	my ($swapid,$swapnum) = &disk_stats($swappart,$new_libsata);
	my ($bootid,$bootnum) = &disk_stats($bootpart,$new_libsata);
	return ($rootid,$rootnum,$swapid,$swapnum,$bootid,$bootnum,$bootsize,$abuildid,$abuildnum,$abuildsize,$swapsize);
	# TODO: check for undefined results
}

sub get_patterns ### Used by newvm only
{
	my ($to_type,$to_version,$to_subversion) = @_;
	my $ret = "base";
	$ret .= ",$additionalpatterns" if (defined $additionalpatterns);
	if($to_type eq 'sled') {
		$ret =~ s/(^|,)base($|,)/$1desktop-base$2/g;
		$ret =~ s/(^|,)kde($|,)/$1desktop-kde$2/g;
		$ret =~ s/(^|,)gnome($|,)/$1desktop-gnome$2/g;
	}
	my %hash;
	$hash{$_}++ foreach (split(',',$ret));
	return join(',', (sort keys %hash));
}

sub get_packages
{
	my ($to_type,$to_version,$to_subversion,$to_arch,$additionalrpms,$patterns) = @_;
	my $ret='qa_tools,qa_hamsta,autoyast2,vim,mc,iputils,less,screen,lsof,pciutils,tcpdump,telnet,zip,yast2-runlevel,SuSEfirewall2,curl,wget,perl,openssh';
	if( $to_type eq 'opensuse' or $to_type eq 'sled') {
		$ret .= ',nfs-client';	
	} else {	
		$ret .= ',nfs-utils';	
	}
	if(defined ($virtHostType) and $virtHostType ne "") {
		$ret .= ",libvirt,libvirt-python,xen-libs,vm-install,virt-manager,virt-viewer";
		$ret .= ($virtHostType eq 'xen') ? ",xen,xen-tools,kernel-xen" : ",kvm"; 
	}	
	#$ret .= ",pam-modules-64bit,resmgr-64bit" if $to_arch eq 'ppc64'; #BZ706671
	$ret .= ",qa_setvncserver" if ($patterns =~ /gnome/ or $patterns =~ /kde/);
	$ret .= ",atk-devel,at-spi,gconf2" if $setupfordesktoptest;
	$ret .= ",$additionalrpms" if (defined $additionalrpms);
	return $ret;
}

sub get_profile
{
	my ($to_type,$to_version,$to_subversion) = @_;
	return "$profiledir/sles9.xml" if $to_version<10;
	return "$profiledir/default.xml";
}

sub get_buildservice_repo
{
# TODO
# SLES_9, SLE_10_SP1_Head, SLE_10_SP2_Head, SLE_Factory, openSUSE_11.0, openSUSE_Factory
	my ($type,$version,$subversion) = @_;
	if( $type eq 'opensuse' ) {
		return 'openSUSE_11.0' if $version==11 and $subversion==0;
		return 'openSUSE_11.1' if $version==11 and $subversion==1;
		return 'openSUSE_11.2' if $version==11 and $subversion==2;
		return 'openSUSE_11.3' if $version==11 and $subversion==3;
		return 'openSUSE_11.4' if $version==11 and $subversion==4;
		return 'openSUSE_Factory' if $version>=11;
	} else {
		return 'SLES_9' if $version==9;
		return 'SLE_10_SP1_Head' if $version==10 and $subversion<=1;
		return 'SLE_10_SP2_Head' if $version==10 and $subversion==2;
		return 'SLE_10_SP3' if $version==10 and $subversion==3;
		return 'SLE_10_SP4' if $version==10;
		return 'SUSE_SLE-11_GA' if $version==11 and $subversion==0;
		return 'SUSE_SLE-11-SP1_GA' if $version==11 and $subversion==1;
		return 'SUSE_SLE-11-SP2_GA' if $version==11 and $subversion==2;
		return 'SLE_Factory' if $version>11;
	}
	return undef;
}

# modifies the profile and stores the result on a NFS share on bender
# returns URL to the result
sub install_profile
{
	my ($profile,$modfile, $suffix) = @_;  # suffix is optional
	my $xml_out = "$mountpoint/autoinst/autoinst_$hostname.xml";
	$xml_out = "$mountpoint/autoinst/autoinst_$suffix.xml" if $suffix;
	&command( "$tooldir/modify_xml.pl -m '$modfile' '$profile' '$xml_out'" );
	return $qaconf{install_profile_url_base}."/autoinst_$hostname.xml";
}

sub install_profile_newvm
{
	my ($profile,$modfile) = @_;
	my $hostname = `hostname`;
	chomp $hostname;
	my $xml_out = "$mountpoint/autoinst/autoinst_${hostname}_vm_$$.xml";
	&command( "$tooldir/modify_xml.pl -m '$modfile' '$profile' '$xml_out'" );

	# FIXME: temporal hack - will be fixed when merged with reinstall.pl code
	my $cmd="sed -i '" . 's/<dhcp_hostname config:type="boolean">false<\/dhcp_hostname>/<dhcp_hostname config:type="boolean">true<\/dhcp_hostname>/' . "' '$xml_out'";
	&command($cmd);
	return $qaconf{install_profile_url_base}."/autoinst_${hostname}_vm_$$.xml";
}

# creates a modification file for AutoYaST
sub make_modfile
{
	my ($source,$url_addon,$new_type,$new_version,$new_subversion,$new_libsata,$patterns,$packages,$defaultboot,$install_update,$virtHostType,$newvm)=@_;
# put it all into one function,
# would return (undef,undef) if the partition does not exist
	my ($rootid,$rootnum,$swapid,$swapnum,$bootid,$bootnum,$bootsize,$abuildid,$abuildnum,$abuildsize,$swapsize) = &read_partitions($new_type,$new_version,$new_subversion,$new_libsata,$arch,$root_pt)  unless (defined($virtHostType) and $virtHostType ne "") or ($newvm);
	my $pdversion = &get_buildservice_repo($new_type, $new_version, $new_subversion);
	my $bsurl = "";
	$bsurl = $pdversion if $newvm;
	my %usls=();
	my $QA_repo=$qaconf{install_qa_repository};
	my $testusr = $qaconf{install_testuser_login};
	my $testpass = $qaconf{install_testuser_password};
	my $testname = $qaconf{install_testuser_fullname};
	my $testhome = $qaconf{install_testuser_home};
	my $rootpass = $qaconf{install_root_password};

	$packages .= ','.$qaconf{install_additional_rpms}  if $qaconf{install_additional_rpms};

	if ($bsurl) { ## for newvm use only
		$urls{'QArepo'}="$QA_repo/$bsurl";
		$urls{'SDK'}=$url_addon if defined $url_addon;
	}

	my @urls=($QA_repo."/".$pdversion);
	if ($url_addon) { 
		foreach my $aurl(split(/,/, $url_addon)) {
			push @urls, $aurl;
		}
	}

	my $modfile="/tmp/modfile_$$.xml";
	open my $f, ">$modfile" or die "Cannot create patch file '$modfile' : $!";
	print $f '<profile xmlns="http://www.suse.com/1.0/yast2ns" xmlns:config="http://www.suse.com/1.0/configns">'."\n";
	print $f " <install>\n" if $new_version<10;
	print $f <<EOF;
	<add-on>
		<add_on_products config:type="list">
EOF
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
	if ( $opensuse_update ) {
		my $opensuse_update_url = "http://download.opensuse.org/update/$new_version\.$new_subversion\/";
		my $opensuse_update_name = "$new_version\.$new_subversion update";
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
	unless ($opts{'U'}) { #partitioning unless upgrade
		## non-VH, custom partitions
		unless ($virtHostType or $newvm) {
			my %drives=();
			$drives->{$rootid}->{$rootnum}='/' if defined $rootid;
			$drives->{$swapid}->{$swapnum}='swap' if defined $swapid;
			$drives->{$abuildid}->{$abuildnum}='/abuild' if defined $abuildid;
			$drives->{$bootid}->{$bootnum}='/boot/efi' if defined $bootid and $arch eq 'ia64';
			$drives->{$bootid}->{$bootnum}='NULL' if defined $bootid and ($arch eq 'ppc64' or $arch eq 'ppc');
			$disksize = `fdisk -l |grep "\$drive" |grep MB |awk {'print \$3'} | cut -f1 -d' '`;
			chmod($disksize);
			$abuildsize = 0 if !$abuildid;
			$bootsize = 0 if !$bootid;
			$sizepercent = $repartitiondisk ? $repartitiondisk*0.01 : 1;
			$swapsize = int($swapsize/1024);
			$rootusesize = int(($disksize - $abuildsize - $bootsize - $swapsize)*$sizepercent);

			my %fs = ( '/'=>$rootfstype, 'swap'=>'swap', '/boot/efi'=>'vfat', '/abuild'=>'ext3', 'NULL' => 'ext3');
			my %format = ( '/'=>'true', 'swap'=>'false', '/boot/efi'=>'true', '/abuild'=>'true','NULL' => 'false' );
			my %size = ( '/'=>$rootusesize, 'swap'=>$swapsize, '/boot/efi'=>$bootsize, '/abuild'=>$abuildsize,'NULL' => 'auto' );
	
			print $f "  <partitioning config:type=\"list\">\n";
			foreach my $drive ( keys %{$drives} ) {
				print $f "   <drive>\n";
				print $f "	<device>$drive</device>\n";
				if ( $repartitiondisk ) {
					print $f "	<initialize config:type=\"boolean\">true</initialize>\n";
				} else {
					print $f "	<use>".(join ',', keys %{$drives->{$drive}} )."</use>\n";
				}
				print $f "	<partitions config:type=\"list\">\n";
				foreach my $num ( keys %{$drives->{$drive}} ) {
					my $mnt=$drives->{$drive}->{$num};
					print $f "	 <partition>\n";
					print $f "	  <filesystem config:type=\"symbol\">".$fs{$mnt}."</filesystem>\n";
					if ( $repartitiondisk ) {
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
					if ( $repartitiondisk ) {
						print $f "	  <size>".$size{$mnt}."mb</size>\n";
					}
					print $f "	  <partition_nr config:type=\"integer\">$num</partition_nr>\n";
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

	my $pat='pattern';
	my $pats='patterns';
	my $updatetag='suse_register';
	$updatetag = "customer_center" if $new_version<11;
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
		print $f "	  <do_online_update config:type=\"boolean\">true</do_online_update>" if $install_update;
		print $f "  </software>\n";
	}

	if ($opts{'U'}) { # Upgrade with autoyast
		print $f "  <upgrade>\n";
		print $f "	  <only_installed_packages config:type=\"boolean\">false</only_installed_packages>\n";
		print $f "	  <stop_on_solver_conflict config:type=\"boolean\">true</stop_on_solver_conflict>\n";
		print $f "  </upgrade>\n";
	}
	
	unless ($opts{'U'}) { # do not change bootloader in upgrade
		unless ($virtHostType) { ## non-VH
			my $bootpartition = `df /boot |tail -n1 |awk {'print \$6'}`;
			chomp($bootpartition);
			# if $defaultboot is set to 'root', we do not generate anything here, just use bootloader in root with active flag
			if( $defaultboot ne 'root' ) {
				print $f "  <bootloader>\n";
				print $f "    <global>\n";
				if ($defaultboot =~ /^MBR$/i) {
					print $f "	<boot_mbr>true</boot_mbr>\n";
				} elsif ($repartitiondisk and $bootpartition eq "\/") {
					print $f "	<boot_mbr>true</boot_mbr>\n";
				}
				if ($arch eq 'ppc64' or $arch eq 'ppc') {
					my $bootpart = `fdisk -l | grep "PPC PReP Boot" | cut -d " " -f1`;
					print $f "	<activate>true</activate>\n";
					print $f "	<boot_chrp_custom>$bootpart</boot_chrp_custom>\n";
					print $f "	<timeout config:type=\"integer\">5</timeout>\n";
					print $f "  </global>\n";
					print $f "  <loader_type>ppc</loader_type>\n";
				} elsif ($arch eq 'ia64') {
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
					print $f "	<boot_root>true</boot_root>\n";
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

	# Start registration info
	if ( $install_update and $new_type ne "opensuse" ) {
		print $f "	<$updatetag>
	  <do_registration config:type=\"boolean\">true</do_registration>
	  <register_regularly config:type=\"boolean\">false</register_regularly>\n";
	}

	# Register NCC without SMT
	if ( $install_update and $ncc_email and $ncc_code and $new_type ne "opensuse" ) {
		print $f "	  <registration_data>
		<email>$ncc_email</email>";
		foreach my $rcode (split(/,/, $ncc_code)) {
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
	print $f "	<reg_server>$smt_server</reg_server>\n" if ( $install_update and $smt_server and $new_type ne "opensuse" );

	# Finish registration info
	if ( $install_update and $new_type ne "opensuse" ) {
		print $f "	  <submit_hwdata config:type=\"boolean\">true</submit_hwdata>
	  <submit_optional config:type=\"boolean\">true</submit_optional>
	</$updatetag>";
	}

	# Scripts section, we can add every command that we would like to run on the 1st boot here.
	# Especially useful for some work arounds of autoyast bug
	print $f "	<scripts>
	  <init-scripts config:type=\"list\">
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

	if ( $install_update and $new_type ne "opensuse" ) { # This is work around for consistent reboot after upgrade
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
	
	unless ($opts{U}) {
		if ( $setupfordesktoptest ) { # Autoun asistive technologies and xhost + on gdm login
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
	
		print $f "      <script>
		  <filename>zzz_write_passwords</filename>
		  <interpreter>shell</interpreter>
		  <source>
		    mkdir -p /usr/share/qa/data/passwords ;
		    echo '$rootpass' > /usr/share/qa/data/passwords/root ;
		    echo '$testpass' > /usr/share/qa/data/passwords/$testusr
		  </source> 
		 </script>";
	
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
	
		if ( $virtHostType ) { ## VH
			print $f "	<script>
				<filename>yyz_set_virthost</filename>
				<interpreter>shell</interpreter>
				<source>
				  echo $virtHostType > /var/lib/hamsta/VH;
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
			if ( $virtHostType eq 'kvm' ) {
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
	if ($opts{U}) {
		my ($bootpart, $bootparttype, $bootpath, $boothpathrel, $postcmd);

		if($arch =~ /^ppc(64)?$/) {
			$bootpath = '/etc/lilo.conf';
			$postcmd = '/sbin/lilo';
		} elsif ($arch eq 'ia64') {
			$bootpath = '/boot/efi/efi/SuSE/elilo.conf';
			$postcmd = ''; #nothing needed
		} elsif ($arch =~ /^(i[356]86)|(x86_64)$/) {
			$bootpath = '/boot/grub/menu.lst';
			$postcmd = ''; # nothing needed
		} else {
			# We should never reach this line!
			die "ERROR: Architecture $arch is not supported for upgrade!";
		}

		# Get boot partition, its type and rel path
		my $p=$bootpath;
		$bootpathrel='';
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

	unless ($opts{U}) {	
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
		print $f "    <dns>
				<dhcp_hostname config:type=\"boolean\">false</dhcp_hostname>
				<resolv_conf_policy>auto</resolv_conf_policy>\n";

		if (!$newvm) { ## no need for VM
			print $f "	  <hostname>$hostname</hostname>\n";
			print $f "	  <domain>$domainname</domain>\n";
		}
		print $f "	</dns>\n";
		print $f "	<interfaces config:type=\"list\">\n";
		if ($virtHostType || $setup_bridge) { ## VH
			for (my $i=0;$i<`ifconfig | grep eth | wc -l`;$i++) {
				print $f "	  <interface>
				<bootproto>dhcp4</bootproto>
				<bridge>yes</bridge>
				<bridge_forwarddelay>0</bridge_forwarddelay>
				<bridge_ports>eth$i</bridge_ports>
				<bridge_stp>off</bridge_stp>
				<device>br$i</device>
				<startmode>auto</startmode>
			  </interface>\n";
			}
		} else { ## non-VH & VM
			for (my $i=0;$i<`ifconfig | grep eth | wc -l`;$i++) {
				print $f "	  <interface>
				<bootproto>dhcp</bootproto>
				<device>eth$i</device>
				<startmode>onboot</startmode>
			  </interface>\n" if `ifconfig eth$i | grep inet`;
			}
		} 
		print $f "	</interfaces>\n";
		print $f "  </networking>\n";
		my $location = &get_location or die "Unknown location (Prague|Nuernberg|Beijing|Provo)";
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
	
	print $f " </install>\n" if $new_version<10;
	print $f "</profile>\n";
	close $f;
	return $modfile;
}

1;

