#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <getopt.h>
#include <iconv.h>
#include <errno.h>
#include <inttypes.h>

#include <sys/types.h>
#include <sys/stat.h>

#include <X11/X.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#define MAGIC	0xd2828e07

struct option options[] = {
  { "verbose", 0, NULL, 'v' },
  { "font", 1, NULL, 'f' },
  { "add", 1, NULL, 'a' },
  { "add-text", 1, NULL, 't' },
  { "add-charset", 1, NULL, 'c' },
  { "line-height", 1, NULL, 'l' },
  { "prop", 1, NULL, 'p' },
  { "fsize", 1, NULL, 300 },
  { "test", 0, NULL, 999 },
  { }
};

typedef struct {
  unsigned size;
  unsigned char *data;
  unsigned real_size;
} file_data_t;

typedef struct {
  uint32_t magic;
  uint16_t entries;
  uint8_t height;
  uint8_t line_height;
} font_header_t; 

typedef struct {
  uint16_t ofs;
  uint16_t c;
  uint32_t size;
} char_header_t;

typedef struct {
  char *name;
  XFontStruct *x;
  unsigned used:1;		/* font actually used */
  int height;
  int yofs;
} font_t;

typedef struct char_data_s {
  struct char_data_s* next;
  unsigned ok:1;		/* char exists */
  int c;			/* char (utf32) */
  int index;			/* array index for font */
  font_t *font;			/* pointer to font */
  int width;			/* char width */
  int height;			/* char (actually font) height */
  unsigned char *bitmap;	/* char bitmap, width x height */
  int x_ofs;
  int y_ofs;
  int real_width;
  int real_height;
  char_header_t head;
} char_data_t;

int opt_verbose = 0;
char *opt_file;
int opt_test = 0;
int opt_line_height = 0;
int opt_prop = 0;
int opt_spacing = 0;
int opt_space_width = 0;

int opt_fsize_height = 0;
int opt_fsize_yofs = 0;

file_data_t font = {};

font_t font_list[16];
int fonts;

char_data_t *char_list;

static char_data_t *add_char(int c);
static char_data_t *find_char(int c);
static void dump_char(char_data_t *cd);
static void dump_char_list(void);
static void sort_char_list(void);
static int char_sort(const void *a, const void *b);
static void locate_char(char_data_t *cd);
static int char_index(XFontStruct *xfont, int c);
static int empty_row(char_data_t *cd, int row);
static int empty_column(char_data_t *cd, int column);
static void add_bbox(char_data_t *cd);
static void make_prop(char_data_t *cd);
static int no_space(char_data_t *cd);
static void encode_chars(font_header_t *fh);
static void add_data(file_data_t *d, void *buffer, unsigned size);
static void write_data(char *name);

