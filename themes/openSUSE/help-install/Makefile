BINDIR    = $(shell [ -x ../../../gfxboot ] && echo ../../../ )
GFXBOOT   = $(BINDIR)gfxboot
PRODUCT   = $(shell perl -ne 'print if s/^product=//' ../config)
HELPFILES = $(addsuffix .hlp, $(shell for i in * ; do [ -d $$i ] && echo $$i ; done))

HELPSRC   = main*
HELPNAVI  = navi
ENTITIES  = product='$(PRODUCT)' fkey_help=F1 fkey_lang=F2 fkey_video=F3 fkey_inst=F4 fkey_dud=F6

%.hlp: %
	$(GFXBOOT) --help-create $@ --define $(ENTITIES) --navi $</$(HELPNAVI).html $</$(HELPSRC).html || true

all: .ready

.ready:	$(HELPFILES)
	@touch .ready

clean:
	rm -f .ready *.hlp *~

