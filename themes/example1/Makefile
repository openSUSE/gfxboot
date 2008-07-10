BINDIR := $(shell [ -x ../../gfxboot-compile ] && echo ../../ )
GFXBOOT_COMPILE = $(BINDIR)gfxboot-compile
GFXBOOT = $(BINDIR)gfxboot
BFLAGS = -O -v -L ../..

.PHONY: all themes clean distclean

all: example1

example1: example1.gb
	@rm -rf $@.dir
	@mkdir $@.dir
	$(GFXBOOT_COMPILE) $(BFLAGS) -l $@.log -c $< $@.dir/init
	$(GFXBOOT) --archive $@.dir --pack-archive $@

test: example1
	$(GFXBOOT) --archive $< --bootloader isolinux --test --preview

clean:
	rm -rf *~ *.log *.dir example1

distclean: clean

