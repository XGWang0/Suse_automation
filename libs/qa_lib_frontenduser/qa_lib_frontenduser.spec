#
# spec file for package qa_lib_frontenduser
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

BuildRequires:  coreutils
Name:           qa_lib_frontenduser
License:        SUSE Proprietary, GPL v2 or later
Group:          System/Management
AutoReqProv:    on
Version:        @@VERSION@@
Release:        0
Summary:        Front end shared library for user management and authentication in PHP
Url:            http://qadb.suse.de/hamsta
Source:         %{name}-%{version}.tar.bz2
Source1:	qa_lib_frontenduser.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
PreReq:         coreutils
Provides:	frontenduser
Obsoletes:	frontenduser
Requires:       tblib php5-ZendFramework php5-gmp

%description
This library contains shared classes, functions and pages for user
management in Hamsta and QADB.

Features:
- User administration page.
- User authentication using Zend library.

Authors:
--------
            Vilem Marsik   <vmarsik@suse.cz>
	    Pavel Kacer	   <pkacer@suse.com>

%define webdir /srv/www/htdocs/frontenduser

%prep
%setup -n %{name}

%build

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d $RPM_BUILD_ROOT%{webdir}
cp -a --target-directory=$RPM_BUILD_ROOT%{webdir} *.php
#cp -a -r --target-directory=$RPM_BUILD_ROOT%{webdir} class
#cp -a -r --target-directory=$RPM_BUILD_ROOT%{webdir} doc
rm -rf `find $RPM_BUILD_ROOT -name .svn`

%clean
rm -rf $RPM_BUILD_ROOT

%post

%files
%defattr(-, root, root)
/usr/share/man/man8/qa_lib_frontenduser.8.gz
%{webdir}

%changelog
* Fri Aug 16 2013 - pkacer@suse.com
- New 2.6 release from QA Automation team
- The Machines page has been greatly improved
- Layout changes at the Machine details page
- Web UI menu was changed (renamed entries and added link to documentation)
- Web UI bottom menu was removed
- Machine reservations can be shared by users
- Improved QA network configuration (synchronization and web UI)
- Title of Hamsta changed from image to text
- All user roles are now checked for privileges (without need to switch user roles)
- Ajaxterm was removed
- A lot of bugs were fixed
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
* Tue Oct 09 2012 pkacer@suse.com
- created package with aim to be shared library
