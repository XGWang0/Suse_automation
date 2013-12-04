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

# norootforbuild

#!BuildIgnore: post-build-checks
%define pkg_name ZendFramework
Summary:        Leading open-source PHP framework

Name:           php5-ZendFramework
Version:        1.11.10
Release:        1
License:        BSD
Group:          Development/Libraries/Other
Source0:        %{pkg_name}-%{version}.tar.bz2
Source1:        autoconf_manual.tar.gz
Source2:        %{name}-rpmlintrc
Source3:        build-tools.tar.bz2
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Patch0:         zf.sh.patch
Url:            http://framework.zend.com/
BuildArch:      noarch

# Satisfy common hard requirements
Requires:       pcre php-ctype php-curl php-dom php-hash php-iconv
Requires:       php-mbstring php-sqlite php-pdo php-xmlreader php-zlib
%if 0%{?suse_version} > 1130
BuildRequires:  php5 >= 5.3
%endif
# BuildRequires:  php5-sqlite php5-xmlreader

# Suggested modules for improved performance/functionality
Suggests:       php-bcmath php-bitset php-json php-posix

# Documentation & dojo requirements
BuildRequires:  autoconf make unzip
BuildRequires:  libxml2 libxslt
BuildRequires:  docbook-xsl-stylesheets docbook_4 iso_ent sgml-skel xmlcharent
Provides:	qa_lib_openid php-ZendFramework
Obsoletes:	qa_lib_openid

%description
Extending the art & spirit of PHP, Zend Framework is based on simplicity,
object-oriented best practices, corporate friendly licensing, and a rigorously
tested agile codebase. Zend Framework is focused on building more secure,
reliable, and modern Web 2.0 applications & web services, and consuming widely
available APIs from leading vendors like Google, Amazon, Yahoo!, Flickr, as
well as API providers and catalogers like StrikeIron and ProgrammableWeb.


%package demos
Summary:        Demos for the Zend Framework
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}-%{release}

%description demos
This package includes Zend Framework demos for the Feeds, Gdata, Mail, OpenId,
Pdf, Search-Lucene and Services subpackages.


%package tests
Summary:        Unit tests for the Zend Framework
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}-%{release}
Requires:       php-pear-phpunit

%description tests
This package includes Zend Framework unit tests for all available subpackages.


%package extras
Summary:        Zend Framework Extras (ZendX)
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}-%{release}
Provides:       %{name}-ZendX = %{version}-%{release}

%description extras
This package includes the ZendX libraries.


%package cache-backend-apc
Summary:        Zend Framework APC cache backend
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}-%{release}
Requires:       php-APC

%description cache-backend-apc
This package contains the backend for Zend_Cache to store and retrieve data via
APC.


%package cache-backend-memcached
Summary:        Zend Framework memcache cache backend
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}-%{release}
Requires:       php-pecl-memcache

%description cache-backend-memcached
This package contains the back end for Zend_Cache to store and retrieve data
via memcache.


%package cache-backend-sqlite
Summary:        Zend Framework sqlite back end
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}-%{release}
Requires:       php-sqlite

%description cache-backend-sqlite
This package contains the back end for Zend_Cache to store and retrieve data
via sqlite databases.


%package captcha
Summary:        Zend Framework CAPTCHA component
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}-%{release}
Requires:       php-gd

%description captcha
This package contains the Zend Framework CAPTCHA extension.


%package dojo
Summary:        Dojo javascript toolkit
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}-%{release} unzip

%description dojo
This package contains a full copy of the Dojo Javascript toolkit from
Zend Framework externals. You may wish to install this as a reference or
to build custom Dojo layers for deployment with your site.


# %package Db-Adapter-Db2
# Summary:  Zend Framework database adapter for DB2
# Group:    Development/Libraries
# Requires: %{name} = %{version}-%{release}
# Requires: php-ibm_db2 # Not available on openSUSE

