# ****************************************************************************
# Copyright © 2011 Unpublished Work of SUSE, Inc. All Rights Reserved.
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
# Copyright (c) 2012 SUSE.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugzilla.novell.com/
#

# norootforbuild

Name:           qa_cscreen
License:        SUSE Proprietary
Group:          SuSE internal
AutoReqProv:    on
Version:        1.0
Release:        1
Summary:        qa_cscreen
Url:            http://www.novell.com/
Source0:        hamsta-cscreen.tgz
Source1:	%name.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Provides:       cscreen
Obsoletes:      cscreen
Requires:       xterm desktop-file-utils
BuildRequires:  desktop-file-utils
BuildArch:	noarch

%description
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
%setup -q -n hamsta-cscreen

%build
#make install

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d $RPM_BUILD_ROOT/usr/bin
install -m 755 -d $RPM_BUILD_ROOT/usr/share/applications
install -m 755 -d $RPM_BUILD_ROOT/etc
install -m 755 -d $RPM_BUILD_ROOT/usr/share
install -m 644 hcscreenrc $RPM_BUILD_ROOT/etc
cp hs_cscreen $RPM_BUILD_ROOT/usr/bin
chmod 755 $RPM_BUILD_ROOT/usr/bin/hs_cscreen
cp hamsta-cscreen.desktop $RPM_BUILD_ROOT/usr/share

%clean
rm -rf $RPM_BUILD_ROOT

%post
desktop-file-install --rebuild-mime-info-cache /usr/share/hamsta-cscreen.desktop
rm -f /usr/share/hamsta-cscreen.desktop

%files
%defattr(-,root,root)
/usr/share/man/man8/%{name}.8.gz
/usr/bin/hs_cscreen
/usr/share/hamsta-cscreen.desktop
/etc/hcscreenrc

%postun
rm -f /usr/share/applications/hamsta-cscreen.desktop

%changelog
* Tue Oct 31 2012 - jyao@suse.com
- Package (v.1.0) created automatically using qa_sdk_spec_generator

