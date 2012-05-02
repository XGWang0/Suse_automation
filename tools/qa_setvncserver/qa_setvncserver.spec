#!BuildIgnore: post-build-checks
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/

Name:           qa_setvncserver
License:        SUSE Proprietary
Group:          SuSE internal
AutoReqProv:    on
Version:        @@VERSION@@
Release:        0
Summary:        set vnc server on SUT, so we can access from hamsta front end
Source0: 	vncd
Source1:	qa_setvncserver.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Provides:	setvncserver
Obsoletes:	setvncserver
Requires:       tightvnc zlib xorg-x11-driver-video qa_tools
BuildArch:      noarch

%description
set vnc server on SUT, so we can access from hamsta front end

Authors:
--------
	Leon Wang <llwang@novell.com>

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
mkdir -p $RPM_BUILD_ROOT/tmp
cp %SOURCE0 $RPM_BUILD_ROOT/tmp

%post
mkdir -p /root/.vnc
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
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/usr/share/man/man8/qa_setvncserver.8.gz
/tmp/vncd

%changelog
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
* Sun Sep 04 2011 - llipavsky@suse.cz
- New, updated release from the automation team. Includes:
- Improved virtual machine handling/QA cloud
- Rename of QA packages
- Upgrade support
- More teststsuites
- Many bug fixes
* Tue Aug 16 2011 - llipavsky@suse.cz
- Package rename: setvncserver -> qa_setvncserver
* Wed Apr 13 2011 dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- Changed the default VNC password
- Man page added
- Bug fixes
* Thu Jun 17 2010 llwang@novell.com
- first submission
