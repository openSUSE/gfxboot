struct jpeg_decdata {
  int dcts[6 * 64 + 16];
  int out[64 * 6];
  int dquant[3][64];
};

int jpeg_decode(unsigned char *jpg, unsigned char *img, struct jpeg_decdata *jdd, int x_0, int x_1, int y_0, int y_1);
void jpeg_get_size(unsigned char *buf, int *width, int *height);
