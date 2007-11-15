ARCH    := $(shell uname -m)

CC	 = gcc
CFLAGS	 = -g -Wall -Wno-pointer-sign -O2 -fomit-frame-pointer
THEMES	 = $(wildcard themes/*)

.PHONY: all clean distclean doc install themes

all:	bin2c mkbootmsg bincode mkblfont addblack

mkblfont: mkblfont.c
	$(CC) $(CFLAGS) -I /usr/include/freetype2 -lfreetype $< -o $@

mkbootmsg: mkbootmsg.c vocabulary.h bincode.h
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
	install -d -m 755 $(DESTDIR)/usr/sbin $(DESTDIR)/usr/share/gfxboot
	install -m 755 mkbootmsg mkblfont help2txt $(DESTDIR)/usr/sbin
	cp -a themes $(DESTDIR)/usr/share/gfxboot
	cp -a bin $(DESTDIR)/usr/share/gfxboot

clean: themes doc
	@rm -f mkbootmsg bincode mkblfont addblack bincode.h bin2c *.lst *.map vocabulary.inc vocabulary.h *.o *~
	@rm -rf tmp

distclean: clean

themes:
	@for i in $(THEMES) ; do make -C $$i BINDIR=../../ $(MAKECMDGOALS) || break ; done

doc:
	make -C doc $(MAKECMDGOALS)

