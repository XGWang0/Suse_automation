SUBDIRS = src

mydocudir = $(prefix)/share/qa/qa_internalapi/docu

mydocu_DATA = Implementation_notes README 

doxygendir = $(mydocudir)/html

# This is needed since automake somehow dails to use doxygenDATA_INSTALL now.
# It uses install command which does not work with directories
doxygen_DATA = docs/html/*

doxygenDATA_INSTALL = cp -rv

EXTRA_DIST = $(mydocu_DATA) doxygen.config

#CLEANFILES = $(doxygen_DATA)

# The '/*' has same reason as in doxygen_DATA
docs/html/*:
	/usr/bin/doxygen doxygen.config 
	for i in docs/man/man3/*; do gzip -f $$i; done

install-data-local:
	test -d $(DESTDIR)/usr/share/man || mkdir -p $(DESTDIR)/usr/share/man
	cp -rv docs/man/man3 $(DESTDIR)/usr/share/man/
