MKBOOTMSG = $(BINDIR)mkbootmsg
BFLAGS    = -O -v -L ../..

.PHONY: all themes clean

all: themes

themes: bootlogo

bootlogo: test1.ps
	$(MKBOOTMSG) $(BFLAGS) -l log -c $< init
	echo -e "init\njaguar.pcx" | cpio -o >bootlogo

clean:
	rm -f *~ log init bootlogo
