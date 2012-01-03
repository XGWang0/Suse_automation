#
# spec file for package libqainternal (Version 0.2)
#
# Copyright (c) 2006 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

Name:           qa_lib_internalapi
BuildRequires:  doxygen libpng swig
License:        SUSE Proprietary, GPL v2 or later
Group:          SuSE internal
Autoreqprov:    on
Version:        @@VERSION@@
Release:        0
Summary:        RD-QA internal library for easier testcase creation
URL:            http://w3d.suse.de/Dev/QA/QAInternalAPI
Source0:        %{name}-%{version}.tar.bz2
Source1:        %{name}perl-%{version}.tar.bz2
Source2:        %{name}shell-%{version}.tar.bz2
Source3:	%name.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Provides:	libqainternal
Obsoletes:	libqainternal
%if 0%{?sles_version} == 9
Requires:       expect
%endif
#BuildArchitectures: noarch
#ExclusiveArch: %ix86

%description
very simple shared c-library for some defined api-functions for easier
or at least common test-programming inside rd-qa.

Shell implementation of the API is avilable as well within this
package.



Authors:
--------
    Frank Seidel <fseidel@suse.de>
    Martin Mrazik <mmrazik@suse.de>

%package perlbinding
Summary:        RD-QA internal library for easier testcase creation
Group:          SuSE internal
#Requires:       %{name}
Requires:       perl-base
Provides:	libqainternal-perlbinding
Obsoletes:	libqainternal-perlbinding

%description perlbinding
very simple shared c-library for some defined api-functions for easier
or at least common test-programming inside rd-qa



Authors:
--------
    Frank Seidel <fseidel@suse.de>

%prep
%setup -a1 -a2 -n %{name}
cp src/libqainternal.h %{name}perl/

%build
autoreconf -fi 
%configure
%{__make}
cd %{name}perl
export LD_LIBRARY_PATH="../src/.libs"
%{__make} -f Makefile.swig clean
%{__make} -f Makefile.swig PINCLUDES=%{perl_archlib} CFLAGS="$RPM_OPT_FLAGS" CXXFLAGS="$RPM_OPT_FLAGS" 
perl Makefile.PL
%{__make} CFLAGS="$RPM_OPT_FLAGS" CXXFLAGS="$RPM_OPT_FLAGS"
cd ..

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:3} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
%{__make} DESTDIR=$RPM_BUILD_ROOT install
cd %{name}perl
%{__make} -f Makefile.swig DESTDIR=$RPM_BUILD_ROOT LIBD=%{_libdir} install 
%perl_make_install
### since 11.4 perl_process_packlist
### removes .packlist, perllocal.pod files
%if 0%{?suse_version} > 1130
%perl_process_packlist
%else
# do not perl_process_packlist
# remove .packlist file
find $RPM_BUILD_ROOT%perl_vendorarch/auto -name .packlist -print0 |
xargs -0 -r rm ;
# remove perllocal.pod file
%{__rm} -f $RPM_BUILD_ROOT%perl_archlib/perllocal.pod
%endif

cd ..
# install the shell implementation
install -d -m 0755 $RPM_BUILD_ROOT/usr/share/qa/qa_internalapi/sh
cp -rv %{name}shell/* $RPM_BUILD_ROOT/usr/share/qa/qa_internalapi/sh
ln -s /usr/share/qa/qa_internalapi/sh/libqainternal.lib.sh $RPM_BUILD_ROOT/usr/bin/libqainternal.lib.sh
%if 0%{?sles_version} == 9
ln -s change_password.exp $RPM_BUILD_ROOT/usr/share/qa/qa_internalapi/sh/change_password
rm $RPM_BUILD_ROOT/usr/share/qa/qa_internalapi/sh/change_password.sh
%else
ln -s change_password.sh $RPM_BUILD_ROOT/usr/share/qa/qa_internalapi/sh/change_password
rm $RPM_BUILD_ROOT/usr/share/qa/qa_internalapi/sh/change_password.exp
%endif

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post perlbinding
ldconfig

%postun perlbinding
ldconfig

%files
%defattr(-,root,root)   
%{_libdir}/libqainternal.so*
%{_libdir}/libqainternal.la
%{_prefix}/include/libqainternal.h
%{_prefix}/share/qa
%{_prefix}/bin/demo_use
%{_prefix}/share/man/man3/*
%{_prefix}/share/man/man8/*
/usr/bin/libqainternal.lib.sh
%if 0%{?sles_version} == 9
%attr(0755,root,root) /usr/share/qa/qa_internalapi/sh/change_password.exp
%else
%attr(0755,root,root) /usr/share/qa/qa_internalapi/sh/change_password.sh
%endif
%doc COPYING

%files perlbinding
%defattr(-,root,root)
%{_libdir}/libqainternalperl.so*
%{perl_vendorarch}/auto/libqainternalperl
%{perl_vendorarch}/libqainternalperl.pm
%{_prefix}/bin/demo_use_perl.pl
#/var/adm/perl-modules/libqainternal

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
