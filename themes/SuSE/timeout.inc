%
% include before common.inc
%

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( timeout time ) ==> ( )
/Timeout {
  % first time
  timeout.time .undef eq { timeout.init } if

  dup /timeout.time exch def

  over sub neg timeout.symbols mul exch div

  dup timeout.current eq { pop return } if

  /timeout.last timeout.current def
  /timeout.current exch def

  timeout.current timeout.symbols ge {

    timeout.time.x timeout.time.y moveto -30 0 rmoveto
    currentpoint 30 fontheight image

    0 1 timeout.symbols 1 sub {
      timeout.clear { 2 } { 1 } ifelse drawtsymbol
    } for

    % free memory
    timeout.areas {
      /to.tmp exch def

      to.tmp .to_mask over over get free
      to.tmp .to_mask .undef put

      to.tmp .to_back over over get free
      to.tmp .to_back .undef put

    } forall
  } {

    black setcolor

    timeout.time.x timeout.time.y moveto -30 0 rmoveto
    currentpoint 30 fontheight image

    timeout.time 10 mul 150 add 182 div "%ds" timeout.buf sprintf

    timeout.time.x timeout.time.y moveto timeout.buf showright

    timeout.last 1 timeout.current {
      1 sub dup 0 ge {
        1 drawtsymbol
      } if
    } for
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% draw a timeout symbol
% ( index status ) ==> ()
%
% status: 0: init, 1: clear, 2: set
%
/drawtsymbol {
  /timeout.status exch def

  timeout.status 1 eq timeout.status 2 eq or {
    timeout.areas exch get /to.tmp exch def

    timeout.x to.tmp .to_x get add
    timeout.y to.tmp .to_y get add
    moveto

    to.tmp .to_back get
    restorescreen
  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Initialize timeout indicator.
%
% ( ) ==> ( )
%
/timeout.init {
  /timeout.current    -1 def
  /timeout.symbols timeout.areas length def
  /timeout.clear    true def
  /timeout.buf        64 string def

  /timeout.time.x 195 def
  /timeout.time.y 295 def

  timeout.areas {
    /to.tmp exch def

    timeout.x to.tmp .to_x get add
    timeout.y to.tmp .to_y get add
    moveto

    currentpoint

    /to.dot
      to.tmp .to_w get
      to.tmp .to_h get
      savescreen
    def

    to.tmp .to_back
      to.dot length dup malloc exch over exch to.dot exch memcpy
    put

    0x004f40 setcolor
    0 0 moveto
    to.tmp .to_mask get
    to.dot

    blend2

    moveto

    to.dot
    restorescreen

    to.dot free
  } forall

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Even before init.
%
% ( ) ==> ( )
%
/timeout.preinit {
  "dots.jpg" findfile setimage
  timeout.areas {
    /to.tmp exch def
    to.tmp .to_mask

    to.tmp .to_x get
    to.tmp .to_y get
    to.tmp .to_w get
    to.tmp .to_h get
    unpackimage

    put
  } forall

} def


/timeout.x 150 def
/timeout.y 216 def

% timeout.areas entries
/.to_x 0 def
/.to_y 1 def
/.to_w 2 def
/.to_h 3 def
/.to_back 4 def
/.to_mask 5 def


/timeout.areas [
  [ 33  0 4 4 .undef .undef ]
  [ 38  0 4 4 .undef .undef ]
  [ 43  2 4 4 .undef .undef ]
  [ 47  4 4 4 .undef .undef ]
  [ 51  8 4 4 .undef .undef ]
  [ 55 11 4 4 .undef .undef ]
  [ 57 15 4 4 .undef .undef ]
  [ 60 20 4 4 .undef .undef ]
  [ 60 25 4 4 .undef .undef ]
  [ 60 30 4 4 .undef .undef ]
  [ 60 36 4 4 .undef .undef ]
  [ 60 41 4 4 .undef .undef ]
  [ 58 45 4 4 .undef .undef ]
  [ 55 49 4 4 .undef .undef ]
  [ 51 53 4 4 .undef .undef ]
  [ 47 56 4 4 .undef .undef ]
  [ 43 59 4 4 .undef .undef ]
  [ 38 60 4 4 .undef .undef ]
  [ 33 60 4 4 .undef .undef ]
  [ 28 60 4 4 .undef .undef ]
  [ 23 60 4 4 .undef .undef ]
  [ 18 59 4 4 .undef .undef ]
  [ 13 56 4 4 .undef .undef ]
  [  9 53 4 4 .undef .undef ]
  [  6 49 4 4 .undef .undef ]
  [  3 45 4 4 .undef .undef ]
  [  1 41 4 4 .undef .undef ]
  [  0 36 4 4 .undef .undef ]
  [  0 30 4 4 .undef .undef ]
  [  0 25 4 4 .undef .undef ]
  [  1 20 4 4 .undef .undef ]
  [  3 16 4 4 .undef .undef ]
  [  6 11 4 4 .undef .undef ]
  [  9  8 4 4 .undef .undef ]
  [ 13  4 4 4 .undef .undef ]
  [ 18  2 4 4 .undef .undef ]
  [ 23  0 4 4 .undef .undef ]
  [ 28  0 4 4 .undef .undef ]
] def


