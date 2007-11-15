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
	echo -e "init\njaguar.pcx" | cpio -o >bootlogo

clean:
	rm -f *~ log init bootlogo

distclean: clean

