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

# norootforbuild

Name:           qa_workplace_desktop-integration
License:        SUSE Proprietary
Group:          SuSE internal
AutoReqProv:    on
Version:        @@VERSION@@
Release:        1
Summary:        Tools and helpers for the desktop integration of QA Automation tools
Url:            http://www.novell.com/
Source0:        %{name}-%{version}.tar.bz2
Source1:	%name.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Requires:       xterm desktop-file-utils
BuildRequires:  desktop-file-utils
BuildArch:	noarch

%description
Tools and helpers for the desktop integration of QA Automation tools:

hamsta-cscreen:
  Tools for a web link to open the serial console of a machine in the local
  terminal emulator, The link can look like this:
    hamsta-cscreen:qaserial.qa/ix64ph043

  The qaserial.qa is the console server, the ix64ph043 is the hamsta client
  machine which link the console server with serial cable.

Author:
--------
	Dominik Heidler <dheidler@suse.com>
#Authors:
#--------
#  Create package:
#    Jia,Yao (jyao@suse.com, SUSE Inc)
#    Oct 26, 2012

%prep
%setup -q -n %{name}

%build

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d $RPM_BUILD_ROOT/usr/bin
install -m 755 -d $RPM_BUILD_ROOT/usr/share/applications
install -m 755 -d $RPM_BUILD_ROOT/etc
install -m 755 -d $RPM_BUILD_ROOT/usr/share

# hamsta-cscreen
pushd hamsta-cscreen
install -m 644 hcscreenrc $RPM_BUILD_ROOT/etc
install -m 644 hamsta-cscreen.desktop $RPM_BUILD_ROOT/etc
cp hs_cscreen $RPM_BUILD_ROOT/usr/bin
chmod 755 $RPM_BUILD_ROOT/usr/bin/hs_cscreen
popd

%clean
rm -rf $RPM_BUILD_ROOT

%post
desktop-file-install --rebuild-mime-info-cache /etc/hamsta-cscreen.desktop
#rm -f /etc/hamsta-cscreen.desktop

%files
%defattr(-,root,root)
/usr/share/man/man8/%{name}.8.gz
/usr/bin/hs_cscreen
/etc/hamsta-cscreen.desktop
/etc/hcscreenrc

%postun
rm -f /usr/share/applications/hamsta-cscreen.desktop

%changelog
* Fri Jan 18 2013 - llipavsky@suse.com
- New 2.5 release from QA Automation team
- Authentication and Authorization in Hamsta
- ctcs2 improvements, speedup, and new tcf commands
- New SUT can be added to Hamsta from hamsta web interface
- Timezone support in reinstall
- Reinstall can now be done using kexec
- Centralized configuration of SUTs
- Sessions support in Hamsta
- AutoPXE now supports ia64 architecture
- Hamsta is no longer configured using config.php, config.ini is used instead
- ...and many small improvements and bug fixes
* Tue Oct 31 2012 - jyao@suse.com
- Package (v.1.0) created automatically using qa_sdk_spec_generator

