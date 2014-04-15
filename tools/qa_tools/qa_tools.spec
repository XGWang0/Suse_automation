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
# spec file for package qa_tools (Version 0.48)
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

%define with_firewall 0

# Where to get the numbers
# http://en.opensuse.org/openSUSE:Build_Service_cross_distribution_howto
%if 0%{?suse_version} >= 1110
%define with_firewall 1
%endif

BuildRequires:  coreutils
BuildRequires:  perl
BuildRequires:  qa-config
BuildRequires:  qa_libperl

Name:           qa_tools
Version:        @@VERSION@@
Release:        0
License:        SUSE-NonFree
Summary:        rd-qa internal package for test systems
Group:          SUSE internal
Source0:        %{name}-%{version}.tar.bz2
Source1:        %{name}.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Requires:       curl
Requires:       openslp
Requires:       perl
Requires:       perl-XML-Simple
Requires:       qa-config
Requires:       qa_libperl
Requires:       coreutils
%if 0%{?sles_version} == 9
Requires:       qa_keys
%else
Recommends:     qa_keys
%endif
BuildArch:      noarch
%if %{?with_firewall}
# These are needed to configure the SUSE firewall
Requires(post):   yast2
Requires(preun):  yast2
Requires(post):   yast2-firewall
Requires(preun):  yast2-firewall
Requires(post):   yast2-ncurses
Requires(preun):  yast2-ncurses
%endif

%description
QA internal package. This package contains QA automation scripts:
reinstall.pl - reinstalls the system (GRUB systems only)
cmllist.pl - grep in systems on cml.suse.cz
product.pl - guesses the SUSE product
and others

%define destdir /usr/share/qa
%define bindir %{destdir}/tools
%define libdir %{destdir}/lib
%define homedir /root
%define fhsdir %{destdir}/keys
%define profiledir %{destdir}/profiles
%define confdir %{_sysconfdir}/qa
%if %{?with_firewall}
%define fwconfdir %{_sysconfdir}/sysconfig/SuSEfirewall2.d/services
%endif

%prep
%setup -n %{name}

%build
ln -s reinstall.pl install.pl
ln -s reinstall.pl newvm.pl
ln -s reinstall.pl winvm.pl
perl reinstall.pl --manual > reinstall.pl.8
perl newvm.pl --manual > newvm.pl.8
gzip -9 *.1 *.8
ln -s reinstall.pl.8.gz reinstall.8.gz
ln -s reinstall.pl.8.gz install.pl.8.gz
ln -s newvm.pl.8.gz newvm.8.gz

%install
install -m 755 -d %{buildroot}%{destdir}
install -m 755 -d %{buildroot}%{bindir}
install -m 755 -d %{buildroot}%{libdir}
install -m 755 -d %{buildroot}%{fhsdir}
install -m 755 -d %{buildroot}%{profiledir}
install -m 755 -d %{buildroot}%{_mandir}/man1
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 755 -d %{buildroot}%{confdir}
install -m 755 -d %{buildroot}%{_sysconfdir}/init.d
install -m 755 -d %{buildroot}%{_sbindir}
%if %{?with_firewall}
install -d %{buildroot}%{fwconfdir}
%endif
cp --target-directory=%{buildroot}%{bindir} setupIA64liloforinstall
cp --target-directory=%{buildroot}%{bindir} setupPPCliloforinstall
cp --target-directory=%{buildroot}%{bindir} setupgrubforinstall
cp --target-directory=%{buildroot}%{bindir} setupUIAutomationtest
cp -d --target-directory=%{buildroot}%{bindir} *.pl
%if %{?with_firewall}
cp --target-directory=%{buildroot}%{fwconfdir} hamsta
%endif
echo ${version} > %{buildroot}%{libdir}/qa_tools.version
cp --target-directory=%{buildroot}%{libdir} install_functions.pm
cp vimrc %{buildroot}%{fhsdir}/.vimrc
cp -d --target-directory=%{buildroot}%{_mandir}/man1 *.1.gz
cp -d --target-directory=%{buildroot}%{_mandir}/man8 *.8.gz
cp --target-directory=%{buildroot}%{_mandir}/man8 %{SOURCE1}
gzip -9 %{buildroot}%{_mandir}/man8/%{name}.8
cp --target-directory=%{buildroot}%{confdir} 00-qa_tools-default 00-qa_tools-default.*
cp -r profiles/* %{buildroot}%{profiledir}
cd %{buildroot}%{bindir}

%clean
rm -rf %{buildroot}

%post
mkdir -p %{homedir}
cp --target-directory=%{homedir} %{fhsdir}/.vimrc

# Shut down the firewall -- keeping for reference
# if [ $(which systemctl) && $(systemctl --no-pager --no-legend list-units SuSEfirewall2*) ]
# then
#     systemctl stop SuSEfirewall2
#     systemclt stop SuSEfirewall2_init
#     systemctl disable SuSEfirewall2
#     systemclt disable SuSEfirewall2_init
# elif [ -x /etc/init.d/SuSEfirewall2_init ]
# then
#     /etc/init.d/SuSEfirewall2_init stop || true
#     /etc/init.d/SuSEfirewall2_setup stop || true
#     chkconfig -d SuSEfirewall2_setup || true
#     chkconfig -d SuSEfirewall2_init || true
# fi

%if %{?with_firewall}
# Instead of disabling the firewall completely, enable the Hamsta
# service for EXTernal zone
/sbin/yast2 firewall services add zone=EXT service=service:hamsta || :
%else
if [ -x /etc/init.d/SuSEfirewall2_init ]
then
	/etc/init.d/SuSEfirewall2_init stop || true
	/etc/init.d/SuSEfirewall2_setup stop || true
	chkconfig -d SuSEfirewall2_setup || true
	chkconfig -d SuSEfirewall2_init || true
fi
%endif

%postun
%if %{?with_firewall}
/sbin/yast2 firewall services remove zone=EXT service=service:hamsta || :
%endif

%files
%defattr(0644,root,root,0755)
%dir %{destdir}
%dir %{profiledir}
%dir %{libdir}
%dir %{bindir}
%dir %{fhsdir}
%{_mandir}/man1/*
%{_mandir}/man8/*
%attr(0755,root,root) %{bindir}/*
%{libdir}/*
%{fhsdir}/.vimrc
%{profiledir}/*
%{confdir}
%if %{?with_firewall}
%{fwconfdir}/hamsta
%endif
%doc COPYING

%changelog
