#
# spec file for package sshpass
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild
Name:           vncsnapshot
Version:        1.2a
Release:        1
License:        GPL-2.0+
Summary:        Get screenshot from vnc protocal
Vendor:         grmcdorman@users.sourceforge.net
Group:          System Environment/Libraries
Source0:        %{name}-%{version}-src.tar.gz
URL:            http://sourceforge.net/projects/vncsnapshot/
BuildRoot:      %{_tmppath}/%{name}-%{version}-root
BuildRequires:  gcc-c++ pkgconfig coreutils zlib libjpeg8
Prefix:         %{_prefix}
Group:          Productivity

%description
VNC Snapshot is a command line utility for VNC (Virtual Network Computing) available from RealVNC, among others. The utility allows one to take a snapshot from a VNC server and save it as a JPEG file. Unix, Linux and Windows platforms are supported.

%prep

%setup -n %{name}-%{version}

%build
make

%install
install -m 755 -d %{buildroot}/usr/bin/
cp vncpasswd vncsnapshot %{buildroot}/usr/bin/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root)
/usr/bin/*

%changelog
* Thu Aug 12 2015 - jtang@suse.com
- packed initial release
