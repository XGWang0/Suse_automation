all: dist-bzip2




VERSION=0.2
FILES=config.lib.sh libqainternal.lib.sh log.lib.sh services.lib.sh \
user.lib.sh docs/README docs/function_list.html
DISTDIR=libqainternalshell-$(VERSION)

dist-bzip2: $(FILES)
	mkdir $(DISTDIR)
	cp --parents -r $(FILES) $(DISTDIR)
	tar chof - $(DISTDIR) | bzip2 -9 -c >$(DISTDIR).tar.bz2
	rm -rf $(DISTDIR)