int main(int argc, char **argv)
{
  Display *display;
  XGCValues gcv;
  GC gc1, gc2;
  Pixmap pixmap;
  XImage *xi;
  XChar2b xc;
  int i, j, k, font_width, font_height;
  char *str, *str1, *t;
  char_data_t *cd;
  iconv_t ic = (iconv_t) -1, ic2;
  char obuf[4], ibuf[6];
  char obuf2[4*0x100], ibuf2[0x100];
  char *obuf_ptr, *ibuf_ptr;
  size_t obuf_left, ibuf_left;
  FILE *f;
  font_header_t fh;
  unsigned char uc;

  opterr = 0;

  while((i = getopt_long(argc, argv, "a:f:c:l:p:t:v", options, NULL)) != -1) {
    switch(i) {
      case 'f':
        if(fonts < sizeof font_list / sizeof *font_list) {
          font_list[fonts].height = opt_fsize_height;
          font_list[fonts].yofs = opt_fsize_yofs;
          font_list[fonts++].name = optarg;
        }
        break;

      case 'a':
        t = optarg;
        while((str = strsep(&t, ","))) {
          if(sscanf(str, "%i - %i%n", &i, &j, &k) == 2 && k == strlen(str)) {
            if(i < 0 || j < 0 || j < i || j - i >= 0x10000) {
              fprintf(stderr, "invalid char range spec: %s\n", str);
              return 1;
            }
            while(i <= j) add_char(i++);
          }
          else {
            i = strtol(str, &str1, 0);
            if(*str1 || i < 0) {
              fprintf(stderr, "invalid char number: %s\n", str);
              return 1;
            }
            add_char(i);
          }
        }
        break;

      case 'l':
        str = optarg;
        i = strtol(str, &str1, 0);
        if(*str1 || i < 0) {
          fprintf(stderr, "invalid line height: %s\n", str);
          return 1;
        }
        opt_line_height = i;
        break;

      case 'p':
        str = optarg;
        if(sscanf(str, "%i , %i%n", &i, &j, &k) == 2 && k == strlen(str)) {
          opt_prop = 1;
          opt_spacing = i;
          opt_space_width = j;
        }
        else {
          fprintf(stderr, "invalid spec: %s\n", str);
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
          if(i >= 0x20) add_char(i);
        }
        iconv_close(ic2);
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
                  i = *(int *) obuf;
                  if(i >= 0x20) {
                    // fprintf(stderr, "add char 0x%x\n", i);
                    add_char(i);
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
        opt_verbose++;
        break;

      case 300:
        str = optarg;
        if(sscanf(str, "%i , %i%n", &i, &j, &k) == 2 && k == strlen(str)) {
          opt_fsize_height = i;
          opt_fsize_yofs = j;
        }
        else {
          fprintf(stderr, "invalid font size spec: %s\n", str);
          return 1;
        }
        break;

      case 999:
        opt_test++;
        break;
    }
  }

  argc -= optind; argv += optind;

  if(argc != 1) {
    fprintf(stderr,
      "Usage: getx11font [options] fontfile\n"
      "Build font for boot loader using X11 fonts.\n"
      "  -a, --add=first[-last]\n\tAdd chars from this range.\n"
      "  -c, --add-charset=charset\n\tAdd all chars from this charset.\n"
      "  -f, --font=X11_font_spec\n\tUse this font.\n"
      "  -h, --help\n\tShow this help text.\n"
      "  -l, --line-height=n\n\tSet line height (default: font height).\n"
      "  -p, --prop=n1,n2\n\tFake proportionally spaced Font.\n\tn1: spacing between chars; n2: space (char U+0020) width\n"
      "  -t, --add-text=samplefile\n\tAdd all chars used in this file. File must be UTF-8 encoded.\n"
      "  -v, --verbose\n\tDump font info.\n"
      "      --fsize=height,yofs\n\tOverride font size.\n"
    );
    return 1;
  }

  opt_file = argv[0];

  if(ic != (iconv_t) -1) iconv_close(ic);

  /* use default char list */
  if(!char_list) for(i = 0x20; i <= 0x7f; i++) add_char(i);

  /* default font */
  if(!fonts) font_list[fonts++].name = "fixed";

  sort_char_list();

  if(!(display = XOpenDisplay(getenv("DISPLAY")))) {
    return fprintf(stderr, "unable to open display\n"), 2;
  }

  /* open all fonts */
  for(i = 0; i < fonts; i++) {
    if(!(font_list[i].x = XLoadQueryFont(display, font_list[i].name))) {
      fprintf(stderr, "Warning: no such font: %s\n", font_list[i].name);
    }
  }

  /* look for chars in fonts */
  for(cd = char_list; cd; cd = cd->next) locate_char(cd);

  /* get font heigth */
  for(font_height = 0, i = 0; i < fonts; i++) {
    if(font_list[i].used) {
      j = font_list[i].x->max_bounds.ascent + font_list[i].x->max_bounds.descent;
      if(font_list[i].height) j = font_list[i].height;
      if(j > font_height) font_height = j;
    }
  }
  
  /* get font width */
  for(font_width = 0, cd = char_list; cd; cd = cd->next) {
    if(cd->width > font_width) font_width = cd->width;
    /* char height = font height */
    cd->height = font_height;
  }

  printf("Font Size: %d x %d", font_width, font_height);
  if(opt_line_height && opt_line_height != font_height) {
    printf(", Line Height: %d", opt_line_height);
  }
  printf("\n");

  if(font_width > 32 || font_height > 32) {
    fprintf(stderr, "Font size too large (max 32 x 32).\n");
    return 8;
  }

  if(!font_width || !font_height) {
    fprintf(stderr, "Strange font.\n");
    return 8;
  }

  /* now, render all chars */

  pixmap = XCreatePixmap(display, DefaultRootWindow(display), font_width, font_height, 1);

  gcv.background = gcv.foreground = 0;
  gcv.fill_style = FillSolid;

  gc1 = XCreateGC(display, pixmap, GCForeground | GCBackground | GCFillStyle, &gcv);
  gcv.foreground = 1;
  gc2 = XCreateGC(display, pixmap, GCForeground | GCBackground | GCFillStyle, &gcv);

  for(cd = char_list; cd; cd = cd->next) {
    if(!cd->ok) continue;
    xc.byte1 = cd->c >> 8;
    xc.byte2 = cd->c;

    XSetFont(display, gc2, cd->font->x->fid);

    XFillRectangle(display, pixmap, gc1, 0, 0, font_width, font_height);
    XDrawImageString16(display, pixmap, gc2, 0, cd->font->x->max_bounds.ascent - cd->font->yofs, &xc, 1);

    xi = XGetImage(display, pixmap, 0, 0, font_width, font_height, 1, XYPixmap);

    cd->bitmap = calloc(cd->height * cd->width, 1);
    for(k = 0, j = 0; j < cd->height; j++) {
      for(i = 0; i < cd->width; i++) {
        cd->bitmap[k++] = XGetPixel(xi, i, j);
      }
    }

    XDestroyImage(xi);
  }

  XFreePixmap(display, pixmap);
  XFreeGC(display, gc2);
  XFreeGC(display, gc1);

  XCloseDisplay(display);

  for(cd = char_list; cd; cd = cd->next) add_bbox(cd);

  if(opt_prop) {
    for(cd = char_list; cd; cd = cd->next) make_prop(cd);
  }

  encode_chars(&fh);

  for(i = j = 0, cd = char_list; cd; cd = cd->next) {
    if(!cd->ok) {
      printf(i ? ", " : "Missing Chars: ");
      printf("0x%04x", cd->c);
      i = 1;
    }
  }
  if(i) printf("\n");

  add_data(&font, &fh, sizeof fh);
  for(cd = char_list; cd; cd = cd->next) {
    if(!cd->ok) continue;
    add_data(&font, &cd->head, sizeof cd->head);
  }

  i = 0;
  for(cd = char_list; cd; cd = cd->next) {
    if(!cd->ok) continue;
    k = cd->real_width * cd->real_height;
    for(uc = 0, i = j = 0; i < k; i++, j++) {
      if(j == 8) {
        add_data(&font, &uc, 1);
        uc = 0;
        j = 0;
      }
      if(cd->bitmap[i]) uc += (1 << j);
    }
    if(j) add_data(&font, &uc, 1);
  }

  if(opt_verbose) dump_char_list();

  write_data(opt_file);

  return 0;
}


char_data_t *add_char(int c)
{
  char_data_t *cd;

  if((cd = find_char(c))) return cd;

  cd = calloc(1, sizeof *cd);
  cd->c = c;
  cd->next = char_list;

  return char_list = cd;
}


char_data_t *find_char(int c)
{
  char_data_t *cd;

  for(cd = char_list; cd; cd = cd->next) {
    if(cd->c == c) return cd;
  }

  return NULL;
}


void dump_char(char_data_t *cd)
{
  int i, j;
  unsigned char *p;

  if(!cd || !cd->ok) return;

  printf(
    "Char 0x%04x\n  Font: %s\n  Size: %d x %d\n",
    cd->c, cd->font->name, cd->width, cd->height
  );

  if(cd->bitmap) {
    printf(
      "  Bitmap: %d x %d\n  Offset: %d x %d\n",
      cd->real_width, cd->real_height, cd->x_ofs, cd->y_ofs
    );
    p = cd->bitmap;
    for(j = 0; j < cd->height; j++) {
      printf("    |");
      if(j < cd->y_ofs || j >= cd->y_ofs + cd->real_height) {
        for(i = 0; i < cd->width; i++) printf(".");
      }
      else {
        for(i = 0; i < cd->width; i++) {
          if(i < cd->x_ofs || i >= cd->x_ofs + cd->real_width) {
            printf(".");
          }
          else {
            printf("%c", *p++ ? '#' : ' ');
          }
        }
      }
      printf("|\n");
    }
  }

}


void dump_char_list()
{
  char_data_t *cd;

  for(cd = char_list; cd; cd = cd->next) {
    dump_char(cd);
  }
}


void sort_char_list()
{
  char_data_t *cd;
  unsigned u, len;
  char_data_t **c_list;

  for(len = 0, cd = char_list; cd; cd = cd->next) len++;

  if(!len) return;

  c_list = calloc(len + 1, sizeof *c_list);

  for(u = 0, cd = char_list; cd; cd = cd->next, u++) c_list[u] = cd;

  qsort(c_list, len, sizeof *c_list, char_sort);

  for(u = 0; u < len; u++) {
    c_list[u]->next = c_list[u + 1];
  }

  char_list = *c_list;

  free(c_list);
}


int char_sort(const void *a, const void *b)
{
  return (*(char_data_t **) a)->c - (*(char_data_t **) b)->c;
}


void locate_char(char_data_t *cd)
{
  int i, j;
  XCharStruct *xc;

  for(i = 0; i < fonts; i++) {
    if((j = char_index(font_list[i].x, cd->c)) >= 0) {
      xc = font_list[i].x->per_char ? font_list[i].x->per_char + j : &(font_list[i].x->max_bounds);
      if(xc && xc->width) {
        cd->index = j;
        cd->font = font_list + i;
        cd->width = xc->width;
        /* work around broken font metric */
        if(cd->font->name && strstr(cd->font->name, "haydar")) cd->width += 10;
        cd->ok = 1;
        font_list[i].used = 1;
        break;
      }
    }
  }
}


int char_index(XFontStruct *xfont, int c)
{
  int i;

  if(!xfont || (c & ~0xffff)) return -1;

  if(!xfont->min_byte1 && !xfont->max_byte1) {
    i = c - xfont->min_char_or_byte2;
    if(i > (int) xfont->max_char_or_byte2) i = -1;
  }
  else {
    i = ((c >> 8) - xfont->min_byte1)
        * (xfont->max_char_or_byte2 - xfont->min_char_or_byte2 + 1)
        + (c & 0xff) - xfont->min_char_or_byte2;
  }

  return i;
}


int empty_row(char_data_t *cd, int row)
{
  unsigned char *p1, *p2;

  p2 = (p1 = cd->bitmap + row * cd->real_width) + cd->real_width;
  while(p1 < p2) if(*p1++) return 0;

  return 1;
}


int empty_column(char_data_t *cd, int col)
{
  int i;
  unsigned char *p;

  for(p = cd->bitmap + col, i = 0; i < cd->real_height; i++, p += cd->real_width) {
    if(*p) return 0;
  }

  return 1;
}


void add_bbox(char_data_t *cd)
{
  int i;
  unsigned char *p1, *p2;

  if(!cd->ok) return;

  cd->real_width = cd->width;
  cd->real_height = cd->height;

  if(opt_test) return;

  while(cd->real_height && empty_row(cd, cd->real_height - 1)) cd->real_height--;

  while(cd->real_height && empty_row(cd, 0)) {
    cd->real_height--;
    cd->y_ofs++;
    memcpy(cd->bitmap, cd->bitmap + cd->real_width, cd->real_width * cd->real_height);
  }

  while(cd->real_width && empty_column(cd, cd->real_width - 1)) {
    cd->real_width--;
    p2 = (p1 = cd->bitmap + cd->real_width) + 1;
    for(i = 1; i < cd->real_height; i++, p1 += cd->real_width, p2 += cd->real_width + 1) {
      memcpy(p1, p2, cd->real_width);
    }
  }

  while(cd->real_width && empty_column(cd, 0)) {
    cd->real_width--;
    cd->x_ofs++;
    p2 = (p1 = cd->bitmap) + 1;
    for(i = 0; i < cd->real_height; i++, p1 += cd->real_width, p2 += cd->real_width + 1) {
      memcpy(p1, p2, cd->real_width);
    }
  }
}


/*
 * Fake proprtionally spaced font from fixed size font.
 */
void make_prop(char_data_t *cd)
{
  if(!cd->ok) return;

  cd->x_ofs = no_space(cd) ? 0 : opt_spacing;
  cd->width = cd->x_ofs + (cd->real_width ?: opt_space_width);
}


int no_space(char_data_t *cd)
{
  int n = 0;

  switch(cd->index) {
    case 0xfecb:
    case 0xfe91:
      n = 1;
      break;
  }

  return n;
}


void encode_chars(font_header_t *fh)
{
  int ofs;
  char_data_t *cd;

  memset(fh, 0, sizeof *fh);
  fh->magic = MAGIC;
  fh->height = char_list->height;
  fh->line_height = opt_line_height ?: fh->height;

  ofs = sizeof *fh;

  for(cd = char_list; cd; cd = cd->next) if(cd->ok) fh->entries++;

  ofs += fh->entries * sizeof cd->head;

  for(cd = char_list; cd; cd = cd->next) {
    if(!cd->ok) continue;
    memset(&cd->head, 0, sizeof cd->head);
    cd->head.ofs = ofs;
    cd->head.c = cd->c;
    cd->head.size =
      (((cd->c >> 16)   & 0x1f) <<  0) +
      ((cd->x_ofs       & 0x1f) <<  5) +
      ((cd->y_ofs       & 0x1f) << 10) +
      ((cd->real_width  & 0x1f) << 15) +
      ((cd->real_height & 0x1f) << 20) +
      ((cd->width       & 0x1f) << 25);
    ofs += (cd->real_width * cd->real_height + 7) >> 3;
  }
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


void write_data(char *name)
{
  FILE *f;

  f = strcmp(name, "-") ? fopen(name, "w") : stdout;

  if(!f) {
    perror(name);
    return;
  }

  if(fwrite(font.data, font.size, 1, f) != 1) {
    perror(name); exit(3);
  }

  fclose(f);
}


