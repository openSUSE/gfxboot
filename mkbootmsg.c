/*
 * Create a boot loader graphics file.
 *
 */

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <inttypes.h>
#include <ctype.h>
#include <iconv.h>

#include "bincode.h"

#define MAGIC		0xb2d97f00
#define VERSION 	5
#define DICT_SIZE	1000

#define MAX_INCLUDE	10

typedef struct {
  uint32_t magic_id;
  uint8_t  version;
  uint8_t  res_1;
  uint8_t  res_2;
  uint8_t  res_3;
  uint32_t bincode;
  uint32_t bincode_size;
  uint32_t bincode_crc;
  uint32_t dict;
  uint32_t code;
  uint32_t code_size;
} file_header_t;

typedef struct {
  unsigned size;
  unsigned char *data;
  unsigned real_size;
  unsigned char *ptr;
  char *name;
  int line;
} file_data_t;

struct option options[] = {
  { "config", 1, NULL, 'c' },
  { "info", 0, NULL, 'i' },
  { "log", 0, NULL, 'l' },
  { "help", 0, NULL, 'h' },
  { }
};

// max. 16
// Keep in sync with bincode.asm!
typedef enum {
  t_none, t_int, t_unsigned, t_bool, t_string, t_code, t_ret, t_prim,
  t_sec, t_dict_idx, t_array, t_end, t_ptr,
  t_skip = 15	/* special, for internal use */
} type_t;

// for log file
static char *type_name[16] = {
  "none", "int", "uint", "bool", "str", "code", "ret", "prim",
  "sec", "dict", "arr", "end", "ptr", "", "", ""
};

typedef struct {
  char *name;
  type_t type;
  int line;
  int del, ref, ref_idx, ref_ind, def, def_idx, def_ind, ref0, ref0_idx;
  union {
    unsigned u;
    unsigned char *p;
  } value;
} dict_t;

typedef struct {
  char *name;
  type_t type;
  unsigned ofs;
  unsigned size;
  int line, incl_level;
  union {
    unsigned u;
    unsigned char *p;
  } value;
  unsigned char *enc;
} code_t;

void help(void);
file_data_t read_file(char *name);
int is_pcx(file_data_t *fd);
void fix_pal(unsigned char *pal, unsigned shade1, unsigned shade2, unsigned char *rgb);
void write_data(char *name);
void add_data(file_data_t *d, void *buffer, unsigned size);
code_t *new_code(void);
dict_t *new_dict(void);
unsigned number(char *value);
void hexdump(file_data_t *fd, unsigned ofs, int len);
void show_info(char *name);
int get_hex(char *s, int len, unsigned *val);
char *utf32_to_utf8(int u8);
char *next_word(char **ptr);
void parse_comment(char *comment, file_data_t *incl);
int find_in_dict(char *name);
int translate(int pass);
void encode_dict(void);
void parse_config(char *name, char *log_file);
void optimize_dict(FILE *lf);
unsigned skip_code(unsigned pos);
unsigned next_code(unsigned pos);
int optimize_code(FILE *lf);
int optimize_code1(FILE *lf);
int optimize_code2(FILE *lf);
int optimize_code3(FILE *lf);
int optimize_code4(FILE *lf);
int optimize_code5(FILE *lf);
int optimize_code6(FILE *lf);
int optimize_code7(FILE *lf);
void log_dict(FILE *lf);
void log_code(FILE *lf);
void log_cline(FILE *lf);
void decompile(unsigned char *data, unsigned size);

/* dummy function to make ld fail */
extern void wrong_struct_size(void);

int config_ok = 0;

file_header_t header = {};

file_data_t pscode = {};
file_data_t dict_file = {};

dict_t *dict = NULL;
unsigned dict_size = 0;
unsigned dict_max_size = 0;

code_t *code = NULL;
unsigned code_size = 0;
unsigned code_max_size = 0;

int number_err = 0;
// current config line
int line = 1;

int verbose = 0;
int optimize = 0;
int opt_force = 0;

char *lib_path[2] = { NULL, "/usr/share/gfxboot" };

// initial vocabulary (note: "{" & "}" are special)
#include "vocabulary.h"

int main(int argc, char **argv)
{
  int i;
  char *config_file = NULL, *log_file = NULL;
  int opt_info = 0;

  if(sizeof (file_header_t) != 32) {
    fprintf(stderr, "file_header_t has wrong size: %d\n", sizeof (file_header_t));
    wrong_struct_size();
    return 1;
  }

  opterr = 0;

  while((i = getopt_long(argc, argv, "c:fhiL:l:Ov", options, NULL)) != -1) {
    switch(i) {
      case 'c':
        config_file = optarg;
        break;

      case 'f':
        opt_force = 1;
        break;

      case 'i':
        opt_info = 1;
        break;

      case 'l':
        log_file = optarg;
        break;

      case 'L':
        lib_path[0] = optarg;
        break;

      case 'O':
        optimize = 1;
        break;

      case 'v':
        verbose++;
        break;

      default:
        help();
        return 0;
    }
  }

  argc -= optind; argv += optind;

  if(config_file && argc == 1) {
    parse_config(config_file, log_file);
    write_data(*argv);
    return 0;
  }

  if(opt_info && argc == 1) {
    show_info(*argv);
    return 0;
  }

  help();

  return 1;
}


void help()
{
  fprintf(stderr, "%s",
    "mkbootmsg: Usage mkbootmsg [options] out_file\n"
    "  Options are:\n"
    "  -c config_file, --config config_file\n"
    "    Create a boot message file using this configuration.\n"
    "  -l log_file, --log log_file\n"
    "    Write log to this file.\n"
    "  -i, --info\n"
    "    Show info about file.\n"
    "  -L\n"
    "    Search path for file read.\n"
    "  -O\n"
    "    Optimize code.\n"
    "  -h, --help\n"
    "    Show this text.\n"
  );
}


