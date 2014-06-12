#
# spec file for package perl-XML-Bare (Version 0.53)
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild


Name:           perl-XML-Bare
Version:        0.53
Release:        1
Requires:       perl 
AutoReqProv:    on
Group:          Development/Libraries/Perl
License:        Artistic-1.0 or GPL-1.0+
Url:            http://search.cpan.org/~codechild/XML-Bare-0.53/Bare.pm 
Summary:        XML::Bare - Minimal XML parser implemented via a C state engine 
Source:         XML-Bare-%{version}.tar.bz2
Source1:	perl-XML-Bare.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
This module is a 'Bare' XML parser. It is implemented in C.
The parser itself is a simple state engine that is less than 500 
lines of C. The parser builds a C struct tree from input text.
That C struct tree is converted to a Perl hash by a Perl function 
that makes basic calls back to the C to go through the nodes sequentially.

Authors:
--------

%prep
%setup -n XML-Bare-%{version}

%build
perl Makefile.PL OPTIMIZE="$RPM_OPT_FLAGS" 
make

%check
make test

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
#make DESTDIR=$RPM_BUILD_ROOT install_site 
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
%{perl_vendorarch}/XML/Bare.pm
%{perl_vendorarch}/auto/XML/Bare/Bare.so
%{perl_vendorarch}/auto/XML/Bare/Bare.bs

%changelog


