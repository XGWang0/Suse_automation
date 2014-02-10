#!BuildIgnore: post-build-checks
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/

Name:           qa_setvncserver
Version:        @@VERSION@@
Release:        0
License:        SUSE-NonFree
Summary:        set vnc server on SUT, so we can access from hamsta front end
Group:          SuSE internal
Source0:        vncd
Source1:        qa_setvncserver.8
Requires:       qa_tools
Requires:       tightvnc
Requires:       xorg-x11-driver-video
Requires:       zlib
Provides:       setvncserver
Obsoletes:      setvncserver
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
Set VNC server on SUT, so it can be accessed from HAMSTA front end.

%install
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -d %{buildroot}/tmp
cp %{SOURCE0} %{buildroot}/tmp

%post
install -d /root/.vnc
mv /tmp/vncd /etc/init.d/vncd
chmod 755 /etc/init.d/vncd
echo "xrdb \$HOME/.Xresources
xsetroot -solid grey
xterm -geometry 80x24+10+10 -ls -title "\$VNCDESKTOP Desktop" &
gnome-session &" > /root/.vnc/xstartup
echo 'DISPLAYMANAGER_AUTOLOGIN="root"
DISPLAYMANAGER_PASSWORD_LESS_LOGIN="yes"' >> /etc/sysconfig/displaymanager
echo "localhost" > /etc/X0.hosts
chmod 755 /root/.vnc/xstartup
touch /root/.vnc/passwd
chmod 600 /root/.vnc/passwd
/sbin/insserv -f /etc/init.d/vncd

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root)
%{_mandir}/man8/qa_setvncserver.8.gz
/tmp/vncd

%changelog
