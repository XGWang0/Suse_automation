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


Name:           qa_lib_frontenduser
Version:        @@VERSION@@
Release:        0
License:        SUSE-NonFree, GPL-2.0+
Summary:        Front end shared library for user management and authentication in PHP
Url:            http://qadb.suse.de/hamsta
Group:          System/Management
Source:         %{name}-%{version}.tar.bz2
Source1:        qa_lib_frontenduser.8
BuildRequires:  coreutils
Requires(pre):  coreutils
Requires:       php-ZendFramework
Requires:       php-gmp
Requires:       tblib
Provides:       frontenduser
Obsoletes:      frontenduser
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
This library contains shared classes, functions and pages for user
management in Hamsta and QADB.

Features:
- User administration page.
- User authentication using Zend library.

%define webdir /srv/www/htdocs/frontenduser

%prep
%setup -n %{name}

%build

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d %{buildroot}%{webdir}
cp -a --target-directory=%{buildroot}%{webdir} *.php
rm -rf `find %{buildroot} -name .svn`

%clean
rm -rf %{buildroot}

%post -p /sbin/ldconfig

%files
%defattr(-, root, root)
%{_mandir}/man8/qa_lib_frontenduser.8.gz
%{webdir}

%changelog
