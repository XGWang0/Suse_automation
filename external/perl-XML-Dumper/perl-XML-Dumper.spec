#
# spec file for package perl-XML-Dumper (Version 0.81)
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild


Name:           perl-XML-Dumper
Version:        0.81
Release:        1
Requires:       perl perl-XML-Parser
BuildRequires:  perl-XML-Parser
AutoReqProv:    on
Group:          Development/Libraries/Perl
License:		Artistic; GPL v2 or later
Url:            http://search.cpan.org/~mikewong/XML-Dumper-0.81/Dumper.pm
Summary:        A Perl Module XML::Dumper - Perl module for dumping Perl objects from/to XML
Source:         XML-Dumper-%{version}.tar.bz2
Source1:	perl-XML-Dumper.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
XML::Dumper dumps Perl data to XML format. XML::Dumper can also read
XML data that was previously dumped by the module and convert it back
to Perl. You can use the module read the XML from a file and write the
XML to a file. Perl objects are blessed back to their original
packaging; if the modules are installed on the system where the perl
objects are reconstituted from xml, they will behave as expected.
Intuitively, if the perl objects are converted and reconstituted in the
same environment, all should be well. And it is.



Authors:
--------
    Mike Wong <mike_w3@pacbell.net>
    Jonathan Eisenzopf <eisen@pobox.com>

%prep
%setup -n XML-Dumper-%{version}

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
/usr/share/man/man8/perl-XML-Dumper.8.gz
%doc README
%doc %{_mandir}/man?/*
%{perl_vendorlib}/XML/Dumper.pm
%{perl_vendorlib}/XML/

%changelog
* Mon May 02 2011 vmarsik@suse.cz
- workaround for redesigned %perl_process_packlist
  see http://lists.opensuse.org/opensuse-packaging/2010-11/msg00221.html
* Mon Feb 26 2007 pkirsch@suse.de
- initial package


