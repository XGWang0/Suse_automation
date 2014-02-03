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
# spec file for package qa_config (Version 1.0)
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild

Name:           qa_lib_config
License:        SUSE-NonFree
Group:		QA Automation
AutoReqProv:    on
Version:        @@VERSION@@
Release:        0
Summary:        Basic configutation for QA automation tools
Source0:        %name-%version.tar.bz2
Source1:	qa_lib_config.8
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Provides:	qa-config
Obsoletes:	qa-config
Requires:       bash
BuildArchitectures: noarch

%description
This package contains base set of tools to handle confuguration tools of QA 
Automation infrastructure tools.


Authors:
--------
    Lukas Lipavsky <llipavsky@suse.cz>

%prep
%setup -q -n %{name}

%install
install -m 755 -d $RPM_BUILD_ROOT/usr/share/man/man8
install -m 644 %{S:1} $RPM_BUILD_ROOT/usr/share/man/man8
gzip $RPM_BUILD_ROOT/usr/share/man/man8/%{name}.8
install -m 755 -d $RPM_BUILD_ROOT/etc/qa
install -m 755 -d $RPM_BUILD_ROOT/usr/share/qa/tools
install -m 755 -d $RPM_BUILD_ROOT/usr/share/qa/lib
cp -a config $RPM_BUILD_ROOT/usr/share/qa/lib
cp -a qaconfig.pm $RPM_BUILD_ROOT/usr/share/qa/lib
cp -a dump_qa_config $RPM_BUILD_ROOT/usr/share/qa/tools
cp -a get_qa_config $RPM_BUILD_ROOT/usr/share/qa/tools
cp -a sync_qa_config $RPM_BUILD_ROOT/usr/share/qa/tools
cp -a 00-automation-default $RPM_BUILD_ROOT/etc/qa

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)   
/usr/share/man/man8/qa_lib_config.8.gz
/usr/share/qa
/etc/qa/
%doc COPYING

%changelog

