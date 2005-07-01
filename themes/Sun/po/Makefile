POFILES	= $(wildcard *.po)
TEXTS	= $(addprefix texts.,$(basename $(wildcard *.po)))

all: text.inc $(TEXTS)

texts.%: %.po text.inc
	bin/po2txt $< >$@

# texts.en uses msgids from bootloader.pot
texts.en text.inc: bootloader.pot
	bin/po2txt $< >texts.en

clean:
	rm -f text.inc texts.* *~
