all: libqainternalperl.so

clean:
	rm -fv libqainternal_perlwrapper.c libqainternal_perlwrapper.o libqainternalperl.so* libqainternalperl.pm

install:
	cp -v libqainternalperl.so.0.0 $(DESTDIR)/$(LIBD)/
	/sbin/ldconfig -n -C $(DESTDIR)/etc/ld.so.cache $(DESTDIR)/$(LIBD)

uninstall:
	rm -fv /usr/lib/libqainternalperl.*
	/sbin/ldconfig


libqainternal_perlwrapper.c: libqainternal.i
	swig -perl -I/usr/include/ -o libqainternal_perlwrapper.c -outdir lib libqainternal.i

libqainternal_perlwrapper.o: libqainternal_perlwrapper.c
	gcc -fPIC -D_GNU_SOURCE $(CFLAGS) -I/usr/include/ -I$(PINCLUDES)/CORE -I. -o libqainternal_perlwrapper.o -g -c libqainternal_perlwrapper.c

libqainternalperl.so.0.0: libqainternal_perlwrapper.o
	gcc -g -shared -I. -L. -L.. -L../src/.libs -Wl,-soname,libqainternalperl.so.0 -o libqainternalperl.so.0.0 libqainternal_perlwrapper.o -lqainternal

libqainternalperl.so.0: libqainternalperl.so.0.0
	/sbin/ldconfig -n .

libqainternalperl.so: libqainternalperl.so.0
	ln -sf libqainternalperl.so.0 libqainternalperl.so



VERSION=0.2
FILES=MANIFEST Makefile.swig Makefile.PL README libqainternal.i \
libqainternal_perlwrapper.c bin/demo_use_perl.pl lib/libqainternalperl.pm
DISTDIR=libqainternalperl-$(VERSION)

dist-bzip2: $(FILES)
	mkdir $(DISTDIR)
	cp --parents -r $(FILES) $(DISTDIR)
	tar chof - $(DISTDIR) | bzip2 -9 -c >$(DISTDIR).tar.bz2
	rm -rf $(DISTDIR)
 
