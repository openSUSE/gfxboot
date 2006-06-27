% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Panel handling.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/panel.size     { clip.size pop 24 } def
/panel.y        { clip.size exch pop panel.size exch pop sub 10 sub } def
/panel.text.y	{ panel.y 5 add } def
/panel.text.Fy	0 def
/panel.font	font.normal def
/panel.normal	white def
/panel.high	blue def
/panel.bg	lightgray def
/panel.border	lightdotcolor def

/panel.expert   false def

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Init panel.
%
% ( ) ==> ( )
%
/panel.init {

  /panel.back 0 panel.y moveto panel.size savescreen def

  % define panel layout
  /panel.full [

    % [ key x label show_func width_func update_func init_func ]

    [ keyF1 0 "F1" /panel.help /panel.help.width /panel.help.update .undef ]

    syslinux {

      livecd {

        [ keyF2 0 "F2" /panel.video /panel.video.width /panel.video.update /video.init ]
        [ keyF3 0 "F3" /panel.splash /panel.splash.width /panel.splash.update /splash.init ]
        [ keyF4 0 "F4" /panel.lang /panel.lang.width /panel.lang.update /lang.init ]

      } {

        [ keyF2 0 "F2" /panel.lang /panel.lang.width /panel.lang.update /lang.init ]
        [ keyF3 0 "F3" /panel.video /panel.video.width /panel.video.update /video.init ]
        [ keyF4 0 "F4" /panel.install /panel.install.width /panel.install.update /install.init ]
        [ keyF5 0 "F5" /panel.dud /panel.dud.width /panel.dud.update /dud.init ]

        32+64bit_source {
          64bit {
            32bit_boot_dir .undef ne
            64bit_boot_dir .undef ne
            32bit_boot_dir 64bit_boot_dir ne
            and and {
              [ keyF6 0 "F6" /panel.bits /panel.bits.width /panel.bits.update /bits.init ]
            } if
          } if
        } if

      } ifelse

      xmenu.bits .undef eq { bits.init } if

    } {

      [ keyF2 0 "F2" /panel.lang /panel.lang.width /panel.lang.update /lang.init ]
      "profiles" findfile dup {
        /profile.data exch def
        [ keyF3 0 "F3" /panel.profile /panel.profile.width /panel.profile.update /profile.init ]
      } { pop } ifelse

    } ifelse

  ] def

  % initialize all
  panel.full { 6 get dup .undef ne { exec } { pop } ifelse } forall

  syslinux {
    /panel.short [
      [ keyF1 0 "F1" /panel.help /panel.help.width /panel.help.update .undef ]
      [ keyF2 0 "F2" /panel.lang /panel.lang.width /panel.lang.update /lang.init ]
      [ keyF3 0 "F3" /panel.options /panel.options.width /panel.options.update .undef ]
    ] def

    /panel.penguin [
      [ keyF1 0 "F1" /panel.ptheme /panel.ptheme.width /panel.ptheme.update .undef ]
      [ keyF2 0 "F2" /panel.lang /panel.lang.width /panel.lang.update /lang.init ]
      [ keyF3 0 "F3" /panel.options /panel.options.width /panel.options.update .undef ]
    ] def

    /panel ptheme {
      panel.penguin
    } {
      panel.full
      CapsLock { pop panel.full } if
    } ifelse def
  } {
    /panel.short [
      [ keyF1 0 "F1" /panel.help /panel.help.width /panel.help.update .undef ]
      [ keyF2 0 "F2" /panel.options /panel.options.width /panel.options.update .undef ]
    ] def

    /panel panel.full def
  } ifelse

  panel.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show panel.
%
% ( ) ==> ( )
%
/panel.show {
  panel.font setfont

%  panel.bg setcolor
  0 panel.y moveto
%  currentpoint
  panel.back restorescreen
%  currenttransparency
%  50 settransparency
%  panel.size fillrect
%  settransparency
%  moveto

%  panel.border setcolor
%  0 -1 rmoveto
%  0 1 clip.size pop 3 div { pop putpixel 3 0 rmoveto } for

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
  
  panel.tmp.x panel.text.y panel.text.Fy add moveto
  panel.high setcolor panel.tmp.F show
  panel.normal setcolor

  6 panel.text.Fy neg rmoveto
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

  % not for live cd
  livecd { return } if

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


