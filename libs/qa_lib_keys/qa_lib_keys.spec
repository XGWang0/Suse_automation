#
# spec file for package qa_tools (Version 0.34)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

#BuildRequires:  coreutils

Name:           qa_lib_keys
License:        GPL v2 or later
Group:          SUSE internal
AutoReqProv:    on
Version:        2.2.0
Release:        0
Summary:        rd-qa access keys
#Url:          http://qa.suse.de/hamsta
Source0:        %{name}-%{version}.tar.bz2
Source1:	qa_lib_keys.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Provides:	qa_keys
Obsoletes:	qa_keys
Requires:       openssh
BuildArch:      noarch
PreReq:         coreutils

%description
Changes SSH fingerprint and installs SSH access keys. Install only
on test systems.



Authors:
--------
    Vilem Marsik <vmarsik@suse.cz>

%define destdir /usr/share/qa
%define sshdir /root/.ssh
%define sshconfdir /etc/ssh
%define fhsdir %{destdir}/keys

%prep
%setup -n %{name}

%build

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d $RPM_BUILD_ROOT%{fhsdir}
cp -r --target-directory=$RPM_BUILD_ROOT%{fhsdir} ssh
cp --target-directory=$RPM_BUILD_ROOT%{fhsdir} id_dsa id_dsa.pub known_hosts added_keys

%clean
rm -rf $RPM_BUILD_ROOT

%post
if [ -d %{sshconfdir} ]
then
  if [ ! -d %{sshconfdir}/bak ]
  then
    mkdir -p %{sshconfdir}/bak
    find %{sshconfdir} -type f -regex '.*\(key\|moduli\).*' ! -regex '.*bak.*' -exec mv -t %{sshconfdir}/bak {} \;
  fi
fi
mkdir -p %{sshdir}
mkdir -p %{sshconfdir}
cp --target-directory=%{sshconfdir} %{fhsdir}/ssh/*
if [ -f %{sshdir}/authorized_keys ]
then
    cat %{fhsdir}/id_dsa.pub >> %{sshdir}/authorized_keys
else
    cp %{fhsdir}/id_dsa.pub %{sshdir}/authorized_keys
fi
cat %{fhsdir}/added_keys >> %{sshdir}/authorized_keys
cp --target-directory=%{sshdir} %{fhsdir}/id_dsa %{fhsdir}/id_dsa.pub %{fhsdir}/known_hosts 
if [ -x /etc/init.d/sshd ]
then
    /etc/init.d/sshd try-restart
fi
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
/usr/share/man/man8/qa_lib_keys.8.gz
%dir %{destdir}
%dir %{destdir}/keys
%dir %{destdir}/keys/ssh
%attr(0600,root,root) %{fhsdir}/id_dsa
%{fhsdir}/id_dsa.pub
%{fhsdir}/added_keys
%attr(0600,root,root) %{fhsdir}/ssh/moduli
%attr(0600,root,root) %{fhsdir}/ssh/ssh_host_dsa_key
%attr(0644,root,root) %{fhsdir}/ssh/ssh_host_dsa_key.pub
%attr(0600,root,root) %{fhsdir}/ssh/ssh_host_key
%attr(0644,root,root) %{fhsdir}/ssh/ssh_host_key.pub
%attr(0600,root,root) %{fhsdir}/ssh/ssh_host_rsa_key
%attr(0644,root,root) %{fhsdir}/ssh/ssh_host_rsa_key.pub
%attr(0644,root,root) %{fhsdir}/known_hosts

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
- Package rename: qa_keys -> qa_lib_keys
* Fri Aug 13 2010 llipavsky@suse.cz
- New, updated release from the automation team.
* Fri Apr 23 2010 dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- fixed known_hosts for remote submit
* Fri Apr 11 2008 vmarsik@suse.cz
- fixed a bug that broke SSHD configuration
* Thu Apr 10 2008 vmarsik@suse.cz
- redirected output to the production QADB database
* Mon Apr 07 2008 vmarsik@suse.cz
- new benchmark parser that parses dbench, bonnie, and siege results
- fixes a bug with &warn() instead of warn()
* Fri Mar 14 2008 pkirsch@suse.de
- added setupgrubfornfsinstall utility and added Requires openslp
* Tue Mar 04 2008 vmarsik@suse.cz
- hacked to bypass FHS and build under Mbuild
* Mon Feb 04 2008 vmarsik@suse.cz
- changed MySQL_loc.pm, so that MySQL user with empty password is possible
* Tue Jan 15 2008 vmarsik@suse.cz
- fixed bugs
- made output suitable for QADB
* Thu Jan 10 2008 vmarsik@suse.cz
- created a new package
