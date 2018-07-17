#
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#


Name:           qa_sdk_spec_generator
Version:        @@VERSION@@
Release:        0
License:        SUSE-NonFree
Summary:        Spec file generator
Group:          SUSE internal
Source0:        %{name}-%{version}.tar.bz2
Source1:        qa_sdk_spec_generator.8
Provides:       Novell
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
This is a helper to create spec files.

%prep
%setup -n %{name}

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d %{buildroot}%{_prefix}/bin
cp spec_generator %{buildroot}%{_prefix}/bin

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root)
%{_mandir}/man8/qa_sdk_spec_generator.8.gz
%{_bindir}/spec_generator

%changelog
