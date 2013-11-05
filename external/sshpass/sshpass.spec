# norootforbuild
Summary: noninteractive ssh password provider
Name: sshpass
Version: 1.05
Release: 1
License: GPL v2 or later
Vendor: Lingnu Open Source Consulting Ltd.
Group: System Environment/Libraries
Source0:  %{name}-%{version}.tar.gz
URL: http://www.lingnu.com
BuildRoot: %{_tmppath}/%{name}-%{version}-root
BuildRequires: gcc-c++ pkgconfig
Prefix: %{_prefix}
Group: Productivity

%description
sshpass  is  a utility designed for running ssh using the mode referred to as "keyboard-interactive" password authentication, but in non-interactive mode.

%prep

%setup -q

%build
# Needed for snapshot releases.
  CFLAGS="$RPM_OPT_FLAGS" ./configure --prefix=%{prefix} 

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



