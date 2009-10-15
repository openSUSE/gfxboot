BINDIR := $(shell [ -x ../../gfxboot-compile ] && echo ../../ )
GFXBOOT_COMPILE = $(BINDIR)gfxboot-compile
GFXBOOT_FONT = $(BINDIR)gfxboot-font
GFXBOOT = $(BINDIR)gfxboot
BFLAGS = -O -v -L ../..

.PHONY: all themes clean distclean

all: bootlogo

bootlogo: example_*.bc
	@rm -rf $@.dir
	@mkdir $@.dir
	$(GFXBOOT_COMPILE) $(BFLAGS) -l $@.log -c $< $@.dir/init
	$(GFXBOOT) --archive $@.dir --pack-archive $@

clean:
	rm -rf *~ *.log *.dir bootlogo

distclean: clean

