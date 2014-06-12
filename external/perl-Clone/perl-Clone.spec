#
# spec file for package perl-Clone (Version 0.34)
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild


Name:           perl-Clone
Version:        0.34
Release:        1
Requires:       perl 
AutoReqProv:    on
Group:          Development/Libraries/Perl
License:        Artistic-1.0 or GPL-1.0+
Url:            http://search.cpan.org/~garu/Clone-0.37/Clone.pm 
Summary:        Clone - recursively copy Perl datatypes 
Source:         Clone-%{version}.tar.bz2
Source1:	perl-Clone.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
This module provides a clone() method which makes recursive copies of nested hash, array, scalar and reference types, including tied variables and objects.

Authors:
--------
ay Finch <rdf@cpan.org>
Breno G. de Oliveira <garu@cpan.org>
Florian Ragwitz <rafl@debian.org>

%prep
%setup -n Clone-%{version}

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

# do not perl_process_packlist
# remove .packlist file
find $RPM_BUILD_ROOT%perl_vendorarch/auto -name .packlist -print0 |
xargs -0 -r rm ;
# remove perllocal.pod file
%{__rm} -f $RPM_BUILD_ROOT%perl_archlib/perllocal.pod

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root)
%doc %{_mandir}/man?/*
%{perl_vendorarch}/Clone.pm
%{perl_vendorarch}/auto/Clone/Clone.so
%{perl_vendorarch}/auto/Clone/Clone.bs
%{perl_vendorarch}/auto/Clone/autosplit.ix

%changelog


