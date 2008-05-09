all: en.tlk

en.tlk: talk.po sc
	./po2talk --compress $< $@

sc: sc.c
	gcc -O2 -Wall $< $@

clean:
	rm -f *~
