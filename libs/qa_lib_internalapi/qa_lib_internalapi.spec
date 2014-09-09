#!BuildIgnore: post-build-checks
#
# spec file for package libqainternal (Version 0.2)
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

Name:           qa_lib_internalapi
Version:        @@VERSION@@
Release:        0
License:        SUSE-NonFree, GPL-2.0+
Summary:        RD-QA internal library for easier testcase creation
Url:            http://w3d.suse.de/Dev/QA/QAInternalAPI
Group:          SuSE internal
Source0:        %{name}-%{version}.tar.bz2
Source1:        %{name}perl-%{version}.tar.bz2
Source2:        %{name}shell-%{version}.tar.bz2
Source3:        %{name}.8
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  doxygen
BuildRequires:  libpng
BuildRequires:  libtool
BuildRequires:  swig
Provides:       libqainternal
Obsoletes:      libqainternal
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
%if 0%{?suse_version} == 910
Requires:       expect
%endif

%description
Very simple shared c library for some defined api-functions for easier
or at least common test-programming inside rd-qa.

Shell implementation of the API is avilable as well within this
package.

%package perlbinding
Summary:        RD-QA internal library for easier testcase creation
Group:          SUSE internal
Requires:       perl-base
Provides:       libqainternal-perlbinding
Obsoletes:      libqainternal-perlbinding

%description perlbinding
Very simple shared c library for some defined api-functions for easier
or at least common test-programming inside rd-qa.

%prep
%setup -a1 -a2 -n %{name}
cp src/libqainternal.h %{name}perl/

%build
autoreconf -fi
%configure
make
cd %{name}perl
export LD_LIBRARY_PATH="../src/.libs"
make -f Makefile.swig clean
make -f Makefile.swig PINCLUDES=%{perl_archlib} CFLAGS="%{optflags}" CXXFLAGS="%{optflags}"
perl Makefile.PL
make CFLAGS="%{optflags}" CXXFLAGS="%{optflags}"
cd ..

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE3} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
make DESTDIR=%{buildroot} install
cd %{name}perl
make -f Makefile.swig DESTDIR=%{buildroot} LIBD=%{_libdir} install
%perl_make_install
### since 11.4 perl_process_packlist
### removes .packlist, perllocal.pod files
%if 0%{?suse_version} > 1130
%perl_process_packlist
%else
# do not perl_process_packlist
# remove .packlist file
find %{buildroot}%perl_vendorarch/auto -name .packlist -print0 |
xargs -0 -r rm ;
# remove perllocal.pod file
rm -f %{buildroot}%perl_archlib/perllocal.pod
%endif

cd ..
# install the shell implementation
install -d -m 0755 %{buildroot}%{_datadir}/qa/qa_internalapi/sh
cp -rv %{name}shell/* %{buildroot}%{_datadir}/qa/qa_internalapi/sh
ln -s /usr/share/qa/qa_internalapi/sh/libqainternal.lib.sh %{buildroot}%{_bindir}/libqainternal.lib.sh
ln -s /usr/share/qa/qa_internalapi/sh/ifconfig2ip %{buildroot}%{_bindir}/ifconfig2ip
%if 0%{?suse_version} == 910
ln -s change_password.exp %{buildroot}%{_datadir}/qa/qa_internalapi/sh/change_password
rm %{buildroot}%{_datadir}/qa/qa_internalapi/sh/change_password.sh
%else
ln -s change_password.sh %{buildroot}%{_datadir}/qa/qa_internalapi/sh/change_password
rm %{buildroot}%{_datadir}/qa/qa_internalapi/sh/change_password.exp
%endif

%clean
rm -rf %{buildroot}

%post perlbinding
ldconfig

%postun perlbinding
ldconfig

%files
%defattr(-,root,root)
%{_libdir}/libqainternal.so*
%{_libdir}/libqainternal.la
%{_includedir}/libqainternal.h
%{_datadir}/qa
%{_bindir}/demo_use
%{_mandir}/man3/*
%{_mandir}/man8/*
%{_bindir}/libqainternal.lib.sh
%{_bindir}/ifconfig2ip
%if 0%{?suse_version} == 910
%attr(0755,root,root) %{_datadir}/qa/qa_internalapi/sh/change_password.exp
%else
%attr(0755,root,root) %{_datadir}/qa/qa_internalapi/sh/change_password.sh
%endif
%doc COPYING

%files perlbinding
%defattr(-,root,root)
%{_libdir}/libqainternalperl.so*
%{perl_vendorarch}/auto/libqainternalperl
%{perl_vendorarch}/libqainternalperl.pm
%{_bindir}/demo_use_perl.pl

%changelog -n libqainternal
* Mon Dec 11 2006 - mmrazik@suse.cz
- fixed strncat compiler warning
* Fri Sep 01 2006 - mmrazik@suse.cz
- man pages added
- removeFromGroup, changePassword functions added
- addUser has a new (optional) parameter - main group
- printError/printInfo/etc aliases added
- backup is now stored in a per-process unique file
* Tue Aug 22 2006 - mmrazik@suse.cz
- build errors fixed
* Tue Aug 22 2006 - mmrazik@suse.cz
- code cleanup
* Tue Aug 15 2006 - mmrazik@suse.cz
- copy/removeConfig takes care of directories
- printMessage added to API
- homes are created in /tmp/home (addUser)
- perlbinding addapted
- minor fixes in shell API (synced with C)
* Wed Aug 09 2006 - mmrazik@suse.cz
- some minor fixes in documentation
- shell binding added
- some minor code cleanup
* Tue Jul 25 2006 - mmrazik@suse.cz
- doxygen documentation added
- some minor code cleanup
* Wed Jan 25 2006 - mls@suse.de
- converted neededforbuild to BuildRequires
* Thu Nov 17 2005 - fseidel@suse.de
- specfile fixes
* Wed Nov 16 2005 - fseidel@suse.de
- initial release
