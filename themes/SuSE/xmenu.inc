% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% List dialog handling.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/xmenu.vspace.default	{ xmenu .xm_list get length 15 ge { 2 } { 4 } ifelse } def
/xmenu.hspace		12 def
/xmenu.light		white def
/xmenu.dark		black def
/xmenu.font		font.normal def
/xmenu.normal.bg	lightgray def
/xmenu.normal.fg	black def
/xmenu.selected.fg	white def
/xmenu.selected.bg	0x6c6c6c newcolor

small_layout {
  /xmenu.maxlines	19 def
} {
  /xmenu.maxlines	24 def	% 28
} ifelse

% xmenu layout
%
% [ selected_entry string_list x y panel_x ]
%
/.xm_current		 0 def		% selected entry
/.xm_list		 1 def		% string list
/.xm_x			 2 def		% menu x pos
/.xm_y			 3 def		% menu y pos
/.xm_width		 4 def		% menu width
/.xm_height		 5 def		% menu height
/.xm_panel_x		 6 def		% panel entry x pos
/.xm_panel_width	 7 def		% panel entry width
/.xm_panel_height	 8 def		% panel entry height
/.xm_vspace		 9 def		% vspace per menu
/.xm_title              10 def          % xmenu title
/.xm_size		11 def		% xmenu size


% short hands
/xmenu.x { xmenu .xm_x get } def
/xmenu.y { xmenu .xm_y get } def
/xmenu.width { xmenu .xm_width get } def
/xmenu.height { xmenu .xm_height get } def

/xmenu.vspace { xmenu .xm_vspace get dup .undef ne { } { pop xmenu.vspace.default } ifelse } def

