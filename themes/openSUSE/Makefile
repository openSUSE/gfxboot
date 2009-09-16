BINDIR      := $(shell [ -x ../../gfxboot-compile ] && echo ../../ )

BASED_ON     = $(shell perl -ne 'print if s/^based_on=//' config)

ifeq ($(BASED_ON),)
PREPARED     = 1
else
PREPARED     = $(shell [ -f .prepared ] && echo 1)
endif

ADDDIR       = ../../bin/adddir
BFLAGS       = -O -v -L ../..

SUBDIRS      = fonts help-boot help-install po src

THEME        = $(shell basename `pwd`)

DEFAULT_LANG =

.PHONY: all clean distclean themes $(SUBDIRS)

ifeq ($(PREPARED), 1)

  all: bootlogo message

else

  all:
	$(ADDDIR) ../$(BASED_ON) .
	make clean
	touch .prepared
	make

endif

themes: all

%/.ready: %
	make -C $*

src/main.bin: src
	make -C src

bootlogo: src/main.bin help-install/.ready po/.ready fonts/.ready
	@rm -rf bootlogo.dir
	@mkdir bootlogo.dir
	perl -p -e 's/^(layout=.*)/$$1,install/' src/gfxboot.cfg >bootlogo.dir/gfxboot.cfg
	perl -pi -e 's/^(theme=).*/$$1$(THEME)/' bootlogo.dir/gfxboot.cfg
	cp -rL data-install/* fonts/*.fnt po/*.tr bootlogo.dir
	cp -rL help-install/*.hlp bootlogo.dir
	cp src/main.bin bootlogo.dir/init
ifdef DEFAULT_LANG
	@echo $(DEFAULT_LANG) >bootlogo.dir/lang
endif
	@sh -c 'cd bootlogo.dir; chmod +t * ; chmod -t init languages'
	@sh -c 'cd bootlogo.dir; echo * | sed -e "s/ /\n/g" | cpio --quiet -o >../bootlogo'

message: src/main.bin help-boot/.ready po/.ready fonts/.ready
	@rm -rf message.dir
	@mkdir message.dir
	perl -p -e 's/^(layout=.*)/$$1,boot/' src/gfxboot.cfg >message.dir/gfxboot.cfg
	perl -pi -e 's/^(theme=).*/$$1$(THEME)/' message.dir/gfxboot.cfg
	cp -rL data-boot/* fonts/*.fnt message.dir
	cp -rL po/en.tr help-boot/en.hlp message.dir
	cp src/main.bin message.dir/init
ifdef DEFAULT_LANG
	cp -rL po/$(DEFAULT_LANG).tr help-boot/$(DEFAULT_LANG).hlp message.dir
	@echo $(DEFAULT_LANG) >message.dir/lang
	@echo $(DEFAULT_LANG) >>message.dir/languages
endif
	@sh -c 'cd message.dir; echo * | sed -e "s/ /\n/g" | cpio --quiet -o >../message'

clean:
	@for i in $(SUBDIRS) ; do [ ! -f $$i/Makefile ] ||  make -C $$i clean || break ; done
	rm -rf bootlogo bootlogo.dir message message.dir *~

distclean: clean
ifneq ($(BASED_ON),)
	rm -f .prepared
	rm -f `find -type l \! -wholename ./Makefile`
	rmdir `find -depth -type d \! -name . \! -name .svn \! -wholename './.svn/*' \! -wholename './*/.svn/*'` 2>/dev/null || true
endif

	