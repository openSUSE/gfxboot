%
% include before common.inc
%

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Boot timeout counter.
%
% ( timeout time ) ==> ( )
%
% timeout: total time in 18.2Hz steps, time: current value.
%
% The code below assumes we're showing seconds and some symbolic counter.
%
/Timeout {
  % first time
  timeout.current .undef eq { over timeout.init } if

  /timeout.s.last timeout.s.current def
  /timeout.s.current over 10 mul 150 add 182 div def

  /timeout.last timeout.current def
  over sub neg timeout.steps mul exch div
  /timeout.current exch def

  timeout.current timeout.steps ge {
    % last run
    timeout.s.done
    timeout.done
  } {
    % 0 270 moveto timeout.last print "<" print timeout.current print "<" print

    timeout.s.last timeout.s.current ne { timeout.s.current timeout.s.update } if

    timeout.last timeout.current ne {
      timeout.last 1 add 1 timeout.current { timeout.update } for
    } if

  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Initialize timeout indicator.
%
% ( time ) ==> ( )
%
/timeout.init {
  "timer_a.jpg" findfile dup .undef ne {
    currentimage exch setimage
    0 0 image.size unpackimage /timeout.image exch def
    setimage
  } { pop } ifelse

  /timeout.steps 8 def

  /timeout.buf 64 string def

  /timeout.x 200 def
  /timeout.y 100 def

  /timeout.time.x 100 def
  /timeout.time.y 250 def

  /timeout.s.current -1 def

  /timeout.current 0 def
  timeout.current timeout.update


  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update timeout indicator.
%
% ( index ) ==> ( )
%
% index runs from 0 to timeout.steps - 1. It is guaranteed that index is
% 1 larger than the last index. Never a step twice and no step is left out.
%
/timeout.update {
  % 0 300 moveto print
  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Clear timeout indicator.
%
% ( ) ==> ( )
%
/timeout.done {


} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update seconds counter.
%
% ( time_in_s ) ==> ( )
%
/timeout.s.update {
  white setcolor
  timeout.time.x timeout.time.y moveto -30 0 rmoveto
  currentpoint 30 fontheight image
  "%ds" timeout.buf sprintf
  timeout.time.x timeout.time.y moveto timeout.buf showright
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Clear seconds counter.
%
% ( ) ==> ( )
%
/timeout.s.done {
  timeout.time.x timeout.time.y moveto -30 0 rmoveto
  currentpoint 30 fontheight image
} def


