POFILES	= $(wildcard *.po)
TEXTS	= $(addsuffix .tr,$(basename $(wildcard *.po)))

all: text.inc $(TEXTS)

%.tr: %.po text.inc
	bin/po2txt $< >$@

# en.tr uses msgids from bootloader.pot
en.tr text.inc: bootloader.pot
	bin/po2txt $< >en.tr

clean:
	rm -f text.inc *.tr *~
