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

#
# spec file for package kotd_test (Version 0.48)
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


BuildRequires:  coreutils

Name:           qa_kotd_test
Version:        @@VERSION@@
Release:        0
License:        SUSE-NonFree
Summary:        QA KOTD test controller
Group:          SUSE internal
Source:         %{name}-%{version}.tar.bz2
Source1:        %{name}.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Requires:       perl
Requires:       qa-config
Requires:       qa_tools
%if 0%{?suse_version} == 910
Requires:       qa_libmicro_test
Requires:       qa_libperl
Requires:       qa_lmbench_test
Requires:       qa_ltp_test
Requires:       qa_tiobench_test
%else
Recommends:     qa_libmicro_test
Recommends:     qa_lmbench_test
Recommends:     qa_ltp_test
Recommends:     qa_tiobench_test
%endif
Requires:       coreutils
Provides:       kotd_test
Obsoletes:      kotd_test
BuildArch:      noarch

%description
QA KOTD test controller.

%define destdir /usr/share/qa
%define bindir %{destdir}/tools
%define libdir %{destdir}/lib
%define mandir	/usr/share/man
%define confdir /etc/qa
%define vardir	/var/lib/qa
%define kotddir %{vardir}/kerneltest

%prep
%setup -q -n %{name}
#%patch

%build

%install
install -m 755 -d %{buildroot}%{bindir}
install -m 755 -d %{buildroot}%{libdir}
install -m 755 -d %{buildroot}%{mandir}/man8
install -m 755 -d %{buildroot}%{confdir}
install -m 755 -d %{buildroot}%{_sysconfdir}/init.d
install -m 755 -d %{buildroot}%{_sbindir}
install -m 755 -d %{buildroot}%{kotddir}
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip -9 %{buildroot}%{_mandir}/man8/%{name}.8
cp --target-directory=%{buildroot}%{bindir} *.pl
echo ${version} > %{buildroot}%{libdir}/kotd_test.version
cp --target-directory=%{buildroot}%{confdir} 25-kotd
cp --target-directory=%{buildroot}%{_sysconfdir}/init.d kotd_test
ln -s %{_sysconfdir}/init.d/kotd_test %{buildroot}%{_sbindir}/rckotd_test
cp --target-directory=%{buildroot}%{kotddir} kerneltest/test

%clean
rm -rf %{buildroot}

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
%doc COPYING

%changelog
