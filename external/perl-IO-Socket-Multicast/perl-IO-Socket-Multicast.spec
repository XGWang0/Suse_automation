#
# spec file for package perl-IO-Socket-Multicast (Version 1.05)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild


Name:           perl-IO-Socket-Multicast
Version:        1.05
Release:        1
Requires:       perl
AutoReqProv:    on
Group:          Development/Libraries/Perl
License:        Artistic License; GPL v2 or later
Url:            http://search.cpan.org/~lds/IO-Socket-Multicast-1.05/Multicast.pm
Summary:        A Perl Module IO::Socket::Multicast - Send and receive multicast messages.
Source:         IO-Socket-Multicast-%{version}.tar.bz2
Source1:	perl-IO-Socket-Multicast.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%description
The IO::Socket::Multicast module subclasses IO::Socket::INET to enable
you to manipulate multicast groups. With this module (and an operating
system that supports multicasting), you will be able to receive
incoming multicast transmissions and generate your own outgoing
multicast packets.



Authors:
--------
    Lincoln Stein <lstein@cshl.org>

%prep
%setup -n IO-Socket-Multicast-%{version}

%build
perl Makefile.PL OPTIMIZE="$RPM_OPT_FLAGS"
make
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
/usr/share/man/man8/perl-IO-Socket-Multicast.8.gz
%doc README
%doc %{_mandir}/man?/*
%{perl_vendorarch}/IO/Socket/Multicast.pm
%{perl_vendorarch}/IO
%{perl_vendorarch}/IO/Socket
%{perl_vendorarch}/auto/IO/
%{perl_vendorarch}/auto/IO/Socket
%{perl_vendorarch}/auto/IO/Socket/Multicast
#%{perl_vendorlib}/IO/
#$RPM_BUILD_ROOT/IO/Socket/Multicast

%changelog
* Mon May 02 2011 vmarsik@suse.de
- workaround for redesigned %perl_process_packlist
  see http://lists.opensuse.org/opensuse-packaging/2010-11/msg00221.html
* Mon Feb 26 2007 pkirsch@suse.de
- initial package
