BINDIR   := $(shell [ -x ../../mkbootmsg ] && echo ../../ )
MKBOOTMSG = $(BINDIR)mkbootmsg
BFLAGS    = -O -v -L ../..

ifneq ($(BINDIR),)
  BM_TARGET := $(MKBOOTMSG)
endif

.PHONY: all prep themes clean distclean

all: themes

prep:

themes: bootlogo

bootlogo: test.ps normal.fnt $(BM_TARGET)
	$(MKBOOTMSG) $(BFLAGS) -l log -c $< init
	echo -e "init\ncat.jpg\nnormal.fnt" | cpio -o >bootlogo

normal.fnt:
	../../mkblfont -v -l 32 -f DejaVuSans:size=32 normal.fnt >normal.fnt.log

clean:
	rm -f *~ log init bootlogo normal.*

distclean: clean

