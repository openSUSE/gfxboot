% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Panel handling.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/panel.text.y	{ clip.size exch pop 19 sub } def
/panel.font	font.normal def
/panel.normal	black def
/panel.high	fn_color def
/panel.bg	lightgray def
/panel.border	lightdotcolor def


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

        [ keyF3 0 "F3" /panel.splash /panel.splash.width /panel.splash.update /splash.init ]

      } {

        [ keyF3 0 "F3" /panel.install /panel.install.width /panel.install.update /install.init ]
        [ keyF4 0 "F4" /panel.lang /panel.lang.width /panel.lang.update /lang.init ]
%        [ keyF5 0 "F5" /panel.splash /panel.splash.width /panel.splash.update /splash.init ]
        [ keyF5 0 "F5" /panel.dud /panel.dud.width /panel.dud.update .undef ]

        do_64bit_check 32+64bit_source and {
          64bit {
            [ keyF6 0 "F6" /panel.bits /panel.bits.width /panel.bits.update /bits.init ]
          } if
        } if

        xmenu.bits .undef eq { bits.init } if

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
  0 -1 rmoveto
  0 1 clip.size pop 3 div { pop putpixel 3 0 rmoveto } for

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
    dup 0 get 2 index eq { over panel.extra pop 3 get exec pop 0 exit } { pop } ifelse
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


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Do some extra things.
%
% ( key ) => ( key )
%
/panel.extra {
  % move down one menu entry; but only once
  % see keyDown in main::main.input

  % only for install CDs
  syslinux not { return } if

  % not for F1
  dup keyF1 eq { return } if

  panel.extra.fkey .undef eq
  menu.entry 0 eq
  menu.entry menu.texts length 1 sub lt
  and and {
    /panel.extra.fkey 1 def
    menu.entry false MenuSelect
    menu.visible.entries menu.entry menu.shift sub sub 1 eq {
      /menu.shift menu.shift 1 add def redrawmenu
    } if
    /menu.entry menu.entry 1 add def
    menu.entry true MenuSelect
  } if
} def


