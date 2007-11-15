BINDIR      := $(shell [ -x ../../../mkbootmsg ] && echo ../../../ )

MKBOOTMSG    = $(BINDIR)mkbootmsg
BFLAGS       = -O -v -L ../..

all: main.bin

main.bin: main.bc *.inc ../po/.ready
	$(MKBOOTMSG) $(BFLAGS) -l main.log -c main.bc $@

../po/.ready:
	make -C ../po

clean:
	rm -f main.bin *.log *~

