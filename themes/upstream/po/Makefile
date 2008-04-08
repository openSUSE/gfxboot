POFILES	= $(wildcard *.po)
TEXTS	= $(addsuffix .tr,$(basename $(wildcard *.po)))

PRODUCT = $(shell perl -ne 'print if s/^product=//' ../config)

all: .ready

.ready: text.inc $(TEXTS)
	@touch .ready

%.tr: %.po text.inc
	bin/po2txt --product='$(PRODUCT)' $< >$@

# en.tr uses msgids from bootloader.pot
en.tr text.inc: bootloader.pot
	bin/po2txt --product='$(PRODUCT)' $< >en.tr

clean:
	rm -f .ready text.inc *.tr *~
