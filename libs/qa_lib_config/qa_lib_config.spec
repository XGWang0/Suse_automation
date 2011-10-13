#
# spec file for package qa_config (Version 1.0)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

Name:           qa_lib_config
License:        GPL v2 or later
Group:		QA Automation
AutoReqProv:    on
Version:        @@VERSION@@
Release:        0
Summary:        Basic configutation for QA automation tools
Source0:        %name-%version.tar.bz2
Source1:	qa_lib_config.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Provides:	qa-config
Obsoletes:	qa-config
Requires:       bash
BuildArchitectures: noarch

%description
This package contains base set of tools to handle confuguration tools of QA 
Automation infrastructure tools.


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
install -m 755 -d $RPM_BUILD_ROOT/usr/share/qa/tools
install -m 755 -d $RPM_BUILD_ROOT/usr/share/qa/lib
cp -a config $RPM_BUILD_ROOT/usr/share/qa/lib
cp -a qaconfig.pm $RPM_BUILD_ROOT/usr/share/qa/lib
cp -a dump_qa_config $RPM_BUILD_ROOT/usr/share/qa/tools
cp -a 00-automation-default $RPM_BUILD_ROOT/etc/qa

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)   
/usr/share/man/man8/qa_lib_config.8.gz
/usr/share/qa
/etc/qa/

%changelog
