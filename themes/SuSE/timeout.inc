%
% include before common.inc
%

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( timeout time ) ==> ( )
/Timeout {
  % first time

  ptheme { over over p.timeout.animate } if

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

      to.tmp .to_back over over get free
      to.tmp .to_back .undef put

    } forall
  } {

    ptheme not {
      white setcolor

      timeout.time.x timeout.time.y moveto -30 0 rmoveto
      currentpoint 30 fontheight image

      timeout.time 10 mul 150 add 182 div "%ds" timeout.buf sprintf

      timeout.time.x timeout.time.y moveto timeout.buf showright
    } if

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

  /timeout.time.x timeout.x 60 add def
  /timeout.time.y timeout.y 120 add def

  timeout.areas {
    /to.tmp exch def

    timeout.x to.tmp .to_x get add
    timeout.y to.tmp .to_y get add
    moveto

    to.tmp .to_back
      6 6 savescreen
    put

  } forall

} def


/timeout.x { head.x } def
/timeout.y { head.y } def

% timeout.areas entries
/.to_x 0 def
/.to_y 1 def
/.to_back 2 def


/timeout.areas [
  [  54   0 .undef ]
  [  62   0 .undef ]
  [  70   3 .undef ]
  [  77   7 .undef ]
  [  84  12 .undef ]
  [  89  18 .undef ]
  [  94  25 .undef ]
  [  97  33 .undef ]
  [  99  41 .undef ]
  [ 100  50 .undef ]
  [  99  58 .undef ]
  [  97  66 .undef ]
  [  94  74 .undef ]
  [  89  81 .undef ]
  [  83  87 .undef ]
  [  77  92 .undef ]
  [  69  96 .undef ]
  [  62  99 .undef ]
  [  54 100 .undef ]
  [  45 100 .undef ]
  [  37  99 .undef ]
  [  29  96 .undef ]
  [  21  92 .undef ]
  [  15  87 .undef ]
  [   9  81 .undef ]
  [   4  73 .undef ]
  [   1  66 .undef ]
  [   0  58 .undef ]
  [   0  49 .undef ]
  [   0  41 .undef ]
  [   1  33 .undef ]
  [   4  25 .undef ]
  [   9  18 .undef ]
  [  15  12 .undef ]
  [  21   7 .undef ]
  [  29   2 .undef ]
  [  37   0 .undef ]
  [  45   0 .undef ]
] def


