CC	 = gcc
CFLAGS	 = -g -Wall -O2 -fomit-frame-pointer
X11LIBS	 = /usr/X11/lib
THEMES	 = $(wildcard themes/*)
# LIBFILES = happysuse.mod system.inc

.PHONY: all themes clean install

all:	bin2c mkbootmsg bincode getx11font addblack

getx11font: getx11font.c
	$(CC) $(CFLAGS) -L$(X11LIBS) $< -lX11 -o $@

mkbootmsg: mkbootmsg.c vocabulary.h bincode.h
	$(CC) $(CFLAGS) $< -o $@

addblack: addblack.c
	$(CC) $(CFLAGS) $< -o $@

bincode.o:  bincode.asm vocabulary.inc modplay_defines.inc modplay.inc kroete.inc
	nasm -f elf -O10 -o $@ -l bincode.lst $<

bincode: bincode.o jpeg.o
	ld --section-start .text=0 --oformat binary -o $@ $^

bincode.h:  bincode bin2c
	./bin2c bincode >bincode.h

bin2c: bin2c.c
	$(CC) $(CFLAGS) $< -o $@

vocabulary.inc: mk_vocabulary
	./mk_vocabulary -a >$@

vocabulary.h: mk_vocabulary
	./mk_vocabulary -c >$@

jpeg.o: jpeg.S
	as -ahlsn=jpeg.lst -o $@ $<

install: all
	install -d -m 755 $(DESTDIR)/usr/sbin $(DESTDIR)/usr/share/gfxboot
	install -m 755 mkbootmsg getx11font help2txt $(DESTDIR)/usr/sbin
#	install -m 644 $(LIBFILES) $(DESTDIR)/usr/share/gfxboot
	cp -a themes $(DESTDIR)/usr/share/gfxboot

clean: themes
	@rm -f mkbootmsg bincode getx11font addblack bincode.h bin2c *.lst vocabulary.inc vocabulary.h *.o *~
	@rm -rf tmp

themes:
	@for i in $(THEMES) ; do make -C $$i BINDIR=../../ $(MAKECMDGOALS) ; done

