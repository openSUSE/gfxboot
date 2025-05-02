BINDIR := $(shell [ -x ../../gfxboot-compile ] && echo ../../ )
GFXBOOT_COMPILE = $(BINDIR)gfxboot-compile
GFXBOOT_FONT = $(BINDIR)gfxboot-font
GFXBOOT = $(BINDIR)gfxboot
BFLAGS = -O -v -L ../..

# the files we need
FILES = clouds.jpg font.fnt

.PHONY: all themes clean distclean

all: bootlogo

bootlogo: example_*.bc font
	@rm -rf $@.dir
	@mkdir $@.dir
	$(GFXBOOT_COMPILE) $(BFLAGS) -l $@.log -c $< $@.dir/init
	@cp $(FILES) $@.dir
	touch --reference example_07.bc $@.dir/*
	$(GFXBOOT) --archive $@.dir --pack-archive $@
	@ln -snf bootlogo message

font:
	$(GFXBOOT_FONT) -v -f DejaVuSans:size=32 font.fnt >font.log

clean:
	rm -rf *~ *.log *.dir bootlogo message *.fnt

distclean: clean

