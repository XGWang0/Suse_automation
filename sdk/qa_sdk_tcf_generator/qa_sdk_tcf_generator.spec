#
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#

# norootforbuild

Name:           qa_sdk_tcf_generator
Version:	@@VERSION@@
Release:	0
Summary:	"find executable script ,convert to tcf format"
Group:		SUSE internal
License:	SUSE Proprietary
#PreReq:
Provides:	Novell
#BuildRequires:
Source0:		%{name}-%{version}.tar.gz
Source1:	qa_sdk_tcf_generator.8
#Patch:
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
AutoReqProv:    on

%description
tcf generator

%prep
%setup -n %{name}

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d $RPM_BUILD_ROOT/usr/local/bin
cp tcf_generator $RPM_BUILD_ROOT/usr/local/bin

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/usr/share/man/man8/qa_sdk_tcf_generator.8.gz
/usr/local/bin

%changelog
* Mon Nov 14 2011 - llipavsky@suse.cz
- New 2.2 release from QA Automation team, includes:
- Automated stage testing
- Repartitioning support during reinstall
- Possible to leave some space unparditioned during reinstall
- Added "default additional RPMs to hamsta frontend"
- Optimized hamsta mutlticast format
- Mutliple build-validation jobs
- Code cleanup
- Bugfixes
* Sun Sep 04 2011 - llipavsky@suse.cz
- New, updated release from the automation team. Includes:
- Improved virtual machine handling/QA cloud
- Rename of QA packages
- Upgrade support
- Changed format od /etc/qa files
- More teststsuites
- Many bug fixes
* Tue Aug 16 2011 - llipavsky@suse.cz
- Package rename: tcf_generator -> qa_sdk_tcf_generator
* Fri Aug 20 2010 jtang@novell.com
- initial release
