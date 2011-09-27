Name:		pssh
Version:	2.2.2
Release:	1
License:	BSD 2-Clause
Group:		Productivity/Networking/SSH
Summary:	Parallel SSH tools
Source:		%{name}-%{version}.tar.bz2
URL:		http://code.google.com/p/parallel-ssh
Requires:	python openssh python-psshlib=%{version}-%{release}
BuildRequires:	python python-setuptools
BuildArch:	noarch

%description
Authors: Brent N. Chun, Andrew McNabb
Parallel SSH
PSSH provides parallel versions of OpenSSH and related tools. 
Included are pssh, pscp, prsync, pnuke, and pslurp.

%package python-psshlib
Summary:        Parallel SSH library for Python
Group:          Development/Python
Version:        %{version}

%description python-psshlib
Parallel SSH library to be used in custom applications.

%prep
%setup -q -n %{name}-%{version}

%build

%install
python setup.py install --prefix=%{_prefix} --root=%{buildroot}
install -m 755 -d $RPM_BUILD_ROOT%{_mandir}
mv $RPM_BUILD_ROOT%{_prefix}/man/man1 $RPM_BUILD_ROOT%{_mandir}
gzip $RPM_BUILD_ROOT%{_mandir}/man1/*

%files
%defattr(-,root,root)
%{_bindir}/*
%{_mandir}/man1/*

%files python-psshlib
%{python_sitelib}/*

%changelog
* Tue Sep 27 2011 - vmarsik@suse.cz
- packed initial release


