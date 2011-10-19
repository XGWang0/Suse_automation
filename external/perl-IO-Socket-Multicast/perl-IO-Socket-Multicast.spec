# ****************************************************************************
# Copyright © 2011 Unpublished Work of SUSE. All Rights Reserved.
# 
# THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
# CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
# RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
# THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
# THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
# TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
# PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
# PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
# AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
# LIABILITY.
# 
# SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
# AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
# LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
# WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
# ****************************************************************************
#

#
# spec file for package perl-IO-Socket-Multicast (Version 1.05)
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
License:		SUSE Proprietary
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

