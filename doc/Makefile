PROJECT	= gfxboot
XMLSRC	= gfxboot.xml reference.xml

all: html
doc: html txt

reference.xml: ../bincode.asm
	./mkdoc ../bincode.asm >reference.xml

txt: $(XMLSRC)
	xmlto txt $(PROJECT).xml

pdf: $(XMLSRC)
	db2pdf gfxboot.xml
	@rm -f *.aux *.log *.tex *.out

html: $(XMLSRC)
	xmlto html-nochunks $(PROJECT).xml

clean:
	rm -rf *~ *.pdf *.html *.txt reference.xml *.dsl *.local

distclean: clean

