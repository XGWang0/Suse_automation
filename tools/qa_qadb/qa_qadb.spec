#
# spec file for package qadb-frontend
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


Name:           qa_qadb
Version:        @@VERSION@@
Release:        0
License:        SUSE-NonFree
Summary:        QA database frontend
Url:            http://qadb.suse.de/qadb
Group:          System/Management
Source:         %{name}-%{version}.tar.bz2
Source1:        %{name}.8
Source2:	AUTHORS
BuildRequires:  coreutils
Requires:       coreutils
Requires:       httpd
Requires:       mod_php_any
Requires:       mysql
Requires:       mysql-client
Requires:       php-ZendFramework
Requires:       php-bz2
Requires:       php-gd
Requires:       php-gmp
Requires:       php-pdo
Requires:       phplot
Requires:       tblib
Provides:       qadb
Obsoletes:      qadb
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
QA DataBase frontend. The database is used to store QA test results.
The frontend allows to display/analyse/administer them.

%define destdir /usr/share/qadb
%define webdir /srv/www/htdocs/qadb

%prep
%setup -n %{name}
cp %{SOURCE2} .

%build

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d %{buildroot}%{webdir}
cp -a -r --target-directory=%{buildroot}%{webdir} frontend/*
install -m 755 -d %{buildroot}%{destdir}
cp -a -r --target-directory=%{buildroot}%{destdir} db patches-deprecated
find %{buildroot} -name '.svn' -delete

%clean
rm -rf %{buildroot}

%post
echo %{version} > %{webdir}/.version
echo %{version} > %{destdir}/.version
echo "=================== I M P O R T A N T ======================="
echo "Please make sure that you have a database prepared."
echo "To create a new DB, install and configure mysql and then"
echo "run 'cd %destdir/db; ./create_db.sh'."
echo "To update the existing database to the newest version,"
echo "run 'cd %destdir/db; ./update_db.sh'."
echo "=================== I M P O R T A N T ======================="

%files
%defattr(-, root, root)
%{_mandir}/man8/%{name}.8.gz
%{webdir}
%{destdir}
%attr(755,root,root) %{destdir}/db/create_db.sh
%attr(755,root,root) %{destdir}/db/update_db.sh
%config(noreplace) %{webdir}/myconnect.inc.php
%attr(-,wwwrun,www) %{webdir}/output
%doc COPYING
%doc AUTHORS

%changelog
