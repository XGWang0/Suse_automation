# norootforbuild
Summary: Tools for the Linux Kernel's network block device.
Name: nbd
Version: 2.9.20
Release: 1
License: GPL v2 or later
Vendor: Lingnu Open Source Consulting Ltd.
Group: System Network/Libraries
Source0:  %{name}-%{version}.tar.bz2
URL: http://cznic.dl.sourceforge.net/project/nbd/nbd/2.9.20/nbd-2.9.20.tar.bz2
BuildRoot: %{_tmppath}/%{name}-%{version}-root
BuildRequires: glib2-devel
Prefix: %{_prefix}
Group: Productivity

%description
Tools for the Linux Kernel's network block device, allowing to use remote block devices over a TCP/IP network.

%prep

%setup -q

%build
./configure && make && make install

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/local/bin
install -m 644 -d $RPM_BUILD_ROOT/usr/local/share/man/man1
install -m 644 -d $RPM_BUILD_ROOT/usr/local/share/man/man5
install -m 644 -d $RPM_BUILD_ROOT/usr/local/share/man/man8
cp nbd-client $RPM_BUILD_ROOT/usr/local/bin/
cp nbd-server $RPM_BUILD_ROOT/usr/local/bin/
cp man/nbd-server.1 $RPM_BUILD_ROOT/usr/local/share/man/man1/
cp man/nbd-server.5 $RPM_BUILD_ROOT/usr/local/share/man/man5/
cp man/nbd-client.8 $RPM_BUILD_ROOT/usr/local/share/man/man8/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root)
%{prefix}/local/bin/nbd-client
%{prefix}/local/bin/nbd-server
%{prefix}/local/share/man/man1/*
%{prefix}/local/share/man/man5/*
%{prefix}/local/share/man/man8/*

%changelog
*Fri Jan 24 2014  Asia/China  <xlai@suse.com>
- Create package in QA repo.


