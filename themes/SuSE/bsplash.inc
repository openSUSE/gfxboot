% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Boot loader splash code.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.

% Boot loader splash areas to uncover.
%
/bsplash.areas [
  [ 327 230 144 108  true ]
  [  82  68 131  35 false ]
  [ 205 157 125  32 false ]
  [ 431  77 173  37 false ]
  [ 661 125  61 112 false ]
  [  62 358 162  51 false ]
  [ 204 461  95  36 false ]
  [ 388 397 127  34 false ]
  [ 560 450 169  39 false ]
] def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show boot loader splash.
%
% ( ) ==> ( )
%
/bsplash.show {
  currentimage

  "splash.jpg" findfile /splash.file over def setimage loadpalette
  /max_image_colors max_image_colors image.colors max def

%  0 0 moveto currentpoint 1 1 image getpixel setcolor screen.size fillrect

%  7 0xffffff setpalette
  0 0 moveto 0 0 image.size image

  "greeting.jpg" findfile /splash.file2 over def setimage

  % center image
  image.size screen.size exch 4 -1 roll sub 2 div 3 1 roll exch sub 2 div
  /bsplash.y exch def
  /bsplash.x exch def

  bsplash.areas 0 get
  dup 0 get over 1 get moveto currentpoint bsplash.x bsplash.y rmoveto
  2 index 2 get 3 index 3 get 5 -1 roll pop blendit
  700000 usleep

  {
    bsplash.areas rand over length mod get
    dup 4 get {
      pop
    } {
      dup 0 get over 1 get moveto currentpoint bsplash.x bsplash.y rmoveto
      2 index 2 get 3 index 3 get 5 -1 roll 4 true put blendit
      70000 usleep
    } ifelse

    true
    0 1 bsplash.areas length 1 sub {
      bsplash.areas exch get 4 get and
    } for
    { exit } if
  } loop

  setimage

  splash.file2 free /splash.file2 .undef def
  splash.file free /splash.file .undef def
} def


/blendit {
  /b.w exch def
  /b.h exch def

  moveto

  /b.back b.h b.w savescreen def
  /b.mask currentpoint b.h 1 add b.w 1 add unpackimage def

  currentpoint

  0 0 moveto
  0x303030 b.mask b.back blend

  1 1 moveto
  white b.mask b.back blend

  moveto
  b.back restorescreen

  b.mask free
  b.back free
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Just wait.
%
% ( ) ==> ( )
%
/bsplash.done {
  3000000 usleep
} def


