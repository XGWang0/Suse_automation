#
# spec file for package qa_conf_unstable
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

Name:           qa_conf_unstable
License:        GPL v2 or later
Group:		QA Automation
AutoReqProv:    on
Version:        2.2.0
Release:        0
Summary:        Configutation for QA automation tools, which switches to the development (bleeding edge) servers
Source0:         %name-%version.tar.bz2
Source1:	qa_conf_unstable.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Provides:	qa-use-devel-servers qa_lib_use-devel-servers
Obsoletes:	qa-use-devel-servers qa_lib_use-devel-servers
Requires:       qa-config
BuildArchitectures: noarch

%description
This package contains set of confuguration files of QA 
Automation infrastructure tools, which swith the tools to use
the bleeding edge servers intead of the stable ones. For development
purpose only!


Authors:
--------
    Lukas Lipavsky <llipavsky@suse.cz>

%prep
%setup -q -n %{name}

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d $RPM_BUILD_ROOT/etc/qa
cp -a * $RPM_BUILD_ROOT/etc/qa

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)   
/usr/share/man/man8/qa_conf_unstable.8.gz
/etc/qa

%changelog
