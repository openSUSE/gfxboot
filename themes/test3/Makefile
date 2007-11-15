BINDIR   := $(shell [ -x ../../mkbootmsg ] && echo ../../ )
MKBOOTMSG = $(BINDIR)mkbootmsg
BFLAGS    = -O -v -L ../..

ifneq ($(BINDIR),)
  BM_TARGET := $(MKBOOTMSG)
endif

.PHONY: all themes clean distclean

all: themes

themes: bootlogo

bootlogo: test.ps $(BM_TARGET)
	$(MKBOOTMSG) $(BFLAGS) -l log -c $< init
	echo -e "init\nhead.jpg\nhead_a.pcx\nsky.jpg\n16x16.fnt" | cpio -o >bootlogo

clean:
	rm -f *~ log init bootlogo

distclean: clean

