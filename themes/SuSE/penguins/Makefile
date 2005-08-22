all: high

high:
	pngtopnm -background black pback.png | cjpeg -optimize -quality 95 >pback.jpg
	pngtopnm -background black panim.png | cjpeg -optimize -quality 95 >panim.jpg
	pngtopnm -alpha panim.png | pgmtoppm white | cjpeg -optimize -quality 95 >panim_a.jpg

low:
	pngtopnm -background black pback.png | cjpeg -optimize -quality 85 >pback.jpg
	pngtopnm -background black panim.png | cjpeg -optimize -quality 85 >panim.jpg
	pngtopnm -alpha panim.png | pgmtoppm white | cjpeg -optimize -quality 85 >panim_a.jpg

