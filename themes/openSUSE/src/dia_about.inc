% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Panel 'about' entry.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show help window.
%
% ( ) => ( )
%
/panel.about {
  panel 0
  "help" panel.entry dup { [ keyF1 0 "F1" 5 -1 roll { } forall ] } if
  put
  about.popup
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of 'about' entry.
%
% ( ) => ( width )
%
/panel.about.width {
  "About" strsize pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.about.update {
  panel.text.moveto
  "About" show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show 'about' box.
%
% ( ) ==> ( )
%
/about.popup {
  window.dialog

  dup .title "About" put
  dup .text about.msg put
  dup .buttons [
    button.ok button.default actRedraw button.setaction
  ] put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return 'about' text, if any.
%
% (  -- obj1 )
%
% obj1: string with message or .undef
%
/about.msg {

  /about.msg
    ptheme { "pabout.txt" } { "about.txt" } ifelse findfile dup .undef ne {
      dup length string dup cvp rot dup length memcpy
    } if
  def

  about.msg

} def

