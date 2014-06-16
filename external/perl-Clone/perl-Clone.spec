#
# spec file for package perl-Clone
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           perl-Clone
Version:        0.36
Release:        0
%define cpan_name Clone
Summary:        recursively copy Perl datatypes
License:        Artistic-1.0 or GPL-1.0+
Group:          Development/Libraries/Perl
Url:            http://search.cpan.org/dist/Clone/
Source:         http://www.cpan.org/authors/id/G/GA/GARU/%{cpan_name}-%{version}.tar.gz
Source1:		perl-Clone.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  perl
BuildRequires:  perl-macros
#BuildRequires: perl(Clone)
#BuildRequires: perl(Hash::Util::FieldHash)
%{perl_requires}

%description
This module provides a clone() method which makes recursive copies of
nested hash, array, scalar and reference types, including tied variables
and objects.

clone() takes a scalar argument and duplicates it. To duplicate lists,
arrays or hashes, pass them in by reference. e.g.

    my $copy = clone (\@array);

    # or

    my %copy = %{ clone (\%hash) };

%prep
%setup -q -n %{cpan_name}-%{version}
find . -type f -print0 | xargs -0 chmod 644

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor OPTIMIZE="%{optflags}"
%{__make} %{?_smp_mflags}

%check
%{__make} test

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
%perl_make_install
%perl_process_packlist
%perl_gen_filelist

%files -f %{name}.files
%defattr(-,root,root,755)
%doc Changes

%changelog
