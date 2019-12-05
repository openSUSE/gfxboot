#define _GNU_SOURCE	/* asprintf */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <getopt.h>
#include <iconv.h>
#include <errno.h>
#include <inttypes.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_SYNTHESIS_H


#define MAGIC 0xd2828e06

// 4 bits seem to be enough
#define GRAY_BITS 4
// 3 gave smallest file for about 16x16 pixel fonts, but it doesn't really matter much
#define GRAY_BIT_COUNT 3

#define MAX_GRAY ((1 << GRAY_BITS) - 3)
#define REP_BLACK (MAX_GRAY + 1)
#define REP_WHITE (MAX_GRAY + 2)

struct option options[] = {
  { "add",         1, NULL, 'a' },
  { "add-charset", 1, NULL, 'c' },
  { "font",        1, NULL, 'f' },
  { "line-height", 1, NULL, 'l' },
  { "font-height", 1, NULL, 'H' },
  { "font-path",   1, NULL, 'p' },
  { "show",        0, NULL, 's' },
  { "add-text",    1, NULL, 't' },
  { "verbose",     0, NULL, 'v' },
  { "test",        0, NULL, 999 },
  { }
};


typedef struct list_any_s {
  struct list_any_s *next;
} list_any_t;

typedef struct {
  void *start;
  void *end;
} list_t;

typedef struct n_set_s {
  struct n_set_s *next;
  int first, last;
} n_set_t;

typedef struct {
  unsigned size;
  unsigned char *data;
  unsigned real_size;
} file_data_t;

typedef struct __attribute ((packed)) {
  uint32_t magic;
  uint32_t entries;
  int8_t height;
  int8_t baseline;
  int8_t line_height;
} font_header_t; 

typedef struct font_s {
  struct font_s *next;
  char *name;
  char *file_name;
  FT_Face face;
  int size;
  int prop;
  int space_width;
  int dy;
  unsigned index;
  int height;
  int baseline;
  list_t chars;			/* n_set_t */
  unsigned used:1;		/* font is actually used */
  unsigned ok:1;
  unsigned bold:1;
  unsigned nobitmap:1;
  unsigned autohint:2;		/* 0: auto, 1: off, 2: on */
  unsigned autosize:1;
  unsigned autoshift:1;
} font_t;

typedef struct char_data_s {
  struct char_data_s* next;
  unsigned ok:1;		/* char exists */
  unsigned top:1;
  unsigned bottom:1;
  int c;			/* char (utf32) */
  font_t *font;			/* pointer to font */
  int x_advance;
  int x_ofs;			/* where to draw lower left bitmap corner */
  int y_ofs;
  unsigned char *bitmap;	/* char bitmap, width x height */
  int bitmap_width;
  int bitmap_height;
  unsigned char *data;
  int data_len;
} char_data_t;

list_t font_list;	/* font_t */
list_t char_list;	/* char_data_t */
list_t chars_missing;	/* n_set_t */
list_t chars_top;	/* n_set_t */
list_t chars_bottom;	/* n_set_t */

int font_height;
int font_y_ofs;

struct {
  int verbose;
  int test;
  int line_height;
  int max_font_height;
  char *font_path;
  list_t chars;		/* n_set_t */
  char *file;
  unsigned show:1;
} opt;


file_data_t *read_file(char *name);
void dump_char(char_data_t *cd);
void add_data(file_data_t *d, void *buffer, unsigned size);
void write_data(file_data_t *d, char *name);
int intersect(int first0, int last0, int first1, int last1);
void insert_int_list(list_t *list, int first, int last);
void *add_list(list_t *list, void *entry);
void *new_mem(size_t size);
char *new_str(char *str);
int parse_int_list(list_t *list, char *str);
char *search_font(char *font_path, char *name);
void render_char(char_data_t *cd);
int empty_row(char_data_t *cd, int row);
int empty_column(char_data_t *cd, int column);
void add_bbox(char_data_t *cd);
void make_prop(char_data_t *cd);
char *utf32_to_utf8(int u8);
void add_bits(unsigned char *buf, int *buf_ptr, int bits, unsigned data);
unsigned read_unsigned_bits(unsigned char *buf, int *buf_ptr, int bits);
int read_signed_bits(unsigned char *buf, int *buf_ptr, int bits);
int signed_bits(int num);
int unsigned_bits(unsigned num);
void encode_char(char_data_t *cd);
int show_font(char *name);
void get_font_height(font_t *font, int *height, int *y_ofs);


