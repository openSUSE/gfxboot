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

  boot.show {
    boot.text.options setcolor
    window.current .font get setfont
    boot.ed.list {
      dup .inp_x get 10 sub over .inp_y get moveto
      currentpoint
      currentpoint 0 exch moveto
      currentpoint rot fontheight image
      moveto
      .inp_label get exec showright
    } forall
  } if

  redrawmenu
  /keepbootoptions 1 def
  menu.entry true MenuSelect
  /keepbootoptions .undef def

  panel.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Setup boot option input field.
%
% ( ) == > ( )
%
/boot.setup {
  boot.show not { return } if

  boot.window .ed.list boot.ed.list put
  boot.window .ed.focus 0 put

  boot.ed.list {
    dup .inp_x get 10 sub over .inp_y get moveto
    dup .inp_label get exec showright

    white setcolor
    dup .inp_x get over .inp_y get boot.ed.height add moveto

    currenttransparency

    0xe0 settransparency
    boot.ed.width 1 fillrect

    settransparency

    pop

  } forall

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Activate boot option input field.
%
% ( ) == > ( )
%
/bootoptions.init {
  window.current .color.fg get setcolor
  window.current .ed.font get setfont

  boot.ed.list boot.window .ed.focus get get edit.hidecursor

  boot.window .ed.focus 0 put

  boot.ed.list { .inp_buf get 0 0 put } forall

  menu.args menu.entry get
  boot.ed.list 0 get .inp_buf get exch strcpy pop

  boot.ed.list { splitcmdline } forall

  boot.show {
    boot.ed.list {
      dup
      dup dup .inp_buf get exch over edit.init
      "" ne { ' ' edit.input } { pop } ifelse
      edit.hidecursor
    } forall
    boot.ed.list boot.window .ed.focus get get edit.showcursor
  } if
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

  boot.text.options setcolor

  window.current .font get setfont

  /boot.ed.width screen.size pop boot.pos pop sub ptheme { 60 } { 20 } ifelse sub def
  /boot.ed.height fontheight 2 add def

  /boot.window window.current def

  /boot.ed.list [
    0 1 0 {
      [
        boot.pos exch 10 add exch 1 sub 4 -1 roll boot.ed.height 5 add mul add
        over over moveto boot.ed.width boot.ed.height savescreen
        cmdlinelength string
        cmdlinelength
        0
        0
        0
        cmdlinelength string
        /txt_boot_harddisk
      ]
    } for
  ] def

  boot.ed.list 0 get .inp_label /txt_bootoptions put

  /boot.ed boot.ed.list 0 get def

  boot.setup

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


