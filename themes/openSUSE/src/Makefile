BINDIR      := $(shell [ -x ../../../gfxboot-compile ] && echo ../../../ )

GFXBOOT_COMPILE = $(BINDIR)gfxboot-compile
BFLAGS       = -O -v -L ../..

all: main.bin

main.bin: main.bc *.inc ../po/.ready
	$(GFXBOOT_COMPILE) $(BFLAGS) -l main.log -c main.bc $@

../po/.ready:
	make -C ../po

clean:
	rm -f main.bin *.log *~

