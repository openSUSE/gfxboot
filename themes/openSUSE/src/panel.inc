% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Panel handling.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/panel.size     { clip.size pop 48 } def
/panel.y        { clip.size exch pop panel.size exch pop sub 5 sub } def
/panel.text.y	{ panel.y 5 add } def
/panel.text.Fy	0 def
/panel.font	font.normal def

/panel.expert   false def

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Init panel.
%
% ( ) ==> ( )
%
/panel.init {

  /panel.back 0 panel.y moveto panel.size savescreen def

  /panel.entry.help [ keyF1 0 "F1" /panel.help /panel.help.width /panel.help.update .undef ] def
  /panel.entry.about [ keyF1 0 "F1" /panel.about /panel.about.width /panel.about.update .undef ] def

  % define panel layout
  /panel.full [

    % [ key x label show_func width_func update_func init_func ]

    about.msg {
      panel.entry.about
    } {
      panel.entry.help
    } ifelse

    syslinux {

      config.livecd {

        [ keyF2 0 "F2" /panel.lang /panel.lang.width /panel.lang.update /lang.init ]
        [ keyF3 0 "F3" /panel.video /panel.video.width /panel.video.update /video.init ]

      } {

        [ keyF2 0 "F2" /panel.lang /panel.lang.width /panel.lang.update /lang.init ]
        [ keyF3 0 "F3" /panel.video /panel.video.width /panel.video.update /video.init ]
        [ keyF4 0 "F4" /panel.install /panel.install.width /panel.install.update /install.init ]
        [ keyF5 0 "F5" /panel.kernelopts /panel.kernelopts.width /panel.kernelopts.update /kernelopts.init ]
        [ keyF6 0 "F6" /panel.dud /panel.dud.width /panel.dud.update /dud.init ]

        32+64bit_source {
          64bit {
            32bit_boot_dir .undef ne
            64bit_boot_dir .undef ne
            32bit_boot_dir 64bit_boot_dir ne
            and and {
              [ keyF7 0 "F7" /panel.bits /panel.bits.width /panel.bits.update /bits.init ]
            } if
          } if
        } if

        keymap.mainmenu {
          [ keyF8 0 "F8" /panel.keymap /panel.keymap.width /panel.keymap.update /keymap.init ]
        } if

      } ifelse

      xmenu.bits .undef eq { bits.init } if

    } {

      [ keyF2 0 "F2" /panel.lang /panel.lang.width /panel.lang.update /lang.init ]
      "profiles" findfile dup {
        /profile.data exch def
        [ keyF3 0 "F3" /panel.profile /panel.profile.width /panel.profile.update /profile.init ]
      } { pop } ifelse

      keymap.mainmenu {
        [ keyF4 0 "F4" /panel.keymap /panel.keymap.width /panel.keymap.update /keymap.init ]
      } if

    } ifelse

  ] def

  % initialize all
  panel.full { 6 get dup .undef ne { exec } { pop } ifelse } forall

  /panel panel.full def

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

%  panel.border.color setcolor
%  0 -1 rmoveto
%  0 1 clip.size pop 3 div { pop putpixel 3 0 rmoveto } for

  % don't change xmenu
  /xmenu xmenu

  /panel.x config.rtl { clip.size pop } { 0 } ifelse def
  panel { dup {
    dup 1 panel.x put
    dup 4 get exec over 2 get strsize pop add 20 add panel.x exch
    config.rtl { sub } { add } ifelse
    /panel.x exch def
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
  /panel.tmp.x over 1 get 10 config.rtl { sub } { add } ifelse def
  /panel.tmp.F exch 2 get def
  
  panel.tmp.x panel.text.y panel.text.Fy add moveto
  panel.f-key.fg setcolor panel.tmp.F show.rtl
  panel.normal.fg setcolor

  6 config.rtl { neg } if panel.text.Fy neg rmoveto
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
  config.livecd { return } if

  % not for F1
  dup keyF1 eq { return } if

  panel.extra.fkey .undef eq
  menu.entry 0 eq
  menu.entry menu.texts length 1 sub lt
  and and {
    /panel.extra.fkey 1 def
    menu.entry false MenuSelect
    menu.visible.entries menu.entry menu.shift sub sub 1 eq {
      /menu.shift menu.shift 1 add def main.drawmenu
    } if
    /menu.entry menu.entry 1 add def
    menu.entry true MenuSelect
  } if
} def


