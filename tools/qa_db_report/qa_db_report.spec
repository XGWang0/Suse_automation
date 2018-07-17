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
# spec file for package qa_db_report (Version 0.34)
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


BuildRequires:  coreutils

Name:           qa_db_report
Version:        @@VERSION@@
Release:        0
License:        SUSE-NonFree
Summary:        QADB submit code
Group:          SUSE internal
Source0:        %{name}-%{version}.tar.bz2
Source1:        %{name}.8
Source2:        %{name}-rpmlintrc
Source3:	AUTHORS
Requires:	coreutils
Requires:       perl
Requires:       perl-DBD-mysql
Requires:       qa-config
Requires:       qa_libperl
Requires:       qa_tools
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
Formerly part of qa_tools, this package contains qa_db_report.pl and
related files. These files now should only be installed on one central
server that alone does the direct MySQL writing. Clients only send
test results and basic configuration, code in this package does the
actual QADB submit.

%define destdir /usr/share/qa
%define bindir %{destdir}/tools
%define confdir /etc/qa
%define libdir %{destdir}/lib
%define mandir	/usr/share/man
%define remoteresdir /var/log/qa-remote-results
%define permdir /etc/permissions.d

%prep
%setup -q -n %{name}
cp %{SOURCE3} .

%build

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d %{buildroot}%{destdir}
install -m 755 -d %{buildroot}%{bindir}
install -m 755 -d %{buildroot}%{libdir}
install -m 755 -d %{buildroot}%{confdir}
install -m 777 -d %{buildroot}%{remoteresdir}
install -m 755 -d %{buildroot}%{mandir}/man1
install -m 755 -d %{buildroot}%{mandir}/man5
install -m 755 -d %{buildroot}%{permdir}
gzip -9 *.1 *.5
cp -r --target-directory=%{buildroot}%{libdir} qadb.pm bench_parsers.pm functions.pm
cp --target-directory=%{buildroot}%{bindir} qa_db_report.pl
cp --target-directory=%{buildroot}%{bindir} fix_qadb_stat.pl
cp --target-directory=%{buildroot}%{bindir} select_db.pl
echo ${version} > %{buildroot}%{libdir}/.version
cp --target-directory=%{buildroot}%{mandir}/man1 *.1.gz
cp --target-directory=%{buildroot}%{mandir}/man5 *.5.gz
cp --target-directory=%{buildroot}%{permdir} permissions.d/qa_db_report
cp --target-directory=%{buildroot}%{confdir} 00-qa_db_report-default

%clean
rm -rf %{buildroot}

%files
%defattr(0644,root,root,0755)
%{_mandir}/man8/qa_db_report.8.gz
%dir %{destdir}
%dir %{libdir}
%dir %{bindir}
%dir %{remoteresdir}
%attr(0777,root,root) %{remoteresdir}
%verify(not mode) %{remoteresdir}
%{permdir}/qa_db_report
%{mandir}/man1/*
%{mandir}/man5/*
%attr(0755,root,root) %{bindir}/qa_db_report.pl
%attr(0755,root,root) %{bindir}/fix_qadb_stat.pl
%attr(0755,root,root) %{bindir}/select_db.pl
%{libdir}/qadb.pm
%{libdir}/functions.pm
%{libdir}/bench_parsers.pm
%{libdir}/.version
%{confdir}
%doc COPYING
%doc AUTHORS

%changelog
