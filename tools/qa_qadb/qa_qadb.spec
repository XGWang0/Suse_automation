#
# spec file for package qadb-frontend
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
Name:           qa_qadb
License:        SUSE Proprietary
Group:          System/Management
AutoReqProv:    on
Version:        @@VERSION@@
Release:        0
Summary:        QA database frontend
Url:            http://qadb.suse.de/qadb
Source:         %{name}-%{version}.tar.bz2
Source1:	%name.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
PreReq:         coreutils
Requires:       mod_php_any httpd php-pdo tblib php-gd mysql mysql-client php-bz2 phplot
Provides:	qadb
Obsoletes:	qadb

%description
QA DataBase frontend. The database is used to store QA test results.
The frontend allows to display/analyse/administer them.

Authors:
--------
            Patrick Kirsch <pkirsch@suse.de>
            Vilem Marsik   <vmarsik@suse.cz>

%define destdir /usr/share/qadb
%define webdir /srv/www/htdocs/qadb


%prep
%setup -n %{name}

%build

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d $RPM_BUILD_ROOT%{webdir}
cp -a -r --target-directory=$RPM_BUILD_ROOT%{webdir} frontend/*
install -m 755 -d $RPM_BUILD_ROOT%{destdir}
cp -a -r --target-directory=$RPM_BUILD_ROOT%{destdir} db patches-deprecated 
rm -rf `find $RPM_BUILD_ROOT -name .svn`

%clean
rm -rf $RPM_BUILD_ROOT

%post
echo %{version} > %{webdir}/.version
echo %{version} > %{destdir}/.version
echo "=================== I M P O R T A N T ======================="
echo "Please make sure that you have a database prepared."
echo "To create a new DB, install and confugure mysql and than"
echo "run 'cd %destdir/db; ./create_db.sh'."
echo "To update the existing database to the newest version,"
echo "run 'cd %destdir/db; ./update_db.sh'."
echo "=================== I M P O R T A N T ======================="

%files
%defattr(-, root, root)
/usr/share/man/man8/%name.8.gz
%{webdir}
%{destdir}
%attr(755,root,root) %{destdir}/db/create_db.sh
%attr(755,root,root) %{destdir}/db/update_db.sh
%config(noreplace) %{webdir}/myconnect.inc.php
%attr(-,wwwrun,www) %{webdir}/output
%doc COPYING

%changelog
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
- More teststsuites
- Many bug fixes
* Tue Aug 16 2011 - llipavsky@suse.cz
- Package rename: qadb -> qa_qadb
* Fri Jun 17 2011 dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- Updates for KOTD testing.
- Improved hwinfo compare.
- Plus, various bug fixes.
* Tue May 24 2011 vmarsik@novell.com
- Added RPM diffing
* Wed Apr 13 2011 dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- Rewritten regression analysis (scales better)
- Beginning fixes for KOTD testing
- Plus bug fixes
* Fri Dec 10 2010 vmarsik@novell.com
- Added support for paging of results and submissions
- Added testsuite/TCF search to results
- Switching card tabs in submissions does not reset search now
* Fri Aug 13 2010 llipavsky@suse.cz
- New release from automation team
  - Added tblib support 
* Wed Aug 04 2010 llipavsky@suse.cz
- Named all foreign keys in DB, so they can be used later in patches
* Thu Jul 29 2010 llipavsky@suse.cz
- DB migrations support
* Fri Jun 11 2010 llipavsky@suse.cz
- Skipped testcase support
* Thu Apr 08 2010 vmarsik@novell.com
- Created the RPM
