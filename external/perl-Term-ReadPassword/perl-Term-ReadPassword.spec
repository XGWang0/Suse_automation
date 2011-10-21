#
# spec file for package perl-Term-ReadPassword (Version 0.11)
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild


Name:           perl-Term-ReadPassword
Version:        0.11
Release:        2
Requires:       perl
AutoReqProv:    on
Group:          Development/Libraries/Perl
License:		GPL v2
Url:            http://cpan.org/modules/by-module/Term/
Summary:        Term::ReadPassword - Asking the user for a password
Source:         Term-ReadPassword-%{version}.tar.bz2
Source1:	perl-Term-ReadPassword.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
This module lets you ask the user for a password in the traditional
way, from the keyboard, without echoing.

This is not intended for use over the web; user authentication over the
web is another matter entirely. Also, this module should generally be
used in conjunction with Perl's crypt() function, sold separately.



Authors:
--------
    Tom Phoenix <rootbeer@redcat.com>

%prep
%setup -n Term-ReadPassword-%{version} -q

%build
perl Makefile.PL
make

%check
mv t/2_interactive.t t/2_interactive.tt #disable interactive testing
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
/usr/share/man/man8/perl-Term-ReadPassword.8.gz
%doc 
%doc %{_mandir}/man?/*
%dir %{perl_vendorlib}/Term
%{perl_vendorlib}/Term/*

%changelog
* Mon May 02 2011 vmarsik@suse.cz
- workaround for redesigned %perl_process_packlist
  see http://lists.opensuse.org/opensuse-packaging/2010-11/msg00221.html
* Thu Mar 13 2008 anicka@suse.cz
- package created (version 0.11)


