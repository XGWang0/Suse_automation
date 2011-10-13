#
# spec file for package perl-XML-Simple (Version 2.18)
#
# Copyright (c) 2007 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

Name:           perl-XML-Simple
BuildRequires:  perl-XML-Parser
Version:        2.18
Release:        1
Requires:       perl-XML-Parser
Requires:       perl
AutoReqProv:    on
Group:          Development/Libraries/Perl
License:        Artistic License; GPL v2 or later
Url:            http://cpan.org/modules/by-module/XML/
Summary:        Easy API to read/write XML (Perl module)
Source:         XML-Simple-%{version}.tar.bz2
Source1:	perl-XML-Simple.8
Patch:          XML-Simple-%{version}-test.diff
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
XML::Simple - Easy API to read/write XML (esp config files)



Authors:
--------
    Grant McLean <grantm@cpan.org>

%prep
%setup -q -n XML-Simple-%{version}
%patch

%build
perl Makefile.PL
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
/usr/share/man/man8/perl-XML-Simple.8.gz
%doc Changes README
%doc %{_mandir}/man?/*
%{perl_vendorlib}/XML

%changelog
* Mon May 02 2011 - vmarsik@suse.cz
- workaround for redesigned %perl_process_packlist
  see http://lists.opensuse.org/opensuse-packaging/2010-11/msg00221.html
* Mon Oct 08 2007 - anicka@suse.cz
- update to 2.18
  * Non-unique key attribute values now trigger a warning (or a fatal
  error in strict mode) rather than silently discarding data
  * Added parse_string(), parse_file() and parse_fh() methods
  * Added default_config_file(), and build_simple_tree() hook methods
  * Tweak to implementation of exporting
  * Documented hook methods
  * Fixed test suite race condition
* Mon Jul 16 2007 - anicka@suse.cz
- remove expat from dependencies
* Wed Dec 13 2006 - anicka@suse.cz
- update to 2.16
  * Added test/fix for bad GroupTags option
  * Added new_hashref() hook method
  * refactored cache save/restore methods for easier overriding
* Thu Oct 05 2006 - anicka@suse.cz
- update to 2.15
  * Makefile.PL changes: reject known-bad PurePerl and RTF parser
  modules; default to XML::SAX::Expat if no parser installed
  * allow '.' characters in variable names
  * fix output of undefs in arrayrefs with SuppressEmpty
  * tidy up code and docs around lexical filehandle
  passed to OutputFile
  * reduce memory usage by passing XML strings by reference
* Wed Jan 25 2006 - mls@suse.de
- converted neededforbuild to BuildRequires
* Mon Aug 01 2005 - mjancar@suse.cz
- update to 2.14
* Thu Aug 19 2004 - mjancar@suse.cz
- update to 2.12
* Thu Feb 26 2004 - mjancar@suse.cz
- update to 2.09
* Sun Jan 11 2004 - adrian@suse.de
- build as user
* Fri Aug 22 2003 - mjancar@suse.cz
- require the perl version we build with
* Thu Aug 07 2003 - mjancar@suse.cz
- fix tests that depend on certain order of entries
  in a hash (it is random in perl 5.8.1)
* Thu Jul 24 2003 - mjancar@suse.cz
- update to 2.08
* Thu Jul 17 2003 - mjancar@suse.cz
- adapt to perl-5.8.1
- use %%perl_process_packlist
* Wed Jun 18 2003 - coolo@suse.de
- package directories
* Mon Jun 16 2003 - mjancar@suse.cz
- don't package MANIFEST
* Mon May 19 2003 - ro@suse.de
- remove perllocal.pod
* Tue Apr 29 2003 - mjancar@suse.cz
- update to version 2.03
* Fri Dec 27 2002 - prehak@suse.cz
- updated to version 2.02
* Mon Jul 29 2002 - mls@suse.de
- Fixed neededforbuild for perl-5.8.0
* Tue Jul 02 2002 - mls@suse.de
- remove race in .packlist generation
* Tue Jul 02 2002 - garloff@suse.de
- Update to 1.08: (rerelease of 1.06 with minor bugfixes)
  * searchpath set to current dir if not set
  * obsolete 'convert' script removed from dist
* Thu Jan 17 2002 - garloff@suse.de
- Creation of package perl-XML-Simple (1.06)
  (needed by InterMezzo)
