HELP2TXT     = $(BINDIR)help2txt
MKBOOTMSG    = $(BINDIR)mkbootmsg
BFLAGS       = -O -v -L ../..
INCLUDES     = $(wildcard *.inc)
TRANSLATIONS = $(addprefix texts.,en $(notdir $(basename $(wildcard po/*.po))))
HELPBOOT     = $(addprefix boot/help,$(suffix $(basename $(wildcard help-boot.*.html))))
HELPINST     = $(addprefix install/help,$(suffix $(basename $(wildcard help-install.*.html))))

HELPBOOT_ALL = $(notdir $(HELPBOOT))
HELPINST_ALL = $(notdir $(HELPINST))

DEFAULT_LANG =

FILES_INST   = init languages $(TRANSLATIONS) 16x16.font background.pcx \
	       splash.pcx kroete.data \
	       $(HELPINST_ALL)

FILES_BOOT   = init languages $(TRANSLATIONS) 16x16.font background.pcx \
	       $(HELPBOOT_ALL)

ifdef DEFAULT_LANG
FILES_INST += lang
FILES_BOOT += lang
endif

boot/help.%: help-boot.%.html boot
	$(HELP2TXT) $< >$@

install/help.%: help-install.%.html install
	$(HELP2TXT) $< >$@

.PHONY: all themes font clean po

all: themes

boot install: po
	mkdir -p $@

po:
	make -C po

themes: bootdir installdir

bootdir: boot.config $(INCLUDES) $(HELPBOOT)
	@cp -a po/texts.* boot
	@for i in $(FILES_BOOT) ; do [ -f $$i ] && cp $$i boot ; done ; true
	$(MKBOOTMSG) $(BFLAGS) -l boot/log -c $< boot/init
ifdef DEFAULT_LANG
	@echo $(DEFAULT_LANG) >boot/lang
endif
	@sh -c 'cd boot; echo $(FILES_BOOT) | sed -e "s/ /\n/g" | cpio --quiet -o >message'

installdir: install.config $(INCLUDES) $(HELPINST)
	@cp -a po/texts.* install
	@for i in $(FILES_INST) ; do [ -f $$i ] && cp $$i install ; done ; true
	$(MKBOOTMSG) $(BFLAGS) -l install/log -c $< install/init
ifdef DEFAULT_LANG
	@echo $(DEFAULT_LANG) >install/lang
endif
	@sh -c 'cd install; echo $(FILES_INST) | sed -e "s/ /\n/g" | cpio --quiet -o >bootlogo'

font:
	../../getx11font -v -l 18 -p 2,4 \
	-c ISO-8859-15 -c ISO-8859-2 -c koi8-r \
	-t help-boot.ja.html \
	-t help-install.ja.html \
	-t po/ja.po \
	-t install/log -t boot/log \
	-f -efont-fixed-medium-r-normal--16-160-75-75-c-80-iso10646-1 \
	-f -efont-fixed-medium-r-normal--16-160-75-75-c-160-iso10646-1 \
	16x16.font >16x16.font.log

clean:
	make -C po clean
	rm -f bootdir installdir *~
	rm -rf boot install

