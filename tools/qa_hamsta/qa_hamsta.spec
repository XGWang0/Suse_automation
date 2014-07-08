#!BuildIgnore: post-build-checks
# ****************************************************************************
# Copyright (c) 2013, 2014 Unpublished Work of SUSE. All Rights Reserved.
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

%define with_systemd 0

# http://en.opensuse.org/openSUSE:Build_Service_cross_distribution_howto
%if 0%{?suse_version} >= 1310
%define with_systemd 1
%define _unitdir /usr/lib/systemd/system
%endif

Name:           qa_hamsta
Version:        @@VERSION@@
Release:        0
License:        SUSE-NonFree
Summary:        HArdware Maintenance, Setup & Test Automation
Url:            http://qa.suse.de/hamsta
Group:          System/Management
Source:         %{name}-%{version}.tar.bz2
Source1:        perl_module_usage
Source2:        qa_hamsta.8
Source3:	AUTHORS
BuildRequires:  coreutils
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
NoSource:       1
Requires:       hamsta-common
Requires:       perl
Requires:       perl-IO-Socket-Multicast
Requires:       perl-Net-Server
Requires:       perl-Proc-Fork
Requires:       perl-URI
Requires:       perl-XML-Dumper
Requires:       perl-XML-Simple
Requires:       qa_libperl
Requires:       qa_tools
Requires:       screen
%if 0%{?suse_version} == 910
Requires:       hamsta-cmdline
%else
Recommends:     hamsta-cmdline
%endif
Provides:       hamsta
Obsoletes:      hamsta

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


%package master
License:        SUSE-NonFree
Summary:        HArdware Maintenance, Setup & Test Automation
Group:          System/Management
Requires:       hamsta-cmdline
Requires:       hamsta-jobs
Requires:       perl
Requires:       perl-Config-IniFiles
Requires:       perl-DBD-mysql
Requires:       perl-Digest-SHA1
Requires:       perl-IO-Socket-Multicast
Requires:       perl-MIME-Lite
Requires:       perl-Proc-Fork
Requires:       perl-URI
Requires:       perl-XML-Dumper
Requires:       perl-XML-Simple
Requires:       qa_libperl
Requires:       screen
Requires:       hamsta-common
Recommends:     hamsta-cmdline
# Since openSUSE 13.1 and SLES 12 the switch statement is provided by
# this package
# http://en.opensuse.org/openSUSE:Build_Service_cross_distribution_howto
%if 0%{?suse_version} >= 1310
Requires:	perl-Switch
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

%package frontend
License:        SUSE-NonFree
Summary:        HArdware Maintenance, Setup & Test Automation
Group:          System/Management
BuildRequires:  ImageMagick
Requires:       frontenduser
Requires:       hamsta-jobs
Requires:       httpd
Requires:       ipmitool
Requires:       jquery
Requires:       libvirt
Requires:       mod_php_any
Requires:       perl-Config-IniFiles
Requires:       php-ZendFramework
Requires:       php-curl
Requires:       php-gmp
Requires:       php-json
Requires:       php-mysql
Requires:       php-openid
Requires:       php-openssl
Requires:       php-pdo
Requires:       php-snmp
Requires:       sshpass
Requires:       tblib
Requires:       qa_tools

%if 0%{?suse_version} > 910
Recommends:     mysql
%endif
Provides:       hamsta-frontend
Obsoletes:      hamsta-frontend

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


%package cmdline
License:        SUSE-NonFree
Summary:        HArdware Maintenance, Setup & Test Automation
Group:          System/Management
Requires:       hamsta-common
Requires:       perl
Requires:       perl-Term-ReadPassword
Requires:       perl-TermReadKey
Requires:       perl-TermReadLine-Gnu
Provides:       hamsta-cmdline
Obsoletes:      hamsta-cmdline

%description cmdline
Allows to build a network of test machines. Machines are monitored by
the master node, and receive planned jobs. The results plus monitoring
info is sent back to the master. Also allows an automated installation
of systems. Hamsta solves the need of distributing different local test
(automation) frameworks (like STAF,LTP etc.), with their integrated
tests, towards extending the coverage of tested hardware configurations
in a distributed and large scale computing environment.

This package is for command line access to Hamsta.


%package multicast-forward
License:        SUSE-NonFree
Summary:        Hamsta UDP multicast forwarder
Group:          System/Management
Requires:       hamsta-common
Requires:       perl
Requires:       perl-IO-Socket-Multicast
Requires:       screen
Provides:       hamsta-multicast-forward
Obsoletes:      hamsta-multicast-forward

%description multicast-forward
This is a support package for Hamsta. It allows you to forward UDP
multicast messages from subnets behind a router that does not forward them.

Do not run more than one instance on the subnet.


%package jobs
License:        SUSE-NonFree
Summary:        HArdware Maintenance, Setup & Test Automation
Group:          System/Management
Provides:       hamsta-jobs
Obsoletes:      hamsta-jobs

%description jobs
This package contains Hamsta job XML files.
It is shared between Hamsta master and Hamsta frontend.

TODO: this is not correct. Frontend uses the XML files to start a job,
but then it sends a LOCAL path to the master. This won't work if master
and frontend run on different machines. Need to fix that.

%package common
License:        SUSE-NonFree
Summary:        HArdware Maintenance, Setup & Test Automation
Group:          System/Management
Requires:       qa-config
Provides:       hamsta-common
Obsoletes:      hamsta-common

%description common
This package contains Hamsta configuration files that are
shared between Hamsta master, multicast-forwarder and slave.

It also contains functions shared between master and command line
client.

