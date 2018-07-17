#
# spec file for package qa_lib_config
#
# Copyright (c) 2016 SUSE LINUX GmbH, Nuernberg, Germany.
# Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
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


Name:           qa_lib_config
Version:        @@VERSION@@
Release:        0
Summary:        Basic configuration for QA automation tools
License:        SUSE-NonFree
Group:          QA Automation
Source0:        %{name}-%{version}.tar.bz2
Source1:        qa_lib_config.8
Requires:       bash
Provides:       qa-config
Obsoletes:      qa-config
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
This package contains base set of tools to handle configuration tools of QA
Automation infrastructure tools.

%prep
%setup -q -n %{name}

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d %{buildroot}%{_sysconfdir}/qa
install -m 755 -d %{buildroot}%{_datadir}/qa/tools
install -m 755 -d %{buildroot}%{_datadir}/qa/lib
cp -a config %{buildroot}%{_datadir}/qa/lib
cp -a qaconfig.pm %{buildroot}%{_datadir}/qa/lib
cp -a dump_qa_config %{buildroot}%{_datadir}/qa/tools
cp -a get_qa_config %{buildroot}%{_datadir}/qa/tools
cp -a sync_qa_config %{buildroot}%{_datadir}/qa/tools
cp -a 00-automation-default %{buildroot}%{_sysconfdir}/qa

%files
%defattr(-,root,root)
%{_mandir}/man8/qa_lib_config.8%{ext_man}
%{_datadir}/qa
%{_sysconfdir}/qa/
%doc COPYING

%changelog
