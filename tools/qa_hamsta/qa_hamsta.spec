#!BuildIgnore: post-build-checks
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
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

BuildRequires:  coreutils
Name:           qa_hamsta
License:        SUSE Proprietary
Group:          System/Management
AutoReqProv:    on
Version:        @@VERSION@@
Release:        0
Summary:        HArdware Maintenance, Setup & Test Automation
Url:            http://qa.suse.de/hamsta
Source:         %{name}-%{version}.tar.bz2
Source1:        perl_module_usage
NoSource:       1       
Source3:	qa_hamsta.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
%if 0%{?sles_version} == 9
Requires:       perl perl-Net-Server perl-URI perl-XML-Dumper perl-IO-Socket-Multicast perl-Proc-Fork perl-XML-Simple qa_tools qa_libperl hamsta-common hamsta-cmdline screen
%else
Requires:       perl perl-Net-Server perl-URI perl-XML-Dumper perl-IO-Socket-Multicast perl-Proc-Fork perl-XML-Simple qa_tools qa_libperl hamsta-common
Recommends:	hamsta-cmdline screen
%endif
Provides:	hamsta
Obsoletes:	hamsta

%description
Allows to build a network of test machines. Machines are monitored by
the master node, and receive planned jobs. The results plus monitoring
info is sent back to the master. Also allows an automated installation
of systems. Hamsta solves the need of distributing different local test
(automation) frameworks (like STAF,LTP etc.), with their integrated
tests, towards extending the coverage of tested hardware configurations
in a distributed and large scale computing environment.

This package should be installed on every machine you want to control
using Hamsta.

Authors:
--------
            Patrick Kirsch <pkirsch@suse.de>
            Vilem Marsik   <vmarsik@suse.cz>
            Leon Wang      <llwang@novell.com>


%package master  
License:        SUSE Proprietary  
Summary:        HArdware Maintenance, Setup & Test Automation  
Group:          System/Management  
%if 0%{?sles_version} == 9
Requires:       perl perl-DBD-mysql perl-IO-Socket-Multicast perl-XML-Dumper perl-XML-Simple perl-Proc-Fork perl-MIME-Lite screen hamsta-cmdline hamsta-jobs qa_libperl perl-URI
%else
Requires:       perl perl-DBD-mysql perl-IO-Socket-Multicast perl-XML-Dumper perl-XML-Simple perl-Proc-Fork perl-MIME-Lite screen hamsta-jobs qa_libperl hamsta-common perl-URI perl-Config-IniFiles perl-Digest-SHA1
Recommends:	hamsta-cmdline
%endif
Provides:	hamsta-master
Obsoletes:	hamsta-master

%description master
Allows to build a network of test machines. Machines are monitored by
the master node, and receive planned jobs. The results plus monitoring
info is sent back to the master. Also allows an automated installation
of systems. Hamsta solves the need of distributing different local test
(automation) frameworks (like STAF,LTP etc.), with their integrated
tests, towards extending the coverage of tested hardware configurations
in a distributed and large scale computing environment.

This is the master package, the controller that rules the entire network.
You will need only one master per test network.

Authors:
--------
            Patrick Kirsch <pkirsch@suse.de>
            Vilem Marsik   <vmarsik@suse.cz>
            Leon Wang      <llwang@novell.com>

%package frontend
License:        SUSE Proprietary  
Summary:        HArdware Maintenance, Setup & Test Automation  
Group:          System/Management  
Requires:       mod_php_any httpd php-pdo php-mysql hamsta-jobs tblib ajaxterm jquery php5-curl php5-snmp ipmitool sshpass libvirt php5-ZendFramework php5-gmp php5-openssl perl-Config-IniFiles frontenduser

%if 0%{?sles_version} > 9
Recommends:	mysql
%endif
Provides:	hamsta-frontend
Obsoletes:	hamsta-frontend