# %description Db-Adapter-Db2
# This package contains the files for Zend Framework necessary to connect to an
# IBM DB2 database.


# %package Db-Adapter-Firebird
# Summary:  Zend Framework database adapter for InterBase
# Group:    Development/Libraries
# Requires: %{name} = %{version}-%{release}
# Requires: php-interbase # Not available on openSUSE

# %description Db-Adapter-Firebird
# This package contains the files for Zend Framework necessary to connect to a
# Firebird/InterBase database.


# %package Db-Adapter-Oracle
# Summary:  Zend Framework database adapter for Oracle
# Group:    Development/Libraries
# Requires: %{name} = %{version}-%{release}
# Requires: php-oci8 # Not available on openSUSE

# %description Db-Adapter-Oracle
# This package contains the files for Zend Framework necessary to connect to an
# Oracle database.

%package pdf
Summary:        PDF document creation and manipulation
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}-%{release}
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

%package manual-en
Summary:        Zend Framework English programmers reference guide
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}-%{release}

%description manual-en
Programmer's reference guide

%package manual-de
Summary:        Zend Framework German programmers reference guide
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}-%{release}

%description manual-de
Programmer's reference guide

%package manual-fr
Summary:        Zend Framework French programmers reference guide
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}-%{release}

%description manual-fr
Programmer's reference guide

%package manual-ja
Summary:        Zend Framework Japanese programmers reference guide
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}-%{release}

%description manual-ja
Programmer's reference guide

%package manual-zh
Summary:        Zend Framework simplified Chinese programmers reference guide
Group:          Development/Libraries/Other
Requires:       %{name} = %{version}-%{release}

%description manual-zh
Programmer's reference guide


%prep
%setup -qn %{pkg_name}-%{version}
tar zfx %{SOURCE1}
tar zfx %{SOURCE3}
%if 0%{?suse_version} < 1140
 cp configure.in documentation/manual
 cp Makefile.in  documentation/manual
 rm documentation/manual/Makefile
%endif
%patch0 -p1

%build
find . -type f -perm /111 \
  -fprint executables -exec %{__chmod} -x '{}' \; >/dev/null

find . -type f -name \*.sh \
  -fprint valid_executables -exec %{__chmod} +x '{}' \; >/dev/null

%{__cat} executables valid_executables|sort|uniq -u > invalid_executables

# build manuals
%if 0%{?suse_version} > 1130

for lang in documentation/manual/{en,de,fr,ja,zh}; do
  cd ${lang}
  %{__autoconf} && %configure
  xsltproc --xinclude ../../../build-tools/docs/db4-upgrade.xsl ../en/manual.xml.in > manual-db5.xml
  chmod +x ../../../build-tools/docs/pear/phd
  ../../../build-tools/docs/pear/phd --verbose=0 -g 'phpdotnet\phd\Highlighter_GeSHi' --xinclude -f zfpackage -d manual-db5.xml
  cd ../../../
done

# manual for ZendX
cd extras/documentation/manual/en/
%{__autoconf} && %configure
xsltproc --xinclude ../../../../build-tools/docs/db4-upgrade.xsl ../en/manual.xml.in > manual-db5.xml
../../../../build-tools/docs/pear/phd --verbose=0 -g 'phpdotnet\phd\Highlighter_GeSHi' --xinclude -f zfpackage -d manual-db5.xml
cd ../../../../

%else

  cd documentation/manual
  %{__autoconf}
  %configure
  %{__make} %{?_smp_mflags}
  cd ../../../

%endif

%install

export NO_BRP_CHECK_BYTECODE_VERSION=true
%{__rm} -rf $RPM_BUILD_ROOT

