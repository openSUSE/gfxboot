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

  ptheme { over over p.timeout.animate } if

  % no counter
  timeout.steps .undef eq { return } if

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
  "timer_a.jpg" findfile /timeout.file over def dup .undef ne {
    currentimage exch setimage
    0 0 image.size unpackimage /timeout.image exch def
    setimage

    /timeout.steps timeout.image imgsize div def

    /timeout.width timeout.image imgsize exch pop def

    /timeout.x menu.start.x menu.bar.width add 24 sub def
    /timeout.y menu.start.y 2 sub menu.entry menu.item.height mul add def

    timeout.x timeout.y moveto
    /timeout.bg timeout.width dup savescreen def
    % just a few buffers
    /timeout.img_buf timeout.width dup savescreen def
    /timeout.alpha_buf timeout.width dup savescreen def

    /timeout.current 0 def

    timeout.current timeout.update
  } { pop } ifelse

  /timeout.s.buf 64 string def
  /timeout.s.x 100 def
  /timeout.s.y 250 def
  /timeout.s.current -1 def

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
  timeout.width mul 0 moveto
  timeout.image 255 timeout.alpha_buf blend

  timeout.img_buf timeout.bg dup length memcpy

  0 0 moveto
  black timeout.alpha_buf timeout.img_buf blend

  timeout.x timeout.y moveto
  timeout.img_buf restorescreen
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Clear timeout indicator.
%
% ( ) ==> ( )
%
/timeout.done {
  timeout.x timeout.y moveto
  timeout.bg restorescreen

  /timeout.bg timeout.bg free .undef def
  /timeout.img_buf timeout.img_buf free .undef def
  /timeout.alpha_buf timeout.alpha_buf free .undef def
  /timeout.image timeout.image free .undef def
  /timeout.file timeout.file free .undef def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update seconds counter.
%
% ( time_in_s ) ==> ( )
%
/timeout.s.update {
%  white setcolor
%  timeout.s.x timeout.s.y moveto -30 0 rmoveto
%  currentpoint 30 fontheight image
%  "%ds" timeout.s.buf sprintf
%  timeout.s.x timeout.s.y moveto timeout.s.buf showright
  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Clear seconds counter.
%
% ( ) ==> ( )
%
/timeout.s.done {
%  timeout.s.x timeout.s.y moveto -30 0 rmoveto
%  currentpoint 30 fontheight image
} def


