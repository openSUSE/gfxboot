all: z2 jpeg.S

z2: z2.c jpg.o
	gcc -O2 -Wall z2.c jpg.o -o z2

jpg.o: jpg.c
	gcc -O2 -Wall -c jpg.c

jpeg.S jpeg.inc: jpg.c
	gcc -fomit-frame-pointer -S -Os -Wall -c jpg.c
	./conv1 jpg.s >jpeg1.s
	./conv2 -o jpeg2.s jpeg1.s
	./conv3 jpeg2.s >jpeg.S 2>jpeg.inc

clean:
	rm -f *~ *.o *.i *.s *.S *.inc *.pnm z2
