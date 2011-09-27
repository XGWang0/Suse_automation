# norootforbuild

%{!?python_sitelib: %global python_sitelib %(%{__python} -c "from distutils.sysconfig import get_python_lib; print get_python_lib()")}
%{!?python_sitearch: %global python_sitearch %(%{__python} -c "from distutils.sysconfig import get_python_lib; print get_python_lib(1)")}

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
Group:          Development/Languages/Python
Version:        %{version}

%description python-psshlib
Parallel SSH library to be used in custom applications.

%prep
%setup -q -n %{name}-%{version}

%build

%install
python setup.py install --prefix=%{_prefix} --root=%{buildroot}
if [ -d %{buildroot}%{_prefix}/man/man1 ]
then
	install -m 755 -d %{buildroot}%{_mandir}
	mv %{buildroot}%{_prefix}/man/man1 %{buildroot}%{_mandir}
fi
gzip %{buildroot}%{_mandir}/man1/pssh*

%files
%defattr(-,root,root)
%{_bindir}/*
%{_mandir}/man1/*

%files python-psshlib
%defattr(-,root,root)
%{python_sitelib}/*

%changelog
* Tue Sep 27 2011 - vmarsik@suse.cz
- packed initial release


