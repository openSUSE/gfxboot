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
  } {

    white setcolor

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
    timeout.areas exch get { } forall
    timeout.clean.x timeout.clean.y
    4 -2 roll 6 -2 roll moveto image
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

  /timeout.time.x  85 def
  /timeout.time.y 330 def
} def


/timeout.clean.x 30 def
/timeout.clean.y 230 def

/timeout.areas [
  [  77 230 4 4 ]
  [  83 231 4 4 ]
  [  89 233 4 4 ]
  [  95 236 4 4 ]
  [ 100 240 4 4 ]
  [ 104 245 4 4 ]
  [ 108 250 4 4 ]
  [ 110 256 4 4 ]
  [ 112 262 4 4 ]
  [ 112 268 4 4 ]
  [ 112 275 4 4 ]
  [ 110 281 4 4 ]
  [ 108 287 4 4 ]
  [ 104 292 4 4 ]
  [ 100 297 4 4 ]
  [  95 301 4 4 ]
  [  89 304 4 4 ]
  [  83 306 4 4 ]
  [  77 306 4 4 ]
  [  71 306 4 4 ]
  [  64 305 4 4 ]
  [  58 303 4 4 ]
  [  53 300 4 4 ]
  [  48 296 4 4 ]
  [  44 292 4 4 ]
  [  40 287 4 4 ]
  [  38 281 4 4 ]
  [  36 275 4 4 ]
  [  36 269 4 4 ]
  [  36 262 4 4 ]
  [  38 256 4 4 ]
  [  40 250 4 4 ]
  [  44 245 4 4 ]
  [  48 240 4 4 ]
  [  53 236 4 4 ]
  [  59 233 4 4 ]
  [  65 231 4 4 ]
  [  71 230 4 4 ]
] def