int main(int argc, char **argv)
{
  int i, j, k, err, ofs;
  char *str, *str1, *t, *s, *s1, *font_spec;
  iconv_t ic = (iconv_t) -1, ic2;
  unsigned char obuf[4];
  char ibuf[6];
  char obuf2[4*0x100], ibuf2[0x100];
  char *obuf_ptr, *ibuf_ptr;
  size_t obuf_left, ibuf_left;
  FILE *f;
  font_t *font;
  n_set_t *n;
  char_data_t *cd;
  FT_Library ft_lib;
  font_header_t fh;
  file_data_t font_file = {};
  unsigned char char_ofs[5];

  opt.font_path = "\
/usr/share/fonts/truetype:\
/usr/share/fonts/Type1:\
/usr/share/fonts/misc:\
/usr/X11R6/lib/X11/fonts/truetype:\
/usr/X11R6/lib/X11/fonts/Type1:\
/usr/X11R6/lib/X11/fonts/misc\
";

  opterr = 0;

  while((i = getopt_long(argc, argv, "Aa:c:f:H:l:p:st:v", options, NULL)) != -1) {
    switch(i) {
      case 'a':
        err = parse_int_list(&opt.chars, optarg);
        if(err) {
          fprintf(stderr, "%s: invalid char range spec\n", optarg);
          return 1;
        }
        break;

      case 'c':
        ic2 = iconv_open("utf32le", optarg);
        if(ic2 == (iconv_t) -1) {
          fprintf(stderr, "don't know char set %s\ntry 'iconv --list'\n", optarg);
          return 1;
        }
        ibuf_ptr = ibuf2;
        ibuf_left = sizeof ibuf2;
        obuf_ptr = obuf2;
        obuf_left = sizeof obuf2;
        for(j = 0; j < sizeof ibuf2; j++) ibuf2[j] = j;
        iconv(ic2, &ibuf_ptr, &ibuf_left, &obuf_ptr, &obuf_left);
        for(str = obuf2; str < obuf_ptr; str += 4) {
          i = *(int *) str;
          if(i >= 0x20) insert_int_list(&opt.chars, i, i);
        }
        iconv_close(ic2);
        break;

      case 'f':
        font = add_list(&font_list, new_mem(sizeof *font));
        font_spec = new_str(optarg);

        if((s = strchr(font_spec, ':'))) {
          font->name = new_mem(s - font_spec + 1);
          memcpy(font->name, font_spec, s - font_spec);
          t = s + 1;
          err =  0;
          while(!err && (str = strsep(&t, ":"))) {
            if((s = strchr(str, '='))) {
              *s++ = 0;
              if(!strcmp(str, "size")) {
                font->size = strtol(s, &s1, 0);
                if(*s1) err = 1;
              }
              else if(!strcmp(str, "prop")) {
                font->prop = strtol(s, &s1, 0);
                if(*s1) err = 1;
              }
              else if(!strcmp(str, "space_width")) {
                font->space_width = strtol(s, &s1, 0);
                if(*s1) err = 1;
              }
              else if(!strcmp(str, "dy")) {
                font->dy = strtol(s, &s1, 0);
                if(*s1) err = 1;
              }
              else if(!strcmp(str, "bold")) {
                font->bold = strtol(s, &s1, 0);
                if(*s1) err = 1;
              }
              else if(!strcmp(str, "nobitmap")) {
                font->nobitmap = strtol(s, &s1, 0);
                if(*s1) err = 1;
              }
              else if(!strcmp(str, "autohint")) {
                font->autohint = strtol(s, &s1, 0) + 1;
                if(*s1) err = 1;
              }
              else if(!strcmp(str, "autosize")) {
                font->autosize = strtol(s, &s1, 0);
                if(*s1) err = 1;
              }
              else if(!strcmp(str, "autoshift")) {
                font->autoshift = strtol(s, &s1, 0);
                if(*s1) err = 1;
              }
              else if(!strcmp(str, "c")) {
                err = parse_int_list(&font->chars, s);
              }
              else {
                err = 1;
              }
            }
            else {
              if(*str) err = 1;
            }
          }
          free(font_spec);
          if(err) {
            fprintf(stderr, "%s: invalid font spec\n", optarg);
            return 1;
          }
        }
        else {
          font->name = font_spec;
        }
        break;

      case 'H':
        str = optarg;
        i = strtol(str, &str1, 0);
        if(*str1 || i < 0) {
          fprintf(stderr, "%s: invalid font height\n", str);
          return 1;
        }
        opt.max_font_height = i;
        break;

      case 'l':
        str = optarg;
        i = strtol(str, &str1, 0);
        if(*str1 || i < 0) {
          fprintf(stderr, "%s: invalid line height\n", str);
          return 1;
        }
        opt.line_height = i;
        break;

      case 'p':
        opt.font_path = optarg;
        break;

      case 's':
        opt.show = 1;
        break;

      case 't':
        if(ic == (iconv_t) -1) {
          ic = iconv_open("utf32le", "utf8");
          if(ic == (iconv_t) -1) {
            fprintf(stderr, "can't convert utf8 data\n");
            return 1;
          }
        }
        if((f = fopen(optarg, "r"))) {
          int ok;

          ibuf_left = 0;
          while((i = fread(ibuf + ibuf_left, 1, sizeof ibuf - ibuf_left, f)) > 0) {
            // fprintf(stderr, "ibuf_left = %d, fread = %d\n", ibuf_left, i);
            ibuf_ptr = ibuf;
            ibuf_left += i;
            do {
              obuf_ptr = obuf;
              obuf_left = sizeof obuf;
              k = iconv(ic, &ibuf_ptr, &ibuf_left, &obuf_ptr, &obuf_left);
              // fprintf(stderr, "k = %d, errno = %d, ibuf_left = %d, obuf_left = %d\n", k, k ? errno : 0, ibuf_left, obuf_left);
              if(k >= 0 || (k == -1 && !obuf_left)) {
                ok = 1;
                if(!obuf_left) {
                  i = obuf[0] + (obuf[1] << 8) + (obuf[2] << 16) + (obuf[3] << 24);
                  if(i >= 0x20) {
                    insert_int_list(&opt.chars, i, i);
                  }
                }
              }
              else {
                ok = 0;
              }
            }
            while(ok && ibuf_left);
            if(k == -1 && errno == EILSEQ) {
              perror("iconv");
              return 1;
            }
            if(ibuf_left) {
              memcpy(ibuf, ibuf + sizeof ibuf - ibuf_left, ibuf_left);
            }
          }
          fclose(f);
        }
        else {
          perror(optarg);
          return 1;
        }
        break;

      case 'v':
        opt.verbose++;
        break;

      case 999:
        opt.test++;
        break;
    }
  }

  if(ic != (iconv_t) -1) iconv_close(ic);

  // use default char list
  if(!opt.chars.start) insert_int_list(&opt.chars, 0x20, 0x7f);

  argc -= optind; argv += optind;

  // FreeSans[size=16 prop=2 space_width=4 dy=16 c=0x1200,0x1000-0x2000]
  if(argc != 1) {
    fprintf(stderr,
      "Usage: gfxboot-font [options] fontfile\n"
      "Build font for boot loader.\n"
      "  -a, --add=first[-last]\n\tAdd chars from this range.\n"
      "  -c, --add-charset=charset\n\tAdd all chars from this charset.\n"
      "  -f, --font=font_spec\n\tUse this font. Spec format is fontname[option1 option2 ...]\n"
      "  -h, --help\n\tShow this help text.\n"
      "  -l, --line-height=n\n\tSet line height (default: font height).\n"
      "  -p, --font-path=font path\n\tFont path, elements separated by ':'.\n"
      "  -s, --show\n\tShow font info.\n"
      "  -t, --add-text=samplefile\n\tAdd all chars used in this file. File must be UTF-8 encoded.\n"
      "  -v, --verbose\n\tDump font info.\n"
    );
    return 1;
  }

  opt.file = argv[0];

  if(opt.show) return show_font(opt.file);

  if((err = FT_Init_FreeType(&ft_lib))) {
    fprintf(stderr, "FreeType init failed (err = %d)\n", err);
    return 3;
  }

  // open all fonts
  for(i = 0, font = font_list.start; font; font = font->next) {
    font->index = i++;
    font->file_name = search_font(opt.font_path, font->name);
    if(font->file_name) {
      err = FT_New_Face(ft_lib, font->file_name, 0, &font->face);
      if(!err) {
        if(!font->size) {
          if(font->face->num_fixed_sizes > 0) {
            font->size = font->face->available_sizes[0].height;
          }
        }
        if(
          font->size &&
          !FT_Set_Pixel_Sizes(font->face, font->size, 0)
        ) {
          font->ok = 1;
        }
      }
    }
  }

  // build char list
  for(n = opt.chars.start; n; n = n->next) {
    for(i = n->first; i <= n->last; i++) {
      cd = add_list(&char_list, new_mem(sizeof *cd));
      cd->c = i;
    }
  }

  // just check the list is really sorted
  for(i = -1, cd = char_list.start; cd; cd = cd->next) {
    if(cd->c <= i) {
      fprintf(stderr, "internal error: char list not sorted\n");
      return 4;
    }
    i = cd->c;
  }

  // render all chars
  for(cd = char_list.start; cd; cd = cd->next) {
    render_char(cd);
  }

  // fix vertical glyph positions
  for(cd = char_list.start; cd; cd = cd->next) {
    if(cd->ok) cd->y_ofs += cd->font->dy;
  }

  if(!opt.test) for(cd = char_list.start; cd; cd = cd->next) add_bbox(cd);

// ##############

  // get font dimensions
  get_font_height(NULL, &font_height, &font_y_ofs);

  for(font = font_list.start; font; font = font->next) {
    if(!font->ok) continue;
    get_font_height(font, &i, &j);
    font->height = i;
    font->baseline = -j;
  }

// ##############

  FT_Done_FreeType(ft_lib);

  // label largest chars
  for(cd = char_list.start; cd; cd = cd->next) {
    if(!cd->ok) continue;
    if(cd->y_ofs - font_y_ofs + cd->bitmap_height >= font_height) cd->top = 1;
    if(cd->y_ofs - font_y_ofs <= 0) cd->bottom = 1;
  }

  for(cd = char_list.start; cd; cd = cd->next) make_prop(cd);

  for(cd = char_list.start; cd; cd = cd->next) {
    if(!cd->ok) insert_int_list(&chars_missing, cd->c, cd->c);
  }

  for(cd = char_list.start; cd; cd = cd->next) {
    if(cd->ok && cd->top) insert_int_list(&chars_top, cd->c, cd->c);
  }

  for(cd = char_list.start; cd; cd = cd->next) {
    if(cd->ok && cd->bottom) insert_int_list(&chars_bottom, cd->c, cd->c);
  }

  for(cd = char_list.start; cd; cd = cd->next) encode_char(cd);

  memset(&fh, 0, sizeof fh);

  fh.magic = MAGIC;
  fh.height = font_height;
  fh.baseline = -font_y_ofs;
  fh.line_height = opt.line_height ?: fh.height + 2;

  for(cd = char_list.start; cd; cd = cd->next) if(cd->ok) fh.entries++;

  // print font info
  if(opt.verbose) {
    printf("Font List\n");
    for(font = font_list.start; font; font = font->next) {
      printf("  #%d %s (%s)\n", font->index, font->name, font->ok ? "ok" : "not used");
      printf("    File %s\n", font->file_name);
      printf("    Size %d", font->size);
      if(font->dy) printf(", dY %d", font->dy);
      if(font->prop) printf(", Prop %d", font->prop);
      if(font->space_width) printf(", SpaceWidth %d", font->space_width);
      printf("\n");
      printf("    Height %d, Baseline %d\n", font->height, font->baseline);
      if(font->chars.start) {
        for(n = font->chars.start; n; n = n->next) {
          printf("    c 0x%04x", n->first);
          if(n->last != n->first) printf("-0x%04x", n->last);
          printf("\n");
        }
      }
    }
    printf("\n");
  }

  if(opt.verbose >= 2) {
    printf("Requested Char List\n");
    for(n = opt.chars.start; n; n = n->next) {
      printf("  0x%04x", n->first);
      if(n->last != n->first) printf("-0x%04x", n->last);
      printf("\n");
    }
    printf("\n");
  }

  if(opt.verbose) {
    if(chars_missing.start) {
      printf("Missing Chars\n");
      for(n = chars_missing.start; n; n = n->next) {
        printf("  0x%04x", n->first);
        if(n->last != n->first) printf("-0x%04x", n->last);
        printf("\n");
      }
      printf("\n");
    }

    if(chars_top.start) {
      printf("Top Chars\n");
      for(n = chars_top.start; n; n = n->next) {
        printf("  0x%04x", n->first);
        if(n->last != n->first) printf("-0x%04x", n->last);
        printf("\n");
      }
      printf("\n");
    }

    if(chars_bottom.start) {
      printf("Bottom Chars\n");
      for(n = chars_bottom.start; n; n = n->next) {
        printf("  0x%04x", n->first);
        if(n->last != n->first) printf("-0x%04x", n->last);
        printf("\n");
      }
      printf("\n");
    }

    printf(
      "Font Size\n  Height: %d\n  Baseline: %d\n  Line Height: %d\n\n",
      font_height, -font_y_ofs, fh.line_height
    );

    for(cd = char_list.start; cd; cd = cd->next) dump_char(cd);
  }

  add_data(&font_file, &fh, sizeof fh);

  ofs = font_file.size + fh.entries * sizeof char_ofs;

  for(cd = char_list.start; cd; cd = cd->next) {
    if(!cd->ok) continue;
    i = 0;
    add_bits(char_ofs, &i, 21, cd->c);
    add_bits(char_ofs, &i, 19, ofs);
    add_data(&font_file, char_ofs, sizeof char_ofs);
    ofs += cd->data_len;
  }

  for(cd = char_list.start; cd; cd = cd->next) {
    if(!cd->ok) continue;
    add_data(&font_file, cd->data, cd->data_len);
  }

  write_data(&font_file, opt.file);

  return 0;
}


