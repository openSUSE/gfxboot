all: z2

z2: z2.c jpg.o
	gcc -O2 -Wall z2.c jpg.o -o z2

jpg.o: jpg.c
	gcc -O2 -Wall -c jpg.c

clean:
	rm -f *~ *.o *.i *.s *.pnm z2
