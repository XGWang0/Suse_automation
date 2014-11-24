#
# spec file for package perl-Proc-Fork (Version 0.61)
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild


Name:           perl-Proc-Fork
Version:        0.61
Release:        1
Requires:       perl
AutoReqProv:    on
Group:          Development/Libraries/Perl
License:        Artistic-1.0 or GPL-1.0+
Url:            http://search.cpan.org/~aristotle/Proc-Fork-0.61/lib/Proc/Fork.pm
Summary:        Perl Module Proc::Fork - Simple, intuitive interface to the fork() system call
Source:         Proc-Fork-%{version}.tar.bz2
Source1:	perl-Proc-Fork.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%description
This module provides an intuitive, Perl-ish way to write forking
programs by letting you use blocks to illustrate which code section
executes in which fork. The code for the parent, child, retry handler
and error handler are grouped together in a "fork block". The clauses
may appear in any order, but they must be consecutive (without any
other statements in between).



Authors:
--------
     Aristotle Pagaltzis, <pagaltzis@gmx.de>

%prep
%setup -n Proc-Fork-%{version}

%build
perl Makefile.PL OPTIMIZE="$RPM_OPT_FLAGS"
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

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root)
/usr/share/man/man8/perl-Proc-Fork.8.gz
%doc README
%doc %{_mandir}/man?/*
%{perl_vendorlib}/Proc/Fork.pm
%{perl_vendorlib}/Proc/
%{perl_vendorarch}/auto/Proc/Fork
%{perl_vendorarch}/auto/Proc/

%changelog
* Mon May 02 2011 vmarsik@suse.de
- workaround for redesigned %perl_process_packlist
* Mon Feb 26 2007 pkirsch@suse.de
- initial package
