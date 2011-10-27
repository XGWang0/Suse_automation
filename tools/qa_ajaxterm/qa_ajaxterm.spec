#!BuildIgnore: post-build-checks
#
# spec file for package ajaxterm (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

Name:           qa_ajaxterm
License:        GPL v2 or later; LGPL v2.1
Group:          SuSE internal
AutoReqProv:    on
Version:        0.10
Release:        8
Summary:        ajax based ssh client, include vncserver setup script
Url:            http://antony.lesuisse.org/software/ajaxterm/
Source0:        ajaxterm-%version.tar.bz2
Source1:        ajaxterm
Source2:	qa_ajaxterm.8
Patch0:         ajaxterm-hamsta.diff
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Provides:	ajaxterm
Obsoletes:	ajaxterm
Requires:       python >= 2.5 apache2 apache2-prefork python-xml
BuildArch:      noarch

%description
patched version of Ajaxterm to handle multiple ssh connections within 1 wsgi
session


Authors:
--------
	Antony Lesuisse <al@udev.org>
	Olli Ries <ories@novell.com>
	Leon Wang <llwang@novell.com>

%prep
%setup -q -n ajaxterm-%version
%patch0 -p1

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
cp %{S:2} $RPM_BUILD_ROOT/usr/share/man/man8/
gzip $RPM_BUILD_ROOT/usr/share/man/man8/qa_ajaxterm.8
install -m 755 -d $RPM_BUILD_ROOT/usr/lib/ajaxterm
install -m 755 -d $RPM_BUILD_ROOT/etc/init.d
cp -ap * $RPM_BUILD_ROOT/usr/lib/ajaxterm
cp %SOURCE1 $RPM_BUILD_ROOT/etc/init.d

%post
sed -i '/^APACHE_MODULES=/c\\APACHE_MODULES="actions alias auth_basic authn_file authz_host authz_groupfile authz_default authz_user authn_dbm autoindex cgi dir env expires include log_config mime negotiation setenvif ssl suexec userdir php5 proxy proxy_http"' /etc/sysconfig/apache2
if [ -z "`grep ajaxterm /etc/apache2/httpd.conf`" ];then
echo "AddHandler cgi-script .cgi .py
ProxyPass /ajaxterm/ http://localhost:8022/
ProxyPassReverse /ajaxterm/ http://localhost:8022/" >> /etc/apache2/httpd.conf
fi
/etc/init.d/apache2 restart > /dev/null 2>&1
/sbin/insserv -f /etc/init.d/ajaxterm
/etc/init.d/ajaxterm restart

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)   
/usr/share/man/man8/qa_ajaxterm.8.gz
/usr/lib/ajaxterm
%attr(755,root,root) /etc/init.d/ajaxterm

%changelog
* Tue Aug 16 2011 - llipavsky@suse.cz
- Package rename: ajaxterm -> qa_ajaxterm
* Fri Aug 13 2010 llipavsky@suse.cz
- New, updated release from the automation team. Includes:
  - bugfixes
* Fri Jun 18 2010 dcollingridge@novell.com
- New, updated release from the automation team. Includes:
- Futher hamsta integration
* Tue Apr 20 2010 llwang@novell.com
- Integration with hamsta
* Tue Apr 20 2010 ories@novell.com
- first submission
