# norootforbuild

Name:           qa_lib_virtauto-data
License:        GPL v2 or later
Group:          SuSE internal
Summary:        (rd-)qa package for virtualization automation - data package
AutoReqProv:    on
Version:        @@VERSION@@_110905
Release:        0
Source:         %name-%version.tar.bz2
Source1:	qa_lib_virtauto-data.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Provides:	virtautolib-data
Obsoletes:	virtautolib-data
BuildArchitectures: noarch

%description
Data for virtualization automation library


Authors:
--------
    Dan Collingridge <dcollingridge@suse.com>
    Lukas Lipavsky   <llipavsky@suse.com>

%prep
%setup -n %{name}

%build

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
mkdir -p $RPM_BUILD_ROOT/usr/share/qa/virtautolib/data
cp -a * $RPM_BUILD_ROOT/usr/share/qa/virtautolib/data
find $RPM_BUILD_ROOT/usr/share/qa/virtautolib -depth -type d -name .svn -exec rm -rf {} \;

%post

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root)
/usr/share/man/man8/qa_lib_virtauto-data.8.gz
/usr/share/qa

%changelog
