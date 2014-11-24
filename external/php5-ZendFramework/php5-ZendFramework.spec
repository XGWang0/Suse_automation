#
# spec file for package php5-ZendFramework
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


#!BuildIgnore: post-build-checks
%define pkg_name ZendFramework
Summary:        Leading open-source PHP framework

Name:           php5-ZendFramework
Version:        1.11.10
Release:        1
License:        BSD-2-Clause
Url:            http://framework.zend.com/
Group:          Development/Libraries/Other
Source0:        %{pkg_name}-%{version}.tar.bz2
Source1:        autoconf_manual.tar.gz
Source2:        %{name}-rpmlintrc
Source3:        build-tools.tar.bz2
# PATCH-FIX-UPSTREAM removes-links-uses-env-variables
Patch1:         zf.sh.patch
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

# Satisfy common hard requirements
Requires:       pcre
Requires:       php-ctype
Requires:       php-curl
Requires:       php-dom
Requires:       php-hash
Requires:       php-iconv
Requires:       php-mbstring
Requires:       php-pdo
Requires:       php-sqlite
Requires:       php-xmlreader
Requires:       php-zlib
%if 0%{?suse_version} > 1130
BuildRequires:  php5 >= 5.3
%endif

# Suggested modules for improved performance/functionality
Suggests:       php-bcmath
Suggests:       php-bitset
Suggests:       php-json
Suggests:       php-posix

Provides:       php-ZendFramework
Provides:       qa_lib_openid
Obsoletes:      qa_lib_openid

%description
Extending the art & spirit of PHP, Zend Framework is based on simplicity,
object-oriented best practices, corporate friendly licensing, and a rigorously
tested agile codebase. Zend Framework is focused on building more secure,
reliable, and modern Web 2.0 applications & web services, and consuming widely
available APIs from leading vendors like Google, Amazon, Yahoo!, Flickr, as
well as API providers and catalogers like StrikeIron and ProgrammableWeb.

%package extras
Summary:        Zend Framework Extras (ZendX)
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}
Provides:       %{name}-ZendX = %{version}

%description extras
This package includes the ZendX libraries.

%package cache-backend-apc
Summary:        Zend Framework APC cache backend
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}
Requires:       php-APC

%description cache-backend-apc
This package contains the backend for Zend_Cache to store and retrieve data via
APC.

%package cache-backend-memcached
Summary:        Zend Framework memcache cache backend
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}
Requires:       php-pecl-memcache

%description cache-backend-memcached
This package contains the back end for Zend_Cache to store and retrieve data
via memcache.

%package cache-backend-sqlite
Summary:        Zend Framework sqlite back end
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}
Requires:       php-sqlite

%description cache-backend-sqlite
This package contains the back end for Zend_Cache to store and retrieve data
via sqlite databases.

%package captcha
Summary:        Zend Framework CAPTCHA component
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}
Requires:       php-gd

%description captcha
This package contains the Zend Framework CAPTCHA extension.

%package pdf
Summary:        PDF document creation and manipulation
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}
Requires:       php-gd

%description pdf
Portable Document Format (PDF) from Adobe is the de facto standard for
cross-platform rich documents. Now, PHP applications can create or read PDF
documents on the fly, without the need to call utilities from the shell, depend
on PHP extensions, or pay licensing fees. Zend_Pdf can even modify existing PDF
documents.

* supports Adobe PDF file format
* parses PDF structure and provides access to elements
* creates or modifies PDF documents
* utilizes memory efficiently

%prep
%setup -qn %{pkg_name}-%{version}
tar zfx %{SOURCE1}
tar zfx %{SOURCE3}
%patch1 -p1

%build
find . -type f -perm /111 \
  -fprint executables -exec chmod -x '{}' \; >/dev/null

find . -type f -name \*.sh \
  -fprint valid_executables -exec chmod +x '{}' \; >/dev/null

cat executables valid_executables|sort|uniq -u > invalid_executables

%install
export NO_BRP_CHECK_BYTECODE_VERSION=true

mkdir -p %{buildroot}%{_datadir}/php5
cp -pr library/Zend %{buildroot}%{_datadir}/php5
cp -pr externals %{buildroot}%{_datadir}/php5/Zend

# ZendX
cd extras
cp -pr library/ZendX %{buildroot}%{_datadir}/php5
cd ..

# Zend_Tool
mkdir -p %{buildroot}%{_bindir}
cp -pr bin/zf.{php,sh} %{buildroot}%{_bindir}
ln -s -f /usr/bin/zf.sh %{buildroot}%{_bindir}/zf

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{_datadir}/php5/Zend
%exclude %{_datadir}/php5/Zend/externals
%exclude %{_datadir}/php5/Zend/Cache/Backend/Apc.php
%exclude %{_datadir}/php5/Zend/Cache/Backend/Memcached.php
%exclude %{_datadir}/php5/Zend/Captcha
%exclude %{_datadir}/php5/Zend/Pdf.php
%exclude %{_datadir}/php5/Zend/Pdf
%{_bindir}/zf.sh
%{_bindir}/zf.php
%{_bindir}/zf

%doc LICENSE.txt INSTALL.txt README.txt

%files extras
%defattr(-,root,root,-)
%{_datadir}/php5/ZendX
%doc LICENSE.txt

%files cache-backend-apc
%defattr(-,root,root,-)
%{_datadir}/php5/Zend/Cache/Backend/Apc.php
%doc LICENSE.txt

%files cache-backend-memcached
%defattr(-,root,root,-)
%{_datadir}/php5/Zend/Cache/Backend/Memcached.php
%doc LICENSE.txt

%files captcha
%defattr(-,root,root,-)
%{_datadir}/php5/Zend/Captcha
%doc LICENSE.txt

%files pdf
%defattr(-,root,root,-)
%{_datadir}/php5/Zend/Pdf.php
%{_datadir}/php5/Zend/Pdf
%doc LICENSE.txt

%changelog
