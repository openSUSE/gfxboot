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

  /timeout.time.x 60 def
  /timeout.time.y 215 def
} def


/timeout.clean.x 20 def
/timeout.clean.y 140 def

/timeout.areas [
  [ 53 150 2 2 ]
  [ 57 150 3 3 ]
  [ 61 151 3 4 ]
  [ 64 153 4 4 ]
  [ 68 156 3 3 ]
  [ 71 159 3 3 ]
  [ 73 163 3 3 ]
  [ 75 167 3 3 ]
  [ 76 171 3 3 ]
  [ 76 175 3 3 ]
  [ 76 180 3 3 ]
  [ 75 184 3 3 ]
  [ 73 188 3 3 ]
  [ 70 191 4 3 ]
  [ 68 194 3 4 ]
  [ 64 197 3 3 ]
  [ 61 199 3 3 ]
  [ 57 200 2 3 ]
  [ 52 201 3 3 ]
  [ 48 201 3 3 ]
  [ 44 200 3 3 ]
  [ 40 199 3 3 ]
  [ 36 197 3 3 ]
  [ 33 194 3 3 ]
  [ 30 191 3 3 ]
  [ 27 188 4 3 ]
  [ 26 184 3 3 ]
  [ 25 180 3 2 ]
  [ 24 175 3 3 ]
  [ 25 171 3 3 ]
  [ 26 167 3 3 ]
  [ 27 163 4 3 ]
  [ 30 159 3 3 ]
  [ 33 156 3 3 ]
  [ 36 153 3 4 ]
  [ 40 151 3 4 ]
  [ 44 150 3 3 ]
  [ 48 150 3 2 ]
] def


