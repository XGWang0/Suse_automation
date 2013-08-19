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

# norootforbuild

Name:           qa_lib_virtauto
License:        SUSE Proprietary
Group:          SuSE internal
Summary:        (rd-)qa package for virtualization automation
Provides:	virtautolib
Obsoletes:	virtautolib
Requires:       ssh libvirt perl-XML-XPath qa_keys expect sshpass qa_libperl virtautolib-data
%if 0%{?sles_version} == 10
Requires:       xen-tools
%else
Requires:	vm-install
%endif
AutoReqProv:    on
Version:        @@VERSION@@
Release:        0
Source:         %name-%version.tar.bz2
Source1:	qa_lib_virtauto.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArchitectures: noarch

%description
QA library for virtualization automation


Authors:
--------
    Dan Collingridge <dcollingridge@suse.com>
    Lukas Lipavsky   <llipavsky@suse.com>

%prep
%setup -n %{name}

%build

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d $RPM_BUILD_ROOT/usr/share/qa/virtautolib
cp -a * $RPM_BUILD_ROOT/usr/share/qa/virtautolib
find $RPM_BUILD_ROOT/usr/share/qa/virtautolib -depth -type d -name .svn -exec rm -rf {} \;

%post

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root)
/usr/share/man/man8/qa_lib_virtauto.8.gz
/usr/share/qa
%doc COPYING

%changelog

