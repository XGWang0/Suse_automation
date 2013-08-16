#
# spec file for package qa_lib_tblib
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
Name:           qa_lib_tblib
License:        LGPL v2.1 or later
Group:          System/Management
AutoReqProv:    on
Version:        @@VERSION@@
Release:        0
Summary:        TBlib - PHP functions for MySQL and HTML
Url:            http://qadb.suse.de/qadb
Source:         %{name}-%{version}.tar.bz2
Source1:	qa_lib_tblib.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
PreReq:         coreutils
Provides:	tblib
Obsoletes:	tblib
Requires:       mod_php_any httpd php-pdo php-mysql gs_sortable epoch

%description
TBlib web frontend library. Works with PHP and MySQL.
Originally developed for QA database. 
Set of functions for DB access and generating HTML tags.

Features:
- cache of prepared DB queries
- fetches DB query results into scalars or 1D/2D arrays
- code to search in a DB table
- support for enum DB tables - caching, translation
- prints 2D arrays as HTML tables
- HTML tables sortable by clicking the captions
- easy enum strings/links/row highlight into the HTML tables
- code to easily print HTML search forms with predefined values
- code for HTML cards

Authors:
--------
            Vilem Marsik   <vmarsik@suse.cz>

%define webdir /srv/www/htdocs/tblib


%prep
%setup -n %{name}

%build

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d $RPM_BUILD_ROOT%{webdir}
cp -a --target-directory=$RPM_BUILD_ROOT%{webdir} *.php
cp -a -r --target-directory=$RPM_BUILD_ROOT%{webdir} doc
cp -a -r --target-directory=$RPM_BUILD_ROOT%{webdir} icons
cp -a -r --target-directory=$RPM_BUILD_ROOT%{webdir} css
rm -rf `find $RPM_BUILD_ROOT -name .svn`

%clean
rm -rf $RPM_BUILD_ROOT

%post
echo %{version} > %{webdir}/.version

%files
%defattr(-, root, root)
/usr/share/man/man8/qa_lib_tblib.8.gz
%{webdir}
%doc COPYING

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
* Fri Aug 10 2012 - llipavsky@suse.cz
- Web user-friendly editor for jobs
- HA Server yast2 UI Automation
- Build mapping in QADB (buildXXX -> beta Y)
- Improved regression analysis
- Support for benchmark parsers in benchmark testsuite (author of testsuite will also provide a script to parse the results)
- Power switch support in Hamsta (thanks mpluskal!)
- Only results created in the job are submitted to QADB
- QADB improvements
* Wed May 2 2012 - llipavsky@suse.cz
- New 2.3 release from QA Automation team, includes: 
- out-of date and developement SUTs are marked in web frontend and can be updated from the frontend 
- HA Server yast2-cluster UI Automation 
- Improved CLI interface to Hamsta 
- It is possible to get/choose all patterns from all products during SUT intallation (until now, only SLES/D & SDK patterns were shown) 
- Parametrized jobs 
- Better web editors of jobs. Now with multimachine job support 
- Hamsta client one-click installer 
- QADB improvements 
- No more Novell icon in Hamsta ;-)
* Mon Nov 14 2011 - llipavsky@suse.cz
- New 2.2 release from QA Automation team, includes:
- Automated stage testing
- Repartitioning support during reinstall
- Possible to leave some space unparditioned during reinstall
- Added "default additional RPMs to hamsta frontend"
- Optimized hamsta mutlticast format
- Mutliple build-validation jobs
- Code cleanup
- Bugfixes
* Sun Sep 04 2011 - llipavsky@suse.cz
- New, updated release from the automation team. Includes:
- Improved virtual machine handling/QA cloud
- Rename of QA packages
- Upgrade support
- Changed format od /etc/qa files
- More teststsuites
- Many bug fixes
* Tue Aug 16 2011 - llipavsky@suse.cz
- Package rename: tblib -> qa_lib_tblib
* Fri Jun 17 2011 dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- Upgraded jQuery version
- Plus, various bug fixes
* Wed Apr 13 2011 dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- Various bug fixes
* Fri Dec 10 2010 vmarsik@novell.com
- added support for table paging
* Thu Apr 08 2010 vmarsik@novell.com
- created the package by splitting from qadb
