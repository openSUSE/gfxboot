% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% button handling
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Button templates.
%
% [ x y width height label selected hotkey action ]
%
/button.ok       { [ 0 0 85 25 txt_ok       false 0      0 ] } def
/button.cancel   { [ 0 0 85 25 txt_cancel   false keyEsc 0 ] } def
/button.reboot   { [ 0 0 85 25 txt_reboot   false 0      0 ] } def
/button.continue { [ 0 0 85 25 txt_continue false 0      0 ] } def
/button.eject    { [ 0 0 85 25 "Eject"      false 0      0 ] } def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Set default button.
%
% ( button ) => ( button )
%
/button.default {
  dup 5 true put
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Make it _not_ the default button.
%
% ( button ) => ( button )
%
/button.notdefault {
  dup 5 false put
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Set button position.
%
% ( button x y ) ==> ( button )
%
/button.moveto {
  rot dup 0 5 -1 roll put exch over 1 rot put
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Assign action to button.
%
% ( button action ) => ( button )
%
/button.setaction {
  over 7 rot put
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw button.
%
% ( button ) ==> ( )
%
/button.show {
  /bt.x over 0 get def
  /bt.y over 1 get def
  /bt.width over 2 get def
  /bt.height over 3 get def
  /bt.text over 4 get def
  /bt.default exch 5 get def

  bt.text strsize
  bt.height sub neg 2 div /bt.y.textofs exch def
  bt.width sub neg 2 div /bt.x.textofs exch def

  bt.x bt.y moveto
  currentpoint currentpoint currentpoint

  currentpoint bt.width bt.height window.current .color.bg get setcolor fillrect moveto

  bt.default {
    black black
  } {
    window.current .color.bg get dup
  } ifelse
  bt.width bt.height drawborder
  moveto 1 1 rmoveto white black bt.width 2 sub bt.height 2 sub drawborder
  moveto
  % 2 2 rmoveto white black bt.width 4 sub bt.height 4 sub drawborder

  window.current .color.fg get setcolor
  moveto bt.x.textofs bt.y.textofs rmoveto bt.text show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Press button.
%
% ( button ) ==> ( )
%
/button.press {
  /bt.x over 0 get def
  /bt.y over 1 get def
  /bt.width over 2 get def
  /bt.height exch 3 get def

  bt.x 3 add bt.y 3 add moveto
  bt.width 7 sub bt.height 7 sub savescreen
  1 1 rmoveto dup restorescreen free

  bt.x 1 add bt.y 1 add moveto black white bt.width 2 sub bt.height 2 sub drawborder
  % bt.x 2 add bt.y 2 add moveto black white bt.width 4 sub bt.height 4 sub drawborder
} def


