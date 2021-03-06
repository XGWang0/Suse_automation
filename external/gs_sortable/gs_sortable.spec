#
# spec file for package gs_sortable
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
Name:           gs_sortable
License:        LGPL-3.0
Group:          Development/Sources
AutoReqProv:    on
Version:        1.8
Release:        0
Summary:        Table sort script
Url:            http://www.allmyscripts.com/Table_Sort/index.html
Source:         %{name}-%{version}.tar.bz2
Source1:	%{name}.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
PreReq:         coreutils

%description
Client-side Javascript tool that sorts HTML tables on click.


Authors:
--------
	2007 - 2011 Gennadiy Shvets

%define webdir /srv/www/htdocs/scripts
%define mandir /usr/share/man/man8


%prep
%setup -q -n %{name}

%build

%install
install -m 755 -d $RPM_BUILD_ROOT%{mandir}
install -m 755 -d $RPM_BUILD_ROOT%{webdir}
install -m 644 %{S:1} $RPM_BUILD_ROOT%{mandir}
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 644 *.js $RPM_BUILD_ROOT%{webdir}
rm -rf `find $RPM_BUILD_ROOT -name .svn`

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-, root, root)
/usr/share/man/man8/%{name}.8.gz
%dir %{webdir}
%{webdir}/*

%changelog
* Tue Dec 6 2011 - vmarsik@suse.cz
- split from tblib
