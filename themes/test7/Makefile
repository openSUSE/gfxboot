BINDIR   := $(shell [ -x ../../gfxboot-compile ] && echo ../../ )
MKBOOTMSG = $(BINDIR)gfxboot-compile
BFLAGS    = -O -v -L ../..

.PHONY: all themes clean distclean

all: bootlogo

bootlogo: test7
	@cp test7 bootlogo

test7: test7.gb
	@rm -rf $@.dir
	@mkdir $@.dir
	$(MKBOOTMSG) $(BFLAGS) -l $@.log -c $< $@.dir/init
	cp -r data/* $@.dir
	@sh -c 'cd $@.dir; echo * | sed -e "s/ /\n/g" | cpio --quiet -o >../$@'

clean:
	rm -rf *~ *.log *.dir bootlogo test7

distclean: clean

