# ****************************************************************************
# Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
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
# spec file for package qa_libperl (Version 0.10)
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

Name:           qa_lib_perl
Version:        @@VERSION@@
Release:        0
License:        SUSE-NonFree
Summary:        Shared QA Perl functions
Group:          SUSE internal
Source0:        %{name}-%{version}.tar.bz2
Source1:        qa_lib_perl.8
BuildRequires:  coreutils
Requires:       perl
Requires:       perl-XML-Simple
Requires:       qa-config
Provides:       qa_libperl
Obsoletes:      qa_libperl
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
QA shared Perl modules:
* log.pm - syslog-like logging in Perl
* detect.pm - local product & architecture detection

%define destdir /usr/share/qa
%define bindir %{destdir}/tools
%define libdir %{destdir}/lib
%define mandir /usr/share/man
%define confdir /etc/qa

%prep
%setup -n %{name}

%build
pod2man log.pm > log.pm.3
pod2man results.pm > results.pm.3
pod2man results/ctcs2.pm > ctcs2.pm.3
pod2man results/hazard.pm > hazard.pm.3
pod2man results/ooo.pm > ooo.pm.3

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -d %{buildroot}%{destdir}
install -d %{buildroot}%{bindir}
install -d %{buildroot}%{libdir}
install -d %{buildroot}%{mandir}/man1
install -d %{buildroot}%{mandir}/man3
install -m 755 -d %{buildroot}%{confdir}
gzip -9 *.1
gzip -9 *.3

cp -r --target-directory=%{buildroot}%{libdir} log.pm detect.pm results results.pm misc.pm benchxml.pm xmlout.pm
cp --target-directory=%{buildroot}%{bindir} arch.pl location.pl product.pl hwinfo.pl location_detect_impl.pl
cp --target-directory=%{buildroot}%{mandir}/man1 *.1.gz
cp --target-directory=%{buildroot}%{mandir}/man3 *.3.gz
cp -r --target-directory=%{buildroot}%{libdir} utils
cp --target-directory=%{buildroot}%{libdir} db_common.pm
cp --target-directory=%{buildroot}%{confdir} 00-qa_libperl-default 00-qa_libperl-default.us
echo ${version} > %{buildroot}%{libdir}/qa_libperl.version

%clean
rm -rf %{buildroot}

%files
%defattr(0644,root,root,0755)
%{_mandir}/man8/qa_lib_perl.8.gz
%dir %{destdir}
%dir %{bindir}
%dir %{libdir}
%dir %{libdir}/utils
%{mandir}/man1/*
%{mandir}/man3/*
%attr(0755,root,root) %{bindir}/*
%attr(0755,root,root) %{libdir}/utils/*
%{libdir}/*
%{confdir}
%doc COPYING

%changelog
