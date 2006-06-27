POFILES	= $(wildcard *.po)
TEXTS	= $(addsuffix .tr,$(basename $(wildcard *.po)))

PRODUCT ?= "SUSE Linux 10.2"

all: text.inc $(TEXTS)

%.tr: %.po text.inc
	bin/po2txt --product=$(PRODUCT) $< >$@

# en.tr uses msgids from bootloader.pot
en.tr text.inc: bootloader.pot
	bin/po2txt --product=$(PRODUCT) $< >en.tr

clean:
	rm -f text.inc *.tr *~
