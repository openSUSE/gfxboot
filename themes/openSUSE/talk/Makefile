all: en.tlk

en.tlk: talk.po
	./po2talk --compress $< $@

clean:
	rm -f *~
