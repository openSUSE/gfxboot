all: en.tlk

en.tlk: talk.po sc
	./po2talk --compress $< $@

sc: sc.c
	gcc -O2 -Wall -o $@ $<

clean:
	rm -f sc *~
