#
# spec file for package perl-Carp-Clan (Version 6.00)
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild


Name:           perl-Carp-Clan
BuildRequires:  perl-Test-Exception
Version:        6.00
Release:        1
Requires:       perl
AutoReqProv:    on
Group:          Development/Libraries/Perl
License:        Artistic-1.0 or GPL-1.0+
Url:            http://cpan.org/modules/by-module/Carp/
Summary:        Report Errors from the Perspective of the Caller of a "Clan" of Modules
Source:         Carp-Clan-%{version}.tar.bz2
Source1:	perl-Carp-Clan.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
This module reports errors from the perspective of the caller of a
"clan" of modules, similar to "Carp.pm" itself. But instead of giving
it a number of levels to skip on the calling stack, you give it a
pattern to characterize the package names of the "clan" of modules that
should never be blamed for errors. It makes these modules stick
together like a "clan" and any error that occurs will be blamed on the
"outsider" script or modules not belonging to this "clan".



Authors:
--------
    Steffen Beyer <sb@engelschall.com>

%prep
%setup -q -n Carp-Clan-%{version}

%build
perl Makefile.PL
make

%check
make test

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
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
for i in `ls *.txt`; do mv $i `basename $i .txt`; done

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root)
/usr/share/man/man8/perl-Carp-Clan.8.gz
%doc Artistic Changes GNU_GPL README
%doc %{_mandir}/man?/*
%{perl_vendorlib}/Carp

%changelog
* Mon May 02 2011 vmarsik@suse.cz
- workaround to build on newer products
  see http://lists.opensuse.org/opensuse-packaging/2010-11/msg00221.html
* Mon Feb 25 2008 anicka@suse.cz
- update to 6.00
  * Removed the circular dependency on Object::Deadly. It was only
  used for testing and would only succeed if you already had O::D
  installed.
* Mon Jun 18 2007 anicka@suse.cz
- update to 5.9
  * Test::Exceptions is mandatory for testing.
  * bugfix
* Wed Dec 13 2006 anicka@suse.cz
- update to 5.8
  * Stop testing that ->VERSION is a specific thing.
* Thu Oct 05 2006 anicka@suse.cz
- update to 5.7
  * Stop PAUSE from attempting to index DB package.
  * test fixes
  * bugfixes
  * Use named lexicals in diag().
  * Use exists &foo/defined &foo instead of symbol table hackery.
  * Changed f() so it accepts 1st parameter of
  carp/cluck/confess/croak instead of 1/2/3/4.
  * Renamed files.
* Mon Sep 25 2006 anicka@suse.cz
- update to 5.4
  *  Made Carp::Clan safe for overloaded objects.
  *  Added diag() to 01_..._carp.t
* Wed Jan 25 2006 mls@suse.de
- converted neededforbuild to BuildRequires
* Mon Aug 01 2005 mjancar@suse.cz
- initial version 5.3
