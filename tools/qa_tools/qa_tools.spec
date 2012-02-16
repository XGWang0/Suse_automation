# ****************************************************************************
# Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
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
# spec file for package qa_tools (Version 0.48)
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

BuildRequires:  coreutils perl qa_libperl qa-config

Name:           qa_tools
License:        SUSE Proprietary
Group:          SUSE internal
AutoReqProv:    on
Version:        @@VERSION@@
Release:        0
Summary:        rd-qa internal package for test systems
#Url:          http://qa.suse.de/hamsta
Source0:         %{name}-%{version}.tar.bz2
Source1:	%name.8
#Patch:        %{name}-%{version}.patch
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
%if 0%{?sles_version} == 9
Requires:       perl perl-XML-Simple openslp curl qa_keys qa_libperl qa-config
%else
Requires:       perl perl-XML-Simple openslp curl qa_libperl qa-config
Recommends:     qa_keys
%endif
BuildArch:      noarch
PreReq:         coreutils

%description
QA internal package. This package contains QA automation scripts:
reinstall.pl - reinstalls the system (GRUB systems only)
cmllist.pl - grep in systems on cml.suse.cz
product.pl - guesses the SuSE product
and others


Authors:
--------
    Vilem Marsik <vmarsik@suse.cz>
    Patrick Kirsch <pkirsch@suse.de>

%define destdir /usr/share/qa
%define bindir %{destdir}/tools
%define libdir %{destdir}/lib
%define homedir /root
%define fhsdir %{destdir}/keys
%define profiledir %{destdir}/profiles
%define mandir	/usr/share/man
%define confdir /etc/qa


%prep
%setup -n %{name}
#%patch

%build
ln -s reinstall.pl install.pl
ln -s reinstall.pl newvm.pl
perl reinstall.pl --manual > reinstall.pl.8
perl newvm.pl --manual > newvm.pl.8
gzip -9 *.1 *.8
ln -s reinstall.pl.8.gz reinstall.8.gz
ln -s reinstall.pl.8.gz install.pl.8.gz
ln -s newvm.pl.8.gz newvm.8.gz

%install
install -m 755 -d $RPM_BUILD_ROOT%{destdir}
install -m 755 -d $RPM_BUILD_ROOT%{bindir}
install -m 755 -d $RPM_BUILD_ROOT%{libdir}
install -m 755 -d $RPM_BUILD_ROOT%{fhsdir}
install -m 755 -d $RPM_BUILD_ROOT%{profiledir}
install -m 755 -d $RPM_BUILD_ROOT%{mandir}/man1
install -m 755 -d $RPM_BUILD_ROOT%{mandir}/man8
install -m 755 -d $RPM_BUILD_ROOT%{confdir}
install -m 755 -d $RPM_BUILD_ROOT%{_sysconfdir}/init.d
install -m 755 -d $RPM_BUILD_ROOT%{_sbindir}
cp --target-directory=$RPM_BUILD_ROOT%{bindir} setupIA64liloforinstall
cp --target-directory=$RPM_BUILD_ROOT%{bindir} setupPPCliloforinstall
cp --target-directory=$RPM_BUILD_ROOT%{bindir} setupgrubforinstall
cp -d --target-directory=$RPM_BUILD_ROOT%{bindir} *.pl
echo ${version} > $RPM_BUILD_ROOT%{libdir}/qa_tools.version
cp --target-directory=$RPM_BUILD_ROOT%{libdir} install_functions.pm
cp vimrc $RPM_BUILD_ROOT%{fhsdir}/.vimrc
cp -d --target-directory=$RPM_BUILD_ROOT%{mandir}/man1 *.1.gz
cp -d --target-directory=$RPM_BUILD_ROOT%{mandir}/man8 *.8.gz
cp --target-directory=$RPM_BUILD_ROOT%{mandir}/man8 %{S:1}
gzip -9 $RPM_BUILD_ROOT%{mandir}/man8/%{name}.8
cp --target-directory=$RPM_BUILD_ROOT%{confdir} 00-qa_tools-default 00-qa_tools-default.*
cp -r profiles/* $RPM_BUILD_ROOT%{profiledir}
cd $RPM_BUILD_ROOT%{bindir}


%clean
rm -rf $RPM_BUILD_ROOT

%post
mkdir -p %{homedir}
cp --target-directory=%{homedir} %{fhsdir}/.vimrc
if [ -x /etc/init.d/SuSEfirewall2_init ]
then
    /etc/init.d/SuSEfirewall2_init stop || true
    /etc/init.d/SuSEfirewall2_setup stop || true
    chkconfig -d SuSEfirewall2_setup || true
    chkconfig -d SuSEfirewall2_init || true
fi
echo "Your system has been hacked successfuly."

%preun

%files
%defattr(0644,root,root,0755)
%dir %{destdir}
%dir %{profiledir}
%dir %{libdir}
%dir %{bindir}
%dir %{fhsdir}
%{mandir}/man1/*
%{mandir}/man8/*
%attr(0755,root,root) %{bindir}/*
%{libdir}/*
%{fhsdir}/.vimrc
%{profiledir}/*
%{confdir}
%doc COPYING

%changelog

