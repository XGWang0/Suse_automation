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


#BuildRequires:  coreutils

Name:           qa_lib_keys
Version:        @@VERSION@@
Release:        0
License:        SUSE-NonFree
Summary:        rd-qa access keys
Group:          SUSE internal
Source0:        %{name}-%{version}.tar.bz2
Source1:        qa_lib_keys.8
Requires:       coreutils
Requires:       openssh
Provides:       qa_keys
Obsoletes:      qa_keys
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
Access package - install on test systems only
- changes SSH fingerprint (same after reinstall)
- installs SSH access keys
- switches off StrictHostKeyChecking
- switches off SuSEfirewall

%define destdir /usr/share/qa
%define sshdir /root/.ssh
%define sshconfdir /etc/ssh
%define fhsdir %{destdir}/keys

%prep
%setup -n %{name}

%build

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d %{buildroot}%{fhsdir}
cp -r --target-directory=%{buildroot}%{fhsdir} ssh
cp --target-directory=%{buildroot}%{fhsdir} id_dsa id_dsa.pub known_hosts added_keys

%clean
rm -rf %{buildroot}

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

%preun -p /sbin/ldconfig

%files
%defattr(0644,root,root,0755)
%{_mandir}/man8/qa_lib_keys.8.gz
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
