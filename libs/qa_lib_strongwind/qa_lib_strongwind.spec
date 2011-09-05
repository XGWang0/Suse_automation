#
# Copyright (c) 2009 SUSE LINUX Products GmbH, Nuernberg, Germany.
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
License:        GPL v2 or later
Group:          System/Packages
Summary:        Desktop automation test framework
Provides:	strongwind
Obsoletes:	strongwind
Requires:       at-spi
BuildRequires:  python
AutoReqProv:    on
URL:            http://git.gnome.org/browse/qa_lib_strongwind
Version:        1.0
Release:        2
Source0:        strongwind-%version.tar.bz2
Source1:	qa_lib_strongwind.8
Patch0:         opsqa.patch
Patch1:         accessibles.patch
Patch2:	        config.patch
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
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d  $RPM_BUILD_ROOT/%{py_libdir}/site-packages/strongwind
cp -r * $RPM_BUILD_ROOT/%{py_libdir}/site-packages/strongwind

%clean
rm -rvf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)   
/usr/share/man/man8/qa_lib_strongwind.8.gz
%{py_libdir}/site-packages/strongwind

%changelog
* Sun Sep 04 2011 - llipavsky@suse.cz
- New, updated release from the automation team. Includes:
- Improved virtual machine handling/QA cloud
- Rename of QA packages
- Upgrade support
- Changed format od /etc/qa files
- More teststsuites
- Many bug fixes
* Tue Aug 16 2011 - llipavsky@suse.cz
- Package rename: strongwind -> qa_lib_strongwind
* Wed Jun 29 2011 cachen@novell.com
- Using config.patch to fix normal user permission deny to create log problem
* Wed Jun 22 2011 cachen@novell.com
- Fix None parent issue in __getattr__
* Tue May 24 2011 cachen@novell.com
- Kill the exist application before running launchApplication(), using launchapp.patch
* Mon Nov 22 2010 cachen@novell.com
- Using procedurelogger.patch to correct try...except... error
* Wed Sep 8 2010 llwang@novell.com
- Modify package as third party style, using opsqa.patch
* Wed Mar 3 2010 llwang@novell.com
- Initial strongwind test framework for SLED desktop test
