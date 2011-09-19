# norootforbuild

Name:           qa_lib_virtauto
License:        GPL v2 or later
Group:          SuSE internal
Summary:        (rd-)qa package for virtualization automation
Provides:	virtautolib
Obsoletes:	virtautolib
Requires:       ssh libvirt perl-XML-XPath qa_keys expect sshpass qa_libperl virtautolib-data
%if 0%{?sles_version} == 10
Requires:       xen-tools
%else
Requires:	vm-install
%endif
AutoReqProv:    on
Version:        @@VERSION@@
Release:        0
Source:         %name-%version.tar.bz2
Source1:	qa_lib_virtauto.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArchitectures: noarch

%description
QA library for virtualization automation


Authors:
--------
    Dan Collingridge <dcollingridge@novell.com>
    Lukas Lipavsky   <llipavsky@suse.cz>

%prep
%setup -n %{name}

%build

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d $RPM_BUILD_ROOT/usr/share/qa/virtautolib
cp -a * $RPM_BUILD_ROOT/usr/share/qa/virtautolib
find $RPM_BUILD_ROOT/usr/share/qa/virtautolib -depth -type d -name .svn -exec rm -rf {} \;

%post

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root)
/usr/share/man/man8/qa_lib_virtauto.8.gz
/usr/share/qa

%changelog
