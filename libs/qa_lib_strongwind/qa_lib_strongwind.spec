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

Name:           qa_lib_strongwind
Version:        1.0
Release:        2
License:        GPL-2.0
Summary:        Desktop automation test framework
Url:            http://git.gnome.org/browse/qa_lib_strongwind
Group:          System/Packages
Source0:        strongwind-%{version}.tar.bz2
Source1:        qa_lib_strongwind.8
# PATCH-FIX-SLE
Patch0:         opsqa.patch
# PATCH-FIX-SLE
Patch1:         accessibles.patch
# PATCH-FIX-SLE
Patch2:         config.patch
BuildRequires:  python
Requires:       at-spi
Provides:       strongwind
Obsoletes:      strongwind
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%description
Desktop automation test framework, base on at-spi.

%prep
%setup -n strongwind
%patch0 -p1
%patch1 -p1
%patch2 -p1

%build

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d  %{buildroot}/%{py_libdir}/site-packages/strongwind
cp -r * %{buildroot}/%{py_libdir}/site-packages/strongwind

%clean
rm -rvf %{buildroot}

%files
%defattr(-,root,root)
%{_mandir}/man8/qa_lib_strongwind.8.gz
%{py_libdir}/site-packages/strongwind

%changelog
