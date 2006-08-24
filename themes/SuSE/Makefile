BINDIR      := $(shell [ -x ../../mkbootmsg ] && echo ../../ )

PRODUCT      = "openSUSE 10.2"
export PRODUCT

HELP2TXT     = $(BINDIR)help2txt
MKBOOTMSG    = $(BINDIR)mkbootmsg
BFLAGS       = -O -v -L ../..
INCLUDES     = $(wildcard *.inc)
TRANSLATIONS = $(addsuffix .tr,en $(notdir $(basename $(wildcard po/*.po))))
HELPBOOT     = $(addsuffix .hlp,$(addprefix boot/,$(subst .,,$(suffix $(basename $(wildcard help-boot.*.html))))))
HELPINST     := $(addsuffix .hlp,$(addprefix install/,$(subst .,,$(suffix $(basename $(wildcard help-install.*.html))))))

HELPBOOT_ALL = $(notdir $(HELPBOOT))
HELPINST_ALL = $(notdir $(HELPINST))

DEFAULT_LANG =

PIC_COMMON   = timer_a.jpg
PIC_INSTALL  = back.jpg welcome.jpg text*.pcx
PIC_BOOT     = back.jpg

FILES_INST   = init languages $(TRANSLATIONS) 16x16.fnt kroete.dat hapysuse.mod \
	       $(PIC_COMMON) $(PIC_INSTALL) $(HELPINST_ALL)

FILES_BOOT   = init languages $(TRANSLATIONS) 16x16.fnt \
	       $(PIC_COMMON) $(PIC_BOOT) $(HELPBOOT_ALL)

FILES_BOOT_EN = init languages en.tr 16x16.fnt $(PIC_COMMON) back.jpg en.hlp

INST_EXT     = 16x16.fnt $(PIC_COMMON) $(PIC_INSTALL) kroete.dat hapysuse.mod *.hlp *.tr

ifdef DEFAULT_LANG
FILES_INST += lang
FILES_BOOT += lang
FILES_BOOT_EN += lang $(DEFAULT_LANG).tr $(DEFAULT_LANG).hlp
endif

boot/%.hlp: help-boot.%.html boot
	$(HELP2TXT) --product=$(PRODUCT) $< >$@

install/%.hlp: help-install.%.html install
	$(HELP2TXT) --product=$(PRODUCT) $< >$@

.PHONY: all themes font clean po

all: themes

boot.config:
	$(error run 'make prep' first)

boot install: po
	mkdir -p $@

po:
	make -C po

themes: bootdir installdir

bootdir: boot.config po boot $(INCLUDES) $(HELPBOOT)
	@cp -a po/*.tr boot
	@for i in $(FILES_BOOT) ; do [ -f $$i ] && cp $$i boot ; done ; true
	@echo en >boot/languages
	$(MKBOOTMSG) $(BFLAGS) -l boot/log -c $< boot/init
ifdef DEFAULT_LANG
	@echo $(DEFAULT_LANG) >boot/lang
	@echo $(DEFAULT_LANG) >>boot/languages
endif
	@sh -c 'cd boot; echo $(FILES_BOOT_EN) | sed -e "s/ /\n/g" | cpio --quiet -o >message'

installdir: install.config po install $(INCLUDES) $(HELPINST)
	@cp -a po/*.tr install
	@for i in $(FILES_INST) ; do [ -f $$i ] && cp $$i install ; done ; true
	$(MKBOOTMSG) $(BFLAGS) -l install/log -c $< install/init
ifdef DEFAULT_LANG
	@echo $(DEFAULT_LANG) >install/lang
endif
	@sh -c 'cd install; chmod +t $(INST_EXT)'
	@sh -c 'cd install; echo $(FILES_INST) | sed -e "s/ /\n/g" | cpio --quiet -o >bootlogo'

font:
	cat po/*.po *.html >tmp.txt
	../../getx11font -v -l 18 -p 2,4 \
	-c ISO-8859-15 -c ISO-8859-2 -c koi8-r \
	`../../bin/keymapchars keymap.*.inc` \
	-t tmp.txt \
	-t install/log -t boot/log \
	-t languages \
	-f -efont-fixed-bold-r-normal--16-160-75-75-c-80-iso10646-1 \
	-f -efont-fixed-bold-r-normal--16-160-75-75-c-160-iso10646-1 \
	--fsize 16,5 -f '-freetype-haydar unicode-medium-r-normal--17-120-100-100-p-81-iso10646-1' \
	16x16.fnt >16x16.fnt.log
	rm -f tmp.txt

clean:
	[ ! -f po/Makefile ] || make -C po clean
	rm -f `find -type l`
	rmdir po 2>/dev/null || true
	rm -f bootdir installdir *~ *.log
	rm -rf boot install

prep:
	[ -e boot.config ] || { mkdir po ; ../../bin/adddir ../SuSE . ; }
	[ ! -f po/Makefile ] || make -C po clean
	rm -f bootdir installdir *~ *.log
	rm -rf boot install

