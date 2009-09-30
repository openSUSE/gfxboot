BINDIR      := $(shell [ -x ../../../gfxboot-font ] && echo ../../../ )

GFXBOOT_FONT = $(BINDIR)gfxboot-font
KEYMAPCHARS  = $(BINDIR)bin/keymapchars

all: .ready

fonts: 16x16.fnt

.ready:
	@touch .ready

16x16.fnt: ../po/en.tr ../src/main.log
	cat ../po/*.tr ../help-*/*/*.html >tmp.txt
	$(GFXBOOT_FONT) -v -l 18 \
	-a 0x2022-0x2023 \
	-c ISO-8859-15 -c ISO-8859-2 -c koi8-r \
	`$(KEYMAPCHARS) ../keymaps/keymap.*.inc` \
	-t tmp.txt \
	-t ../src/main.log \
	-t ../data-install/languages \
	-f NachlieliCLM-Bold:size=14:c=0x590-0x5ff \
	-f KacstOne:size=14:c=0x600-0x6ff,0xfe70-0xfefc:dy=2 \
	-f MuktiNarrow:size=18:c=0x0981-0x09fa:bold=1 \
	-f lohit_hi:size=16:c=0x0901-0x0970:bold=1 \
	-f lohit_pa:size=15:c=0x0a01-0x0a74:bold=1:autohint=1 \
	-f lohit_gu:size=15:c=0x0a81-0x0af1:bold=1 \
	-f TSCu_Paranar:size=18:c=0x0b82-0x0bfa:dy=2:bold=1 \
	-f lklug:size=17:c=0x0d82-0x0df4:bold=1:dy=1 \
	-f Loma:size=17:c=0x0e01-0x0e7f:bold=0:dy=-2 \
	-f Loma:size=17:c=0x0e81-0x0eff:bold=0:dy=-2 \
	-f KhmerOS_sys:size=16:c=0x1780-0x17f9:dy=-2 \
	-f DejaVuSans-Bold:size=14 \
	-f FZHeiTi:size=17:nobitmap=1:autohint=1 \
	-f gulim:size=17:bold=1:nobitmap=1:autohint=1 \
	16x16.fnt >16x16.fnt.log
	rm -f tmp.txt

clean:
	rm -f .ready *~

