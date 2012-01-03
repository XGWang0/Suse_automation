#
# spec file for package qa_lib_tblib
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
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
