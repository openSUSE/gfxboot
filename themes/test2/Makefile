BINDIR   := $(shell [ -x ../../mkbootmsg ] && echo ../../ )
MKBOOTMSG = $(BINDIR)mkbootmsg
BFLAGS    = -O -v -L ../..

ifneq ($(BINDIR),)
  BM_TARGET := $(MKBOOTMSG)
endif

.PHONY: all themes clean

all: themes

themes: bootlogo

bootlogo: test.ps $(BM_TARGET)
	$(MKBOOTMSG) $(BFLAGS) -l log -c $< init
	echo -e "init\ntest.jpg\ntest.pcx\n16x16.fnt" | cpio -o >bootlogo

clean:
	rm -f *~ log init bootlogo
