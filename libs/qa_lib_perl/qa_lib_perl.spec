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
# spec file for package qa_libperl (Version 0.10)
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

BuildRequires:	coreutils
Name:		qa_lib_perl
License:        SUSE Proprietary
Group:		SUSE internal
AutoReqProv:	on
Version:	@@VERSION@@
Release:	0
Summary:	Shared QA Perl functions
Source0:	%{name}-%{version}.tar.bz2
Source1:	qa_lib_perl.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Provides:	qa_libperl
Obsoletes:	qa_libperl
Requires:	perl qa-config
BuildArch:	noarch

%description
QA shared Perl modules:
* log.pm - syslog-like logging in Perl
* detect.pm - local product & architecture detection

Authors:
--------
    Vilem Marsik <vmarsik@suse.cz>
    Lukas Lipavsky <llipavsky@suse.cz>

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
pod2man results/autotest.pm > autotest.pm.3
pod2man results/ctcs2.pm > ctcs2.pm.3
pod2man results/hazard.pm > hazard.pm.3
pod2man results/ooo.pm > ooo.pm.3

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -d $RPM_BUILD_ROOT%{destdir}
install -d $RPM_BUILD_ROOT%{bindir}
install -d $RPM_BUILD_ROOT%{libdir}
install -d $RPM_BUILD_ROOT%{mandir}/man1
install -d $RPM_BUILD_ROOT%{mandir}/man3
install -m 755 -d $RPM_BUILD_ROOT%{confdir}
gzip -9 *.1
gzip -9 *.3

cp -r --target-directory=$RPM_BUILD_ROOT%{libdir} log.pm detect.pm results results.pm misc.pm
cp --target-directory=$RPM_BUILD_ROOT%{bindir} arch.pl location.pl product.pl hwinfo.pl location_detect_impl.pl
cp --target-directory=$RPM_BUILD_ROOT%{mandir}/man1 *.1.gz
cp --target-directory=$RPM_BUILD_ROOT%{mandir}/man3 *.3.gz
cp -r --target-directory=$RPM_BUILD_ROOT%{libdir} utils
cp --target-directory=$RPM_BUILD_ROOT%{libdir} db_common.pm
cp --target-directory=$RPM_BUILD_ROOT%{confdir} 00-qa_libperl-default
echo ${version} > $RPM_BUILD_ROOT%{libdir}/qa_libperl.version

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(0644,root,root,0755)
/usr/share/man/man8/qa_lib_perl.8.gz
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

%changelog
* Sun Sep 04 2011 - llipavsky@suse.cz
- New, updated release from the automation team. Includes:
- Improved virtual machine handling/QA cloud
- Rename of QA packages
- Upgrade support
- Changed format od /etc/qa files
- More teststsuites
- Many bug fixes
* Tue Aug 16 2011 - llipavsky@suse.cz
- Package rename: qa_libperl -> qa_lib_perl
* Wed Aug 03 2011 - vmarsik@novell.com
- added db_common.pm, merged DB code from hamsta-master and qa_db_report
* Fri Jun 17 2011 - dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- Autotest sub-parsers (bonnie, dbench, aiostress, cerberus,
- sleeptest and disktest)
- Various bug fixes
* Wed Apr 13 2011 - dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- Improved log output
- Various bug fixes
* Thu Jan 27 2011 - llipavsky@suse.cz
- Use new QA configuration model
* Fri Jan 21 2011 - dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- Logging enhancements
- Lots of bug fixes
* Fri Jan  7 2011 - llipavsky@suse.cz
- Added filtering of hwinfo functionality. Hwinfo will be filtered during 
  result submission automatically
* Thu Dec 21 2010 dcollingridge@novell.com
- Bug fixes from the automation team
- Added hazard parser
* Wed Dec 15 2010 vmarsik@novell.com
- improved log.pm
- perldoc conversion to manpages
* Fri Aug 13 2010 llipavsky@novell.com
- New release from automation team includes:
  - update to parsers infrastructure
  - multiple result parsers are now supported
* Mon Jun 28 2010 llipavsky@novell.com
- moved results/ and results.pm from qa_db_report to qa_lib_perl
* Tue Jun 01 2010 vmarsik@novell.com
- created the package by splitting from qa_tools
- fixed arch.pl
- added missing manual pages


