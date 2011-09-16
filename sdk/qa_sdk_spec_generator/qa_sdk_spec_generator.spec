#
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#

# norootforbuild

Name:           qa_sdk_spec_generator
Version:	2.1.0
Release:	0
Summary:	"generate a .spec file"
Group:		SUSE internal
License:	GPL v2 or later
Provides:	Novell
Source0:		%{name}-%{version}.tar.bz2
Source1:	qa_sdk_spec_generator.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
AutoReqProv:    on

%description
Spec generator 


%prep
%setup -n %{name}

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d $RPM_BUILD_ROOT/usr/bin
cp spec_generator $RPM_BUILD_ROOT/usr/bin
%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root)
/usr/share/man/man8/qa_sdk_spec_generator.8.gz
/usr/bin/qa_sdk_spec_generator

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
- Package rename: spec_generator -> qa_sdk_spec_generator
* Fri Aug 27 2010 - jtang@novell.com
- initial release

