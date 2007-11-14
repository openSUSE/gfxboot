BINDIR      := $(shell [ -x ../../mkbootmsg ] && echo ../../ )

PRODUCT      = "openSUSE 10.3"
export PRODUCT

MKBOOTMSG    = $(BINDIR)mkbootmsg
BFLAGS       = -O -v -L ../..

SUBDIRS      = fonts help-boot help-install po src

DEFAULT_LANG =

.PHONY: all clean $(SUBDIRS)

all: bootlogo message

%/.ready: %
	make -C $*

src/main.bin: src
	make -C src

bootlogo: src/main.bin help-install/.ready po/.ready fonts/.ready
	@rm -rf bootlogo.dir
	@mkdir bootlogo.dir
	cp -r languages gfxboot.cfg data-install/* fonts/*.fnt po/*.tr bootlogo.dir
	cp -r help-install/*.hlp bootlogo.dir
	cp src/main.bin bootlogo.dir/init
ifdef DEFAULT_LANG
	@echo $(DEFAULT_LANG) >bootlogo.dir/lang
endif
	@sh -c 'cd bootlogo.dir; chmod +t * ; chmod -t init languages'
	@sh -c 'cd bootlogo.dir; echo * | sed -e "s/ /\n/g" | cpio --quiet -o >../bootlogo'

message: src/main.bin help-boot/.ready po/.ready fonts/.ready
	@rm -rf message.dir
	@mkdir message.dir
	cp -r languages gfxboot.cfg data-boot/* fonts/*.fnt message.dir
	cp -r po/en.tr help-boot/en.hlp message.dir
	cp src/main.bin message.dir/init
	@echo en_US >message.dir/languages
ifdef DEFAULT_LANG
	cp -r po/$(DEFAULT_LANG).tr help-boot/$(DEFAULT_LANG).hlp message.dir
	@echo $(DEFAULT_LANG) >message.dir/lang
	@echo $(DEFAULT_LANG) >>message.dir/languages
endif
#	@sh -c 'cd message.dir; chmod +t * ; chmod -t init languages'
	@sh -c 'cd message.dir; echo * | sed -e "s/ /\n/g" | cpio --quiet -o >../message'

clean:
	@for i in $(SUBDIRS) ; do make -C $$i clean ; done
	rm -rf bootlogo bootlogo.dir message message.dir *~