%{__mkdir_p} $RPM_BUILD_ROOT%{_datadir}/php5
%{__cp} -pr library/Zend $RPM_BUILD_ROOT%{_datadir}/php5
%{__cp} -pr demos/Zend $RPM_BUILD_ROOT%{_datadir}/php5/Zend/demos
%{__cp} -pr tests $RPM_BUILD_ROOT%{_datadir}/php5/Zend
%{__cp} -pr externals $RPM_BUILD_ROOT%{_datadir}/php5/Zend

# ZendX
cd extras
%{__cp} -pr library/ZendX $RPM_BUILD_ROOT%{_datadir}/php5
%{__cp} -pr tests $RPM_BUILD_ROOT%{_datadir}/php5/ZendX
cd ..

# Manual
cd documentation/manual

%if 0%{?suse_version} > 1130

for lang in {en,de,fr,ja,zh}; do
  %{__mkdir_p} $RPM_BUILD_ROOT%{_datadir}/doc/ZendFramework/${lang}
  %{__cp} -pr ${lang}/output/zf-package-chunked-xhtml/* $RPM_BUILD_ROOT%{_datadir}/doc/ZendFramework/${lang}
done

%else

for lang in {en,de,fr,ja,zh}; do
  %{__mkdir_p} $RPM_BUILD_ROOT%{_datadir}/doc/ZendFramework/${lang}
  %{__cp} -pr ${lang}/html/* $RPM_BUILD_ROOT%{_datadir}/doc/ZendFramework/${lang}
done

%endif

cd ../../

# Zend_Tool
%{__mkdir_p} %{buildroot}%{_bindir}
%{__cp} -pr bin/zf.{php,sh} %{buildroot}%{_bindir}
%{__ln_s} -f /usr/bin/zf.sh %{buildroot}%{_bindir}/zf

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_datadir}/php5/Zend
%exclude %{_datadir}/php5/Zend/demos
%exclude %{_datadir}/php5/Zend/externals
%exclude %{_datadir}/php5/Zend/tests
%exclude %{_datadir}/php5/Zend/Cache/Backend/Apc.php
%exclude %{_datadir}/php5/Zend/Cache/Backend/Memcached.php
%exclude %{_datadir}/php5/Zend/Captcha
%exclude %{_datadir}/php5/Zend/Pdf.php
%exclude %{_datadir}/php5/Zend/Pdf
%{_bindir}/zf.sh
%{_bindir}/zf.php
%{_bindir}/zf

%doc LICENSE.txt INSTALL.txt README.txt

%files demos
%defattr(-,root,root,-)
%{_datadir}/php5/Zend/demos
%doc LICENSE.txt

%files tests
%defattr(-,root,root,-)
%{_datadir}/php5/Zend/tests
%doc LICENSE.txt

%files extras
%defattr(-,root,root,-)
%{_datadir}/php5/ZendX
%if 0%{?suse_version} < 1140
  %doc LICENSE.txt extras/documentation/manual/en/html/*
%else
  %doc LICENSE.txt extras/documentation/manual/en/output/zf-package-chunked-xhtml/*
%endif

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

%files dojo
%defattr(-,root,root,-)
%{_datadir}/php5/Zend/externals/dojo
%doc LICENSE.txt

%files pdf
%defattr(-,root,root,-)
%{_datadir}/php5/Zend/Pdf.php
%{_datadir}/php5/Zend/Pdf
%doc LICENSE.txt

%files manual-en
%defattr(-,root,root,-)
%{_datadir}/doc/ZendFramework/en
%doc LICENSE.txt

%files manual-de
%defattr(-,root,root,-)
%{_datadir}/doc/ZendFramework/de
%doc LICENSE.txt

%files manual-fr
%defattr(-,root,root,-)
%{_datadir}/doc/ZendFramework/fr
%doc LICENSE.txt

%files manual-ja
%defattr(-,root,root,-)
%{_datadir}/doc/ZendFramework/ja
%doc LICENSE.txt

%files manual-zh
%defattr(-,root,root,-)
%{_datadir}/doc/ZendFramework/zh
%doc LICENSE.txt

%changelog
