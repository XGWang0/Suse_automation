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


Name:           qa_lib_tblib
Version:        @@VERSION@@
Release:        0
License:        LGPL-2.1+
Summary:        TBlib - PHP functions for MySQL and HTML
Url:            http://qadb.suse.de/qadb
Group:          System/Management
Source:         %{name}-%{version}.tar.bz2
Source1:        qa_lib_tblib.8
BuildRequires:  coreutils
Requires:       coreutils
Requires:       epoch
Requires:       gs_sortable
Requires:       httpd
Requires:       mod_php_any
Requires:       php-mysql
Requires:       php-pdo
Provides:       tblib
Obsoletes:      tblib
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

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

%define webdir /srv/www/htdocs/tblib

%prep
%setup -n %{name}

%build

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d %{buildroot}%{webdir}
cp -a --target-directory=%{buildroot}%{webdir} *.php
cp -a -r --target-directory=%{buildroot}%{webdir} doc
cp -a -r --target-directory=%{buildroot}%{webdir} icons
cp -a -r --target-directory=%{buildroot}%{webdir} css
find %{buildroot} -name .svn -delete

%clean
rm -rf %{buildroot}

%post
echo %{version} > %{webdir}/.version

%files
%defattr(-, root, root)
%{_mandir}/man8/qa_lib_tblib.8.gz
%{webdir}
%doc COPYING

%changelog
