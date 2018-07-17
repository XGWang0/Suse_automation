# norootforbuild
Summary: Simple http server for mostly static content
Name: webfs
Version: 1.21
Release: 1
License: GPL-2.0
Source0:  %{name}-%{version}.tar.gz
URL: http://linux.bytesex.org/misc/webfs.html
BuildRoot: %{_tmppath}/%{name}-%{version}-root
BuildRequires: gcc pkgconfig
Group: Productivity/Networking/Web/Servers
Prefix: %{_prefix}

%description
Webfs is a simple http server for mostly static content.  You can use it to serve the content of a ftp server via http for example.  It is also nice to export some files the quick way by starting a http server in a few seconds, without editing some config file first.

It uses sendfile() and knows how to use sendfile on linux and FreeBSD. Adding other systems should'nt be difficuilt. There is some sendfile emulation code which uses read()+write() and a userland bounce buffer, this allows to compile and use webfs on systems without sendfile() too.

Recent versions also got limited CGI support (GET requests only) and optional SSL support.

%prep

%setup -q

%build
make 

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



