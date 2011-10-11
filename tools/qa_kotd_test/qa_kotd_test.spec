#
# spec file for package kotd_test (Version 0.48)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

BuildRequires:  coreutils

Name:           qa_kotd_test
License:        GPL v2 or later
Group:          SUSE internal
AutoReqProv:    on
Version:        @@VERSION@@
Release:        0
Summary:        QA KOTD test controller
#Url:          http://qa.suse.de/hamsta
Source:         %{name}-%{version}.tar.bz2
Source1:	%name.8
#Patch:        %{name}-%{version}.patch
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
%if 0%{?sles_version} == 9
Requires:       perl qa_tools qa_libperl qa-config qa_lmbench_test qa_tiobench_test qa_ltp_test qa_libmicro_test
%else
Requires:       perl qa_tools qa_libperl qa-config
Recommends:	qa_lmbench_test qa_tiobench_test qa_ltp_test qa_libmicro_test
%endif
Provides:	kotd_test
Obsoletes:	kotd_test
BuildArch:      noarch
PreReq:         coreutils

%description
QA KOTD test controller.


Authors:
--------
    Vilem Marsik <vmarsik@suse.cz>

%define destdir /usr/share/qa
%define bindir %{destdir}/tools
%define libdir %{destdir}/lib
%define mandir	/usr/share/man
%define confdir /etc/qa
%define vardir	/var/lib/qa
%define kotddir %{vardir}/kerneltest

%prep
%setup -n %{name}
#%patch

%build

%install
install -m 755 -d $RPM_BUILD_ROOT%{bindir}
install -m 755 -d $RPM_BUILD_ROOT%{libdir}
install -m 755 -d $RPM_BUILD_ROOT%{mandir}/man8
install -m 755 -d $RPM_BUILD_ROOT%{confdir}
install -m 755 -d $RPM_BUILD_ROOT%{_sysconfdir}/init.d
install -m 755 -d $RPM_BUILD_ROOT%{_sbindir}
install -m 755 -d $RPM_BUILD_ROOT%{kotddir}
gzip -9 *.8
cp --target-directory=$RPM_BUILD_ROOT%{bindir} *.pl
echo ${version} > $RPM_BUILD_ROOT%{libdir}/kotd_test.version
cp --target-directory=$RPM_BUILD_ROOT%{mandir}/man8 *.8.gz
cp --target-directory=$RPM_BUILD_ROOT%{confdir} 25-kotd
cp --target-directory=$RPM_BUILD_ROOT%{_sysconfdir}/init.d kotd_test
ln -s %{_sysconfdir}/init.d/kotd_test $RPM_BUILD_ROOT%{_sbindir}/rckotd_test
cp --target-directory=$RPM_BUILD_ROOT%{kotddir} kerneltest/test

%clean
rm -rf $RPM_BUILD_ROOT

%post
cd %{kotddir}
for A in cmnd_fifo status qa_kcmt_last qa_krnl_last qa_krnl_list
do
	if [ ! -f $A ]
	then
		touch $A
	fi
done

%preun

%files
%defattr(0644,root,root,0755)
%dir %{destdir}
%dir %{libdir}
%dir %{bindir}
%{mandir}/man8/*
%attr(0755,root,root) %{bindir}/*
%{libdir}/*
%{confdir}
%{kotddir}
%dir %{vardir}
%attr(0755,root,root) %{_sysconfdir}/init.d/kotd_test
%attr(0755,root,root) %{_sbindir}/rckotd_test
%config(noreplace) %{kotddir}/test
%config(noreplace) %{confdir}/kotd/25-kotd

%changelog
