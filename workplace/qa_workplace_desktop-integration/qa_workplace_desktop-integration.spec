# ****************************************************************************
# Copyright © 2013 Unpublished Work of SUSE, Inc. All Rights Reserved.
#
# THIS IS AN UNPUBLISHED WORK OF SUSE, INC.  IT CONTAINS SUSE'S
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
# spec file for package qa_test_cscreen (Version 0.1)
#
# Please submit bugfixes or comments via http://bugzilla.novell.com/
#

# norootforbuil
#
# spec file for package qa_test_cscreen
# Copyright (c) 2013 SUSE.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugzilla.novell.com/
#


Name:           qa_workplace_desktop-integration
Version:        @@VERSION@@
Release:        1
License:        SUSE-NonFree
Summary:        Tools and helpers for the desktop integration of QA Automation tools
Url:            http://www.novell.com/
Group:          SuSE internal
Source0:        %{name}-%{version}.tar.bz2
Source1:        %{name}.8
BuildRequires:  desktop-file-utils
Requires:       desktop-file-utils
Requires:       xterm
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
Tools and helpers for the desktop integration of QA Automation tools:

hamsta-cscreen:
  Tools for a web link to open the serial console of a machine in the local
  terminal emulator, The link can look like this:
    hamsta-cscreen:qaserial.qa/ix64ph043

  The qaserial.qa is the console server, the ix64ph043 is the hamsta client
  machine which link the console server with serial cable.


%prep
%setup -q -n %{name}

%build

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d %{buildroot}%{_bindir}
install -m 755 -d %{buildroot}%{_datadir}/applications
install -m 755 -d %{buildroot}%{_sysconfdir}
install -m 755 -d %{buildroot}%{_prefix}/share

# hamsta-cscreen
pushd hamsta-cscreen
install -m 644 hcscreenrc %{buildroot}/etc
install -m 644 hamsta-cscreen.desktop %{buildroot}%{_sysconfdir}
cp hs_cscreen %{buildroot}%{_prefix}/bin
chmod 755 %{buildroot}%{_bindir}/hs_cscreen
popd

%clean
rm -rf %{buildroot}

%post
desktop-file-install --rebuild-mime-info-cache /etc/hamsta-cscreen.desktop

%files
%defattr(-,root,root)
%{_mandir}/man8/%{name}.8.gz
%{_bindir}/hs_cscreen
%{_sysconfdir}/hamsta-cscreen.desktop
%{_sysconfdir}/hcscreenrc

%postun
rm -f /usr/share/applications/hamsta-cscreen.desktop

%changelog
