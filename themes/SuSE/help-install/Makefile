BINDIR    := $(shell [ -x ../../../mkbootmsg ] && echo ../../../ )

PRODUCT   = "openSUSE 10.3"
export PRODUCT

HELP2TXT  = $(BINDIR)help2txt

HELPFILES = $(addsuffix .hlp,$(basename $(wildcard *.html)))

%.hlp: %.html
	$(HELP2TXT) --product=$(PRODUCT) $< >$@

all: .ready

.ready:	$(HELPFILES)
	@touch .ready

clean:
	rm -f .ready *.hlp *~

