% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Main menu (boot entry + boot options + panel).
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Create new main window.
%
% ( ) ==> ( window )
%
/window.main {
  widget.size array
  dup .type t_main put
  dup .font font.normal put
  dup .ed.font font.normal put
  dup .color.fg boot.text.normal put
  
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Initialize main window.
%
% ( window ) ==> ( )
%
/main.init {
  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw main window.
% (E.g. after selecting a new language.)
%
% ( window ) ==> ( )
%
/main.redraw {
  boot.text.options setcolor
  window.current .font get setfont
  frame3.pos moveto
  currentpoint 300 fontheight image
  txt_bootoptions show

  redrawmenu
  /keepbootoptions 1 def
  menu.entry true MenuSelect
  /keepbootoptions .undef def

  panel.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw main window.
%
% ( window ) ==> ( )
%
/main.show {
  window.push

  /menu.shift 0 def
  /menu.visible.entries menu.texts length menu.max.entries min def

  % get index of default entry
  /menu.entry 0 def
  0 1 menu.texts length 1 sub {
    dup menu.texts exch get menu.dentry eq { /menu.entry exch def exit } { pop } ifelse
  } for

  menu.entry menu.visible.entries sub 0 ge {
    /menu.shift menu.entry menu.texts length menu.visible.entries sub min def
  } if

  frame2.pos moveto prog_frame_color dup prog_frame_color2 frame2.size drawborder3

  menu.visible.entries menu.texts length lt menu.scrollbar and {
   /menu.bar.width frame1.size pop frame4.size pop sub def

    -1 settransparentcolor

    frame4.pos moveto black dup frame4.size drawborder
    frame4.pos moveto
    ms.up ms.size image
    frame4.pos moveto frame4.size exch pop 0 exch ms.size exch pop 0 add sub rmoveto
    ms.down ms.size image

    /menu.sb.x frame4.pos pop 1 add def
    /menu.sb.y frame4.pos exch pop 22 add def
    /menu.sb.width frame4.size pop 2 sub def
    /menu.sb.height frame4.size exch pop 22 2 mul sub def

    menu.sb.x menu.sb.y 1 sub moveto
    menu.sb.x menu.sb.width add menu.sb.y 1 sub lineto

    menu.sb.x menu.sb.y menu.sb.height add moveto
    menu.sb.x menu.sb.width add menu.sb.y menu.sb.height add lineto
  } if

  boot.text.options setcolor

  window.current .font get setfont

  frame3.pos moveto
  txt_bootoptions show

  /boot.ed.width frame2.size pop 10 sub def
  /boot.ed.height fontheight 2 add def

  /boot.ed [
    frame2.pos exch 5 add exch 4 add
    over over moveto boot.ed.width boot.ed.height savescreen
    boot.buf
    boot.buf.size
    0
    0
    0
  ] def

  window.current .ed boot.ed put

  redrawmenu
  menu.entry true MenuSelect

  % find default splash mode
  0 1 splash.options length 1 sub {
    splash.options over get menu.args menu.entry get exch strstr {
      /splash.default exch def
    } {
      pop
    } ifelse
  } for

  panel.init

  "main" help.setcontext

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Handle keyboard input.
%
% ( key_in ) ==> ( key_out )
%
/main.input {
  dup 0 eq { return } if 

  % handle panel entries
  panel.input

  dup keyF10 eq {
    power_off
    pop 0
  } if

  dup keyEsc eq { exit_popup pop 0 } if

  dup keyEnter eq {
    /window.action actStart def
    pop 0
  } if

  dup keyUp eq {
    menu.entry 0 gt {
      menu.entry false MenuSelect
      menu.entry menu.shift eq {
        /menu.shift menu.shift 1 sub def redrawmenu
      } if
      /menu.entry menu.entry 1 sub def
      menu.entry true MenuSelect
    } if
    pop 0
  } if

  dup keyDown eq {
    menu.entry menu.texts length 1 sub lt {
      menu.entry false MenuSelect
      menu.visible.entries menu.entry menu.shift sub sub 1 eq {
        /menu.shift menu.shift 1 add def redrawmenu
      } if
      /menu.entry menu.entry 1 add def
      menu.entry true MenuSelect
    } if
    pop 0
  } if

  dup keyPgUp eq {
    menu.entry 0 gt {
      menu.entry false MenuSelect
      /menu.entry 0 def
      menu.shift 0 ne {
        /menu.shift 0 def redrawmenu
      } if
      menu.entry true MenuSelect
    } if
    pop 0
  } if

  dup keyPgDown eq {
    menu.entry menu.texts length 1 sub lt {
      menu.entry false MenuSelect
      /menu.entry menu.texts length 1 sub def
      menu.texts length menu.visible.entries sub dup menu.shift ne {
        /menu.shift exch def redrawmenu
      } {
        pop
      } ifelse
      menu.entry true MenuSelect
    } if
    pop 0
  } if

  dup 0 ne {
    "opt" help.setcontext
  } if

} def


