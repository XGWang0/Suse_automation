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


Name:           qa_lib_virtauto
License:        SUSE-NonFree
Summary:        (rd-)qa package for virtualization automation
Group:          SUSE internal
Requires:       expect
Requires:       libvirt
Requires:       perl-XML-XPath
Requires:       qa_keys
Requires:       qa_libperl
Requires:       openssh
# sshpass version 1.04 has bug for ssh commands which sometimes hang
# forever. Is fixed in 1.05.
Requires:       sshpass >= 1.05
Requires:       virtautolib-data
Requires:       nbd
Provides:       virtautolib
Obsoletes:      virtautolib
%if 0%{?suse_version} == 1010
Requires:       xen-tools
%else
Requires:       vm-install
%endif
Version:        @@VERSION@@
Release:        0
Source:         %{name}-%{version}.tar.bz2
Source1:        qa_lib_virtauto.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArchitectures: noarch

%description
QA library for virtualization automation

%prep
%setup -n %{name}

%build

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d %{buildroot}%{_datadir}/qa/virtautolib
install -m 755 -d %{buildroot}%{_datadir}/qa/tools
cp -a * %{buildroot}%{_datadir}/qa/virtautolib
mv  %{buildroot}%{_datadir}/qa/virtautolib/lib/vm-migrate-allhosttype.pl %{buildroot}%{_datadir}/qa/tools
find %{buildroot}%{_datadir}/qa/virtautolib -depth -type d -name .svn -exec rm -rf {} \;

%post

%clean
rm -rf %{buildroot}

%files
%defattr(-, root, root)
%{_mandir}/man8/qa_lib_virtauto.8.gz
%{_datadir}/qa
%doc COPYING

%changelog
