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
  [   0 146 640 166  true ]
  [  54  43 137  42 false ]
  [ 228  89 128  36 false ]
  [ 325  35 186  45 false ]
  [ 544  19  73 116 false ]
  [  19 353 172  62 false ]
  [ 199 406 104  41 false ]
  [ 308 327 134  42 false ]
  [ 427 384 177  42 false ]
] def

% start value
/rand.start time def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Generate pseudo random number.
% Good enough for boot loader splash screen.
%
% ( ) ==> ( int )
%
/rand {
  rand.start 59 mul 97 add 0x7fffffff and
  /rand.start over def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show boot loader splash.
%
% ( ) ==> ( )
%
/bsplash.show {
  currentimage

  "splash.pcx" findfile setimage loadpalette
  /max_image_colors max_image_colors image.colors max def

  0 0 moveto currentpoint 1 1 image getpixel setcolor screen.size fillrect

%  7 0xffffff setpalette
%  0 0 moveto 0 0 image.size image

  % center image
  image.size screen.size exch 4 -1 roll sub 2 div 3 1 roll exch sub 2 div
  /bsplash.y exch def
  /bsplash.x exch def

  bsplash.areas 0 get
  dup 0 get over 1 get moveto currentpoint bsplash.x bsplash.y rmoveto
  2 index 2 get 3 index 3 get 5 -1 roll pop image
  500000 usleep

  {
    bsplash.areas rand over length mod get
    dup 4 get {
      pop
    } {
      dup 0 get over 1 get moveto currentpoint bsplash.x bsplash.y rmoveto
      2 index 2 get 3 index 3 get 5 -1 roll 4 true put image
      50000 usleep
    } ifelse

    true
    0 1 bsplash.areas length 1 sub {
      bsplash.areas exch get 4 get and
    } for
    { exit } if
  } loop

  setimage
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Just wait.
%
% ( ) ==> ( )
%
/bsplash.done {
  3000000 usleep
} def


