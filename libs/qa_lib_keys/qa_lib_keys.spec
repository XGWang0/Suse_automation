#
# spec file for package qa_lib_keys
#
# Copyright (c) 2016 SUSE LINUX GmbH, Nuernberg, Germany.
# Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


#BuildRequires:  coreutils
Name:           qa_lib_keys
Version:        @@VERSION@@
Release:        0
Summary:        rd-qa access keys
License:        SUSE-NonFree
Group:          SUSE internal
Source0:        %{name}-%{version}.tar.bz2
Source1:        qa_lib_keys.8
Requires:       coreutils
Requires:       openssh
Requires(post): yast2
Requires(post): yast2-firewall
Requires(post): yast2-ncurses
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

%define destdir %{_datadir}/qa
%define sshdir /root/.ssh
%define sshconfdir %{_sysconfdir}/ssh
%define fhsdir %{destdir}/keys

%prep
%setup -q -n %{name}

%build

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d %{buildroot}%{fhsdir}
cp -r --target-directory=%{buildroot}%{fhsdir} ssh
cp --target-directory=%{buildroot}%{fhsdir} id_dsa id_dsa.pub id_rsa id_rsa.pub known_hosts added_keys

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
    cat %{fhsdir}/id_rsa.pub >> %{sshdir}/authorized_keys
else
    cp %{fhsdir}/id_dsa.pub %{sshdir}/authorized_keys
    cat %{fhsdir}/id_rsa.pub >> %{sshdir}/authorized_keys
fi
cat %{fhsdir}/added_keys >> %{sshdir}/authorized_keys
# install root's keys
cp --target-directory=%{sshdir} %{fhsdir}/id_dsa %{fhsdir}/id_dsa.pub %{fhsdir}/known_hosts %{fhsdir}/id_rsa.pub %{fhsdir}/id_rsa
if [ -x %{_initddir}/sshd ]
then
    %{_initddir}/sshd try-restart
fi
# switch off StrictHostKeyChecking
FILE=%{_sysconfdir}/ssh/ssh_config
if grep '#\?\([ \t]\+\)StrictHostKeyChecking' $FILE >/dev/null 2>/dev/null
then
	sed -i 's/#\?\([ \t]\+\)\(StrictHostKeyChecking\)\(.\+\)/\1\2 no/' $FILE
else
	echo "StrictHostKeyChecking no" >> $FILE
fi
# Add an exception for sshd to SUSE firewall. No service restart
# needed.



%if 0%{?suse_version} >= 1110
	#we ignore the setting during chroot
	if  ps -ef|grep -q 'root /mnt.*mnt\/var' ;then
		:
	else
		yast2 firewall services add service=service:sshd zone=EXT || :
	fi

%else
	#we ignore the setting during chroot
	if  ps -ef|grep -q 'root /mnt.*mnt\/var' ;then
		:
	else
		yast2 firewall services add service=ssh zone=EXT || :
	fi

%endif

%preun -p /sbin/ldconfig

%files
%defattr(0644,root,root,0755)
%{_mandir}/man8/qa_lib_keys.8%{ext_man}
%dir %{destdir}
%dir %{destdir}/keys
%dir %{destdir}/keys/ssh
%attr(0600,root,root) %{fhsdir}/id_dsa
%attr(0600,root,root) %{fhsdir}/id_rsa
%{fhsdir}/id_dsa.pub
%{fhsdir}/id_rsa.pub
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
