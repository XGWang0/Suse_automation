#
# spec file for package jquery_treetable
#
# Copyright (c) 2013, 2014 SUSE LINUX Products GmbH, Nuernberg, Germany.
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
Name:           jquery_treetable
License:        LGPL-3.0
Group:          Development/Sources
AutoReqProv:    on
Version:        3.1.0
Release:        0
Summary:        Treetable  script
Url:            http://ludo.cubicphuse.nl/jquery-treetable/
Source:         %{name}-%{version}.tar.bz2
Source1:	%{name}.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
PreReq:         coreutils

%description
Client-side Jquery Plugin that sorts HTML tables on click.


Authors:
--------
	Ludo van den

%define webdir /srv/www/htdocs/hamsta
%define mandir /usr/share/man/man8


%prep
%setup -q -n %{name}

%build

%install
install -m 755 -d $RPM_BUILD_ROOT%{mandir}
install -m 755 -d $RPM_BUILD_ROOT%{webdir}/css
install -m 755 -d $RPM_BUILD_ROOT%{webdir}/js
install -m 644 %{S:1} $RPM_BUILD_ROOT%{mandir}
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 644 *.css $RPM_BUILD_ROOT%{webdir}/css
install -m 644 *.js $RPM_BUILD_ROOT%{webdir}/js
rm -rf `find $RPM_BUILD_ROOT -name .svn`

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-, root, root)
/usr/share/man/man8/%{name}.8.gz
%dir %{webdir}
%{webdir}/*

%changelog
* Tue Jul 22 2014 - vmarsik@suse.cz
- treetable view for jobs
