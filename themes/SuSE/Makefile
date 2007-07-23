BINDIR      := $(shell [ -x ../../mkbootmsg ] && echo ../../ )

PRODUCT      = "openSUSE 10.3"
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

PIC_COMMON   = timer_a.jpg pback.jpg phead.jpg panim{,_a}.jpg pabout.txt gfxboot.cfg
PIC_INSTALL  = back.jpg welcome.jpg text*.pcx
PIC_BOOT     = back-boot.jpg

FILES_INST   = init languages $(TRANSLATIONS) 16x16.fnt kroete.dat \
	       $(PIC_COMMON) $(PIC_INSTALL) $(HELPINST_ALL)

FILES_BOOT   = init languages $(TRANSLATIONS) 16x16.fnt \
	       $(PIC_COMMON) $(PIC_BOOT) $(HELPBOOT_ALL)

FILES_BOOT_EN = init languages en.tr 16x16.fnt $(PIC_COMMON) back.jpg en.hlp

INST_EXT     = 16x16.fnt $(PIC_COMMON) $(PIC_INSTALL) kroete.dat *.hlp *.tr

ifdef DEFAULT_LANG
FILES_INST += lang
FILES_BOOT += lang
FILES_BOOT_EN += lang $(DEFAULT_LANG).tr $(DEFAULT_LANG).hlp
endif

boot/%.hlp: help-boot.%.html boot
	$(HELP2TXT) --product=$(PRODUCT) $< >$@

install/%.hlp: help-install.%.html install
	$(HELP2TXT) --product=$(PRODUCT) $< >$@

.PHONY: all themes font aafont bitmapfont clean po

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
	@mv boot/back-boot.jpg boot/back.jpg
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

font: aafont

aafont:
	cat po/*.tr *.html >tmp.txt
	../../mkblfont -v -l 18 \
	-c ISO-8859-15 -c ISO-8859-2 -c koi8-r \
	`../../bin/keymapchars keymap.*.inc` \
	-t tmp.txt \
	-t install/log -t boot/log \
	-t languages \
	-f NachlieliCLM-Bold:size=14:c=0x590-0x5ff \
	-f KacstOne:size=14:c=0x600-0x6ff,0xfe70-0xfefc:dy=2 \
	-f MuktiNarrow:size=18:c=0x0981-0x09fa:bold=1 \
	-f lohit_hi:size=18:c=0x0901-0x0970:bold=1 \
	-f lohit_pa:size=19:c=0x0a01-0x0a74:bold=1 \
	-f lohit_gu:size=18:c=0x0a81-0x0af1:bold=1 \
	-f TSCu_Paranar:size=18:c=0x0b82-0x0bfa:dy=2:bold=1 \
	-f lklug:size=17:c=0x0d82-0x0df4:bold=1:dy=1 \
	-f KhmerOSsys:size=16:c=0x1780-0x17f9:dy=-2 \
	-f DejaVuSans-Bold:size=14 \
	-f FZHeiTi:size=17:nobitmap=1 \
	-f gulim:size=17:bold=1:nobitmap=1 \
	16x16.fnt >16x16.fnt.log
	rm -f tmp.txt

bitmapfont:
	cat po/*.tr *.html >tmp.txt
	../../mkblfont -v -l 18 \
	-c ISO-8859-15 -c ISO-8859-2 -c koi8-r \
	`../../bin/keymapchars keymap.*.inc` \
	-t tmp.txt \
	-t install/log -t boot/log \
	-t languages \
	-f b16_b:prop=2:space_width=6 \
	16x16.fnt >16x16.fnt.log
	rm -f tmp.txt

clean:
	[ ! -f po/Makefile ] || make -C po clean
	rm -f `find -type l`
	rmdir po 2>/dev/null || true
	rm -f bootdir installdir *~
	rm -rf boot install

prep:
	[ -e boot.config ] || { mkdir po ; ../../bin/adddir ../SuSE . ; }
	[ ! -f po/Makefile ] || make -C po clean
	rm -f bootdir installdir *~
	rm -rf boot install

