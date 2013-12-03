#
# spec file for package ctcs2 (Version 0.1.6)
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
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

# norootforbuild


Name:           qa_lib_ctcs2
License:        GPL v2 or later
Group:          Development/Tools/Other
AutoReqProv:    on
Version:        @@VERSION@@
Release:        0
Summary:        Cerberus Test Control System
Url:            http://sourceforge.net/projects/ctcs2/
Source0:         %{name}-%{version}.tar.bz2
Source1:	%name.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:	noarch
Requires:       python psmisc perl
Provides:	ctcs2
Obsoletes:	ctcs2
#BuildArchitectures: noarch
#ExclusiveArch: %ix86

%description
This testing framework was originally developed at VA Linux System and
is now contiuously extended by the SUSE QA department. Now it is called
"ctcs2" to mark the difference to the older CVS based versions, as
ctcs2 is now broken down into many separate packages.

This very package is the base package, it contains all necessary
scripts to run Cerberus Test Control Files and to analyze the results.



Authors:
--------
    Various unknown people from VA Linux Systems
    SUSE QA Department <qa@suse.de>

%prep
#cp %{name}-%{version}.tar.bz2 $RPM_BUILD_ROOT
%setup -n %{name}

%build

%pre
if [ -d /var/log/ctcs2 ] ; then
	if [ ! -d /var/log/qa ] ; then
		# completely safe move (preserve link) - only does not work if 
		# /var/log/ctcs2 is mountpoint :( but this is not used
		CTCS2_TMPD="$(mktemp -d /var/log/ctcs2/ctcs2-XXXXXX)"
		shopt -s dotglob
		# will omit "$CTCS2_TMPD" itself from the moving, of course
		mv /var/log/ctcs2/* "$CTCS2_TMPD" 2>/dev/null
		mv $CTCS2_TMPD /var/log/ctcs2/ctcs2
		mv /var/log/ctcs2 /var/log/qa
	elif [ ! -d /var/log/qa/ctcs2 ] ; then
		if [ -L /var/log/qa ] ; then
			if [ -L /var/log/ctcs2 ] ; then
				# move the symlink
				CTCS2_SL="`readlink /var/log/ctcs2`"
				# correct relative symlink to fit the new parent dir
				[ "$CTCS2_SL" == "${CTCS2_SL#/}" ] && CTCS2_SL=../"$CTCS2_SL"
				ln -s "$CTCS2_SL" /var/log/qa/ctcs2
			else
				# assume that /var/log/qa points to correct log location 
				# and move ctcs2 logs there as well
				mv /var/log/ctcs2 /var/log/qa
			fi
		else
			if [ -L /var/log/ctcs2 ] ; then
				# completely safe move (preserve link) - only does not work 
				# if /var/log/ctcs2 is mountpoint :( but this is not used
				CTCS2_TMPD="$(mktemp -d /var/log/ctcs2/ctcs2-XXXXXX)"
				shopt -s dotglob
				# will omit "$CTCS2_TMPD" itself from the moving, of course
				mv /var/log/ctcs2/* "$CTCS2_TMPD" 2>/dev/null
				mv $CTCS2_TMPD /var/log/ctcs2/ctcs2
				for i in /var/log/qa/* ; do mv "$i" /var/log/ctcs2/ ; done
				rmdir /var/log/qa
				mv /var/log/ctcs2 /var/log/qa
			else
				# safe to move
				mv /var/log/ctcs2 /var/log/qa
			fi
		fi
	else
		[ -L /var/log/ctcs2 ] && CTCS2_SL="`readlink /var/log/ctcs2`" || CTCS2_SL=""
		if ! [ "$CTCS2_SL" == "/var/log/qa/ctcs2" -o "$CTCS2_SL" == "qa/ctcs2" ] ; then
			echo
			echo "* * * * * * * * * * * W A R N I N G * * * * * * * * * * * * * * "
			echo "You have different /var/log/qa/ctcs2 and /var/log/ctcs2!"
			echo "Directory /var/log/ctcs2 is no longer supported by any QA tools"
			echo "If you want your files procesed by QA tools, move content of "
			echo "/var/log/ctcs2 to /var/log/qa/ctcs2 (and delete /var/log/ctcs2"
			echo "to prevent displaying this warning again)."
			echo "* * * * * * * * * * * W A R N I N G * * * * * * * * * * * * * * "
			echo
		fi
	fi
fi # [ -d /var/log/ctcs2 ] 


%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d $RPM_BUILD_ROOT/usr/lib/ctcs2
install -m 755 -d $RPM_BUILD_ROOT/usr/lib/ctcs2/tcf
install -m 755 -d $RPM_BUILD_ROOT/usr/lib/ctcs2/bin
install -m 755 -d $RPM_BUILD_ROOT/usr/lib/ctcs2/lib
install -m 755 -d $RPM_BUILD_ROOT/usr/lib/ctcs2/lib/perl
install -m 755 -d $RPM_BUILD_ROOT/usr/lib/ctcs2/lib/sh
install -m 755 -d $RPM_BUILD_ROOT/usr/lib/ctcs2/tools
install -m 755 -d $RPM_BUILD_ROOT/usr/lib/ctcs2/config
cp tools/* $RPM_BUILD_ROOT/usr/lib/ctcs2/tools
cp bin/* $RPM_BUILD_ROOT/usr/lib/ctcs2/bin
cp -r lib/perl/* $RPM_BUILD_ROOT/usr/lib/ctcs2/lib/perl
cp lib/sh/* $RPM_BUILD_ROOT/usr/lib/ctcs2/lib/sh
mkdir -p $RPM_BUILD_ROOT/var/log/qa/ctcs2

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/usr/share/man/man8/%name.8.gz
#%dir /usr/lib/ctcs2
#%dir /usr/lib/ctcs2/*
#%dir /usr/lib/ctcs2/lib
#%dir /usr/lib/ctcs2/lib/perl
#%dir /usr/lib/ctcs2/bin
/usr/lib/ctcs2
/var/log/qa
#/usr/lib/ctcs2/tools/*
#/usr/lib/ctcs2/lib/perl/*
#/usr/lib/ctcs2/bin/*
%attr(755,root,root) /usr/lib/ctcs2/tools/report.py
%doc COPYING

%changelog
* Tue Jun 29 2010 vmarsik@suse.cz
- fixed permissions for /usr/lib/ctcs2/tools/report.py
* Thu Apr 01 2010 vmarsik@suse.cz
- removed dependency on perl-DBD-myslq, not available in SLED
- this was only needed by the obsolete report script
- use remote_qa_db_report.pl from qa_tools instead
- addded dependency on perl, there is enough perl code
* Fri Feb 27 2009 ehamera@suse.cz
- repaired bnc#197135 - temeouted tests are marked as internal
  error instead of pass.
* Tue Jan 06 2009 mmrazik@suse.cz
- don't ignore SIGUSR1 (bnc#446597). Patch provided by dgollub.
* Tue Oct 28 2008 dgollub@suse.de
- Modified pdisk_openpower.patch:
  Redirect stderr also to /dev/null for the `which pdisk` call
* Fri Aug 08 2008 dgollub@suse.de
- Added cleanup syntax, which is the opposite of wait, and
  terminates unfinished background processes once it got called.
* Thu Jun 12 2008 pkirsch@suse.de
- added dependency psmisc because of internal call of pstree
* Tue May 06 2008 pkirsch@suse.de
- removed Requires kernel-source, the test packages should correct
  their dependencies
* Thu Apr 10 2008 pkirsch@suse.de
- removed Group SuSE intern
* Thu Jan 31 2008 pkirsch@suse.de
- pdisk does not work on OpenPOWER 'no valid block' (this is
  wanted: olh), so there is a new check in fpdisk.pm
* Tue Jan 15 2008 mmrazik@suse.cz
- fixed colors during test execution (correct escape sequences are now
  used when test fails)
* Mon May 07 2007 pkirsch@suse.de
- added kernel-source as requirement, some testcases need that
* Wed Apr 18 2007 pkirsch@suse.de
- wrong patch in fpdisk, there was a stdout redirection 2>1 missing
* Mon Mar 12 2007 pkirsch@suse.de
- for clarification, in report.py the default log directory
  is mentioned
* Fri Feb 16 2007 pkirsch@suse.de
- in fpdisc.pm added correct return value query
* Fri Oct 13 2006 yxu@suse.de
- add link-logfile.diff, which will make correct link at report html
  files for each testcase to its log file
- (olli) remove logdir.patch, use new-logdir.patch instead
* Fri Aug 18 2006 ehamera@suse.cz
- added timestamp_logging.patch
  when -t switch used, it makes file timestamp_log in logging
  directory and log times when testsuite has been ran (in seconds
  from 1.1.1970)
- added logdir.patch
  logging directory is in /var/log/ctcs2/ now
- added rpmlist.patch
  makes file with list of installed rpms
- removed netcat patch
* Fri Mar 17 2006 fseidel@suse.de
- prealpha netcat utilization
* Wed Jan 25 2006 mls@suse.de
- converted neededforbuild to BuildRequires
* Mon Nov 21 2005 fseidel@suse.de
- added patch which adds two new commands for tcf-files
  that are:
  fgif <prepcommand> <count> ... (rest is as usual fg command)
  bgif <prepcommand> <count> ... (rest is as usual bg command)
  they will only execute the testcase is the prepcommand was
  successfull
* Thu Oct 27 2005 ories@suse.de
- default dir for ctcs2 is /usr/lib/ctcs2 !
- set absolute paths in bin/runtest & tools/run
* Thu Aug 11 2005 gpayer@suse.de
- package is now built for all architectures to stop autobuild bitching
* Tue Aug 02 2005 gpayer@suse.de
- installs now to default libdir
* Tue Mar 15 2005 gpayer@suse.de
- testcases hitting timeout are now marked by tools/report.py
* Wed Jan 26 2005 gpayer@suse.de
- fixed internal error propagation in bin/runtest, tools/run and tools/report.py
* Tue Jan 11 2005 gpayer@suse.de
- now bin/runtest can handle absolute paths for real
* Mon Dec 13 2004 gpayer@suse.de
- included fixed fpdisk.pm (thanks to fseidel@suse.de)
* Tue Sep 21 2004 gpayer@suse.de
- now report.py sorts testresults by testcase name
* Mon Aug 16 2004 gpayer@suse.de
- simplified entries in %%files section
* Fri Jul 30 2004 gpayer@suse.de
- fixed occurance of old installation path in tools/run
* Wed Jul 28 2004 gpayer@suse.de
- changed install location to /usr/lib/ctcs2
* Wed May 19 2004 gpayer@suse.de
- added missing files and scripts from ctcs CVS
- fixed relative path bug in runtest
* Wed May 12 2004 gpayer@suse.de
- initial package
- derived from internal QA tool ctcs-1.3.0pre4
