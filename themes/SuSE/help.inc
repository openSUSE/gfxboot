% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% help system
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% global vars used by help system


/help.context "main" def

/help.light white def
/help.dark black def
/help.font font.normal def
/help.normal.bg lightgray def
/help.normal.fg black def
/help.highlight.fg green def
/help.link.fg blue def
/help.link.selected.fg white def
/help.link.selected.bg blue def

/help.x 80 def
/help.y 50 def
/help.width 480 def
/help.height 322 def

/help.text.x help.x 10 add def
/help.text.y help.y 30 add def

/help.text.width help.width 20 sub def
/help.text.height help.height help.text.y sub help.y add 4 sub def
/help.text.rightmargin help.text.x help.text.width add def

/help.title.x help.x 10 add def
/help.title.y help.y 3 add def
/help.title.height 20 def
/help.title.font font.normal def

% /help.title.bg 0x299dcd newcolor
% for dialogs, too
/title.bg 0x317db4 newcolor
% /title.bg 0x2d9e6b newcolor
% /title.bg 0x2c9f84 newcolor
% /title.bg 0x36b74e newcolor

/help.hist.page 16 array def
/help.hist.startrow help.hist.page length array def
/help.hist.selectedlink help.hist.page length array def


% for boot option lookup
/bo.opt.max 32 def
/bo.opt bo.opt.max 3 add string def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Map help context.
%
% ( context ) ==> ( new_context )
%
/help.mapcontext {
  dup "o_vncpassword" eq { pop "o_vnc" } if
  dup "o_hostip" eq { pop "network" } if
  dup "o_netmask" eq { pop "network" } if
  dup "o_gateway" eq { pop "network" } if
  dup "o_pci" eq { pop "o_acpi" } if

  syslinux not {
    % only help, startup, keytable and option pages
    dup "o_" strstr 1 ne {
      dup "help" ne
      over "startup" ne and
      over "keytable" ne and
      over "profile" ne and { pop "opt" } if
    } if
  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Set help context.
%
% ( context ) ==> ( )
%
/help.setcontext {
  help.mapcontext /help.context exch def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Find boot option the cursor is positioned at.
%
% ( ) ==> ( option )
%
/findbootoption {
  /bo.buf boot.ed 3 get def
  /bo.len boot.ed 4 get def
  /bo.pos boot.ed 5 get def

  {
    bo.pos 0 eq { exit } if
    bo.buf bo.pos 1 sub get ' ' le  { exit } if
    /bo.pos bo.pos 1 sub def
  } loop

  /bo.buf bo.buf bo.pos add def

  bo.buf 0 get ' ' le { "" return } if

  % "o_" + option name is the help text label
  "o_" 3 bo.opt snprintf

  0 1 bo.opt.max 1 sub {
    dup
    bo.buf exch get
    dup ' ' le over '=' eq or { pop pop exit } if
    over bo.opt 2 add exch rot put
    bo.opt 3 add exch 0 put
  } for

  bo.opt

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Find help page.
%
% returns help page or empty string if no page was found
%
% ( label ) ==> ( help_text )
%
/help.findpage {
  dup length 3 add dup string
  "\x12%s\x14"
  3 1 roll dup 5 1 roll snprintf
  help.getmessages over strstr
  dup { help.getmessages exch 1 sub add } { pop "" } ifelse
  exch free
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Find help page.
%
% returns n-th help page or empty string if no page was found
%
% ( n ) ==> ( help_text )
%
/help.findpagebyindex {
  help.getmessages exch
  {
    dup "\x04" strstr
    dup { add } { pop pop "" exit } ifelse
  } repeat
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Init & display help page.
%
% ( help_text start_row selected_link ) ==> ( )
%
/help.initpage {
  /help.selectedlink exch def
  /help.startrow exch def

  /help.currenttext over def

  title.bg setcolor
  help.x 1 add help.y 1 add moveto
  help.width 2 sub help.title.height 1 sub fillrect

  help.text.x help.text.y moveto
  currentmaxrows 0 setmaxrows exch formattext setmaxrows

  white setcolor
  currenteotchar 16 seteotchar
  help.title.x help.title.y moveto currenttitle
  currentfont help.title.font setfont exch show setfont
  seteotchar

  getlinks { help.selectedlink setlink } if

  help.updatepage

  % 500 0 moveto gettextrows print
  % 400 0 moveto getlinks print

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw help page.
%
% ( ) ==> ( )
%
/help.updatepage {
  help.normal.bg setcolor
  help.text.x help.text.y moveto
  help.text.width help.text.height fillrect

  help.normal.fg help.highlight.fg help.link.fg help.link.selected.fg settextcolors

  help.startrow setstartrow

  help.text.x help.text.y moveto
  help.currenttext show

  0 setstartrow

  true help.selectedlink help.redrawlink

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Used to iterate over all help pages (for debugging).
%
% get the n-th page starting from current pos
%
% ( n ) ==> ( help_text )
%
/help.test {
  help.test.cnt add
  dup 1 lt { pop 1 } if
  /help.test.cnt over def
  help.findpagebyindex
  dup "" eq {
    % one page back
    pop help.test.cnt 1 sub /help.test.cnt over def
    help.findpagebyindex
  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw link.
%
% selected: true or false.
%
% ( selected n ) ==> ( )
%
%
/help.redrawlink {
  getlinks 0 eq { pop pop return } if
  getlink
  dup help.startrow lt
  over help.startrow help.text.rows add ge or {
    5 { pop } repeat return
  } if
  help.startrow sub lineheight mul help.text.y add
  moveto
  rot

  16 seteotchar

  {
    currenttextcolors 4 1 roll pop pop pop
    help.link.selected.bg
  } {
    currenttextcolors 4 2 roll pop pop pop
    help.normal.bg
  } ifelse

  setcolor over currentpoint rot strsize fillrect moveto

  setcolor show

  4 seteotchar

  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Select n-th link.
%
% ( n ) ==> ( )
%
/help.selectlink {
  help.selectedlink over eq {
    pop
  } {
    % deselect old link
    false help.selectedlink help.redrawlink

    /help.selectedlink over dup setlink def

    % select link
    true exch help.redrawlink
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Select first visible link.
%
% No screen update if 'update' is false.
%
% ( update ) ==> ( )
%
/help.sel.firstlink {
  getlinks {
    0 1 getlinks 1 sub {
      dup
      getlink 4 1 roll pop pop pop
      dup help.startrow help.text.rows add ge {
        pop pop exit
      } if
      dup help.startrow ge {
        pop
        over { help.selectlink } { /help.selectedlink exch dup setlink def } ifelse
        exit
      } if
      pop pop
    } for
  } if
  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Select last visible link.
%
% No screen update if 'update' is false.
%
% ( update ) ==> ( )
%
/help.sel.lastlink {
  getlinks {
    getlinks 1 sub -1 0 {
      dup
      getlink 4 1 roll pop pop pop
      dup help.startrow lt {
        pop pop exit
      } if
      dup help.startrow help.text.rows add lt {
        pop
        over { help.selectlink } { /help.selectedlink exch dup setlink def } ifelse
        exit
      } if
      pop pop
    } for
  } if
  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Push current help context to history.
%
% ( ) ==> ( )
%
/help.add2history {
  help.hist.index help.hist.page length lt {
    help.hist.page help.hist.index help.currenttext put
    help.hist.startrow help.hist.index help.startrow put
    help.hist.selectedlink help.hist.index help.selectedlink put
    /help.hist.index help.hist.index 1 add def
  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Follow currently selected link.
%
% ( ) ==> ( )
%
/help.followlink {
  getlinks {
    help.selectedlink getlink pop pop pop
    help.add2history
    help.findpage
    dup "" eq {
      pop
    } {
      0 0 help.initpage
    } ifelse
  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Go back to previous page.
%
% ( ) ==> ( )
%
/help.prevlink {
  help.hist.index 0 gt {
    /help.hist.index help.hist.index 1 sub def
    help.hist.page help.hist.index get
    help.hist.startrow help.hist.index get
    help.hist.selectedlink help.hist.index get
    help.initpage
  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Scroll a page down.
%
% ( ) ==> ( )
%
/help.key.pagedown {
  help.startrow
  gettextrows help.text.rows gt {
    pop
    gettextrows help.text.rows sub
    help.startrow help.text.rows add
    min
  } if

  dup help.startrow eq {
    pop
    true help.sel.lastlink
  } {
    /help.startrow exch def
    false help.sel.firstlink
    help.updatepage
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Scroll a page up.
%
% ( ) ==> ( )
%
/help.key.pageup {
  help.startrow
  gettextrows help.text.rows gt {
    pop
    0
    help.startrow help.text.rows sub
    max
  } if

  dup help.startrow eq {
    pop
    true help.sel.firstlink
  } {
    /help.startrow exch def
    false help.sel.firstlink
    help.updatepage
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Go to page start.
%
% ( ) ==> ( )
%
/help.key.home {
  help.startrow 0 eq {
    true help.sel.firstlink
  } {
    /help.startrow 0 def
    false help.sel.firstlink
    help.updatepage
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Go to page end.
%
% ( ) ==> ( )
%
/help.key.end {
  gettextrows help.text.rows sub 0 max
  dup help.startrow  eq {
    pop
    true help.sel.lastlink
  } {
    /help.startrow exch def
    false help.sel.lastlink
    help.updatepage
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Next link or scroll down.
%
% ( ) ==> ( )
%
/help.key.down {
  help.selectedlink getlinks 1 sub lt {
    help.selectedlink 1 add getlink 4 1 roll pop pop pop
    dup help.startrow help.text.rows add lt {
      % link visible
      pop help.selectedlink 1 add help.selectlink
      return
    } {
      help.startrow help.text.rows add eq {
        % link visible after scrolling down
        /help.selectedlink help.selectedlink 1 add dup setlink def
      } if
    } ifelse
  } if

  % scroll down

  help.startrow help.text.rows add gettextrows lt {
    /help.startrow help.startrow 1 add def
    help.updatepage
  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Previous link or scroll up.
%
% ( ) ==> ( )
%
/help.key.up {
  help.selectedlink 0 gt {
    help.selectedlink 1 sub getlink 4 1 roll pop pop pop
    % row
    dup help.startrow ge {
      % link visible
      pop help.selectedlink 1 sub help.selectlink
      return
    } {
      help.startrow 1 sub eq {
        % link visible after scrolling up
        /help.selectedlink help.selectedlink 1 sub dup setlink def
      } if
    } ifelse
  } if

  % scroll up

  help.startrow 0 gt {
    /help.startrow help.startrow 1 sub def
    help.updatepage
  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Handle keyboard input.
%
% ( key_in ) ==> ( key_out )
%
/help.input {
  dup 0 eq { return } if

  dup keyEsc eq { /window.action actNothing def window.done } if
  dup keyCtrlDown eq { 1 help.test 0 0 help.initpage } if 
  dup keyCtrlUp eq { -1 help.test 0 0 help.initpage } if 
  dup keyDown eq { help.key.down } if 
  dup keyUp eq { help.key.up } if 
  dup keyPgDown eq { help.key.pagedown } if 
  dup keyPgUp eq { help.key.pageup } if 
  dup keyHome eq { help.key.home } if 
  dup keyEnd eq { help.key.end } if 
  dup keyRight eq { help.followlink } if 
  dup keyEnter eq { help.followlink } if 
  dup 0xff and ' ' eq { help.followlink } if 
  dup keyLeft eq { help.prevlink } if 
  dup 0xff and '\x08' eq { help.prevlink } if 
  dup keyF1 eq {
    "help" help.findpage
    dup help.currenttext eq {
      pop
    } {
      help.add2history
      0 0 help.initpage
    } ifelse
  } if 
%  dup keyF9 eq {
%    /help.font help.font 8 add 10 mod def help.reinit
%    help.currenttext help.startrow help.selectedlink help.initpage
%  } if 
  pop 0
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Recalculate some sizes and redraw help screen.
%
% ( ) ==> ( )
%
/help.reinit {
  help.normal.bg setcolor
  help.x help.y moveto
  help.width help.height fillrect

  help.x 1 add help.y 1 add help.title.height add moveto
  help.dark help.light
  help.width 2 sub help.height 2 sub help.title.height sub
  drawborder

  help.font setfont

  /help.text.rows help.text.height lineheight div def
  help.text.rows setmaxrows

  help.text.rightmargin settextwrap
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Initialize help window.
%
% ( window ) ==> ( )
%
/help.init {
  /help.tmp exch def

  help.x 1 sub help.y 1 sub moveto
  help.light help.dark
  help.width 2 add help.height 2 add
  over over

  % just for testing: lilo has enough low memory
  lilo { savescreen } { xsavescreen } ifelse

  help.tmp .saved rot put
  drawborder

  help.reinit

  4 seteotchar

  /help.hist.index 0 def

  /help.test.cnt 1 def

  help.context help.findpage 0 0 help.initpage
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw help window.
%
% ( window ) ==> ( )
%
/help.show {
  window.push
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Close current help window.
%
% ( ) ==> ( )
%
/help.done {
  0 settextwrap
  0 seteotchar
  0 setmaxrows
} def



% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Create new help window.
%
% ( ) ==> ( window )
%
/window.help {
  widget.size array
  dup .type t_help put

  dup .x help.x put
  dup .y help.y put

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Find help texts.
%
% ( ) ==> ( start_of_help_messages )
%
/help.getmessages {

  help.messages .undef eq {
    % find help texts
    /help.messages
      16 string dup config.lang "help.%s" 2 index sprintf
      findfile exch free
      dup .undef eq { pop "help.en" findfile } if
      dup .undef eq { pop "" } if
      cvs
    def
  } if

  help.messages

} def