file_data_t read_file(char *name)
{
  file_data_t fd = { };
  FILE *f;
  unsigned u;
  char *s;

  if(!name) return fd;

  f = fopen(name, "r");
  if(!f) {
    for(u = 0; u < sizeof lib_path / sizeof *lib_path; u++) {
      if(lib_path[u]) {
        asprintf(&s, "%s/%s", lib_path[u], name);
        f = fopen(s, "r");
        if(f) {
          fd.name = s;
          break;
        }
        else {
          free(s);
        }
      }
    }
  }
  else {
    fd.name = strdup(name);
  }
  
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
    fd.ptr = fd.data = malloc(fd.size);
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


void write_data(char *name)
{
  FILE *f;
  unsigned ofs;
  file_data_t fd = {};

  f = strcmp(name, "-") ? fopen(name, "w") : stdout;

  if(!f) {
    perror(name);
    return;
  }

  // first, fix all offsets

  ofs = sizeof header;

  header.bincode = ofs;
  header.bincode_size = sizeof bincode_data;
  ofs += sizeof bincode_data;

  if(dict_file.data) {
    header.dict = ofs;
    ofs += dict_file.size;
  }

  if(pscode.data) {
    header.code = ofs;
    header.code_size = pscode.size;
    ofs += pscode.size;
  }

  // then, put everything together

  add_data(&fd, &header, sizeof header);

  add_data(&fd, bincode_data, sizeof bincode_data);

  add_data(&fd, dict_file.data, dict_file.size);

  add_data(&fd, pscode.data, pscode.size);

  // now write everything

  if(fwrite(fd.data, fd.size, 1, f) != 1) {
    perror(name); exit(3);
  }

  fclose(f);
}


void add_data(file_data_t *d, void *buffer, unsigned size)
{
  ssize_t ofs = 0;

  if(!size || !d || !buffer) return;

  if(d->ptr && d->data) ofs = d->ptr - d->data;

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

  if(d->ptr && d->data) d->ptr = d->data + ofs;
}


code_t *new_code()
{
  if(code_size >= code_max_size) {
    code_max_size += 10;
    code = realloc(code, code_max_size * sizeof * code);
    memset(code + code_size, 0, (code_max_size - code_size) * sizeof * code);
  }

  return code + code_size++;
}



dict_t *new_dict()
{
  if(dict_size >= dict_max_size) {
    dict_max_size += 10;
    dict = realloc(dict, dict_max_size * sizeof *dict);
    memset(dict + dict_size, 0, (dict_max_size - dict_size) * sizeof *dict);
  }

  return dict + dict_size++;
}


unsigned number(char *value)
{
  char *s;
  unsigned u;

  u = strtoul(value, &s, 0);

  if(*s) {
    fprintf(stderr, "Line %d: \"%s\" is not a number\n", line, value);
    exit(1);
  }

  return u;
}


void hexdump(file_data_t *fd, unsigned ofs, int len)
{
  unsigned u, p;
  char s[17];
  char ind[] = "    ";
  int i;

  if(!len || !fd) return;

  if(len < 0 || ofs + len > fd->size) {
    printf("invalid data range: %d bytes at 0x%x\n", len, ofs);
  }

  p = ofs;
  u = ofs & ~0xf;

  memset(s, ' ', 16);
  s[16] = 0;

  if(u < p) {
    printf("%s%05x  ", ind, u);
    i = (p - u) * 3;
    if(i > 8 * 3) i++;
    while(i--) printf(" ");
  }

  while(p < ofs + len) {
    s[p & 15] = (fd->data[p] >= 0x20 && fd->data[p] <= 0x7e) ? fd->data[p] : '.';
    if(!(p & 15)) {
      printf("%s%05x  ", ind, p);
    }
    if(!(p & 7) && (p & 15)) printf(" ");
    printf("%02x ", fd->data[p]);
    if(!(++p & 15)) {
      printf(" %s\n", s);
    }
  }

  if(p & 15) {
    s[p & 15] = 0;
    if(!(p & 8)) printf(" ");
    printf("%*s %s\n", 3 * (16 - (p & 15)), "", s);
  }


}


void show_info(char *name)
{
  unsigned ofs = 0;
  file_data_t fd;
  unsigned u;

  fd = read_file(name);

  if(fd.size >= sizeof header) {
    memcpy(&header, fd.data, sizeof header);
    ofs += sizeof header;
  }

  if(header.magic_id != MAGIC) {
    fprintf(stderr, "No mkbootmsg file.\n");
    return;
  }

  if(header.version != VERSION) {
    fprintf(stderr, "Version %u not supported.\n", header.version);
    return;
  }

  if(header.bincode && header.bincode_size) {
    printf("%u bytes ia32 code:\n", header.bincode_size);
    if(verbose >= 2) hexdump(&fd, header.bincode, header.bincode_size);
    printf("\n");
  }

  if(header.dict && header.code) {
    u = header.code - header.dict;
    printf("dictionary: %d bytes at 0x%x:\n", u, header.dict);
    hexdump(&fd, header.dict, u);
    printf("\n");
  }

  if(header.code && header.code_size) {
    printf("%u bytes code:\n", header.code_size);
    if(verbose >= 1) hexdump(&fd, header.code, header.code_size);
    printf("\n");
    decompile(fd.data + header.code, header.code_size);
    printf("\n");
  }
}


/*
 * Convert hex number of excatly len bytes.
 */
int get_hex(char *s, int len, unsigned *val)
{
  unsigned u;
  char s2[len + 1];

  if(!s || !len) return 0;
  strncpy(s2, s, len);
  s2[len] = 0;

  u = strtoul(s2, &s, 16);
  if(!*s) {
    if(val) *val = u;
    return 1;
  }

  return 0;
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


char *next_word(char **ptr)
{
  char *s, *start, *utf8;
  int is_str, is_comment;
  static char word[1024];
  int i, n;
  char qc = 0;

  s = *ptr;

  *word = 0;

  while(isspace(*s)) if(*s++ == '\n') line++;

  if(!*s) {
    *ptr = s;
    return word;
  }

  start = s;

  qc = *start;
  is_str = qc == '"' || qc == '\'' ? 1 : 0;
  is_comment = qc == '%' ? 1 : 0;

  if(is_comment) {
    while(*s && *s != '\n') s++;
  }
  else if(is_str) {
    *word = *s++;
    for(n = 1; n < sizeof word - 1; n++) {
      if(!*s) break;
      if(*s == qc) { s++; break; }
      if(*s == '\\') {
        s++;
        switch(*s) {
          case 0:
            word[n++] = '\\';
            break;

          case 'n':
            word[n] = '\n';
            break;
          
          case 't':
            word[n] = '\t';
            break;
          
          case '0':
            if(
              s[0] >= '0' && s[0] <= '7' &&
              s[1] >= '0' && s[1] <= '7' &&
              s[2] >= '0' && s[2] <= '7'
            ) {
              word[n] = ((s[0] - '0') << 6) + ((s[1] - '0') << 3) + (s[2] - '0');
              s += 2;
            }
            else {
              word[n] = *s;
            }
            break;
          
          case 'x':
            if(get_hex(s + 1, 2, &i)) {
              s += 2;
              word[n] = i;
            }
            else {
              word[n++] = '\\';
              word[n] = *s;
            }
            break;
          
          case 'u':
            if(get_hex(s + 1, 4, &i)) {
              s += 4;
              utf8 = utf32_to_utf8(i);
              while(*utf8) word[n++] = *utf8++;
              n--;
            }
            else {
              word[n++] = '\\';
              word[n] = *s;
            }
            break;
          
          case 'U':
            if(get_hex(s + 1, 8, &i)) {
              s += 8;
              utf8 = utf32_to_utf8(i);
              while(*utf8) word[n++] = *utf8++;
              n--;
            }
            else {
              word[n++] = '\\';
              word[n] = *s;
            }
            break;
          
          default:
            word[n] = *s;
        }
        s++;
      }
      else {
        word[n] = *s++;
      }
    }
    word[n] = 0;
  }
  else {
    while(!isspace(*s)) s++;
  }

  if(!is_str) {
    n = s - start;
    if(n >= sizeof word) n = sizeof word - 1;
    strncpy(word, start, n);
    word[n] = 0;
  }

  *ptr = s;

  return word;
}


void parse_comment(char *comment, file_data_t *incl)
{
  char t[5][100];
  int n;

  n = sscanf(comment, " %99s %99s %99s %99s %99s", t[0], t[1], t[2], t[3], t[4]);

  if(!n) return;

  if(n == 2 && !strcmp(t[0], "include")) {
    *incl = read_file(t[1]);
    if(!incl->data) exit(18);
    add_data(incl, "", 1);
    fprintf(stderr, "Including \"%s\"\n", incl->name);
    return;
  }
}


int find_in_dict(char *name)
{
  int i;

  for(i = 0; i < dict_size; i++) {
    if(dict[i].name && !strcmp(name, dict[i].name)) return i;
  }

  return -1;
}


unsigned usize(unsigned u)
{
  if(u >> 24) return 4;
  if(u >> 16) return 3;
  if(u >> 8) return 2;
  if(u) return 1;

  return 0;
}


unsigned isize(int i)
{
  if(i == 0) return 0;
  if(i >= -0x80 && i <= 0x7f) return 1;
  if(i >= -0x8000 && i <= 0x7fff) return 2;
  if(i >= -0x800000 && i <= 0x7fffff) return 3;

  return 4;
}


int translate(int pass)
{
  int i;
  code_t *c;
  unsigned u0, u1, u2;
  unsigned ofs = 0;
  int changed = 0;

  if(pass == 0) {
    changed = 1;
    for(i = 0; i < code_size; i++) {
      c = code + i;

      c->ofs = ofs;

      switch(c->type) {
        case t_skip:
          c->size = 0;
          break;

        case t_int:
        case t_unsigned:
          u0 = isize(c->value.u);
          u1 = usize(c->value.u);
          u2 = u0;
          if(u1 < u0) {
            c->type = t_unsigned;
            u2 = u1;
          }
          c->size = u2 + 1;
          c->enc = malloc(c->size);
          c->enc[0] = c->type + (u2 << 4);
          if(u2) memcpy(c->enc + 1, &c->value.u, u2);
          break;

        case t_string:
          u1 = strlen(c->value.p) + 1;
          u0 = usize(u1);
          c->size = u1 + u0 + 1;
          c->enc = malloc(c->size);
          c->enc[0] = c->type + (u0 << 4) + 0x80;
          memcpy(c->enc + 1, &u1, u0);
          memcpy(c->enc + 1 + u0, c->value.p, u1);
          break;

        case t_code:
          c->size = 5;
          break;

        case t_ret:
        case t_end:
          c->size = 1;
          c->enc = malloc(c->size);
          c->enc[0] = c->type;
          break;

        case t_none:
        case t_bool:
        case t_sec:
        case t_prim:
        case t_dict_idx:
          u0 = usize(c->value.u);
          c->size = u0 + 1;
          c->enc = malloc(c->size);
          c->enc[0] = c->type + (u0 << 4);
          if(u0) memcpy(c->enc + 1, &c->value.u, u0);
          break;

        default:
          fprintf(stderr, "Internal oops %d: type %d not allowed\n", __LINE__, c->type);
          exit(8);
      }

      ofs += c->size;
    }
  }
  else {
    for(i = 0; i < code_size; i++) {
      c = code + i;

      if(c->ofs != ofs) changed = 1;
      c->ofs = ofs;

      if(c->type == t_code) {
        u0 = c->value.u;
        if(u0 >= code_size) {
          fprintf(stderr, "Internal error %d\n", __LINE__);
          exit(11);
        }
        u1 = usize(code[u0].ofs);
        if(c->size != u1 + 1) changed = 1;
        c->size = u1 + 1;
        if(c->enc) free(c->enc);
        c->enc = malloc(c->size);
        c->enc[0] = c->type + (u1 << 4);
        if(u1) memcpy(c->enc + 1, &code[u0].ofs, u1);
      }

      ofs += c->size;
    }
  }

  return changed;
}


void encode_dict()
{
  unsigned u;
  int i;

  if(dict_size == 0 || dict_size > 0xffff) {
    fprintf(stderr, "Internal oops %d\n", __LINE__);
    exit(6);
  }

  add_data(&dict_file, &dict_size, 4);

  u = 0;

  for(i = 0; i < dict_size; i++) {
    if(dict[i].type == t_none || dict[i].type == t_prim) continue;
    add_data(&dict_file, &i, 2);
    add_data(&dict_file, &dict[i].type, 1);
    add_data(&dict_file, &dict[i].value.u, 4);
    u++;
  }

  dict_file.data[2] = u;
  dict_file.data[3] = u >> 8;
}


void parse_config(char *name, char *log_file)
{
  char *word;
  file_data_t cfg[MAX_INCLUDE];
  file_data_t incl;
  int i, j;
  unsigned u;
  dict_t *d;
  code_t *c, *c1;
  char *s;
  FILE *lf = NULL;
  int incl_level = 0;

  cfg[incl_level] = read_file(name);
  add_data(&cfg[incl_level], "", 1);

  if(!cfg[incl_level].ptr || !*cfg[incl_level].ptr) {
    fprintf(stderr, "Empty config file!\n");
    exit(1);
  }

  if(log_file && *log_file) lf = fopen(log_file, "w");

  header.magic_id = MAGIC;
  header.version = VERSION;

  // setup initial vocabulary
  for(i = 0; i < sizeof prim_names / sizeof *prim_names; i++) {
    d = new_dict();
    d->type = prim_names[i].type;
    d->value.u = prim_names[i].value;
    d->name = prim_names[i].name;
  }

  while(*cfg[incl_level].ptr || incl_level) {
    if(!*cfg[incl_level].ptr) {
      incl_level--;
      line = cfg[incl_level].line;
    }
    word = next_word((char **) &cfg[incl_level].ptr);
    if(!word || !*word) continue;

    if(word[0] == '%') {
      if(word[1] == '%') {
        incl.ptr = NULL;
        parse_comment(word + 2, &incl);
        if(incl.ptr) {
          if(incl_level == MAX_INCLUDE - 1) {
            fprintf(stderr, "Error: include level exceeded\n");
            exit(17);
          }
          else {
            cfg[incl_level].line = line;
            cfg[++incl_level] = incl;
            line = 1;
          }
        }
      }
      continue;
    }

    if(verbose >= 2) printf(">%s< (%d)\n", word, line);

    c = new_code();
    c->line = line;
    c->incl_level = incl_level;

    if(*word == '"') {
      c->type = t_string;
      c->value.p = strdup(word + 1);
    }
    else if(*word == '\'') {
      c->type = t_int;
      c->value.u = word[1];
      asprintf(&c->name, "%s'", word);
    }
    else if(*word == '/') {
      c->name = strdup(word + 1);

      c->type = t_dict_idx;

      if((i = find_in_dict(word + 1)) == -1) {
        d = new_dict();
        d->type = t_none;
        d->value.u = 1;		// mark as defined
        d->name = strdup(word + 1);
        c->value.u = dict_size - 1;
      }
      else {
        if(dict[i].type == t_none && !dict[i].value.u) {
          dict[i].value.u = 1;	// mark as defined
        }
        c->value.u = i;
      }
    }
    else if(!strcmp(word, "{")) {
      c->type = t_code;
      c->name = strdup(word);
    }
    else if(!strcmp(word, "}")) {
      c->type = t_ret;
      c->name = strdup(word);
      for(c1 = c; c1 >= code; c1--) {
        if(c1->type == t_code && !c1->value.u) {
          // point _after_ "}"
          c1->value.u = c - code + 1;
          break;
        }
      }
      if(c1 < code) {
        fprintf(stderr, "Syntax error: no matching \"{\" for \"}\" in line %d\n", line);
        exit(10);
      }
    }
    else {
      c->name = strdup(word);

      i = find_in_dict(word);

      if(i == -1) {
        u = strtoul(word, &s, 0);
        if(*s) {
          d = new_dict();
          d->type = t_none;
          d->name = strdup(word);
          c->type = t_sec;
          c->value.u = dict_size - 1;
        }
        else {
          c->type = t_int;
          c->value.u = u;
        }
      }
      else {
        c->type = t_sec;
        c->value.u = i;
      }
    }
  }

  // add a final 'end'
  c = new_code();
  c->type = t_end;
  c->name = "end";

  // check vocabulary
  for(i = j = 0; i < dict_size; i++) {
    if(
      dict[i].type == t_none && !dict[i].value.u &&
      i >= sizeof prim_names / sizeof *prim_names	/* callback functions need not be defined */
    ) {
      if(!j) fprintf(stderr, "Undefined words:");
      else fprintf(stderr, ",");
      fprintf(stderr, " %s", dict[i].name);
      j = 1;
    }
  }
  if(j) {
    fprintf(stderr, "\n");
    if(!opt_force) exit(10);
  }

  if(optimize) {
    if(lf) fprintf(lf, "# searching for unused code:\n");
    for(i = 0; i < 64; i++) {
      if(verbose && lf) fprintf(lf, "# pass %d\n", i + 1);
      if(!optimize_code(lf)) break;
    }
    if(lf) fprintf(lf, "# %d optimization passes\n", i + 1);
    if(i) {
      if(lf) fprintf(lf, "# searching for unused dictionary entries:\n");
      optimize_dict(lf);
    }
  }

  // now translate to byte code
  for(i = 0; i < 20; i++) {
    if(!translate(i)) break;
  }
  if(lf) fprintf(lf, "# %d encoding passes\n", i + 1);
  if(i == 20) {
    fprintf(stderr, "Oops, code translation does not converge.\n");
    exit(7);
  }

  // store it
  for(i = 0; i < code_size; i++) {
    if((!code[i].enc || !code[i].size) && code[i].type != t_skip) {
      fprintf(stderr, "Internal oops %d\n", __LINE__);
      exit(8);
    }
    add_data(&pscode, code[i].enc, code[i].size);
  }

  // now encode the dictionary
  encode_dict();

  log_code(lf);
  log_dict(lf);

  if(lf) fclose(lf);
}


/*
 * Remove deleted dictionary entries.
 */
void optimize_dict(FILE *lf)
{
  int i;
  int old_ofs, new_ofs;

  for(old_ofs = new_ofs = 0; old_ofs < dict_size; old_ofs++) {
    if(dict[old_ofs].del) continue;
    if(old_ofs != new_ofs) {
      if(verbose && lf) fprintf(lf, "#   rename %d -> %d\n", old_ofs, new_ofs);
      dict[new_ofs] = dict[old_ofs];
      for(i = 0; i < code_size; i++) {
        if(
          (
            code[i].type == t_sec ||
            code[i].type == t_dict_idx
          ) &&
          code[i].value.u == old_ofs
        ) {
          code[i].value.u = new_ofs;
        }
      }
    }
    new_ofs++;
  }
  if(lf && new_ofs != old_ofs) {
    fprintf(lf, "# new dictionary size %d (%d - %d)\n", new_ofs, old_ofs, old_ofs - new_ofs);
  }

  dict_size = new_ofs;
}


/*
 * Skip deleted code.
 */
unsigned skip_code(unsigned pos)
{
  while(pos < code_size && code[pos].type == t_skip) pos++;

  return pos;
}


/*
 * Return next instruction.
 */
unsigned next_code(unsigned pos)
{
  if((pos + 1) >= code_size) return pos;

  return skip_code(++pos);
}


int optimize_code(FILE *lf)
{
  unsigned i;
  int changed, ind = 0;
  code_t *c;

  for(i = 0; i < dict_size; i++) {
    dict[i].def = dict[i].def_idx =
    dict[i].ref = dict[i].ref_idx =
    dict[i].ref0 =  dict[i].ref0_idx = 0;
  }

  for(i = 0; i < code_size; i++) {
    c = code + i;

    switch(c->type) {
      case t_code:
        ind++;
        break;

      case t_ret:
        if(!ind) {
          fprintf(stderr, "Warning: nesting error at line %d\n", c->line);
        }
        ind--;
        break;

      case t_sec:
        if(c->value.u < dict_size) {
          dict[c->value.u].ref++;
          dict[c->value.u].ref_idx = i;
          dict[c->value.u].ref_ind = ind;
          if(ind == 0 && !dict[c->value.u].ref0) {
            dict[c->value.u].ref0 = 1;
            dict[c->value.u].ref0_idx = i;
          }
        }
        break;

      case t_dict_idx:
        if(c->value.u < dict_size) {
          dict[c->value.u].def++;
          dict[c->value.u].def_idx = i;
          dict[c->value.u].def_ind = ind;
        }
        break;

      default:
        break;
    }
  }

  changed = 1;

  optimize_code1(lf) ||
  optimize_code2(lf) ||
  optimize_code3(lf) ||
  optimize_code4(lf) ||
  optimize_code5(lf) ||
  optimize_code6(lf) ||
  optimize_code7(lf) ||
  (changed = 0);

  return changed;
}


/*
 * Find references to primary words.
 */
int optimize_code1(FILE *lf)
{
  unsigned i, j;
  int changed = 0;
  code_t *c;

  for(i = 0; i < dict_size; i++) {
    if(
      i < sizeof prim_names / sizeof *prim_names &&
      !dict[i].del &&
      dict[i].def == 0 &&
      dict[i].ref &&
      dict[i].type == t_prim
    ) {
      if(verbose && lf) fprintf(lf, "#   replacing %s\n", dict[i].name);
      for(j = 0; j < code_size; j++) {
        c = code + j;
        if(c->type == t_sec && c->value.u == i) {
          c->type = dict[i].type;
          c->value.u = dict[i].value.u;
        }
      }

      changed = 1;
    }
  }

  return changed;
}


/*
 * Remove things like
 *
 *   /foo 123 def
 *   /foo "abc" def
 *   /foo /bar def
 *
 * if foo is unused.
 */
int optimize_code2(FILE *lf)
{
  unsigned i, j;
  int changed = 0;
  code_t *c0, *c1, *c2;

  for(i = 0; i < dict_size; i++) {
    if(
      i >= sizeof prim_names / sizeof *prim_names &&
      !dict[i].del &&
      !dict[i].ref &&
      dict[i].def == 1 &&
      dict[i].type == t_none
    ) {
      c0 = code + (j = dict[i].def_idx);
      c1 = code + (j = next_code(j));
      c2 = code + (j = next_code(j));

      if(
        c0->type == t_dict_idx &&
        c0->value.u == i &&
        (
          c1->type == t_none ||
          c1->type == t_int ||
          c1->type == t_unsigned ||
          c1->type == t_bool ||
          c1->type == t_string ||
          c1->type == t_dict_idx ||
          c1->type == t_ptr
        ) &&
        c2->type == t_prim &&
        c2->value.u == p_def
      ) {
        if(verbose && lf) fprintf(lf, "#   defined but unused: %s (index %d)\n", dict[i].name, i);
        if(verbose && lf) fprintf(lf, "#   deleting code: %d - %d\n", dict[i].def_idx, j);
        c0->type = c1->type = c2->type = t_skip;
        dict[i].del = 1;

        changed = 1;
      }
    }
  }

  return changed;
}


/*
 * Remove things like
 *
 *   /foo { ... } def
 *
 * if foo is unused.
 */
int optimize_code3(FILE *lf)
{
  unsigned i, j, k;
  int changed = 0;
  code_t *c0, *c1;

  for(i = 0; i < dict_size; i++) {
    if(
      i >= sizeof prim_names / sizeof *prim_names &&
      !dict[i].del &&
      !dict[i].ref &&
      dict[i].def == 1 &&
      dict[i].type == t_none
    ) {
      c0 = code + (j = dict[i].def_idx);
      c1 = code + next_code(j);

      if(c1 == c0) continue;

      if(
        c0->type == t_dict_idx &&
        c0->value.u == i &&
        c1->type == t_code &&
        code[j = skip_code(c1->value.u)].type == t_prim &&
        code[j].value.u == p_def &&
        j > dict[i].def_idx
      ) {
        if(verbose && lf) fprintf(lf, "#   defined but unused: %s (index %d)\n", dict[i].name, i);
        if(verbose && lf) fprintf(lf, "#   deleting code: %d - %d\n", dict[i].def_idx, j);
        for(k = dict[i].def_idx; k <= j; k++) code[k].type = t_skip;
        dict[i].del = 1;

        changed = 1;
      }
    }
  }

  return changed;
}



/*
 * Find unused dictionary entries.
 */
int optimize_code4(FILE *lf)
{
  unsigned i;
  int changed = 0;

  for(i = 0; i < dict_size; i++) {
    if(
      i >= sizeof prim_names / sizeof *prim_names &&
      !dict[i].del &&
      !dict[i].ref &&
      !dict[i].def
    ) {
      if(verbose && lf) fprintf(lf, "#   unused: %s (index %d)\n", dict[i].name, i);

      dict[i].del = 1;

      changed = 1;
    }
  }

  return changed;
}


/*
 * Replace references to constant global vars.
 */
int optimize_code5(FILE *lf)
{
  unsigned i, j, k;
  int changed = 0;
  code_t *c, *c0, *c1, *c2;
  char *s;

  for(i = 0; i < dict_size; i++) {
    if(
      i >= sizeof prim_names / sizeof *prim_names &&
      !dict[i].del &&
      dict[i].def == 1 &&
      dict[i].def_ind == 0 &&
      (
        !dict[i].ref0 ||
        dict[i].ref0_idx >  dict[i].def_idx
      ) &&
      dict[i].type == t_none
    ) {
      c0 = code + (j = dict[i].def_idx);
      c1 = code + (j = next_code(j));
      c2 = code + (j = next_code(j));

      if(
        c0->type == t_dict_idx &&
        c0->value.u == i &&
        (
          c1->type == t_none ||
          c1->type == t_int ||
          c1->type == t_unsigned ||
          c1->type == t_bool
        ) &&
        c2->type == t_prim &&
        c2->value.u == p_def
      ) {
        if(verbose && lf) fprintf(lf, "#   global constant: %s (index %d)\n", dict[i].name, i);
        if(verbose && lf) fprintf(lf, "#   replacing %s with %s\n", dict[i].name, c1->name);
        for(k = 0; k < code_size; k++) {
          c = code + k;
          if(c->type == t_sec && c->value.u == i) {
            c->type = c1->type;
            c->value = c1->value;
            if(c->type == t_int || c->type == t_unsigned) {
              asprintf(&s, "%s # %s", c1->name, c->name);
              free(c->name);
              c->name = s;
            }
            else if(c->type == t_bool) {
              asprintf(&s, "%s # %s", c->value.u ? "true" : "false", c->name);
              free(c->name);
              c->name = s;
            }
            else if(c->type == t_none) {
              asprintf(&s, ".undef # %s", c->name);
              free(c->name);
              c->name = s;
            }
          }
        }

        dict[i].del = 1;

        if(verbose && lf) fprintf(lf, "#   deleting code: %d - %d\n", dict[i].def_idx, j);
        c0->type = c1->type = c2->type = t_skip;

        changed = 1;
      }
    }
  }

  return changed;
}


/*
 * Find .undef.
 */
int optimize_code6(FILE *lf)
{
  unsigned i, j;
  int changed = 0;
  code_t *c0, *c1, *c2;
  char *s;

  for(i = 0; i < code_size; i++) {
    c0 = code + i;
    c1 = code + (j = next_code(i));
    c2 = code + (j = next_code(j));
    if(
      c0->type == t_int && c0->value.u == 0 &&
      c1->type == t_int && c1->value.u == 0 &&
      c2->type == t_prim &&
      c2->value.u == p_settype
    ) {
      c0->type = t_none;
      c0->value.u = 0;
      asprintf(&s, ".undef # %s", c0->name);
      free(c0->name);
      c0->name = s;

      if(verbose && lf) fprintf(lf, "#   constant expression: .undef (at %d)\n", i);
      if(verbose && lf) fprintf(lf, "#   deleting code: %d - %d\n", i + 1, j);
      c1->type = c2->type = t_skip;

      changed = 1;
    }
  }

  return changed;
}


/*
 * Find constant boolean expr.
 */
int optimize_code7(FILE *lf)
{
  unsigned i, j;
  int changed = 0;
  code_t *c0, *c1, *c2;
  char *s;

  for(i = 0; i < code_size; i++) {
    c0 = code + i;
    c1 = code + (j = next_code(i));
    c2 = code + (j = next_code(j));
    if(
      c0->type == t_int && c0->value.u == 0 &&
      c1->type == t_int && c1->value.u == 0 &&
      c2->type == t_prim &&
      (c2->value.u == p_eq || c2->value.u == p_ne)
    ) {
      c0->type = t_bool;
      c0->value.u = c0->value.u == c1->value.u ? 1 : 0;
      if(c2->value.u == p_ne) c0->value.u ^= 1;
      asprintf(&s, "%s # %s", c0->value.u ? "true" : "false", c0->name);
      free(c0->name);
      c0->name = s;

      if(verbose && lf) fprintf(lf, "#   constant expression: %d:%d (at %d)\n", c0->type, c0->value.u, i);
      if(verbose && lf) fprintf(lf, "#   deleting code: %d - %d\n", i + 1, j);
      c1->type = c2->type = t_skip;

      changed = 1;
    }
  }

  return changed;
}


void log_dict(FILE *lf)
{
  int i, j;

  if(!lf) return;

  fputc('\n', lf);
  log_cline(lf);
  fprintf(lf, "# dictionary: %d entries\n", dict_size);
  log_cline(lf);
  for(i = 0; i < dict_size; i++) {
    fprintf(lf, "%5d%*s", i, 12 + (verbose ? 7 : 0), "");
    fprintf(lf, "%-6s ", type_name[dict[i].type & 15]);
    if(dict[i].type == t_string) {
      j = fprintf(lf, "\"%s\"", dict[i].value.p);
    }
    else {
      j = fprintf(lf, "0x%x", dict[i].value.u);
    }
    if(j > 24) j = 24;
    fprintf(lf, "%*s", 25 - j, "");
    fprintf(lf, "%s\n", dict[i].name ? dict[i].name : "\"\"");
  }
}


void log_code(FILE *lf)
{
  int i, j, l, line = 0, incl_level = 0;
  int ind = 0;
  char *s;

  if(!lf) return;

  for(i = j = 0; i < code_size; i++) {
    if(code[i].type == t_skip) j++;
  }

  fputc('\n', lf);
  log_cline(lf);
  fprintf(lf, "# code: %d entries (%d - %d)\n", code_size - j, code_size, j);
  log_cline(lf);
  for(i = 0; i < code_size; i++) {
    if(code[i].type == t_skip && !verbose) continue;
    if((line != code[i].line || incl_level != code[i].incl_level) && code[i].line) {
      line = code[i].line;
      incl_level = code[i].incl_level;
      fprintf(lf, "%5d", line);
      if(incl_level) {
        fprintf(lf, " %d  ", incl_level);
      }
      else {
         fprintf(lf, "    ");
      }
    }
    else {
      fprintf(lf, "%9s", "");
    }
    if(verbose) fprintf(lf, "%5d  ", i);
    if(code[i].size) {
      fprintf(lf, "0x%04x  ", code[i].ofs);
    }
    else {
      fprintf(lf, "%*s", 8, "");
    }
    fprintf(lf, "%-6s", type_name[code[i].type & 15]);
    l = code[i].enc ? code[i].size : 0;
    if(l > 8) l = 8;
    for(j = 0; j < l; j++) {
      fprintf(lf, " %02x", code[i].enc[j]);
    }
    if(
      (
        code[i].type == t_ret ||
        (code[i].type == t_sec && !strcmp(code[i].name, "]"))
      ) &&
      ind > 0
    ) ind -= 2;
    fprintf(lf, "%*s", 3 * (8 - l) + 2 + ind, "");
    if(code[i].type == t_skip) fprintf(lf, "# ");
    if(
      code[i].type == t_code ||
      (code[i].type == t_sec && !strcmp(code[i].name, "["))
    ) ind += 2;
    if(code[i].type == t_string) {
      fprintf(lf, "\"");
      s = code[i].value.p;
      while(*s) {
        if(*s >= 0 && *s < 0x20) {
          if(*s == '\n') {
            fprintf(lf, "\\n");
          }
          else if(*s == '\t') {
            fprintf(lf, "\\t");
          }
          else {
            fprintf(lf, "\\x%02x", (unsigned char) *s);
          }
        }
        else {
          fprintf(lf, "%c", *s);
        }
        s++;
      }
      fprintf(lf, "\"");
    }
    else {
      fprintf(lf,
        "%s%s",
        code[i].type == t_dict_idx ? "/" : "",
        code[i].name ? code[i].name : ""
      );
    }

    // while we're here, just do a consistency check
    if(
      code[i].type == t_sec &&
      (
        !code[i].name ||
        strcmp(code[i].name, dict[code[i].value.u].name)
      )
    ) {
      fprintf(stderr, "Internal oops %d: broken dictionary\n", __LINE__);
      exit(19);
    }

    if(code[i].enc && code[i].size > 8) {
      for(j = 8; j < code[i].size; j++) {
        if(j & 7) {
          fprintf(lf, " ");
        }
        else {
          fprintf(lf, "\n%*s", 24 + (verbose ? 7 : 0), "");
        }
        fprintf(lf, "%02x", code[i].enc[j]);
      }
    }
    fprintf(lf, "\n");
  }
}


void log_cline(FILE *lf)
{
  int i = 78;

  fputc('#', lf);
  while(i--) fputc('-', lf);
  fputc('\n', lf);
}


char *add_to_line(char *s)
{
  static char buf[10240] = {};
  static int ind = 0;
  static int first = 1;

  if(!s) {
    if(first) return "";
    return buf;
  }

  if(strlen(buf) + strlen(s) >= sizeof buf - 1) {
    fprintf(stderr, "Oops, buffer overflow %d\n", __LINE__);
    exit(5);
  }

  if(!strcmp(s, "{")) ind += 2;
  if(!strcmp(s, "}")) ind -= 2;
  if(ind < 0) ind = 0;

  if(!*s) {
    sprintf(buf, "%*s", ind, "");
    first = 1;
    return buf;
  }

  if(first) {
    if(!strcmp(s, "}")) {
      sprintf(buf, "%*s", ind, "");
    }
  }
  else {
    strcat(buf, " ");
  }

  strcat(buf, s);

  first = 0;

  return buf;
}

void decompile(unsigned char *data, unsigned size)
{
  int i, j, idx = 0;
  unsigned u, val, uc;
  unsigned inst_size;
  dict_t *d;
  unsigned type;
  char *s, buf[1024];
  unsigned char *p;

  // setup initial vocabulary
  for(i = 0; i < sizeof prim_names / sizeof *prim_names; i++) {
    d = new_dict();
    d->type = prim_names[i].type;
    d->value.u = prim_names[i].value;
    d->name = prim_names[i].name;
  }

  for(i = 0; i < size; i += inst_size, idx++) {
    u = (data[i] >> 4) & 7;
    val = 0;
    if(u >= 1) val = data[i + 1];
    if(u >= 2) val += data[i + 2] << 8;
    if(u >= 3) val += data[i + 3] << 16;
    if(u >= 4) val += data[i + 4] << 24;
    inst_size = 1 + u;
    if((data[i] >> 4) & 8) {
      inst_size += val;
    }

    if(i + inst_size > size) {
      printf("Oops: bounds exceeded: %u > %u\n", i + inst_size, size);
      return;
    }

    if(verbose >= 1) {
      printf("%% %04x:", i);
      for(j = 0; j < inst_size; j++) {
        printf(" %02x", data[i + j]);
      }
      printf("\n");
    }

    switch((type = data[i] & 0x0f)) {
      case t_code:
        s = add_to_line("{");
        printf("%s\n", s);
        add_to_line("");
        break;

      case t_ret:
        s = add_to_line(NULL);
        if(*s) printf("%s\n", s);
        add_to_line("");
        add_to_line("}");
        break;
        
      case t_end:
        uc = *add_to_line(NULL);
        s = add_to_line("end");
        if(uc) {
          printf("%s\n", s);
        }
        else {
          printf("%s\n\n", s);
        }
        add_to_line("");
        break;

      case t_int:
        // expand sign bit
        switch(u) {
          case 1:
            if(val & 0x80) val |= ~0xff;
            break;
          case 2:
            if(val & 0x8000) val |= ~0xffff;
            break;
          case 3:
            if(val & 0x800000) val |= ~0xffffff;
            break;
        }

      case t_unsigned:
        sprintf(buf, "%d", val);
        add_to_line(buf);
        break;

      case t_string:
        buf[0] = '"';
        for(j = 1, p = data + i + u + 1; *p && j < sizeof buf - 10; p++) {
          if(*p == '\n') {
            buf[j++] = '\\';
            buf[j++] = 'n';
          }
          else if(*p < 0x20 || *p >= 0x7f) {
            buf[j++] = '\\';
            buf[j++] = 'x';
            uc = *p >> 4;
            uc += uc > 9 ? 'a' - 10 : '0';
            buf[j++] = uc;
            uc = *p & 0xf;
            uc += uc > 9 ? 'a' - 10 : '0';
            buf[j++] = uc;
          }
          else {
            buf[j++] = *p;
          }
        }
        buf[j++] = '"';
        buf[j] = 0;
        s = add_to_line(buf);
        break;

      case t_sec:
        if(val < dict_size && dict[val].name) {
          sprintf(buf, "%s", dict[val].name);
        }
        else {
          sprintf(buf, "name_%d", val);
        }
        s = add_to_line(buf);
        printf("%s\n", s);
        add_to_line("");
        break;

      case t_dict_idx:
        if(val < dict_size && dict[val].name) {
          sprintf(buf, "/%s", dict[val].name);
        }
        else {
          sprintf(buf, "/name_%d", val);
        }
        add_to_line(buf);
        break;

      default:
        fprintf(stderr, "Oops %d: type %d not allowed\n", __LINE__, type);
        exit(8);
    }
  }
}


