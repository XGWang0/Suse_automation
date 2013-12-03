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
* Fri Aug 16 2013 - pkacer@suse.com
- New 2.6 release from QA Automation team
- The Machines page has been greatly improved
- Layout changes at the Machine details page
- Web UI menu was changed (renamed entries and added link to documentation)
- Web UI bottom menu was removed
- Machine reservations can be shared by users
- Improved QA network configuration (synchronization and web UI)
- Title of Hamsta changed from image to text
- All user roles are now checked for privileges (without need to switch user roles)
- Ajaxterm was removed
- A lot of bugs were fixed
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
