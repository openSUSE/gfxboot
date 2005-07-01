#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
  int i, j = 0;
  FILE *f;

  if(argc > 1) {
    if(!(f = fopen(argv[1], "r"))) {
      perror(argv[1]);
      return 1;
    }
  }
  else {
    fprintf(stderr, "usage: bin2c file\n");
    return 2;
  }

  printf("unsigned char %s_data[] = {\n", argv[1]);

  while((i = fgetc(f)) != EOF) {
    i = i & 0xff;
    if(!j++) {
      printf(" ");
    }
    else {
      printf(",%s", (j & 7) != 1 ? "" : "\n ");
    }
    printf(" 0x%02x", i);
  }

  printf("\n};\n");

  return 0;
}

