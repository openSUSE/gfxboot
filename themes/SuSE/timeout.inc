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

  /timeout.time.x 195 def
  /timeout.time.y 295 def
} def


/timeout.clean.x 30 def
/timeout.clean.y 230 def

/timeout.areas [
  [ 183 219 4 4 ]
  [ 188 219 4 4 ]
  [ 193 220 4 4 ]
  [ 197 223 4 4 ]
  [ 201 226 4 4 ]
  [ 205 230 4 4 ]
  [ 208 234 4 4 ]
  [ 210 239 4 4 ]
  [ 211 244 4 4 ]
  [ 211 250 4 4 ]
  [ 211 255 4 4 ]
  [ 210 260 4 4 ]
  [ 208 264 4 4 ]
  [ 204 268 4 4 ]
  [ 201 272 4 4 ]
  [ 197 275 4 4 ]
  [ 193 278 4 4 ]
  [ 188 280 4 4 ]
  [ 183 280 4 4 ]
  [ 178 280 4 4 ]
  [ 173 279 4 4 ]
  [ 168 278 4 4 ]
  [ 163 275 4 4 ]
  [ 159 272 4 4 ]
  [ 156 268 4 4 ]
  [ 153 264 4 4 ]
  [ 151 259 4 4 ]
  [ 150 255 4 4 ]
  [ 149 249 4 4 ]
  [ 150 244 4 4 ]
  [ 150 239 4 4 ]
  [ 153 234 4 4 ]
  [ 155 230 4 4 ]
  [ 159 226 4 4 ]
  [ 163 223 4 4 ]
  [ 168 221 4 4 ]
  [ 173 219 4 4 ]
  [ 178 219 4 4 ]
] def


