BINDIR := $(shell [ -x ../../gfxboot-compile ] && echo ../../ )
GFXBOOT_COMPILE = $(BINDIR)gfxboot-compile
GFXBOOT_FONT = $(BINDIR)gfxboot-font
GFXBOOT = $(BINDIR)gfxboot
BFLAGS = -O -v -L ../..

.PHONY: all themes clean distclean

all: bootlogo

bootlogo: example_*.bc font
	@rm -rf $@.dir
	@mkdir $@.dir
	$(GFXBOOT_COMPILE) $(BFLAGS) -l $@.log -c $< $@.dir/init
	@cp clouds.jpg font.fnt $@.dir
	touch --reference Makefile $@.dir/*
	$(GFXBOOT) --archive $@.dir --pack-archive $@

font:
	$(GFXBOOT_FONT) -v -f DejaVuSans:size=32 font.fnt >font.log

clean:
	rm -rf *~ *.log *.dir bootlogo *.fnt

distclean: clean

