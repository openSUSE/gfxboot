% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Panel handling.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/panel.text.y	461 def
/panel.font	font.normal def
/panel.normal	black def
/panel.high	fn_color def
/panel.bg	lightgray def
/panel.border	white def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Init panel.
%
% ( ) ==> ( )
%
/panel.init {

  % define panel layout
  /panel [

    % [ key x label show_func width_func update_func init_func ]

    [ keyF1 0 "F1" /panel.help /panel.help.width /panel.help.update .undef ]

    syslinux {

      [ keyF2 0 "F2" /panel.video /panel.video.width /panel.video.update /video.init ]

      livecd {

        [ keyF3 0 "F3" /panel.lang /panel.lang.width /panel.lang.update /lang.init ]
        [ keyF4 0 "F4" /panel.splash /panel.splash.width /panel.splash.update /splash.init ]

      } {

        [ keyF3 0 "F3" /panel.install /panel.install.width /panel.install.update /install.init ]
        [ keyF4 0 "F4" /panel.lang /panel.lang.width /panel.lang.update /lang.init ]
        [ keyF5 0 "F5" /panel.splash /panel.splash.width /panel.splash.update /splash.init ]
        [ keyF6 0 "F6" /panel.dud /panel.dud.width /panel.dud.update .undef ]

      } ifelse

    } {

      [ keyF2 0 "F2" /panel.lang /panel.lang.width /panel.lang.update /lang.init ]
      [ keyF3 0 "F3" /panel.splash /panel.splash.width /panel.splash.update /splash.init ]
      "profiles" findfile dup {
        /profile.data exch def
        [ keyF4 0 "F4" /panel.profile /panel.profile.width /panel.profile.update /profile.init ]
      } { pop } ifelse

    } ifelse

  ] def

  % initialize all
  panel { 6 get dup .undef ne { exec } { pop } ifelse } forall

  panel.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show panel.
%
% ( ) ==> ( )
%
/panel.show {
  panel.font setfont

  panel.bg setcolor
  0 panel.text.y 5 sub moveto currentpoint
  clip.size panel.text.y 5 sub sub fillrect
  moveto
  panel.border setcolor
  currentpoint exch pop clip.size pop 1 sub exch
  lineto

  % don't change xmenu
  /xmenu xmenu

  /panel.x 0 def
  panel { dup {
    dup 1 panel.x put
    dup 4 get exec over 2 get strsize pop add 20 add panel.x add /panel.x exch def
    dup 5 get exec
  } { pop } ifelse } forall

  def

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Handle keyboard input.
%
% ( key_in ) ==> ( key_out )
%
/panel.input {
  panel { dup {
    dup 0 get 2 index eq { 3 get exec pop 0 exit } { pop } ifelse
  } { pop } ifelse } forall
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw panel entry label and move to text field.
%
% ( panel ) => ( )
%
/panel.text.moveto {
  /panel.tmp.x over 1 get 10 add def
  /panel.tmp.F exch 2 get def
  
  panel.tmp.x panel.text.y moveto
  panel.high setcolor panel.tmp.F show
  panel.normal setcolor

  6 0 rmoveto
} def


