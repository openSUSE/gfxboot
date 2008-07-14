BINDIR    := $(shell [ -x ../../../gfxboot-compile ] && echo ../../../ )
GFXBOOT   = $(BINDIR)gfxboot

PRODUCT   = $(shell perl -ne 'print if s/^product=//' ../config)

HELP2TXT  = ../../../bin/help2txt

HELPFILES = $(addsuffix .hlp, $(shell for i in * ; do [ -d $$i ] && echo $$i ; done))

%.hlp: %
	$(GFXBOOT) --product='$(PRODUCT)' --help-create $@ --navi $</navi.html $</main*.html || true

all: .ready

.ready:	$(HELPFILES)
	@touch .ready

clean:
	rm -f .ready *.hlp *~

