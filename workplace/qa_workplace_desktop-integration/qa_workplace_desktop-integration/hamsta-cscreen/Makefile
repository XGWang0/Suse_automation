DESTDIR = "/"

install:
	test -e $(DESTDIR)/etc/hcscreenrc || install -Dm 644 hcscreenrc $(DESTDIR)/etc/hcscreenrc
	install -Dm 755 hs_cscreen $(DESTDIR)/usr/bin/hs_cscreen
	#install -Dm 644 hamsta-cscreen.desktop $(DESTDIR)/usr/share/applications/hamsta-cscreen.desktop
	desktop-file-install --rebuild-mime-info-cache hamsta-cscreen.desktop
	test -e /sbin/SuSEconfig && /sbin/SuSEconfig || :
