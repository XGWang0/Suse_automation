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
# spec file for package qa_conf_unstable
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           qa_conf_unstable
Version:        @@VERSION@@
Release:        0
License:        SUSE-NonFree
Summary:        Configutation for QA automation tools, which switches to the development (bleeding edge) servers
Group:          QA Automation
Source0:        %{name}-%{version}.tar.bz2
Source1:        qa_conf_unstable.8
Requires:       qa-config
Provides:       qa-use-devel-servers
Provides:       qa_lib_use-devel-servers
Obsoletes:      qa-use-devel-servers
Obsoletes:      qa_lib_use-devel-servers
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArchitectures: noarch

%description
This package contains set of confuguration files of QA
Automation infrastructure tools, which swith the tools to use
the bleeding edge servers intead of the stable ones. For development
purpose only!

%prep
%setup -q -n %{name}

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d %{buildroot}%{_sysconfdir}/qa
cp -a * %{buildroot}%{_sysconfdir}/qa

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root)
%{_mandir}/man8/qa_conf_unstable.8.gz
%{_sysconfdir}/qa

%changelog
