BINDIR   := $(shell [ -x ../../gfxboot-compile ] && echo ../../ )
MKBOOTMSG = $(BINDIR)gfxboot-compile
BFLAGS    = -O -v -L ../..

ifneq ($(BINDIR),)
  BM_TARGET := $(MKBOOTMSG)
endif

.PHONY: all prep themes clean distclean

all: themes

prep:

themes: bootlogo

bootlogo: test.ps 16x16.fnt $(BM_TARGET)
	$(MKBOOTMSG) $(BFLAGS) -l log -c $< init
	echo -e "init\nsky.jpg\n16x16.fnt" | cpio -o >bootlogo

16x16.fnt:
	../../gfxboot-font -v -l 24 -f DejaVuSans:size=20 16x16.fnt >16x16.fnt.log

clean:
	rm -f *~ log init bootlogo 16x16.*

distclean: clean

