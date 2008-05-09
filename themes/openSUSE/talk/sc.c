#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <inttypes.h>

#define MAGIC 0x7d53b605

#define MIN_REF_LEN 5
#define MAX_REF 127 + MIN_REF_LEN

typedef struct {
  unsigned size;
  unsigned char *data;
  unsigned real_size;
} file_data_t;

typedef struct __attribute ((packed)) {
  uint32_t magic;
  uint32_t size;
  uint32_t unpacked_size;
  uint32_t sample_rate;
} snd_header_t; 

file_data_t *read_file(char *name);
void add_data(file_data_t *d, void *buffer, unsigned size);
void write_data(file_data_t *d, char *name);

void compr(file_data_t *fd, file_data_t *fd_compr);
unsigned find_longest(unsigned char *data, unsigned len, unsigned start, unsigned *ofs);


int main(int argc, char **argv)
{
  file_data_t *fd, fd_compr = { }, fd_samples = { };
  snd_header_t sh;
  unsigned sample_rate;

  if(argc != 3) return 1;

  fd = read_file(argv[1]);

  if(fd->size <= 44) return 1;

  if(
    *((unsigned *) (fd->data + 0)) != 0x46464952 ||
    *((unsigned *) (fd->data + 8)) != 0x45564157 ||
    *((short *) (fd->data + 20)) != 1 ||
    *((short *) (fd->data + 34)) != 8 ||
    *((short *) (fd->data + 22)) != 1
  ) {
    fprintf(stderr, "invalid data, expecting 8bit mono wav (ms pcm) file\n");
    return 3;
  }
  sample_rate = *((unsigned *) (fd->data + 24));

  printf("%s: %u Hz, %u samples\n", argv[1], sample_rate, fd->size - 44);

  add_data(&fd_samples, fd->data + 44, fd->size - 44);

  sh.magic = MAGIC;
  sh.unpacked_size = fd_samples.size;
  sh.sample_rate = sample_rate;

  add_data(&fd_compr, &sh, sizeof sh);

  compr(&fd_samples, &fd_compr);

  sh.size = fd_compr.size - sizeof (snd_header_t);

  memcpy(fd_compr.data, &sh, sizeof (snd_header_t));

  write_data(&fd_compr, argv[2]);

  return 0;
}


file_data_t *read_file(char *name)
{
  file_data_t *fd;
  FILE *f;

  fd = calloc(1, sizeof *fd);

  if(!name) return fd;

  f = fopen(name, "r");
  
  if(!f) { perror(name); return fd; }

  if(fseek(f, 0, SEEK_END)) {
    perror(name);
    exit(30);
  }

  fd->size = fd->real_size = ftell(f);

  if(fseek(f, 0, SEEK_SET)) {
    perror(name);
    exit(30);
  }

  if(fd->size) {
    fd->data = calloc(1, fd->size);
    if(!fd->data) {
      fprintf(stderr, "malloc failed\n");
      exit(30);
    }
  }

  if(fread(fd->data, 1, fd->size, f) != fd->size) {
    perror(name);
    exit(30);
  }

  fclose(f);

  return fd;
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


void write_data(file_data_t *d, char *name)
{
  FILE *f;

  f = strcmp(name, "-") ? fopen(name, "w") : stdout;

  if(!f) {
    perror(name);
    return;
  }

  if(fwrite(d->data, d->size, 1, f) != 1) {
    perror(name);
    exit(3);
  }

  fclose(f);
}


void compr(file_data_t *fd, file_data_t *fd_compr)
{
  unsigned u, v, l, ofs;
  unsigned char uc;

  if(!fd->size) return;

  for(u = 0; u < fd->size; u++) {
    if(fd->data[u] == 0xff) fd->data[u] = 0xfe;
  }

  // printf("%5u: %02x\n", fd->size, fd->data[0]);
  add_data(fd_compr, fd->data, 1);

  for(u = 1; u < fd->size; ) {
    l = find_longest(fd->data, fd->size, u, &ofs);
    // printf("%u: %u bytes @ %u\n", u, l, ofs);
    if(l >= MIN_REF_LEN) {
      // printf("%5u: %u bytes @ %u\n", fd->size, l, ofs);
      v = (ofs << 7) + l - MIN_REF_LEN;
      uc = 0xff; add_data(fd_compr, &uc, 1);
      uc = v; add_data(fd_compr, &uc, 1);
      uc = v >> 8; add_data(fd_compr, &uc, 1);
      uc = v >> 16; add_data(fd_compr, &uc, 1);
      u += l;
    }
    else {
      // printf("%5u: %02x\n", fd->size, fd->data[u]);
      add_data(fd_compr, fd->data + u, 1);
      u++;
    }
  }
}


unsigned find_longest(unsigned char *data, unsigned len, unsigned start, unsigned *ofs)
{
  unsigned l;
  unsigned char *p, *p1;

  p = data;
  l = MIN_REF_LEN;

  for(;;) {
    p1 = memmem(p, data + start + l - 1 - p, data + start, l);
    if(!p1) break;
    p = p1;
    l++;

    if(l > MAX_REF) break;
  }

  l--;

  if(l < MIN_REF_LEN) {
    *ofs = 0;
    return 0;
  }

  *ofs = p - data;
  return l;
}