%define destdir /usr/share/hamsta
%define initfile %{_sysconfdir}/init.d/hamsta
%define webdir /srv/www/htdocs/hamsta
%define xml_link /srv/www/htdocs/xml_files
%define confdir /etc/qa

%prep
%setup -n %{name}
cp %{SOURCE3} .

%build
sh frontend/images/resize-icons.sh frontend/images
sed -i 's/HAMSTA_VERSION/%{version}/g' feed_hamsta.{1,pl} frontend/globals.php %{SOURCE2}

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE2} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d %{buildroot}%{_mandir}/man1
install -m 644 feed_hamsta.1 %{buildroot}%{_mandir}/man1
gzip %{buildroot}%{_mandir}/man1/feed_hamsta.1
install -d %{buildroot}%{_sysconfdir}/init.d
cp -a hamsta hamsta-master hamsta-multicast-forward %{buildroot}%{_sysconfdir}/init.d/
install -d %{buildroot}%{_sbindir}
ln -s %{_sysconfdir}/init.d/hamsta %{buildroot}%{_sbindir}/rchamsta
ln -s %{_sysconfdir}/init.d/hamsta-master %{buildroot}%{_sbindir}/rchamsta-master
ln -s %{_sysconfdir}/init.d/hamsta-multicast-forward %{buildroot}%{_sbindir}/rchamsta-multicast-forward
# Install systemd unit file
%if %{?with_systemd}
install -d %{buildroot}/%{_unitdir}
install -m 644 hamsta.service %{buildroot}/%{_unitdir}/
install -m 644 hamsta-master.service %{buildroot}/%{_unitdir}/
%endif
install -d %{buildroot}%{_bindir}
cp -a Slave/hamsta.sh %{buildroot}%{_bindir}/
install -d %{buildroot}%{_sbindir}
cp -a starthamstamaster %{buildroot}%{_sbindir}/
install -d %{buildroot}%{webdir}
cp -a -r --target-directory=%{buildroot}%{webdir} frontend/*
ln -s %{destdir}/xml_files %{buildroot}%{xml_link}
install -m 755 -d %{buildroot}%{destdir}
cp -a -r --target-directory=%{buildroot}%{destdir} Slave command_frontend.pl feed_hamsta.pl master testscript xml_files db hamsta-multicast-forward.pl Hamsta.pm
install -d %{buildroot}%{webdir}/profiles
install -m 755 -d %{buildroot}%{confdir}
cp --target-directory=%{buildroot}%{confdir} 00-hamsta-common-default 00-hamsta-default 00-hamsta-master-default 00-hamsta-multicast-forward-default
find %{buildroot} -name '.svn' -delete
install -d %{buildroot}%{_localstatedir}/log/hamsta/master
install -d %{buildroot}%{_localstatedir}/lib/hamsta

%clean
rm -rf %{buildroot}/*

%post
%if %{?with_systemd}
systemctl daemon-reload
systemctl enable hamsta
systemctl start hamsta
%else
/sbin/insserv -f %{initfile}
%endif
echo %{version} > /usr/share/hamsta/.version
echo %{version} > /usr/share/hamsta/Slave/.version


%post master
%if %{?with_systemd}
systemctl daemon-reload
systemctl enable hamsta-master
%endif
echo "=================== I M P O R T A N T ======================="
echo "Please make sure that you have a database prepared."
echo "To create a new DB, install and configure mysql and then"
echo "run 'cd %destdir/db; ./create_db.sh'."
echo "To update the existing database to the newest version,"
echo "run 'cd %destdir/db; ./update_db.sh'."
echo 'IMPORTANT: you need to add "wwwrun  ALL = (root) NOPASSWD: /usr/bin/ssh" to /etc/sudoers for AutoPXE to work'
echo "=================== I M P O R T A N T ======================="


%post frontend
sed -i "s/Options None/Options FollowSymLinks/" /etc/apache2/default-server.conf
%if %{?with_systemd}
if systemctl --quiet is-active apache2 ; then
	 systemctl restart apache2
fi
%else
if /etc/init.d/apache2 status > /dev/null 2>&1 ; then
	/etc/init.d/apache2 restart
fi
%endif


%preun
%stop_on_removal

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
%{_mandir}/man8/%{name}.8.gz
%{destdir}/testscript
%{destdir}/Slave
%dir %{_datadir}/hamsta/
%{_bindir}/hamsta.sh
%{_sysconfdir}/init.d/hamsta
%if %{?with_systemd}
%dir %{_unitdir}
%{_unitdir}/hamsta.service
%endif
%{_sbindir}/rchamsta
%{confdir}/00-hamsta-default
%dir %{_localstatedir}/lib/hamsta
%doc COPYING
%doc AUTHORS

%files master
%defattr(-, root, root)
%{_sysconfdir}/init.d/hamsta-master
%{_sbindir}/starthamstamaster
%{destdir}/master
%{destdir}/db
%attr(755,root,root) %{destdir}/db/create_db.sh
%attr(755,root,root) %{destdir}/db/update_db.sh
%attr(755,root,root) %{destdir}/master/hamsta_cycle.pl
%dir %{destdir}
%{_sbindir}/rchamsta-master
%if %{?with_systemd}
%dir %{_unitdir}
%{_unitdir}/hamsta-master.service
%endif
%{confdir}/00-hamsta-master-default
%dir %{_localstatedir}/log/hamsta/master

%files cmdline
%defattr(-, root, root)
%{destdir}/command_frontend.pl
%{destdir}/feed_hamsta.pl
%{_mandir}/man1/feed_hamsta.1.gz
%dir %{destdir}

%files frontend
%defattr(-, root, root)
%{webdir}
%attr(-,wwwrun,www) %{webdir}/profiles
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
%{xml_link}
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
%{destdir}/Hamsta.pm

%changelog
