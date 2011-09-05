#
# spec file for package qa_db_report (Version 0.34)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

BuildRequires:  coreutils

Name:           qa_db_report
License:        GPL v2 or later
Group:          SUSE internal
AutoReqProv:    on
Version:        2.2.0
Release:        0
Summary:        QADB submit code
#Url:          http://qa.suse.de/hamsta
Source0:        %{name}-%{version}.tar.bz2
Source1:	qa_db_report.8
#Patch:        %{name}-%{version}.patch
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Requires:       perl perl-DBD-mysql qa_tools qa_libperl
Requires:  	qa-config
BuildArch:      noarch
PreReq:         coreutils

%description
Formerly part of qa_tools, this package contains qa_db_report.pl and
related files. These files now should only be installed on one central
server that alone does the direct MySQL writing. Clients only send
test results and basic configuration, code in this package does the
actual QADB submit.


Authors:
--------
    Vilem Marsik <vmarsik@suse.cz>
    Patrick Kirsch <pkirsch@suse.de>
    Lukas Lipavsky <llipavsky@suse.cz>

%define destdir /usr/share/qa
%define bindir %{destdir}/tools
%define confdir /etc/qa
%define libdir %{destdir}/lib
%define mandir	/usr/share/man
%define remoteresdir /var/log/qa-remote-results
%define permdir /etc/permissions.d

%prep
%setup -n %{name}
#%patch

%build

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d $RPM_BUILD_ROOT%{destdir}
install -m 755 -d $RPM_BUILD_ROOT%{bindir}
install -m 755 -d $RPM_BUILD_ROOT%{libdir}
install -m 755 -d $RPM_BUILD_ROOT%{confdir}
install -m 777 -d $RPM_BUILD_ROOT%{remoteresdir}
install -m 755 -d $RPM_BUILD_ROOT%{mandir}/man1
install -m 755 -d $RPM_BUILD_ROOT%{mandir}/man5
install -m 755 -d $RPM_BUILD_ROOT%{permdir}
gzip -9 *.1 *.5
cp -r --target-directory=$RPM_BUILD_ROOT%{libdir} qadb.pm bench_parsers.pm functions.pm
cp --target-directory=$RPM_BUILD_ROOT%{bindir} qa_db_report.pl
cp --target-directory=$RPM_BUILD_ROOT%{bindir} select_db.pl
echo ${version} > $RPM_BUILD_ROOT%{libdir}/.version
cp --target-directory=$RPM_BUILD_ROOT%{mandir}/man1 *.1.gz
cp --target-directory=$RPM_BUILD_ROOT%{mandir}/man5 *.5.gz
cp --target-directory=$RPM_BUILD_ROOT%{permdir} permissions.d/qa_db_report
cp --target-directory=$RPM_BUILD_ROOT%{confdir} 00-qa_db_report-default

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(0644,root,root,0755)
/usr/share/man/man8/qa_db_report.8.gz
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
%attr(0755,root,root) %{bindir}/select_db.pl
%{libdir}/qadb.pm
%{libdir}/functions.pm
%{libdir}/bench_parsers.pm
%{libdir}/.version
%{confdir}

%changelog