file_data_t *read_file(char *name)
{
  file_data_t *fd;
  FILE *f;

  fd = new_mem(sizeof *fd);

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
    fd->data = new_mem(fd->size);
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


void dump_char(char_data_t *cd)
{
  int i, j, y0, y1, y2, x0, x1, x2, width;
  unsigned char *p;
  char c;

  if(!cd || !cd->ok) return;

  printf("Char 0x%04x '%s'", cd->c, utf32_to_utf8(cd->c));
  if(cd->top) printf(" top");
  if(cd->bottom) printf(" bottom");
  printf("\n");

  if(cd->font) printf("  Font: #%d %s (%d)\n", cd->font->index, cd->font->name, cd->font->size);

  printf(
    "  Bitmap: %d x %d\n  Advance: %d\n  Offset: %d x %d\n",
    cd->bitmap_width, cd->bitmap_height,
    cd->x_advance, cd->x_ofs, cd->y_ofs
  );

  if(opt.verbose >= 2 && cd->data) {
    printf("  Data[%d]:", cd->data_len);
    for(i = 0; i < cd->data_len; i++) {
      if(!(i & 7)) {
        printf("\n   ");
      }
      printf(" %02x", cd->data[i]);
    }
    printf("\n");
  }

  if(cd->bitmap) {
    p = cd->bitmap;

    y0 = font_height + font_y_ofs;
    y1 = y0 - cd->bitmap_height - cd->y_ofs;
    y2 = y1 + cd->bitmap_height;

    x1 = cd->bitmap_width + cd->x_ofs;
    if(cd->x_advance > x1) x1 = cd->x_advance;

    if(cd->x_ofs < 0) {
      width = x1 - cd->x_ofs;
      x1 = 0;
      x0 = -cd->x_ofs;
    }
    else {
      width = x1;
      x1 = cd->x_ofs;
      x0 = 0;
    }

    x2 = x1 + cd->bitmap_width;

    // printf("y0 = %d, y1 = %d, y2 = %d\n", y0, y1, y2);
    // printf("x0 = %d, x1 = %d, x2 = %d, width = %d\n", x0, x1, x2, width);

    printf("     ");
    c = ' ';
    for(i = 0; i < cd->x_advance + x0; i++ ) {
      if(i == x0) c = '_';
      printf("%c", c);
    }
    printf("\n");

    for(j = 0; j < font_height; j++) {
      printf("  %s", j == y0 - 1 ? "->|" : "  |");
      if(j < y1 || j >= y2) {
        for(i = 0; i < width; i++) printf(".");
      }
      else {
        for(i = 0; i < width; i++) {
          if(i < x1 || i >= x2) {
            printf(".");
          }
          else {
            c = p[(j - y1) * cd->bitmap_width + i - x1];
            if(c == 0) {
              c = ' ';
            }
            else if(c >= MAX_GRAY) {
              c = '#';
            }
            else {
              c += '0';
              if(c > '9') c += 'a' - '9' - 1;
            }
            printf("%c", c);
          }
        }
      }
      printf("|%s\n", j == y0 - 1 ? "<-" : "");
    }

    printf("     ");
    c = ' ';
    for(i = 0; i < cd->x_advance + x0; i++ ) {
      if(i == x0) c = '-';
      printf("%c", c);
    }
    printf("\n");
  }

  printf("\n");
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


int intersect(int first0, int last0, int first1, int last1)
{
  return
    (first1 >= first0 && first1 <= last0 + 1) ||
    (last1 >= first0 - 1 && last1 <= last0) ||
    (first1 < first0 && last1 > last0);
}


void insert_int_list(list_t *list, int first, int last)
{
  n_set_t *n, *p, *next;

  for(n = list->start; n; n = n->next) {
    if(intersect(n->first, n->last, first, last)) {
      if(first < n->first) n->first = first;
      if(last > n->last) n->last = last;
      break;
    }
  }

  if(!n) {	/* not joined */
    if(!(n = list->start) || first < n->first) {
      list->start = p = new_mem(sizeof *p);
      p->next = n;
      p->first = first;
      p->last = last;
    }
    else {
      for(n = list->start; n; n = n->next) {
        if(!n->next || first < n->next->first) {
          p = new_mem(sizeof *p);
          p->next = n->next;
          p->first = first;
          p->last = last;
          n->next = p;
          if(!p->next) list->end = p;
          break;
        }
      }
    }
  }

  for(n = list->start; n; n = next) {
    if(!(next = n->next)) break;

    if(intersect(n->first, n->last, next->first, next->last)) {
      if(next->first < n->first) n->first = next->first;
      if(next->last > n->last) n->last = next->last;
      n->next = next->next;
      if(!n->next) list->end = n;
      free(next);
      next = n;
    }
  }
}


void *add_list(list_t *list, void *entry)
{
  if(list->end) {
    ((list_any_t *) list->end)->next = entry;
  }
  list->end = entry;

  if(!list->start) {
    list->start = entry;
  }

  return entry;
}


void *new_mem(size_t size)
{
  return calloc(size, 1);
}


char *new_str(char *str)
{
  return str ? strdup(str) : str;
}


int parse_int_list(list_t *list, char *str)
{
  int err = 0, i, j, k;
  char *s, *s1, *t;

  if(!str) return 0;

  while(isspace(*str)) str++;

  if(!*str) return 0;

  t = str = new_str(str);

  while((s = strsep(&t, ","))) {
    if(sscanf(s, "%i - %i%n", &i, &j, &k) == 2 && k == strlen(s)) {
      insert_int_list(list, i, j);
    }
    else {
      i = strtol(s, &s1, 0);
      if(*s1) {
        err = 1;
        break;
      }
      insert_int_list(list, i, i);
    }
  }

  free(str);

  return err;
}


char *search_font(char *font_path, char *name)
{
  int i;
  char *font_name = NULL;
  char *cur_path, *sep;
  struct stat sbuf;
  static char *suffix[] = { "", ".otf", ".ttf", ".ttc", ".pfa", ".pfb", ".pcf.gz" };

  if(!font_path || !name) return NULL;

  while(*font_path) {
    cur_path = strdup(font_path);

    if((sep = strchr(cur_path, ':'))) *sep = 0;

    for(i = 0; i < sizeof suffix / sizeof *suffix; i++) {
      asprintf(&font_name, "%s/%s%s", cur_path, name, suffix[i]);
      if(!stat(font_name, &sbuf) && S_ISREG(sbuf.st_mode)) break;
      free(font_name);
      font_name = NULL;
    }

    if(i < sizeof suffix / sizeof *suffix) {
      free(cur_path);
      break;
    }

    if(sep) {
      font_path += sep - cur_path + 1;
    }
    else {
      font_path = "";
    }

    free(cur_path);
  }

  return font_name;
}


void render_char(char_data_t *cd)
{
  n_set_t *n;
  int err, glyph_index;
  FT_GlyphSlot glyph;
  int i, j;
  unsigned char uc;

  if(cd->ok) {
    glyph_index = FT_Get_Char_Index(cd->font->face, cd->c);
    if(!glyph_index) return;

    err = FT_Load_Char(
      cd->font->face,
      cd->c,
      FT_LOAD_RENDER |
      (cd->font->nobitmap ? FT_LOAD_NO_BITMAP : 0) |
      (cd->font->autohint ? cd->font->autohint == 1 ? FT_LOAD_NO_AUTOHINT : FT_LOAD_FORCE_AUTOHINT : 0)
    );
    if(err) return;
  }
  else {
    font_t *font;

    for(font = font_list.start; font; font = font->next) {
      if(!font->ok) continue;
      if(font->chars.start) {
        for(n = font->chars.start; n; n = n->next) {
          if(cd->c >= n->first && cd->c <= n->last) break;
        }
        if(!n) continue;
      }

      glyph_index = FT_Get_Char_Index(font->face, cd->c);
      if(!glyph_index) continue;

      err = FT_Load_Char(
        font->face,
        cd->c,
        FT_LOAD_RENDER |
        (font->nobitmap ? FT_LOAD_NO_BITMAP : 0) |
        (font->autohint ? font->autohint == 1 ? FT_LOAD_NO_AUTOHINT : FT_LOAD_FORCE_AUTOHINT : 0)
      );
      if(err) continue;

      cd->ok = 1;
      cd->font = font;

      break;
    }
  }

  if(!cd->ok) return;

  glyph = cd->font->face->glyph;
  if(cd->font->bold) FT_GlyphSlot_Embolden(glyph);

  cd->bitmap_width = glyph->bitmap.width;
  cd->bitmap_height = glyph->bitmap.rows;
  free(cd->bitmap);
  cd->bitmap = new_mem(cd->bitmap_width * cd->bitmap_height);

  cd->x_advance = glyph->advance.x / 64.;
  cd->x_ofs = glyph->bitmap_left;
  cd->y_ofs = glyph->bitmap_top - glyph->bitmap.rows;

  for(j = 0; j < cd->bitmap_height; j++) {
    for(i = 0; i < cd->bitmap_width; i++) {
      switch(glyph->bitmap.pixel_mode) {
        case FT_PIXEL_MODE_MONO:
          uc = ((glyph->bitmap.buffer[i / 8 + j * glyph->bitmap.pitch] >> (7 - (i & 7))) & 1) * MAX_GRAY;
          break;

        case FT_PIXEL_MODE_GRAY:
          uc = (glyph->bitmap.buffer[i + j * glyph->bitmap.pitch] * (MAX_GRAY + 1)) / (255 + 1);
          break;

        default:
          uc = 0;
      }
      cd->bitmap[i + j * cd->bitmap_width] = uc;
    }
  }

#if 0
  printf(
    "bitmap: mode %d, %d x %d, + %d x %d, advance %f x %f\n",
    glyph->bitmap.pixel_mode,
    glyph->bitmap.width,
    glyph->bitmap.rows,
    glyph->bitmap_left,
    glyph->bitmap_top,
    glyph->advance.x / 64.,
    glyph->advance.y / 64.
  );

  printf(
    "metrics:\n  size %f x %f\n  bearing %f x %f, advance %f\n",
    glyph->metrics.width / 64., glyph->metrics.height / 64.,
    glyph->metrics.horiBearingX / 64., glyph->metrics.horiBearingY / 64.,
    glyph->metrics.horiAdvance / 64.
  );
#endif
}


int empty_row(char_data_t *cd, int row)
{
  unsigned char *p1, *p2;

  p2 = (p1 = cd->bitmap + row * cd->bitmap_width) + cd->bitmap_width;
  while(p1 < p2) if(*p1++) return 0;

  return 1;
}


int empty_column(char_data_t *cd, int col)
{
  int i;
  unsigned char *p;

  for(p = cd->bitmap + col, i = 0; i < cd->bitmap_height; i++, p += cd->bitmap_width) {
    if(*p) return 0;
  }

  return 1;
}


void add_bbox(char_data_t *cd)
{
  int i;
  unsigned char *bitmap;
  int width, height, dx, dy;

  if(!cd->ok) return;

  width = cd->bitmap_width;
  height = cd->bitmap_height;
  dx = dy = 0;

  while(height && empty_row(cd, height - 1)) height--;
  while(width && empty_column(cd, width - 1)) width--;

  for(dx = 0; dx < width && empty_column(cd, dx); dx++);
  for(dy = 0; dy < height && empty_row(cd, dy); dy++);

  width -= dx;
  height -= dy;

  if(width != cd->bitmap_width || height != cd->bitmap_height) {
    bitmap = new_mem(width * height);

    for(i = 0; i < height; i++) {
      memcpy(bitmap + i * width, cd->bitmap + dx + (i + dy) * cd->bitmap_width, width);
    }

    free(cd->bitmap);
    cd->bitmap = bitmap;

    cd->x_ofs += dx;
    cd->y_ofs += cd->bitmap_height - height - dy;

    cd->bitmap_width = width;
    cd->bitmap_height = height;
  }

  if(!cd->bitmap_width || !cd->bitmap_height) {
    cd->x_ofs = cd->y_ofs = 0;
  }
}


/*
 * Fake proprtionally spaced font from fixed size font.
 */
void make_prop(char_data_t *cd)
{
  int width;

  if(!cd->ok || !cd->font->prop) return;

  width = cd->bitmap_width ? cd->bitmap_width + cd->font->prop : cd->font->space_width;
  cd->x_ofs = cd->font->prop;
  cd->x_advance = width;
}


char *utf32_to_utf8(int u8)
{
  static char buf[16];
  static iconv_t ic = (iconv_t) -1;
  char *ibuf, *obuf;
  size_t obuf_left, ibuf_left;
  int i;

  *buf = 0;

  if(ic == (iconv_t) -1) {
    ic = iconv_open("utf8", "utf32le");
    if(ic == (iconv_t) -1) {
      fprintf(stderr, "Error: can't convert utf8 data.\n");
      exit(1);
    }
  }

  ibuf = (char *) &u8;
  obuf = buf;
  ibuf_left = 4;
  obuf_left = sizeof buf - 1;

  i = iconv(ic, &ibuf, &ibuf_left, &obuf, &obuf_left);

  if(i >= 0) {
    i = sizeof buf - 1 - obuf_left;
    buf[i] = 0;
  }
  else {
    fprintf(stderr, "Warning: failed to convert 0x%x to utf8.\n", u8);
  }

  return buf;
}


void add_bits(unsigned char *buf, int *buf_ptr, int bits, unsigned data)
{
  int rem, ptr;

  while(bits > 0) {
    ptr = *buf_ptr >> 3;
    rem = 8 - (*buf_ptr & 7);
    if(rem > bits) rem = bits;
    buf[ptr] = (buf[ptr] & ((1 << (*buf_ptr & 7)) - 1)) + ((data & ((1 << rem) - 1)) << (*buf_ptr & 7));
    *buf_ptr += rem;
    bits -= rem;
    data >>= rem;
  }
}


unsigned read_unsigned_bits(unsigned char *buf, int *buf_ptr, int bits)
{
  int rem, ptr;
  unsigned data = 0, dptr = 0;

  while(bits > 0) {
    ptr = *buf_ptr >> 3;
    rem = 8 - (*buf_ptr & 7);
    if(rem > bits) rem = bits;
    data += ((buf[ptr] >> (*buf_ptr & 7)) & ((1 << rem) - 1)) << dptr;
    dptr += rem;
    *buf_ptr += rem;
    bits -= rem;
  }

  return data;
}


int read_signed_bits(unsigned char *buf, int *buf_ptr, int bits)
{
  int i;

  i = read_unsigned_bits(buf, buf_ptr, bits);

  if(bits == 0) return i;

  if((i & (1 << (bits - 1)))) {
    i += -1 << bits;
  }

  return i;
}


int signed_bits(int num)
{
  int bits = 32;
  int val = num & (1 << 31);

  if(num == 0) return 0;
  
  while((num & (1 << 31)) == val) {
    bits--;
    num <<= 1;
  }

  return bits + 1;
}


int unsigned_bits(unsigned num)
{
  int bits = 0;

  if(num == 0) return 0;

  while(num) {
    num >>= 1;
    bits++;
  }

  return bits;
}


void encode_cnt(unsigned char *buf, int *buf_ptr, int lc, int lc_cnt)
{
  if((lc_cnt - 2) >= (1 << GRAY_BIT_COUNT)) {
    fprintf(stderr, "cnt %d too large\n", lc_cnt);
    exit(1);
  }

  if(lc_cnt >= 2) {
    *buf_ptr -= GRAY_BITS;
    add_bits(buf, buf_ptr, GRAY_BITS, lc == 0 ? REP_BLACK : REP_WHITE);
    // printf("(%d)", lc == 0 ? REP_BLACK : REP_WHITE);
    add_bits(buf, buf_ptr, GRAY_BIT_COUNT, lc_cnt - 2);
    // printf("(%d)", lc_cnt - 2);
  }
  else if(lc_cnt) {
    add_bits(buf, buf_ptr, GRAY_BITS, lc);
    // printf("[%d]", lc);
  }
}


void encode_char(char_data_t *cd)
{
  int i, j, bits, lc_cnt;
  unsigned char *buf;
  int buf_ptr;
  unsigned type;
  unsigned char col[MAX_GRAY + 1];
  int lc;

  if(!cd->ok) return;

  // just large enough
  buf = new_mem(cd->bitmap_width * cd->bitmap_height + 5 * 8 + 1);
  buf_ptr = 0;

  memset(col, 0, sizeof col);

  for(i = 0; i < cd->bitmap_width * cd->bitmap_height; i++) {
    if(cd->bitmap[i] <= MAX_GRAY) {
      col[cd->bitmap[i]] = 1;
    }
  }

  type = 0;
  for(i = 1; i < MAX_GRAY; i++) {
    if(col[i]) {
      type = 1;
      break;
    }
  }

  // type 0: mono, 1: grays

  add_bits(buf, &buf_ptr, 2, type);

  bits = unsigned_bits(cd->bitmap_width);
  j = unsigned_bits(cd->bitmap_height);
  if(j > bits) bits = j;
  j = signed_bits(cd->x_advance);
  if(j > bits) bits = j;
  j = signed_bits(cd->x_ofs);
  if(j > bits) bits = j;
  j = signed_bits(cd->y_ofs);
  if(j > bits) bits = j;

  if(!bits) bits = 1;

  if(bits > 8) {
    free(buf);
    cd->ok = 0;

    return;
  }

  add_bits(buf, &buf_ptr, 3, bits - 1);
  add_bits(buf, &buf_ptr, bits, cd->bitmap_width);
  add_bits(buf, &buf_ptr, bits, cd->bitmap_height);
  add_bits(buf, &buf_ptr, bits, cd->x_ofs);
  add_bits(buf, &buf_ptr, bits, cd->y_ofs);
  add_bits(buf, &buf_ptr, bits, cd->x_advance);

  switch(type) {
    case 0:
      for(i = 0; i < cd->bitmap_width * cd->bitmap_height; i++) {
        add_bits(buf, &buf_ptr, 1, cd->bitmap[i] ? 1 : 0);
      }
      break;

    case 1:
      lc = -1;
      for(i = lc_cnt = 0; i < cd->bitmap_width * cd->bitmap_height; i++) {
        if(cd->bitmap[i] == lc && (lc == 0 || lc == MAX_GRAY) && lc_cnt < ((1 << GRAY_BIT_COUNT) + 1)) {
          lc_cnt++;
        }
        else {
          if(lc_cnt) {
            encode_cnt(buf, &buf_ptr, lc, lc_cnt);
            lc_cnt = 0;
            lc = -1;
          }
          add_bits(buf, &buf_ptr, GRAY_BITS, cd->bitmap[i]);
          // printf("[%d]", cd->bitmap[i]);
        }
        lc = cd->bitmap[i];
      }
      if(lc_cnt) {
        encode_cnt(buf, &buf_ptr, lc, lc_cnt);
      }
      break;
  }

  cd->data = new_mem(cd->data_len = ((buf_ptr + 7) >> 3));
  memcpy(cd->data, buf, cd->data_len);

  free(buf);
}


int show_font(char *name)
{
  int i, j, ofs, ofs2, bits, lc, lc_cnt, bitmap_len;
  file_data_t *font_file;
  font_header_t fh;
  unsigned type;
  char_data_t *cd;

  opt.verbose++;

  font_file = read_file(name);

  if(font_file->size < sizeof fh) return 0;

  memcpy(&fh, font_file->data, sizeof fh);

  if(fh.magic != MAGIC) {
    fprintf(stderr, "%s: wrong file format\n", name);
    return 1;
  }

  if(font_file->size < sizeof fh + fh.entries * 5) {
    fprintf(stderr, "%s: file too short\n", name);
    return 2;
  }

  font_height = fh.height;
  font_y_ofs = -fh.baseline;

  for(i = 0; i < fh.entries; i++) {
    cd = add_list(&char_list, new_mem(sizeof *cd));
    j = 0;
    cd->c = read_unsigned_bits(font_file->data + sizeof fh + i * 5, &j, 21);
    ofs = read_unsigned_bits(font_file->data + sizeof fh + i * 5, &j, 19);

    if(i != fh.entries - 1) {
      j = 21;
      ofs2 = read_unsigned_bits(font_file->data + sizeof fh + (i + 1) * 5, &j, 19);
    }
    else {
      ofs2 = font_file->size;
    }

    if(ofs2 < ofs || ofs2 > font_file->size) {
      fprintf(stderr, "%s: invalid data for chhar 0x%04x\n", name, cd->c);
      return 3;
    }

    cd->data = new_mem(cd->data_len = ofs2 - ofs);
    memcpy(cd->data, font_file->data + ofs, cd->data_len);
  }

  for(cd = char_list.start; cd; cd = cd->next) {
    j = 0;
    type = read_unsigned_bits(cd->data, &j, 2);
    bits = read_unsigned_bits(cd->data, &j, 3) + 1;
    
    if(type > 1) {
      fprintf(stderr, "%s: unknown type %d for char 0x%04x\n", name, type, cd->c);
      return 3;
    }

    cd->bitmap_width = read_unsigned_bits(cd->data, &j, bits);
    cd->bitmap_height = read_unsigned_bits(cd->data, &j, bits);
    cd->x_ofs = read_signed_bits(cd->data, &j, bits);
    cd->y_ofs = read_signed_bits(cd->data, &j, bits);
    cd->x_advance = read_signed_bits(cd->data, &j, bits);

    cd->bitmap = new_mem(bitmap_len = cd->bitmap_width * cd->bitmap_height);

    switch(type) {
      case 0:
        for(i = 0; i < bitmap_len; i++) {
          cd->bitmap[i] = read_unsigned_bits(cd->data, &j, 1) ? MAX_GRAY : 0;
        }
        break;

      case 1:
        for(i = 0; i < bitmap_len;) {
          lc = read_unsigned_bits(cd->data, &j, GRAY_BITS);
          // printf("(%d)", lc);
          if(lc <= MAX_GRAY) {
            cd->bitmap[i++] = lc;
            continue;
          }
          lc = lc == REP_BLACK ? 0 : MAX_GRAY;
          lc_cnt = read_unsigned_bits(cd->data, &j, GRAY_BIT_COUNT) + 3;
          // printf("(%d)", lc_cnt);
          while(i < bitmap_len && lc_cnt--) cd->bitmap[i++] = lc;
        }
        break;
    }

    cd->ok = 1;
  }

  printf(
    "Font Size\n  Height: %d\n  Baseline: %d\n  Line Height: %d\n\n",
    font_height, -font_y_ofs, fh.line_height
  );

  for(cd = char_list.start; cd; cd = cd->next) dump_char(cd);

  return 0;
}


void get_font_height(font_t *font, int *height, int *y_ofs)
{
  int h, dy, i;
  char_data_t *cd;

  // get font dimensions
  h = dy = 0;
  for(cd = char_list.start; cd; cd = cd->next) {
    if(!cd->ok) continue;
    if(font && cd->font != font) continue;
    if(cd->y_ofs < dy) dy = cd->y_ofs;
    i = cd->bitmap_height + cd->y_ofs;
    if(i > h) h = i;
  }

  *height = h - dy;
  *y_ofs = dy;
}


