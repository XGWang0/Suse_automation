#
# spec file for package php-openid
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

%define	auth	Auth
%define php_dir /usr/share/php5
%define mandir /usr/share/man/man8

BuildRequires:  coreutils
Name:           php-openid
License:        Apache License version 2.0
Group:          Development/Libraries/Sources
AutoReqProv:    on
Version:        2.2.2
Release:        0
Summary:        PHP OpenID library
Url:            http://www.openidenabled.com/
Source:         %{auth}-%{version}.tar.bz2
Source1:	%{name}.8
Requires:	php >= 4.3.0 php-gmp php-pear php-curl
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
PreReq:         coreutils

%description
This is the PHP OpenID library by JanRain, Inc. You can visit our
website for more information about this package and other OpenID
implementations and tools:

  http://www.openidenabled.com/

Authors:
--------
	Jonathan Daugherty <cygnus@janrain.com>
	Josh Hoyt <josh@janrain.com>


%prep
%setup -n %{auth}

%build

%install
install -m 755 -d $RPM_BUILD_ROOT%{mandir}
install -m 755 -d $RPM_BUILD_ROOT%{php_dir}/%{auth}
install -m 644 %{S:1} $RPM_BUILD_ROOT%{mandir}
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
cp -rL * $RPM_BUILD_ROOT%{php_dir}/%{auth}

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-, root, root)
/usr/share/man/man8/%{name}.8.gz
%{php_dir}
%{php_dir}/%{auth}

%changelog
* Tue Oct  9 2013 - pkacer@suse.com
- Package created
