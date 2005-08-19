#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "jpg.h"

int main(int argc, char **argv)
{
  int fd, i, width, height;
  unsigned char *jpg = malloc(1 << 20);
  unsigned char *img, *p;
  unsigned char pixel[3];
  unsigned x, z;
  unsigned x0, x1, y0, y1;
  unsigned bits = 0;

  if(argc < 4) return 1;

  if(!strcmp(argv[1], "--8")) {
    bits = 8;
  }

  if(!strcmp(argv[1], "--16")) {
    bits = 16;
  }

  if(!strcmp(argv[1], "--24")) {
    bits = 24;
  }

  if(!strcmp(argv[1], "--32")) {
    bits = 32;
  }

  if(!bits) return 10;

  fd = open(argv[2], O_RDONLY);

  if(fd == -1) return 2;

  i = read(fd, jpg, 1 << 20);

  if(i < 0) return 3;

  close(fd);

  jpg = realloc(jpg, i);

  x = jpeg_get_size(jpg);

  width = x & 0xffff;
  height = x >> 16;

  fprintf(stderr, "size = %d bytes, width = %d, height = %d\n", i, width, height);

  img = malloc(width * height * 4);

  x0 = 0;
  x1 = width;
  y0 = 0;
  y1 = height;

  i = jpeg_decode(jpg, img, x0, x1, y0, y1, bits);

  width = x1 - x0;
  height = y1 - y0;

  fprintf(stderr, "decode = %d\n", i);

  fprintf(stderr,
    "%02x %02x %02x %02x %02x %02x %02x %02x\n",
    img[0], img[1], img[2], img[3],
    img[4], img[5], img[6], img[7]
  );

  if(argc >= 3) {

    fd = open(argv[3], O_WRONLY | O_CREAT | O_TRUNC, 0644);

    if(fd >= 0) {
      char *s = NULL;

      i = asprintf(&s, "P6\n%d %d\n255\n", width, height);
      if(i > 0) write(fd, s, i);

      free(s);

      switch(bits) {
        case 8:
          for(i = 0, p = img; i < width * height; i++) {
            x = *p++;
            // 2 3 3

            z = x >> (4 + 2);
            pixel[0] = z * 0x55;

            z = (x >> 3) & 0x07;
            pixel[1] = z * 0x24 + (z >> 1);

            z = x & 0x7;
            pixel[2] = z * 0x24 + (z >> 1);

            write(fd, &pixel, 3);
          }
          break;

        case 16:
          for(i = 0, p = img; i < width * height; i++) {
            x = p[0] + (p[1] << 8);
            p += 2;

            // 5 6 5

            pixel[0] = ((x >> 11) & 0x1f) << 3;
            pixel[0] += pixel[0] >> 5;
            pixel[1] = ((x >> 5) & 0x3f) << 2;
            pixel[1] += pixel[1] >> 6;
            pixel[2] = (x & 0x1f) << 3;
            pixel[2] += pixel[2] >> 5;

            write(fd, &pixel, 3);
          }
          break;

        case 24:
          for(i = 0, p = img; i < width * height; i++) {
            pixel[2] = *p++;
            pixel[1] = *p++;
            pixel[0] = *p++;

            write(fd, &pixel, 3);
          }
          break;

        case 32:
          for(i = 0, p = img; i < width * height; i++) {
            pixel[2] = *p++;
            pixel[1] = *p++;
            pixel[0] = *p++;
            p++;

            write(fd, &pixel, 3);
          }
          break;

      }

      close(fd);
    }
  }

  return 0;
}


