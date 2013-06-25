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
# spec file for package qa_tools (Version 0.34)
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

#BuildRequires:  coreutils

Name:           qa_lib_keys
License:        SUSE Proprietary
Group:          SUSE internal
AutoReqProv:    on
Version:        @@VERSION@@
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
Access package - install on test systems only
- changes SSH fingerprint (same after reinstall)
- installs SSH access keys
- switches off StrictHostKeyChecking
- switches off SuSEfirewall

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
# back up old SSH server keys, unless already done
if [ -d %{sshconfdir} ]
then
  if [ ! -d %{sshconfdir}/bak ]
  then
    mkdir -p %{sshconfdir}/bak
    find %{sshconfdir} -type f -regex '.*\(key\|moduli\).*' ! -regex '.*bak.*' -exec mv -t %{sshconfdir}/bak {} \;
  fi
fi
# install SSH server keys from the package
mkdir -p %{sshdir}
mkdir -p %{sshconfdir}
cp --target-directory=%{sshconfdir} %{fhsdir}/ssh/*
# install root's authorized_keys
if [ -f %{sshdir}/authorized_keys ]
then
    cat %{fhsdir}/id_dsa.pub >> %{sshdir}/authorized_keys
else
    cp %{fhsdir}/id_dsa.pub %{sshdir}/authorized_keys
fi
cat %{fhsdir}/added_keys >> %{sshdir}/authorized_keys
# install root's keys
cp --target-directory=%{sshdir} %{fhsdir}/id_dsa %{fhsdir}/id_dsa.pub %{fhsdir}/known_hosts 
if [ -x /etc/init.d/sshd ]
then
    /etc/init.d/sshd try-restart
fi
# switch off StrictHostKeyChecking
FILE=/etc/ssh/ssh_config
if grep '#\?\([ \t]\+\)StrictHostKeyChecking' $FILE >/dev/null 2>/dev/null
then
	sed -i 's/#\?\([ \t]\+\)\(StrictHostKeyChecking\)\(.\+\)/\1\2 no/' $FILE
else
	echo "StrictHostKeyChecking no" >> $FILE
fi
# shut down firewall
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
%doc COPYING

%changelog
* Fri Jan 18 2013 - llipavsky@suse.com
- New 2.5 release from QA Automation team
- Authentication and Authorization in Hamsta
- ctcs2 improvements, speedup, and new tcf commands
- New SUT can be added to Hamsta from hamsta web interface
- Timezone support in reinstall
- Reinstall can now be done using kexec
- Centralized configuration of SUTs
- Sessions support in Hamsta
- AutoPXE now supports ia64 architecture
- Hamsta is no longer configured using config.php, config.ini is used instead
- ...and many small improvements and bug fixes
* Fri Aug 10 2012 - llipavsky@suse.cz
- Web user-friendly editor for jobs
- HA Server yast2 UI Automation
- Build mapping in QADB (buildXXX -> beta Y)
- Improved regression analysis
- Support for benchmark parsers in benchmark testsuite (author of testsuite will also provide a script to parse the results)
- Power switch support in Hamsta (thanks mpluskal!)
- Only results created in the job are submitted to QADB
- QADB improvements
* Wed May 2 2012 - llipavsky@suse.cz
- New 2.3 release from QA Automation team, includes: 
- out-of date and developement SUTs are marked in web frontend and can be updated from the frontend 
- HA Server yast2-cluster UI Automation 
- Improved CLI interface to Hamsta 
- It is possible to get/choose all patterns from all products during SUT intallation (until now, only SLES/D & SDK patterns were shown) 
- Parametrized jobs 
- Better web editors of jobs. Now with multimachine job support 
- Hamsta client one-click installer 
- QADB improvements 
- No more Novell icon in Hamsta ;-)
* Mon Nov 14 2011 - llipavsky@suse.cz
- New 2.2 release from QA Automation team, includes:
- Automated stage testing
- Repartitioning support during reinstall
- Possible to leave some space unparditioned during reinstall
- Added "default additional RPMs to hamsta frontend"
- Optimized hamsta mutlticast format
- Mutliple build-validation jobs
- Code cleanup
- Bugfixes
* Mon Oct 17 2011 - vmarsik@suse.cz
- added switching off StrictHostKeyChecking
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

