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

Name:           qa_lib_ctcs2
Version:        @@VERSION@@
Release:        0
License:        GPLv2+
Summary:        Cerberus Test Control System
Url:            http://sourceforge.net/projects/ctcs2/
Group:          Development/Tools/Other
Source0:        %{name}-%{version}.tar.bz2
Source1:        %{name}.8
Requires:       perl
Requires:       psmisc
Requires:       python
Provides:       ctcs2
Obsoletes:      ctcs2
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

%description
This testing framework was originally developed at VA Linux System and
is now contiuously extended by the SUSE QA department. Now it is
called CTCS2 to mark the difference to the older CVS based versions,
as CTCS2 is now broken down into many separate packages.

This very package is the base package, it contains all necessary
scripts to run Cerberus Test Control Files and to analyze the results.

%prep
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
install -m 755 -d %{buildroot}%{_mandir}/man8
install -m 644 %{SOURCE1} %{buildroot}%{_mandir}/man8
gzip %{buildroot}%{_mandir}/man8/%{name}.8
install -m 755 -d %{buildroot}%{_prefix}/lib/ctcs2
install -m 755 -d %{buildroot}%{_prefix}/lib/ctcs2/tcf
install -m 755 -d %{buildroot}%{_prefix}/lib/ctcs2/bin
install -m 755 -d %{buildroot}%{_prefix}/lib/ctcs2/lib
install -m 755 -d %{buildroot}%{_prefix}/lib/ctcs2/lib/perl
install -m 755 -d %{buildroot}%{_prefix}/lib/ctcs2/lib/sh
install -m 755 -d %{buildroot}%{_prefix}/lib/ctcs2/tools
install -m 755 -d %{buildroot}%{_prefix}/lib/ctcs2/config
cp tools/* %{buildroot}%{_prefix}/lib/ctcs2/tools
cp bin/* %{buildroot}%{_prefix}/lib/ctcs2/bin
cp -r lib/perl/* %{buildroot}%{_prefix}/lib/ctcs2/lib/perl
cp lib/sh/* %{buildroot}%{_prefix}/lib/ctcs2/lib/sh
mkdir -p %{buildroot}%{_localstatedir}/log/qa/ctcs2

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root)
%{_mandir}/man8/%{name}.8.gz
%{_prefix}/lib/ctcs2
%{_localstatedir}/log/qa
%attr(755,root,root) %{_prefix}/lib/ctcs2/tools/report.py
%doc COPYING

%changelog
