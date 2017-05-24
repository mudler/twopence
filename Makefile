.PHONY: all install clean \
        library server ruby shell examples tests \
        library-install server-install ruby-install shell-install examples-install \
        library-clean server-clean ruby-clean shell-clean examples-clean

VERSION:= $(shell ./subst.sh --version)

SUBDIRS = \
	library \
	server \
	ruby \
	shell \
	tests \
	examples

all clean install::
	@for dir in $(SUBDIRS); do \
		echo "make -C $$dir $@"; make -C $$dir $@ || exit 1; \
	done

install::
	mkdir -p $(DESTDIR)/usr/lib/twopence-0
	mkdir -p $(DESTDIR)/var/run/twopence
	chgrp qemu $(DESTDIR)/var/run/twopence
	chmod 770 $(DESTDIR)/var/run/twopence
	ln -s $(DESTDIR)/usr/lib64/libtwopence.so.$(VERSION) $(DESTDIR)/usr/lib64/libtwopence.so.0
	cp add_virtio_channel.sh $(DESTDIR)/usr/lib/twopence-0/


tests: server shell
	make -C tests $@
