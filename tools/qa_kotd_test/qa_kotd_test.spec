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

#
# spec file for package kotd_test (Version 0.48)
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

BuildRequires:  coreutils

Name:           qa_kotd_test
License:        SUSE Proprietary
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
%config(noreplace) %{confdir}/25-kotd

%changelog

