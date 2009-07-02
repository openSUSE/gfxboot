ARCH    := $(shell uname -m)

CC	 = gcc
CFLAGS	 = -g -Wall -Wno-pointer-sign -O2 -fomit-frame-pointer
# THEMES	 = $(wildcard themes/*)
THEMES	 = themes/upstream themes/openSUSE themes/SLES themes/SLED

.PHONY: all clean distclean doc install installsrc themes

all:	bin2c gfxboot-compile bincode gfxboot-font addblack

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
	as --32 -ahlsn=jpeg.lst -o $@ $<

install: all
	install -d -m 755 $(DESTDIR)/usr/sbin
	install -m 755 gfxboot gfxboot-compile gfxboot-font $(DESTDIR)/usr/sbin
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
	cp -a bin $(DESTDIR)/usr/share/gfxboot

clean: themes doc
	@rm -f gfxboot-compile bincode gfxboot-font addblack bincode.h bin2c *.lst *.map vocabulary.inc vocabulary.h *.o *~
	@rm -rf tmp

distclean: clean

themes:
	@for i in $(THEMES) ; do make -C $$i $(MAKECMDGOALS) || break ; done

doc:
	make -C doc $(MAKECMDGOALS)

