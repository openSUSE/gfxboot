CC	 = gcc
CFLAGS	 = -g -Wall -Wno-pointer-sign -O2 -fomit-frame-pointer

GIT2LOG := $(shell if [ -x ./git2log ] ; then echo ./git2log --update ; else echo true ; fi)
GITDEPS := $(shell [ -d .git ] && echo .git/HEAD .git/refs/heads .git/refs/tags)
VERSION := $(shell $(GIT2LOG) --version VERSION ; cat VERSION)
BRANCH  := $(shell git branch | perl -ne 'print $$_ if s/^\*\s*//')
PREFIX  := gfxboot-$(VERSION)

# THEMES	 = $(wildcard themes/*)
THEMES	 = themes/upstream themes/openSUSE themes/SLES themes/SLED themes/KDE

.PHONY: all clean distclean doc install installsrc themes

all:	changelog bin2c gfxboot-compile bincode gfxboot-font addblack

changelog: $(GITDEPS)
	$(GIT2LOG) --changelog changelog

gfxboot-font: gfxboot-font.c
	$(CC) $(CFLAGS) -I /usr/include/freetype2 -lfreetype $< -o $@

gfxboot-compile: gfxboot-compile.c vocabulary.h bincode.h
	$(CC) $(CFLAGS) $< -o $@

addblack: addblack.c
	$(CC) $(CFLAGS) $< -o $@

bincode.o:  bincode.asm vocabulary.inc modplay_defines.inc modplay.inc kroete.inc
	bin/trace_context bincode.asm
	nasm -f elf -O99 -o $@ -l bincode.lst $<

bincode: bincode.o jpeg.o
	ld -m elf_i386 --section-start .text=0 --oformat binary -Map bincode.map -o $@ $^

bincode.h:  bincode bin2c
	./bin2c bincode >bincode.h

bin2c: bin2c.c
	$(CC) $(CFLAGS) $< -o $@

vocabulary.inc: mk_vocabulary
	./mk_vocabulary -a >$@

vocabulary.h: mk_vocabulary
	./mk_vocabulary -c >$@

jpeg.o: jpeg.S
	as --32 -mx86-used-note=no -ahlsn=jpeg.lst -o $@ $<

install: all
	install -d -m 755 $(DESTDIR)/usr/sbin
	perl -p -e 's/<VERSION>/$(VERSION)/' gfxboot >gfxboot~
	install -m 755 gfxboot~ $(DESTDIR)/usr/sbin/gfxboot
	install -m 755 gfxtest $(DESTDIR)/usr/sbin
	install -m 755 gfxboot-compile gfxboot-font $(DESTDIR)/usr/sbin
	@for i in $(THEMES) ; do \
	  install -d -m 755 $(DESTDIR)/etc/bootsplash/$$i/{bootloader,cdrom} ; \
	  cp $$i/bootlogo $(DESTDIR)/etc/bootsplash/$$i/cdrom ; \
	  bin/unpack_bootlogo $(DESTDIR)/etc/bootsplash/$$i/cdrom ; \
          install -m 644 $$i/{message,po/*.tr,help-boot/*.hlp} $(DESTDIR)/etc/bootsplash/$$i/bootloader ; \
	  bin/2hl --link --quiet $(DESTDIR)/etc/bootsplash/$$i/* ; \
	done

installsrc:
	install -d -m 755 $(DESTDIR)/usr/share/gfxboot/themes
	@for i in $(THEMES) ; do \
	  cp -a $$i $(DESTDIR)/usr/share/gfxboot/themes ; \
	done
	cp -a themes/example* $(DESTDIR)/usr/share/gfxboot/themes
	cp -a bin test $(DESTDIR)/usr/share/gfxboot

archive: changelog
	mkdir -p package
	git archive --prefix=$(PREFIX)/ $(BRANCH) | tar --no-wildcards-match-slash --wildcards --delete 'gfxboot-*/themes' > package/$(PREFIX).tar
	tar -r -f package/$(PREFIX).tar --mode=0664 --owner=root --group=root --mtime="`git show -s --format=%ci`" --transform='s:^:$(PREFIX)/:' VERSION changelog
	xz -f package/$(PREFIX).tar
	for i in $(THEMES) ; do \
	  git archive $(BRANCH) $$i | xz > package/$${i#*/}.tar.xz || break ; \
	done
	git archive $(BRANCH) themes/example* | xz > package/examples.tar.xz

clean: themes doc
	@rm -f gfxboot-compile bincode gfxboot-font addblack bincode.h bin2c *.lst *.map vocabulary.inc vocabulary.h *.o *~
	@rm -rf tmp package

distclean: clean
	@for i in themes/example* ; do make -C $$i clean || break ; done

themes:
	@for i in $(THEMES) ; do make -C $$i $(MAKECMDGOALS) || break ; done

doc:
	make -C doc $(MAKECMDGOALS)