%description frontend
Allows to build a network of test machines. Machines are monitored by
the master node, and receive planned jobs. The results plus monitoring
info is sent back to the master. Also allows an automated installation
of systems. Hamsta solves the need of distributing different local test
(automation) frameworks (like STAF,LTP etc.), with their integrated
tests, towards extending the coverage of tested hardware configurations
in a distributed and large scale computing environment.

This package provides a web frontend for the Hamsta master.
You will need only one frontend per test network.

Authors:
--------
            Patrick Kirsch <pkirsch@suse.de>
            Vilem Marsik   <vmarsik@suse.cz>
            Leon Wang      <llwang@novell.com>

%package cmdline
License:        SUSE Proprietary  
Summary:        HArdware Maintenance, Setup & Test Automation  
Group:          System/Management  
Requires:       perl perl-Term-ReadPassword perl-TermReadKey perl-TermReadLine-Gnu hamsta-common
Provides:	hamsta-cmdline
Obsoletes:	hamsta-cmdline

%description cmdline
Allows to build a network of test machines. Machines are monitored by
the master node, and receive planned jobs. The results plus monitoring
info is sent back to the master. Also allows an automated installation
of systems. Hamsta solves the need of distributing different local test
(automation) frameworks (like STAF,LTP etc.), with their integrated
tests, towards extending the coverage of tested hardware configurations
in a distributed and large scale computing environment.

This package is for command line access to Hamsta.

Authors:
--------
            Patrick Kirsch <pkirsch@suse.de>

%package multicast-forward
License:	SUSE Proprietary
Summary:	Hamsta UDP multicast forwarder
Group:		System/Management
Requires:	perl perl-IO-Socket-Multicast screen hamsta-common
Provides:	hamsta-multicast-forward
Obsoletes:	hamsta-multicast-forward

%description multicast-forward
This is a support package for Hamsta. It allows you to forward UDP
multicast messages from subnets behind a router that does not forward them.

Do not run more than one instance on the subnet.

Authors:
--------
	Vilem Marsik	<vmarsik@suse.cz>

%package jobs
License:	SUSE Proprietary
Summary:        HArdware Maintenance, Setup & Test Automation  
Group:          System/Management
Provides:	hamsta-jobs
Obsoletes:	hamsta-jobs

%description jobs
This package contains Hamsta job XML files.
It is shared between Hamsta master and Hamsta frontend.

TODO: this is not correct. Frontend uses the XML files to start a job,
but then it sends a LOCAL path to the master. This won't work if master
and frontend run on different machines. Need to fix that.

%package common
License:	SUSE Proprietary
Summary:        HArdware Maintenance, Setup & Test Automation  
Group:          System/Management
Requires:	qa-config
Provides:	hamsta-common
Obsoletes:	hamsta-common

%description common
This package contains Hamsta configuration files that are
shared between Hamsta master, multicast-forwarder and slave.


%define destdir /usr/share/hamsta
%define initfile %{_sysconfdir}/init.d/hamsta
%define webdir /srv/www/htdocs/hamsta
%define xml_link /srv/www/htdocs/xml_files
%define confdir /etc/qa

%prep
%setup -n %{name}

