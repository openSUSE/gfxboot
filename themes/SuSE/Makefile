HELP2TXT   = $(BINDIR)help2txt
MKBOOTMSG  = $(BINDIR)mkbootmsg
BFLAGS     = -O -v -L ../..
INCLUDES   = $(wildcard *.inc)
HELPBOOT   = help-boot.en.txt help-boot.cs.txt help-boot.sk.txt
HELPINST   = help-install.en.txt
TRANSL     = texts.en texts.cs texts.de texts.sk     

FILES_INST = init languages $(TRANSL) help.en \
	     16x16.font kroete.data background.pcx splash.pcx
FILES_BOOT = init languages $(TRANSL) help.en help.cs help.sk 16x16.font background.pcx

%.txt: %.html
	$(HELP2TXT) $< >$@

.PHONY: all themes clean po

all: themes

po:
	make -C po

themes: boot install

boot install: po

boot: boot.config $(INCLUDES) $(HELPBOOT)
	@mkdir -p $@
	@cp -a po/texts.* .
	$(MKBOOTMSG) $(BFLAGS) -l $@/log -c $< init
	@cp help-$@.en.txt help.en
	@cp help-$@.cs.txt help.cs
	@cp help-$@.sk.txt help.sk
	@echo $(FILES_BOOT) | sed -e 's/ /\n/g' | cpio --quiet -o >$@/message
	@mv init help.en help.cs help.sk $@
	@mv texts.* $@

install: install.config $(INCLUDES) $(HELPINST)
	@mkdir -p $@
	@cp -a po/texts.* .
	$(MKBOOTMSG) $(BFLAGS) -l $@/log -c $< init
#	@echo de >lang
	@cp help-$@.en.txt help.en
#	@cp help-$@.de.txt help.de
	@echo $(FILES_INST) | sed -e 's/ /\n/g' | cpio --quiet -o >$@/bootlogo
	@mv init help.en $@
	@mv texts.* $@
#	@rm -f lang

clean:
	make -C po clean
	rm -f *.txt *~
	rm -rf boot install

