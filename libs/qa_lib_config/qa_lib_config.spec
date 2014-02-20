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
# spec file for package qa_config (Version 1.0)
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

Name:           qa_lib_config
Version:        @@VERSION@@
Release:        0
License:        SUSE-NonFree
Summary:        Basic configutation for QA automation tools
Group:          QA Automation
Source0:        %{name}-%{version}.tar.bz2
Source1:        qa_lib_config.8
Requires:       bash
Provides:       qa-config
Obsoletes:      qa-config
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArchitectures: noarch

%description
This package contains base set of tools to handle confuguration tools of QA
Automation infrastructure tools.

%prep
%setup -q -n %{name}

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d %{buildroot}%{_sysconfdir}/qa
install -m 755 -d %{buildroot}%{_datadir}/qa/tools
install -m 755 -d %{buildroot}%{_datadir}/qa/lib
cp -a config %{buildroot}%{_datadir}/qa/lib
cp -a qaconfig.pm %{buildroot}%{_datadir}/qa/lib
cp -a dump_qa_config %{buildroot}%{_datadir}/qa/tools
cp -a get_qa_config %{buildroot}%{_datadir}/qa/tools
cp -a sync_qa_config %{buildroot}%{_datadir}/qa/tools
cp -a 00-automation-default %{buildroot}%{_sysconfdir}/qa

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root)
%{_mandir}/man8/qa_lib_config.8.gz
%{_datadir}/qa
%{_sysconfdir}/qa/
%doc COPYING

%changelog