/xmenu.saved { xmenu.saved.areas xmenu.column get 2 get } def

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Create new xmenu.
%
% ( ) ==> ( window )
%
/window.xmenu {
  widget.size array
  dup .type t_xmenu put
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Handle keyboad input.
%
% ( key_in ) ==> ( key_out )
%
/xmenu.input {
  dup 0 eq { return } if

  dup keyEsc eq {
    xmenu 0 xmenu.oldentry put
    window.done
    pop 0
  } if

  dup keyEnter eq {
    window.current .xmenu.update get
    window.done
    exec
    pop 0
  } if

  dup keyDown eq {
    xmenu .xm_current get 1 add xmenu.select
    pop 0
  } if 

  dup keyUp eq {
    xmenu .xm_current get 1 sub xmenu.select
    pop 0
  } if 

  dup keyPgDown eq {
    xmenu .xm_current get 5 add
    xmenu .xm_list get length 1 sub min xmenu.select
    pop 0
  } if 

  dup keyPgUp eq {
    xmenu .xm_current get 5 sub
    0 max xmenu.select
    pop 0
  } if 

  dup keyHome eq {
    0 xmenu.select
    pop 0
  } if 

  dup keyEnd eq {
    xmenu .xm_list get length 1 sub xmenu.select
    pop 0
  } if 

  dup keyRight eq {
    xmenu .xm_current get
    dup xmenu.maxlines div 1 add xmenu.columns mod xmenu.maxlines mul
    exch xmenu.maxlines mod add
    xmenu .xm_list get length 1 sub min xmenu.select
    pop 0
  } if 

  dup keyLeft eq {
    xmenu .xm_current get
    dup xmenu.maxlines div xmenu.columns add 1 sub xmenu.columns mod xmenu.maxlines mul
    exch xmenu.maxlines mod add
    xmenu .xm_list get length 1 sub min xmenu.select
    pop 0
  } if 

  dup keyF1 eq {
    show_help
    pop 0
  } if 

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Calculate menu sizes.
%
% ( ) ==> ( )
%
/xmenu.sizes {
  /xmenu.lheight xmenu.font setfont fontheight xmenu.vspace dup add add def

  /xmenu.columns xmenu .xm_list get length xmenu.maxlines add 1 sub xmenu.maxlines div def

  /xmenu.lastheight
    xmenu .xm_list get length xmenu.maxlines xmenu.columns 1 sub mul sub xmenu.lheight mul
  def

  xmenu .xm_height
    xmenu .xm_list get length xmenu.maxlines min xmenu.lheight mul
  put

  xmenu .xm_width
    0 xmenu .xm_list get { exec strsize pop max } forall xmenu.hspace 2 mul add
  put

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Init and show menu.
%
% ( window ) ==> ( )
%
% xmenu: [ selected_entry [ text0 text1 ... ] x y ]
%
/xmenu.init {
  /xmenu over .xmenu get def

  xmenu.sizes

  dup .saved.areas xmenu.columns array /xmenu.saved.areas over def put

  0 1 xmenu.columns 1 sub {
    /xmenu.column exch def

    dup .saved.areas get xmenu.column

    [
      xmenu.column xmenu.width 2 add mul xmenu.x add 1 sub xmenu.y 1 sub moveto
      currentpoint

      xmenu.light xmenu.dark
      xmenu.width 2 add
      xmenu.column 1 add xmenu.columns eq { xmenu.lastheight } { xmenu.height } ifelse 2 add
      over over savescreen 5 1 roll
      drawborder

    ] put

  } for

  0 1 xmenu .xm_list get length 1 sub { xmenu.viewentry } for

  /xmenu.oldentry xmenu .xm_current get def

  dup .x xmenu.x put
      .y xmenu.y put

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Close menu.
%
% ( ) ==> ( )
%
/xmenu.done {
  /xmenu.tmpbuf xmenu.tmpbuf free .undef def
  /xmenu.saved.normal xmenu.saved.normal free .undef def
  /xmenu.saved.selected xmenu.saved.selected free .undef def
  /xmenu.saved.areas .undef def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw xmenu.
%
% ( window ) ==> ( )
%
/xmenu.show {
  window.push
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw single entry.
%
% ( entry ) ==> ( )
%
/xmenu.viewentry {
  xmenu.font setfont

  dup xmenu.maxlines mod xmenu.lheight mul xmenu.y add /xmenu.pos.y exch def

  dup xmenu.maxlines div /xmenu.column over def
  xmenu.width 2 add mul xmenu.x add /xmenu.pos.x exch def

  xmenu.pos.x xmenu.pos.y moveto

  dup xmenu .xm_current get eq { xmenu.saved.selected } { xmenu.saved.normal } ifelse

  dup {
    transp { pop } { restorescreen } ifelse
  } {
    pop

    dup xmenu .xm_current get eq { xmenu.selected.bg } { xmenu.normal.bg } ifelse
    setcolor xmenu.width xmenu.lheight fillrect

    dup xmenu .xm_current get eq {
      xmenu.pos.x xmenu.pos.y moveto
      xmenu.dark xmenu.light xmenu.width xmenu.lheight drawborder
    } if

    dup xmenu .xm_current get eq { /xmenu.saved.selected } { /xmenu.saved.normal } ifelse
      xmenu.pos.x xmenu.pos.y moveto
      xmenu.width xmenu.lheight
      savescreen
    def
  } ifelse


  transp {
    % copy entry to avoid reading the screen again
    dup xmenu .xm_current get eq { xmenu.saved.selected } { xmenu.saved.normal } ifelse
    xmenu.tmpbuf .undef eq {
      dup length malloc /xmenu.tmpbuf exch def
    } if
    xmenu.tmpbuf exch dup length memcpy

    0 xmenu.pos.y xmenu.y sub moveto 1 1 rmoveto
    xmenu.saved transp xmenu.tmpbuf blend

    xmenu.pos.x xmenu.pos.y moveto xmenu.tmpbuf restorescreen
  } if

  dup xmenu .xm_current get eq { xmenu.selected.fg } { xmenu.normal.fg } ifelse setcolor
  xmenu.pos.x xmenu.hspace add xmenu.pos.y xmenu.vspace add moveto
  xmenu .xm_list get over get exec show

  pop


} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Select menu entry.
%
% ( new_entry ) ==> ( )
%
/xmenu.select {
  dup 0 lt { xmenu .xm_list get length add } if
  dup xmenu .xm_list get length ge { xmenu .xm_list get length sub } if

  xmenu .xm_current get over xmenu .xm_current rot put
  xmenu.viewentry
  xmenu.viewentry
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Panel/xmenu helper function.
%
% ( ) => ( )
%
/pmenu.panel.update {
  panel.text.moveto

  xmenu .xm_panel_x currentpoint pop xmenu.hspace sub put
  xmenu .xm_x xmenu .xm_panel_x get put

  pmenu.update
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Panel/xmenu helper function.
%
% ( ) => ( width )
%
/pmenu.width {
  % Use this instead of the line below and remove the actRedrawPanel
  % things if you want fixed size panel entries.

  % xmenu .xm_panel_width get xmenu.hspace 2 mul sub

  xmenu .xm_title get dup .undef eq {
    pop xmenu .xm_list get xmenu .xm_current get get
  } if
  exec strsize pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Panel/xmenu helper function.
%
% ( ) => ( )
%
/pmenu.update {
  xmenu .xm_panel_x get xmenu.hspace add panel.text.y moveto

% currently not needed - we're redrawing the whole panel anyway
%  xmenu .xm_panel_width get xmenu.hspace sub xmenu .xm_panel_height get
%  panel.bg setcolor fillrect

  panel.normal setcolor
  panel.font setfont
  xmenu .xm_panel_x get xmenu.hspace add
  panel.text.y
  moveto
  xmenu .xm_title get dup .undef eq {
    pop xmenu .xm_list get xmenu .xm_current get get
  } if
  exec show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Panel/xmenu helper function.
%
% ( ) => ( )
%
/pmenu.init {
  xmenu.sizes

  xmenu .xm_y panel.text.y 1 sub xmenu.height sub put
  xmenu .xm_panel_width xmenu.width put
  xmenu .xm_panel_height fontheight put
} def