%build

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:3} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
mkdir -p $RPM_BUILD_ROOT/%{_sysconfdir}/init.d
cp -a hamsta hamsta-master hamsta-multicast-forward $RPM_BUILD_ROOT/%{_sysconfdir}/init.d/
mkdir -p $RPM_BUILD_ROOT/usr/sbin
ln -s %{_sysconfdir}/init.d/hamsta $RPM_BUILD_ROOT/%{_sbindir}/rchamsta
ln -s %{_sysconfdir}/init.d/hamsta-master $RPM_BUILD_ROOT/%{_sbindir}/rchamsta-master
ln -s %{_sysconfdir}/init.d/hamsta-multicast-forward $RPM_BUILD_ROOT/%{_sbindir}/rchamsta-multicast-forward
mkdir -p $RPM_BUILD_ROOT/usr/bin
cp -a Slave/hamsta.sh $RPM_BUILD_ROOT/usr/bin/
mkdir -p $RPM_BUILD_ROOT/usr/sbin
cp -a starthamstamaster $RPM_BUILD_ROOT/usr/sbin/
mkdir -p $RPM_BUILD_ROOT%{webdir}
cp -a -r --target-directory=$RPM_BUILD_ROOT%{webdir} frontend/*
ln -s %{destdir}/xml_files $RPM_BUILD_ROOT%{xml_link}
install -m 755 -d $RPM_BUILD_ROOT%{destdir}
cp -a -r --target-directory=$RPM_BUILD_ROOT%{destdir} Slave command_frontend.pl feed_hamsta.pl master testscript xml_files db hamsta-multicast-forward.pl 
#find $RPM_BUILD_ROOT%{destdir}/xml_files -name '*.xml' -exec chown wwwrun:www {} \;
#find $RPM_BUILD_ROOT%{destdir} -type d -exec chown wwwrun:www {} \; -exec chmod 1777 {} \;
#install -m 1777 -d %{webdir}/profiles
mkdir -p $RPM_BUILD_ROOT%{webdir}/profiles
install -m 755 -d $RPM_BUILD_ROOT%{confdir}
cp --target-directory=$RPM_BUILD_ROOT%{confdir} 00-hamsta-common-default 00-hamsta-default 00-hamsta-master-default 00-hamsta-multicast-forward-default
rm -rf `find $RPM_BUILD_ROOT -name .svn`
mkdir -p $RPM_BUILD_ROOT/var/log/hamsta/master
mkdir -p $RPM_BUILD_ROOT/var/lib/hamsta


%clean
rm -rf $RPM_BUILD_ROOT/*

%post
/sbin/insserv -f %{initfile}
echo %{version} > /usr/share/hamsta/.version
echo %{version} > /usr/share/hamsta/Slave/.version

%post master
echo "=================== I M P O R T A N T ======================="
echo "Please make sure that you have a database prepared."
echo "To create a new DB, install and confugure mysql and then"
echo "run 'cd %destdir/db; ./create_db.sh'."
echo "To update the existing database to the newest version,"
echo "run 'cd %destdir/db; ./update_db.sh'."
echo 'IMPORTANT: you need to add "wwwrun  ALL = (root) NOPASSWD: /usr/bin/ssh" to /etc/sudoers for AutoPXE to work'
echo "=================== I M P O R T A N T ======================="

%post frontend
sed -i "s/Options None/Options FollowSymLinks/" /etc/apache2/default-server.conf
/etc/init.d/apache2 restart
#install -m 1777 -d %{webdir}/profiles

#mysql -u root < /usr/share/hamsta/hamsta.sql
# after installation patch perl modul IPC::Open3
# due to return value on failed command
#cat <<EOF | perl
#my @paths_to_open3 = grep {-e $_."/IPC/Open3.pm"} @INC;
#if( @paths_to_open3 > 0 ) {
#    my $open3_path=$paths_to_open3[0];
#    `perl -i -pe 's/exec \@cmd # XXX: /system \@cmd ;# XXX: /ig; s/or croak "\$Me: exec of \@cmd failed";/ if (\$\? == -1) {print "OPEN3_FAILURE: \$\?\n";} else { printf "OPEN3_FAILURE: \%d\n", \$\? >> 8; }/ig; ' $open3_path`;
#    my @check = `cat $open3_path | grep OPEN3_FAILURE`;
#    if (@check) {
#	print "Check OK: $check[0] \n";
#    } else {
#	print "Check failed for patching $open3_path \n It is ";
#	print "not 'that' important, due to missing return values of executed code \n";
#    }
#}
#else {
#    print STDERR "WARNING: File 'IPC/Open3.pm' not found in \@INC. Hope it won't do any harm.\n";
#}
#EOF
#/sbin/insserv %{initfile}
#%{initfile} start || true

%preun
%stop_on_removal
#if [ "$1" = "0" ]; then
#    %{initfile} stop || true
#    /sbin/insserv -r %{initfile}
#fi

%preun master
%stop_on_removal

%preun multicast-forward
%stop_on_removal

%postun
%insserv_cleanup

%postun master
%insserv_cleanup

%postun multicast-forward
%insserv_cleanup


%files
%defattr(-, root, root)
/usr/share/man/man8/%name.8.gz
%{destdir}/testscript
%{destdir}/Slave
%dir /usr/share/hamsta/
/usr/bin/hamsta.sh
%{_sysconfdir}/init.d/hamsta
%{_sbindir}/rchamsta
%{confdir}/00-hamsta-default
%dir /var/lib/hamsta
%doc COPYING

%files master  
%defattr(-, root, root)
%{_sysconfdir}/init.d/hamsta-master  
/usr/sbin/starthamstamaster  
%{destdir}/master  
%{destdir}/db
%attr(755,root,root) %{destdir}/db/create_db.sh
%attr(755,root,root) %{destdir}/db/update_db.sh
%attr(755,root,root) %{destdir}/master/hamsta_cycle.pl
%dir %{destdir}
%{_sbindir}/rchamsta-master
%{confdir}/00-hamsta-master-default
%dir /var/log/hamsta/master

%files cmdline
%defattr(-, root, root)
%{destdir}/command_frontend.pl
%{destdir}/feed_hamsta.pl
%dir %{destdir}

%files frontend
%defattr(-, root, root)
%{webdir}
%attr(-,wwwrun,www) %{webdir}/profiles
#%config(noreplace) %{webdir}/config.php
%config(noreplace) %{webdir}/config.ini
%dir %{destdir}

%files multicast-forward
%defattr(-, root, root)
%{_sysconfdir}/init.d/hamsta-multicast-forward
%{destdir}/hamsta-multicast-forward.pl
%dir %{destdir}
%{_sbindir}/rchamsta-multicast-forward
%{confdir}/00-hamsta-multicast-forward-default

%files jobs
%defattr(-, root, root)
/srv/www/htdocs/xml_files 
%defattr(755,wwwrun,www)
%dir %{destdir}/xml_files  
%dir %{destdir}/xml_files/templates
%dir %{destdir}/xml_files/nonactive
%dir %{destdir}/xml_files/multimachine
%dir %{destdir}/xml_files/relax
%attr(644,wwwrun,www) %{destdir}/xml_files/*.xml
%attr(644,wwwrun,www) %{destdir}/xml_files/templates/*.xml
%attr(644,wwwrun,www) %{destdir}/xml_files/multimachine/*.xml
%attr(644,wwwrun,www) %{destdir}/xml_files/nonactive/*.xml
%attr(644,wwwrun,www) %{destdir}/xml_files/relax/*

%files common
%defattr(-, root, root)
%dir %{confdir}
%{confdir}/00-hamsta-common-default

%changelog
* Fri Jan 18 2013 - llipavsky@suse.com
- New 2.5 release from QA Automation team
- Authentication and Authorization in Hamsta
- ctcs2 improvements, speedup, and new tcf commands
- New SUT can be added to Hamsta from hamsta web interface
- Timezone support in reinstall
- Reinstall can now be done using kexec
- Centralized configuration of SUTs
- Sessions support in Hamsta
- AutoPXE now supports ia64 architecture
- Hamsta is no longer configured using config.php, config.ini is used instead
- ...and many small improvements and bug fixes
* Tue Dec 11 2012 pkacer@suse.com
- Added dependency on perl-Config-IniFiles and fixed command line to read ini file.
- Removed config.php file.
* Mon Nov  5 2012 pkacer@suse.com
- Changed the configuration to be read only from config.ini file.
* Fri Aug 31 2012 pkacer@suse.com
- Changed dependency from qa_lib_openid to php5-ZendFramework.
* Fri Aug 17 2012 pkacer@suse.com
- OpenID authentication only on request by user (see header.php).
- OpenID is on by default in configuration.
- Added login/logout links and user name at the top right corner.
- Added page with user configuration (configuration is available, yet).
* Fri Aug 10 2012 - llipavsky@suse.cz
- Web user-friendly editor for jobs
- HA Server yast2 UI Automation
- Build mapping in QADB (buildXXX -> beta Y)
- Improved regression analysis
- Support for benchmark parsers in benchmark testsuite (author of testsuite will also provide a script to parse the results)
- Power switch support in Hamsta (thanks mpluskal!)
- Only results created in the job are submitted to QADB
- QADB improvements
* Wed May 2 2012 - llipavsky@suse.cz
- New 2.3 release from QA Automation team, includes: 
- out-of date and developement SUTs are marked in web frontend and can be updated from the frontend 
- HA Server yast2-cluster UI Automation 
- Improved CLI interface to Hamsta 
- It is possible to get/choose all patterns from all products during SUT intallation (until now, only SLES/D & SDK patterns were shown) 
- Parametrized jobs 
- Better web editors of jobs. Now with multimachine job support 
- Hamsta client one-click installer 
- QADB improvements 
- No more Novell icon in Hamsta ;-)
* Mon Nov 14 2011 - llipavsky@suse.cz
- New 2.2 release from QA Automation team, includes:
- Automated stage testing
- Repartitioning support during reinstall
- Possible to leave some space unparditioned during reinstall
- Added "default additional RPMs to hamsta frontend"
- Optimized hamsta mutlticast format
- Mutliple build-validation jobs
- Code cleanup
- Bugfixes
* Sun Sep 04 2011 - llipavsky@suse.cz
- New, updated release from the automation team. Includes:
- Improved virtual machine handling/QA cloud
- Rename of QA packages
- Upgrade support
- More teststsuites
- Many bug fixes
* Tue Aug 16 2011 - llipavsky@suse.cz
- Package rename: hamsta -> qa_hamsta
* Fri Jun 17 2011 dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- Reinstall pattern list customization
- Additional add-on repository capability
- Chainloader selective root partition install
- Improved virtual machine integration/QA cloud (technical preview)
- Plus, logs of bug fixes
* Wed Apr 13 2011 dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- Improved job output and filtering
- New page showing the entire action history
- Hamsta logo added to main page
- Revision/feature history added to main page
- Better filtering of repo index lists
- New dispaly field options shown (RAM, procs, disks, etc.)
- Graphical desktop selection possible on reinstall
- Improved/unified WebUI error reporting
- Plus, lots of bug fixes
* Fri Jan 28 2011 llipavsky@suse.cz
- migrate hamsta (excluding frontend) to new QA config schema
* Fri Jan 21 2011 dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- New machine action history logs important events
- New job logging format (color-coded, severity-separated)
- Serial console device/speed and default install options added
- Xen host install improvements
- Lots of bug fixes
* Thu Nov 18 2010 dcollingridge@novell.com
- Lots of recent bug fixes from the automation team
- Added x86-xen and x86_64-xen install support
- Added the ability to store serial console information
- Improved logging
* Thu Nov 18 2010 dcollingridge@novell.com
- Lots of recent bug fixes from the automation team.
* Thu Aug 21 2010 vmarsik@suse.cz
- Milestone release notes:
 - Added autotest tests to the "Send job" page of Hamsta 
 - Automatical installation of latest online updates during reinstall
 - Allowed running jobs across multiple machines 
 - Enhancements to autopxe page
 - New quick unlock/unreserve button 
 - Hamsta now shows "real" server architecture and "installed" arch for x86
* Fri Aug 13 2010 llipavsky@suse.cz
- New, updated release from the automation team. Includes:
  - AutoPXE support to restore broken installations
  - Various bugfixes
* Wed Aug 04 2010 llipavsky@suse.cz
- Named all foreign keys in db, so we can easily modify them
  in future patches
* Mon Aug 02 2010 llipavsky@suse.cz
- Add update support to the DB
* Fri Jun 18 2010 dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- Automated build validation
- Improved job status
- DB cleanup and enhancements
- More autoyast customizations for auto-installs
- Improved form validation and handling
- Email notifications for completed jobs
- SUT VNC and terminal access
- PPC installation support
- Context help
- Improved logging and monitoring
- Various bug fixes
* Fri Apr 23 2010 dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- Steps towards getting an automatic build validation
- Added dropdown selectors for installation repos on install
- Now able to run any qa_ package test from frontend
- Multiple jobs can be queued
- Custom job with arbitrary command creation from frontend
- Auto-repopulation of some fields on form submit error
- Improved framework for future front-end enhancements
- RPM updates can now be defined in the job XML
- Email notifications enabled
- Hamsta client auto-starts on reboot
- Lots of bug fixes
* Fri Apr 09 2010 vmarsik@novell.com
- made a few changes to make rpmlint more happy
- created the package jobs
* Thu Mar 25 2010 dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- SLED no longer depends on SDK for install
- Updated dependencies
- Added options to reinstall
- Added custom autoyast upload
- Installation repo auto-complete
- Automatically update qa_tools before system reinstall
- UI enhancements and updates
- Added the ability to specify rpms to install for a job
- Better diagnostics
- Separated install job from standard jobs
- Better tracking of reinstall job
- Able to delete machines
- Lots of bug fixes
* Wed Mar 03 2010 vmarsik@novell.com
- added a new package multicast-forward
* Fri Feb 19 2010 vmarsik@novell.com
- changed /usr/share/hamsta to /usr/share/hamsta
- changed /srv/www/htdocs/hamsta/frontend to /srv/www/htdocs/hamsta
* Thu Feb 18 2010 vmarsik@novell.com
- split packages into 4 pieces
- removed qa_tools from dependencies
- modified PHP dependencies not do depend on PHP5
- marked config files as %%config
- removed obsolete old installation files
* Tue Feb 16 2010 dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- added first listed MAC address to system unique ID
- added installation repo support in hamsta frontend
- auto-generation of reinstall job
- added sdk repo support in hamsta frontend
- added smoke test job
- added test_all job
- added status for /etc/init.d/hamsta-master
- frontend page added showing current version
- set up list of test packages to install
- added automatic qadb submit for smoke and test_all jobs
- bug fixes
* Fri Jan 15 2010 llwang@novell.com
- added database prepare, bugfixes, auto-install support
* Thu Nov 26 2009 vmarsik@suse.cz
- added bugfixes
- added master control scripts
* Wed Aug 06 2008 vmarsik@suse.cz
- no more automatic starting (crashed autoinstall)
* Mon Apr 14 2008 pkirsch@suse.de
- added GPLv2 COPYRIGHT file
* Thu Apr 10 2008 pkirsch@suse.de
- changed Group to System/Management
* Thu Apr 03 2008 pkirsch@suse.de
- removed requirement perl-Mail-Mailer, added
  perl-MailTools
* Fri Mar 14 2008 pkirsch@suse.de
- fixed install requires
* Tue Feb 26 2008 pkirsch@suse.de
- removed setupgrubfornfsinstall, it's suse intern
- minor changes due to build system requirements
* Mon Jan 21 2008 vmarsik@suse.cz
- added a clickable XML list to the frontend
- added screen as a requirement
* Wed Nov 28 2007 vmarsik@suse.cz
- commented the code that stops Hamsta when uninstalling
- this caused to fail the reinstall process
* Thu Nov 15 2007 vmarsik@suse.cz
- added a local IP for slaves to the configuration
* Thu Nov 15 2007 vmarsik@suse.cz
- added initscripts
* Tue Nov 13 2007 vmarsik@suse.cz
- created an RPM

