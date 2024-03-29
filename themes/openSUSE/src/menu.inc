% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Main menu (boot entry + boot options + panel).
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% max number of boot option input fields
/boot.ed.max 2 def

% boot option input line separator
/boot.splitchar 1 def
/boot.splitstr 1 string dup 0 boot.splitchar put def

/boot.update_options true def

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
% ( redraw_boot_options ) ==> ( )
%
% redraw_boot_options: true|false
% redraw boot option line if true
%
/main.redraw {

  % boot.drawlabels

  main.drawmenu
  /boot.update_options exch def
  menu.entry true MenuSelect
  /boot.update_options true def

  panel.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw boot option input field labels.
%
% ( ) == > ( )
%
/boot.drawlabels {
  boot.show not { return } if

  boot.text.options setcolor
  window.current .font get setfont
  boot.ed.list {
    dup .inp_x get 10 sub over .inp_y get moveto
    currentpoint
    currentpoint 0 exch moveto
    currentpoint rot 1 add fontheight image
    moveto
    dup .inp_show get {
      .inp_label get exec showright
    } { pop } ifelse
  } forall
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Setup boot option input field.
%
% ( ) == > ( )
%
/boot.input.setup {
  % boot.show not { return } if

  boot.ed.list {
    dup .inp_x get over .inp_y get boot.ed.height add moveto

    currentpoint boot.ed.width 2 image

    currentcolor
    currenttransparency

    white setcolor
    0xe0 settransparency

    2 index .inp_show get {
      boot.ed.width 2 fillrect
    } if

    settransparency
    setcolor

    pop

  } forall
} def


/boot.input.preinit {

  boot.ed.list { dup .inp_show false put .inp_buf get 0 0 put } forall

  menu.args menu.entry get boot.splitchar split

    0 1 boot.ed.list length 1 sub {
      over over aget dup .undef ne {
        boot.ed.list rot get dup .inp_show true put .inp_buf get exch strcpy pop
      } {
        pop pop exit
      } ifelse
    } for

  free

  config.nobootoptions menu.texts menu.entry get submenu.skip_prefix iselement
  menu.args menu.entry get submenu.tag strstr 1 eq
  or
  {
    boot.ed.list 0 get .inp_show false put
  } if

  boot.ed.list { splitcmdline } forall

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

  boot.show {
    boot.ed.list {
      dup .inp_show get {
        dup
        dup dup .inp_buf get exch over edit.init
        "" ne { ' ' edit.input } { pop } ifelse
        edit.hidecursor
      } {
        edit.done
      } ifelse
    } forall
    boot.ed.list boot.window .ed.focus get get dup .inp_show get { edit.showcursor } { pop } ifelse

    boot.ed.list {
      dup .inp_show get .inp_visible exch put
    } forall

  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw boot option input field.
%
% ( ) == > ( )
%
/bootoptions.redraw {

  % clear old options

  boot.text.options setcolor
  window.current .font get setfont
  boot.ed.list {
    dup .inp_x get 10 sub over .inp_y get moveto
    currentpoint
    currentpoint 0 exch moveto
    currentpoint rot 1 add fontheight image
    moveto
    dup .inp_show get {
      .inp_label get exec showright
    } { pop } ifelse
  } forall

  boot.drawlabels
  boot.input.setup

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw boot menu.
%
% No entry is marked as selected.
%
% ( ) == > ( )
%
/main.drawmenu {
  % center menu title if x == -1
  /menu.title.pos.x_aligned
    menu.title.pos.x -1 eq {
      clip.size pop menu.title strsize pop sub 2 div 0 max
    } {
      menu.title.pos.x
    } ifelse
  def

  menu.title.pos.x_aligned menu.title.pos.y moveto
  menu.title.color setcolor
  menu.title show

  menu.text.normal setcolor

  /menu.bar.width.old menu.bar.width def

  /menu.bar.width
    menu.bar.min.width
    % also leave space for timeout indicator (+24)
    menu.texts { menuitemmap strsize pop menu.text.xofs 2 mul add 2 add 24 add max } forall
  def

  % center menu
  menu.start.x -1 eq {
    /menu.start.x clip.size pop menu.bar.width sub 2 div 0 max def
  } if

  /x menu.start.x def
  /y menu.start.y def

  0 1 menu.visible.entries 1 sub {
    /idx_tmp1 over def
    x y moveto currentpoint menu.bar.width.old menu.bar.height image
    x config.rtl { menu.bar.width menu.text.xofs sub } { menu.text.xofs } ifelse add
    y menu.text.yofs add moveto
    menu.texts exch menu.shift add get menuitemmap
    currentfont exch font.large setfont show.rtl setfont

    x y moveto idx_tmp1 menu.shift add show.submenu.tag

    /y y menu.item.height add def
  } for

  menu.visible.entries menu.max.entries lt {
    menu.visible.entries 1 menu.max.entries 1 sub {
     pop
     x y moveto currentpoint menu.bar.width.old menu.bar.height image
     /y y menu.item.height add def
    } for
  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Select/deselect menu entry.
%
% If an entry is selected (status = true), the boot options input field is
% initialized.
%
% ( entry status ) ==> ( )
%
% status:
%  false	not selected
%  true		selected
%
% Note: menu.bar.width must be valid even if status = false.
%
/MenuSelect {
  /menu.status exch def

  /menu.idx over def

  menu.shift sub
  menu.item.height mul menu.start.y add
  menu.start.x exch
  moveto

  currentpoint
  menu.status {
    menu.bar.color setcolor
    currenttransparency
    menu.bar.transparency settransparency
    menu.bar.width menu.bar.height
    fillrect
    settransparency
  } {
    currentpoint menu.bar.width menu.bar.height image
  } ifelse
  moveto

  currentpoint
  config.rtl { menu.bar.width menu.text.xofs sub } { menu.text.xofs } ifelse
  menu.text.yofs rmoveto
  menu.status {
    menu.text.select
  } {
    menu.text.normal
  } ifelse
  setcolor
  menu.texts menu.idx get menuitemmap
  menu.status { config.talk { dup speak } if } if
  currentfont exch font.large setfont show.rtl setfont
  moveto

  menu.idx show.submenu.tag

  menu.status {
    % init boot options
    boot.update_options {

      boot.input.preinit

      false
        boot.ed.list {
          dup .inp_show get exch .inp_visible get xor or
        } forall
      {
        boot.input.setup
        boot.drawlabels
      } if

      bootoptions.init
    } {
      bootoptions.redraw
    } ifelse

    % set help context
    "main" help.setcontext
    menu.texts menu.idx get
    dup help.findpage "" eq {
      pop
    } {
      help.setcontext
    } ifelse
  } if

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show little arrow symbol indicating a submenu entry.
%
% ( menu_idx ) ==> ( )
/show.submenu.tag {
  menu.args exch get submenu.tag strstr 1 eq {
    config.rtl {
      menu.text.xofs menu.text.yofs rmoveto
      "\u25c0"
    } {
      menu.bar.width menu.text.xofs sub "\u25b6" strsize pop sub
      menu.text.yofs rmoveto
      "\u25b6"
    } ifelse
    show
  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw main window.
%
% ( window ) ==> ( )
%
/main.show {
  window.push

  main.recalc

  % get index of default entry
  /menu.entry 0 def
  0 1 menu.texts length 1 sub {
    dup menu.texts exch get menu.dentry eq { /menu.entry exch def exit } { pop } ifelse
  } for

  boot.text.options setcolor

  window.current .font get setfont

  /boot.ed.width screen.size pop boot.pos.x boot.pos.y pop sub ptheme { 60 } { 20 } ifelse sub def
  /boot.ed.height fontheight 2 add def

  /boot.window window.current def

  /boot.ed.list [
    0 1 boot.ed.max 1 sub {
      [
        boot.pos.x boot.pos.y exch 10 add exch 1 sub 4 -1 roll boot.ed.height 5 add mul add
        over over moveto boot.ed.width boot.ed.height savescreen
        cmdlinelength string
        cmdlinelength
        .undef
        cmdlinelength string
        "More Options"
        false
        false
      ]
    } for
  ] def

  boot.ed.list 0 get .inp_label /txt_bootoptions put

  boot.window .ed.list boot.ed.list put
  boot.window .ed.focus 0 put

  main.drawmenu

  boot.drawlabels

  menu.entry true MenuSelect

  % find default splash mode
  % 0 1 splash.options length 1 sub {
  %   splash.options over get menu.args menu.entry get exch strstr {
  %     /splash.default exch def
  %   } {
  %     pop
  %   } ifelse
  % } for

  panel.init

  "main" help.setcontext

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Re-calculate basic menu layout data.
%
% ( ) ==> ( )
/main.recalc {
  /menu.shift 0 def

  /menu.visible.entries menu.texts length menu.max.entries min def

  menu.entry menu.visible.entries sub 0 ge {
    /menu.shift menu.entry menu.texts length menu.visible.entries sub min def
  } if
} def

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Split command line into hidden and normal part.
%
% ( edit_object ) == > ( )
%
/splitcmdline {
  dup length .inp_hidden le { pop return } if
  dup .inp_hidden get .undef eq { pop return } if

  dup .inp_hidden get over .inp_buf get strcpy pop

  dup .inp_hidden get "showopts" bootopt.find dup {
    dup "showopts" length add skipspaces
    2 index .inp_buf get exch strcpy dropspaces
    0 0 put
    .inp_hidden get dropspaces
  } {
    pop dup .inp_hidden get 0 0 put
    .inp_buf get dropspaces
  } ifelse
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

  dup keyEsc eq {
    submenu.current {
      /window.action actExit def
    } {
      exit_popup
    } ifelse
    pop 0
  } if

  dup keyEnter eq {
    /window.action actStart def
    pop 0
  } if

  dup keyUp eq {
    menu.entry 0 gt {
      menu.entry false MenuSelect
      menu.entry menu.shift eq {
        /menu.shift menu.shift 1 sub def main.drawmenu
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
        /menu.shift menu.shift 1 add def main.drawmenu
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
        /menu.shift 0 def main.drawmenu
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
        /menu.shift exch def main.drawmenu
      } {
        pop
      } ifelse
      menu.entry true MenuSelect
    } if
    pop 0
  } if

  dup 0 ne {
    "opt" help.setcontext
  } {
    % set if at least one key has been processed
    % see panel::panel.extra

    /panel.extra.fkey 1 def
  } ifelse
} def


