#
# spec file for package qa_lib_frontenduser
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
cp -a -r --target-directory=$RPM_BUILD_ROOT%{webdir} class
cp -a -r --target-directory=$RPM_BUILD_ROOT%{webdir} doc
rm -rf `find $RPM_BUILD_ROOT -name .svn`

%clean
rm -rf $RPM_BUILD_ROOT

%post

%files
%defattr(-, root, root)
/usr/share/man/man8/qa_lib_frontenduser.8.gz
%{webdir}

%changelog
* Tue Oct 09 2012 pkacer@suse.com
- created package with aim to be shared library
