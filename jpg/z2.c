#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "jpg.h"

int main(int argc, char **argv)
{
  int fd, i, width, height;
  unsigned char *jpg = malloc(1 << 20);
  unsigned char *img, *p;
  struct jpeg_decdata jdd;
  unsigned bits = 16;
  unsigned char pixel[3];
  unsigned x;
  unsigned x0, x1, y0, y1;

  if(argc < 2) return 1;

  fd = open(argv[1], O_RDONLY);

  if(fd == -1) return 2;

  i = read(fd, jpg, 1 << 20);

  if(i < 0) return 3;

  close(fd);

  jpg = realloc(jpg, i);

  jpeg_get_size(jpg, &width, &height);

  fprintf(stderr, "size = %d bytes, width = %d, height = %d\n", i, width, height);

  img = malloc(width * height * 4);

  x0 = 10;
  x1 = 170;
  y0 = 20;
  y1 = 177;

  i = jpeg_decode(jpg, img, &jdd, x0, x1, y0, y1);

  width = x1 - x0;
  height = y1 - y0;

  fprintf(stderr, "decode = %d\n", i);

  if(argc >= 3) {

    fd = open(argv[2], O_WRONLY | O_CREAT | O_TRUNC, 0644);

    if(fd >= 0) {
      char *s = NULL;

      i = asprintf(&s, "P6\n%d %d\n255\n", width, height);
      if(i > 0) write(fd, s, i);

      free(s);

      for(i = 0, p = img; i < width * height; i++) {
        if(bits == 24) {
          pixel[0] = *p++;
          pixel[1] = *p++;
          pixel[2] = *p++;
        }
        else {
          x = p[1] + (p[0] << 8);
          p += 2;

          pixel[0] = ((x >> 11) & 0x1f) << 3;
          pixel[0] += pixel[0] >> 5;
          pixel[1] = ((x >> 5) & 0x3f) << 2;
          pixel[1] += pixel[1] >> 6;
          pixel[2] = (x & 0x1f) << 3;
          pixel[2] += pixel[2] >> 5;
        }

        write(fd, &pixel, 3);
      }

      close(fd);
    }
  }

  return 0;
}


