/*
 * add black as color #0 to a pcx file
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <ctype.h>

typedef struct {
  unsigned size;
  unsigned char *data;
  unsigned real_size;
} file_data_t;

void help(void);
file_data_t read_file(char *name);
int is_pcx(file_data_t *fd);
void write_data(file_data_t *fd, char *name);
void add_data(file_data_t *d, void *buffer, unsigned size);
void add_black(file_data_t *new, file_data_t *old);

file_data_t pcx_old = {};
file_data_t pcx_new = {};

int main(int argc, char **argv)
{
  if(argc != 3) return 1;

  pcx_old = read_file(argv[1]);

  if(!is_pcx(&pcx_old)) return 2;

  add_black(&pcx_new, &pcx_old);

  write_data(&pcx_new, argv[2]);

  return 0;
}


file_data_t read_file(char *name)
{
  file_data_t fd = { };
  FILE *f;

  if(!name) return fd;

  f = fopen(name, "r");
  if(!f) { perror(name); return fd; }

  if(fseek(f, 0, SEEK_END)) {
    perror(name);
    exit(30);
  }

  fd.size = fd.real_size = ftell(f);

  if(fseek(f, 0, SEEK_SET)) {
    perror(name);
    exit(30);
  }

  if(fd.size) {
    fd.data = malloc(fd.size);
    if(!fd.data) {
      fprintf(stderr, "malloc failed\n");
      exit(30);
    }
  }

  if(fread(fd.data, 1, fd.size, f) != fd.size) {
    perror(name);
    exit(30);
  }

  fclose(f);

  return fd;
}


int is_pcx(file_data_t *fd)
{
  if(!fd->data || fd->size < 0x381) return 0;
  if(
    fd->data[0] != 10 ||
    fd->data[1] != 5 ||
    fd->data[2] != 1 ||
    fd->data[3] != 8 ||
    fd->data[fd->size - 0x301] != 12
  ) return 0;

  return 1;
}


void write_data(file_data_t *fd, char *name)
{
  FILE *f;

  if(!fd->size) return;

  f = strcmp(name, "-") ? fopen(name, "w") : stdout;

  if(!f) {
    perror(name);
    return;
  }

  if(fwrite(fd->data, fd->size, 1, f) != 1) {
    perror(name); exit(3);
  }

  fclose(f);
}


void add_data(file_data_t *d, void *buffer, unsigned size)
{
  if(!size || !d || !buffer) return;

  if(d->size + size > d->real_size) {
    d->real_size = d->size + size + 0x1000;
    d->data = realloc(d->data, d->real_size);
    if(!d->data) d->real_size = 0;
  }

  if(d->size + size <= d->real_size) {
    memcpy(d->data + d->size, buffer, size);
    d->size += size;
  }
  else {
    fprintf(stderr, "Oops, out of memory? Aborted.\n");
    exit(10);
  }
}


void add_black(file_data_t *new, file_data_t *old)
{
  int i, size;
  unsigned char black[4] = { 12, 0, 0, 0 };
  unsigned char *src = old->data + 0x80;
  unsigned char c[1];

  add_data(new, old->data, 0x80);
  size = old->size - 0x381;

  for(i = 0; i < size; i++) {
    if(src[i] < 0xbf) {
      *c = src[i] + 1;
      add_data(new, c, 1);
    }
    else if(src[i] == 0xbf) {
      *c = 0xc1;
      add_data(new, c, 1);
      *c = 0xc0;
      add_data(new, c, 1);
    }
    else {
      add_data(new, src + i, 1);
      i++;
      *c = src[i] + 1;
      add_data(new, c, 1);
    }
  }

  add_data(new, black, 4);
  add_data(new, old->data + old->size - 0x300, 0x300 - 3);
}

