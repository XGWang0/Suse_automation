lib_LTLIBRARIES = libqainternal.la

libqainternal_la_SOURCES = cleanup.c compare.c config.c error.c execute.c file.c handlemanager.c libqainternal.c md5.c service.c user.c version.c log.c

noinst_HEADERS = cleanup.h error.h execute.h file.h global.h handlemanager.h md5.h service.h user.h 

include_HEADERS = libqainternal.h

bin_PROGRAMS = demo_use

demo_use_SOURCES = demo_use.c

demo_use_LDADD = -lqainternal
