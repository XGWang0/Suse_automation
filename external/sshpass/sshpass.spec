#
# spec file for package sshpass
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild
Name:           sshpass
Version:        1.05
Release:        1
License:        GPL-2.0+
Summary:        Non-interactive ssh password provider
Vendor:         Lingnu Open Source Consulting Ltd.
Group:          System Environment/Libraries
Source0:        %{name}-%{version}.tar.gz
URL:            http://www.lingnu.com
BuildRoot:      %{_tmppath}/%{name}-%{version}-root
BuildRequires:  gcc-c++ pkgconfig coreutils
Prefix:         %{_prefix}
Group:          Productivity

%description
sshpass is a utility designed for running ssh using the mode referred
to as "keyboard-interactive" password authentication, but in
non-interactive mode.

%prep

%setup -q

%build
# Needed for snapshot releases.
env CFLAGS="$RPM_OPT_FLAGS" ./configure --prefix=%{prefix}

if [ "$SMP" != "" ]; then
  (make "MAKE=make -k -j $SMP"; exit 0)
  make
else
  make
fi

%install
make prefix=$RPM_BUILD_ROOT%{prefix} install

%clean
rm -rf $RPM_BUILD_ROOT

%post
/sbin/ldconfig

%postun
/sbin/ldconfig

%files
%defattr(-, root, root)
%{prefix}/bin/*
%{prefix}/share/man/man1/*

%changelog
* Wed Oct 22 2009 Brasil/East 2009  <alessandrofaria@netitec.com.br>
- Create package in openSuse Build : Alessandro de Oliveira Faria.
