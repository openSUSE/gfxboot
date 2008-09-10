% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
% Some vars.

/act.nop	0 def
/act.boot	1 def

/.sm.setup	0 def
/.sm.ok		1 def

/serial.action act.nop def

/serial.setup /serial.setup.start def

/serial.menu.index 0 def

/serial.line.status 0 def

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
% serial line input event handling
%
% ( key -- input_buffer menu_entry action )
%
% key
%  bit 0-7      ascii
%  bit 24-32    scan code (0xf0 + serial line number)
%
% action
%    0:         ok, stay in input loop
%    1:         switch to text mode
%  >=2:         start linux
%
/serial.input {
  dup 24 shr 0x0f and 1 exch shl serial.line.status or /serial.line.status exch def

  0xffffff and

  % ^? -> ^H
  dup 0x7f eq { pop 8 } if

  serial.setup exec

  serial.edit
  dup 0 eq { pop "" -1 0 return } if

  1 eq { serial.menu.ok } { serial.menu.prev } ifelse

  serial.action act.boot eq {
    /serial.setup serial.menu.layout serial.menu.index get .sm.setup get def

    serial.cmdline serial.menu_idx 2
    return
  } if

  "" -1 0
} def

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Write string to serial line.
%
% ( str1 -- )
%
/serial.show {
  {
    dup 0x0a eq { 0x0d serial.putc } if
    serial.putc
  } forall
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( str1 -- )
%
/serial.edit.init {
  serial.edit.buf exch strcpy
  "> " serial.show serial.show
} def

/serial.edit.buf 1024 string def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( int1 -- int2 )
%
/serial.edit {
  dup 0x0d eq {
    "\n\n" serial.show
    pop 1 return
  } if

  dup 0x1b eq {
    "\n\n" serial.show
    pop 2 return
  } if

  dup 0x08 eq {
    serial.edit.buf length 0 gt {
      serial.edit.buf dup length 1 sub 0 put
      "\x08 \x08" serial.show
    } if
    pop 0 return
  } if

  dup 0x15 eq {
    serial.edit.buf length 0 gt {
      serial.edit.buf length {
        "\x08 \x08" serial.show
      } repeat
      serial.edit.buf 0 0 put
    } if
    pop 0 return
  } if

  dup 0x20 ge over 0x7e le and {
    serial.edit.buf cvp length serial.edit.buf length 1 add gt {
      serial.edit.buf dup length add dup 1 0 put 0 2 index put

      serial.putc 0 return
    } if
  } if

  pop 0
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( -- )
%
/serial.smenu.init {
  "\n===  " serial.show
  smenu .xm_title get exec serial.show
  "  ===\n\n" serial.show
  smenu .xm_text get exec serial.show
  "\n\n" serial.show

  /serial.smenu.cnt 0 def
  /serial.smenu.tmp 256 string def

  smenu .xm_list get {
    exec
    serial.smenu.cnt smenu .xm_current get eq { " * " } { " " } ifelse
    /serial.smenu.cnt inc
    serial.smenu.cnt
      smenu .xm_list get length 10 ge { "%2d)%s%s\n" } { "%d)%s%s\n" } ifelse
    serial.smenu.tmp sprintf
    serial.smenu.tmp serial.show
  } forall

  /serial.smenu.tmp xfree

  "\n" serial.show

   "" serial.edit.init
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw main menu.
%
% ( int1 -- int2 )
%
% int1: key
% int2: key
%
/serial.setup.start {
  /serial.menu.layout [
    [ /serial.main.setup /serial.main.ok ]
    xmenu.bits .xm_list get length 1 gt { [ /serial.bits.setup /serial.bits.ok ] } if
    xmenu.kernelopts .undef ne { [ /serial.kernel.setup /serial.kernel.ok ] } if
    [ /serial.options.setup /serial.options.ok ]
  ] def

  % go for text mode (or use 0?)
  xmenu.video .xm_current 1 put

  "\nopenSUSE 11.1 installation\n\n" serial.show

  /serial.setup /serial.nop def

  serial.menu.again

  pop 0
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Setup main menu.
%
% ( -- )
%
/serial.main.setup {
  smenu.main .undef eq {
    /smenu.main .xm_size array def

    smenu.main .xm_current menu.entry put
    smenu.main .xm_title "Main Menu" put
    smenu.main .xm_text "Select a boot entry." put
    smenu.main .xm_list [ menu.texts { menuitemmap } forall ] put
  } if

  /smenu smenu.main def

  serial.smenu.init

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Leave main menu.
%
% ( -- )
%
/serial.main.ok {
  serial.edit.buf to_number

  menu.entry false MenuSelect

  serial.smenu.select {
    /menu.entry smenu .xm_current get def
    serial.menu.next
  } {
    serial.menu.again
  } ifelse

  menu.entry true MenuSelect
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Setup kernel menu.
%
% ( -- )
%
/serial.kernel.setup {
  xmenu.kernelopts .xm_text "Select a predefined set of kernel options." put

  /smenu xmenu.kernelopts def

  serial.smenu.init
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Leave kernel menu.
%
% ( -- )
%
/serial.kernel.ok {
  serial.edit.buf to_number
  serial.smenu.select { serial.menu.next } { serial.menu.again } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Setup arch menu.
%
% ( -- )
%
/serial.bits.setup {
  xmenu.bits .xm_text "32 or 64 bit?" put

  /smenu xmenu.bits def

  serial.smenu.init
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Leave arch menu.
%
% ( -- )
%
/serial.bits.ok {
  serial.edit.buf to_number
  serial.smenu.select { serial.menu.next } { serial.menu.again } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Setup lang menu.
%
% ( -- )
%
/serial.lang.setup {
  /smenu xmenu.lang def

  serial.smenu.init
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Leave lang menu.
%
% ( -- )
%
/serial.lang.ok {
  serial.edit.buf to_number
  serial.smenu.select { serial.menu.next } { serial.menu.again } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Setup options menu.
%
% ( -- )
%
/serial.options.setup {
  "===  Boot Options  ===\n" serial.show

"
Edit boot options.

- lang=<locale> selects the default language
- install=<url> sets the install repository
- dud=<url> adds a driverupdate (option can be given more than once)

"
  serial.show

  boot.ed.list buildcmdline /serial.menu_idx exch def /serial.cmdline exch def

  serial.console.option dup .undef ne {
    " %s" serial.cmdline dup length add sprintf
  } { pop } ifelse

  serial.cmdline serial.edit.init
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Options -> Boot.
%
% ( -- )
%
/serial.options.ok {
  serial.cmdline serial.edit.buf strcpy pop

  /serial.menu.index 0 def

  /serial.action act.boot def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Do nothing.
%
% ( -- )
%
/serial.nop {
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Convert String to number.
%
% ( str1 -- int1 )
%
% Returns -1 if str1 is not a number.
%
/to_number {
  dup cvn
  dup 0 ne { exch pop return } if
  pop
  dup "" eq exch "0" eq or { 0 } { -1 } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Ensure serial.menu.index has a valid value.
%
% ( -- )
%
/serial.menu.index.normalize {
  serial.menu.index serial.menu.layout length gt { /serial.menu.index serial.menu.layout length def } if
  serial.menu.index 0 lt { /serial.menu.index 0 def } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Reinit current menu.
%
% ( -- )
%
/serial.menu.again {
  serial.menu.index.normalize
  serial.menu.layout serial.menu.index get .sm.setup get exec
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Run 'ok' action for current menu.
%
% ( -- )
%
/serial.menu.ok {
  serial.menu.index.normalize
  serial.menu.layout serial.menu.index get .sm.ok get exec
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Go to next menu.
%
% ( -- )
%
/serial.menu.next {
  /serial.menu.index inc
  serial.menu.again
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Go to previous menu.
%
% ( -- )
%
/serial.menu.prev {
  /serial.menu.index dec
  serial.menu.again
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Select menu item (update smenu->.xm_current).
%
% ( int1 -- bool1 )
%
/serial.smenu.select {
  smenu .xm_list get length over lt over 0 lt or {
    pop

    false
  } {
    dup 0 eq { pop smenu .xm_current get 1 add } if

    1 sub smenu .xm_current rot put

    true
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build 'console' option for kernel.
%
% ( -- str1 )
%
/serial.console.option {

  /serial.tmp.bm 0 def
  {
    serial.line.status 1 serial.tmp.bm shl and { exit } if
    /serial.tmp.bm inc
    serial.tmp.bm 8 ge { /serial.tmp.bm .undef def exit } if
  } loop

  serial.tmp.bm .undef eq { .undef return } if
  serial.lines length serial.tmp.bm le { .undef return } if

  serial.lines serial.tmp.bm get 2 aget dup .undef ne {
    serial.lines serial.tmp.bm get 1 get cvn exch
    "console=%s,%d" serial.console.buf sprintf
    serial.console.buf
  } if

} def

/serial.console.buf 64 string def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Setup serial lines.
%
0 1 serial.lines length 1 sub {
  serial.lines over get dup length 2 ge {
    dup 0 get cvn exch 1 get cvn serial.setconfig
  } {
    pop pop
  } ifelse
} for

serial.init

