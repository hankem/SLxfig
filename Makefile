# -*- sh -*-


SHELL = /bin/sh

all:
	cd src; $(MAKE) all
clean:
	cd src; $(MAKE) clean
	/bin/rm -f *~ \#*
distclean: clean
	cd src; $(MAKE) distclean
	/bin/rm -f config.log config.cache config.status Makefile
install:
	cd src; $(MAKE) install
#
configure: autoconf/aclocal.m4 autoconf/configure.ac
	cd autoconf && autoconf && mv ./configure ..
update: autoconf/config.sub autoconf/config.guess
autoconf/config.guess: /usr/share/misc/config.guess
	/bin/cp -f /usr/share/misc/config.guess autoconf/config.guess
autoconf/config.sub: /usr/share/misc/config.sub
	/bin/cp -f /usr/share/misc/config.sub autoconf/config.sub
#
.PHONY: all install clean update
#
