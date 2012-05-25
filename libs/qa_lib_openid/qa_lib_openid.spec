#
# spec file for package 
#
# Copyright (c) 2012 SUSE LINUX Products GmbH, Nuernberg, Germany.
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

Name:           qa_lib_openid
Summary:	Consumer openid pieces of Zend Framework
Version:	1.11.11
Release:	1
License:	BSD
Url:		http://framework.zend.com/
Group:		Development/Libraries/Other
Source:		%{name}-%{version}.tar.gz
Source1:	%{name}.8
BuildRequires:	php5 >= 5.2
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%description
Extending the art & spirit of PHP, Zend Framework is based on simplicity,
object-oriented best practices, corporate friendly licensing, and a rigorously
tested agile codebase. Zend Framework is focused on building more secure,
reliable, and modern Web 2.0 applications & web services, and consuming widely
available APIs from leading vendors like Google, Amazon, Yahoo!, Flickr, as
well as API providers and catalogers like StrikeIron and ProgrammableWeb.

%prep
%setup -q

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
mkdir -p $RPM_BUILD_ROOT%{_datadir}/php5
install --directory $RPM_BUILD_ROOT%{_datadir}/php5/Zend
%{__cp} -pr Zend/* $RPM_BUILD_ROOT%{_datadir}/php5/Zend

%clean
%{?buildroot:%__rm -rf "%{buildroot}"}

%files
%defattr(-,root,root)
/usr/share/man/man8/%{name}.8.gz
%{_datadir}/php5/Zend

%changelog
* Wed May 23 2012 dmulder@suse.com
- Created package.
