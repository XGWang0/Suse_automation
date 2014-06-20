#
# spec file for package nbd
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


Name:           nbd
%define lt_sle12_build (0%{?suse_version} < 1315)
%define ge_sle12_build (0%{?suse_version} >= 1315)
%if %{lt_sle12_build}
Version: 2.9.20
Source0:  %{name}-%{version}.tar.bz2
BuildRequires: glib2-devel
%else
BuildRequires:  doxygen
BuildRequires:  glib2-devel >= 2.26.0
PreReq:         %insserv_prereq coreutils
Version:        3.3
Source:         http://downloads.sourceforge.net/project/%{name}/%{name}/%{version}/%{name}-%{version}.tar.bz2
Source2:        init.nbd-server
Patch2:         nbd-2.9.25-close.diff
Patch3:         nbd-2.9.25-doxyfile.diff
Suggests:       nbd-doc
%endif
Release:        0
Summary:        Network Block Device Server and Client Utilities
License:        GPL-2.0+
Group:          Productivity/Networking/Other
Url:            http://nbd.sourceforge.net/
Prefix:         /usr
BuildRoot:      %{_tmppath}/%{name}-%{version}-build


%description
This package contains nbd-server. It is the server backend for the nbd
network block device driver that's in the Linux kernel.

nbd can be used to have a filesystem stored on another machine. It does
provide a block device, not a file system; so unless you put a
clustering filesystem on top of it, you can't access it simultaneously
from more than one client. Use NFS or a real cluster FS (such as 
ocfs2) if you want to do this. nbd-server can export a file (which may
contain a filesystem image) or a partition. Swapping over nbd is
possible as well, though it's said not to be safe against OOM and
should not be used for that case. nbd-server also has a copy-on-write
mode where changes are saved to a separate file and thrown away when
the connection closes.

The package also contains the nbd-client tools, which you need to
configure the nbd devices on the client side.



Authors:
--------
    Wouter Verhelst <wouter@debian.org>
    Anton Altaparmakov <aia21@cam.ac.uk>
    Pavel Machek <pavel@ucw.cz>
    Paul Clements <Paul.Clements@steeleye.com>

%package doc
Summary:        Network Block Device Server and Client Utilities
Group:          Productivity/Networking/Other
Requires:       nbd = %{version}

%description doc
This package contains the HTML documentation for the network block
device (nbd) utilities.

nbd can be used to have a filesystem stored on another machine. It does
provide a block device, not a file system; so unless you put a
clustering filesystem on top of it, you can't access it simultaneously
from more than one client. Use NFS or a real cluster FS (such as 
ocfs2) if you want to do this. nbd-server can export a file (which may
contain a filesystem image) or a partition. Swapping over nbd is
possible as well, though it's said not to be safe against OOM and
should not be used for that case. nbd-server also has a copy-on-write
mode where changes are saved to a separate file and thrown away when
the connection closes.



Authors:
--------
    Wouter Verhelst <wouter@debian.org>
    Anton Altaparmakov <aia21@cam.ac.uk>
    Pavel Machek <pavel@ucw.cz>
    Paul Clements <Paul.Clements@steeleye.com>

%prep
%if %{lt_sle12_build}
%setup -q
%else
%setup
%patch2 -p1
%patch3 -p1
%endif

%build
export CFLAGS="$RPM_OPT_FLAGS -fstack-protector -fno-strict-aliasing"
./configure --with-gnu-ld --prefix=/usr --mandir=%{_mandir} \
	--infodir=%{_infodir} --libdir=%{_libdir} --libexecdir=%{_libdir} \
	--program-prefix="" --sysconfdir=/etc --build=%{_target_cpu}-suse-linux
make
%if %{ge_sle12_build}
doxygen doc/Doxyfile.in
%endif

%install
%if %{lt_sle12_build}
make install DESTDIR=$RPM_BUILD_ROOT man_MANS='nbd-client.8 nbd-server.1 nbd-server.5'
install -m 755 -d $RPM_BUILD_ROOT/usr/bin
cp nbd-client $RPM_BUILD_ROOT/usr/bin/
%else
make install DESTDIR=$RPM_BUILD_ROOT man_MANS='nbd-client.8 nbd-server.1 nbd-server.5 nbd-trdump.1'
mkdir -p $RPM_BUILD_ROOT/etc/init.d
install %SOURCE2 $RPM_BUILD_ROOT/etc/init.d/nbd-server
mkdir -p $RPM_BUILD_ROOT/usr/bin
ln -s ../../etc/init.d/nbd-server $RPM_BUILD_ROOT/usr/bin/rcnbd-server
#echo "#Port	file	options" > $RPM_BUILD_ROOT/etc/nbd-server.conf
cp nbd-client $RPM_BUILD_ROOT/usr/bin/nbd-client
mkdir -p $RPM_BUILD_ROOT/etc/nbd-server
touch $RPM_BUILD_ROOT/etc/nbd-server/config
touch $RPM_BUILD_ROOT/etc/nbd-server/allow
grep -A16 -B1 '^\[generic\]' README > $RPM_BUILD_ROOT/etc/nbd-server/config.example
%endif

%files
%defattr(-,root,root)
%attr(0755,root,root) /usr/sbin/nbd-client
%attr(0755,root,root) /usr/bin/nbd-client
%attr(0755,root,root) /usr/bin/nbd-server
%{_mandir}/man1/nbd-server.1.gz
%{_mandir}/man5/nbd-server.5.gz
%{_mandir}/man8/nbd-client.8.gz
%if %{ge_sle12_build}
%attr(0755,root,root) /usr/bin/nbd-trdump
%attr(0755,root,root) /etc/init.d/nbd-server
%attr(0755,root,root) /usr/bin/rcnbd-server
%{_mandir}/man1/nbd-trdump.1.gz
%doc README
%dir /etc/nbd-server
%ghost %config(noreplace) /etc/nbd-server/config
%ghost %config(noreplace) /etc/nbd-server/allow
%config /etc/nbd-server/config.example
%files doc
%defattr(-,root,root)
%doc doc/html
%post
%{fillup_and_insserv -f nbd-server}
if test -e /etc/nbd-server.conf; then
  # Do we have to create a generic section?
  unset generic
  if test -e /etc/nbd-server/config; then generic=1; fi
  while read port file opts; do
    if test -z "$port"; then continue; fi
    if test "${port:0:1}" = "#"; then continue; fi
    if test -z "$generic"; then
      echo -e "[generic]\n\t# No generic options yet\n" > /etc/nbd-server/config
      generic=1
    fi
    FN=${file%/*}
    nm="cvt.$port.${FN##*/}.${file##*/}"
    echo " ... convert $port $file $opts -> $nm"
    /usr/bin/nbd-server $port $file $opts -o "$nm" >> /etc/nbd-server/config
  done < /etc/nbd-server.conf
  mv /etc/nbd-server.conf /etc/nbd-server.conf.converted
fi
%postun
%{insserv_cleanup}
%restart_on_update nbd-server
%preun
%{stop_on_removal nbd-server}
%endif


%changelog

