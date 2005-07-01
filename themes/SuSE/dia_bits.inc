% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% 32/64 bit install selection dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/bits.default 0 def

/bits.suffix [
  .undef
  "64"
] def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build menu list.
%
% ( ) ==> ( )
%
/bits.init {
  /xmenu.bits .xm_size array def

  /xmenu xmenu.bits def

  xmenu .xm_list [ "32bit" ] put

  do_64bit_check 32+64bit_source and {
    64bit {
      /bits.default 1 def
      xmenu .xm_list [ "32bit" "64bit" ] put
    } if
  } if

  xmenu .xm_current bits.default put

  pmenu.init
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update bit selection menu.
%
% ( ) ==> ( )
%
/bits.update {
  /xmenu xmenu.bits def

  /window.action actRedrawPanel def

  pmenu.update
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show bit selection menu.
%
% ( ) => ( )
%
/panel.bits {
  "bits" help.setcontext

  window.xmenu
  dup .xmenu xmenu.bits put
  dup .xmenu.update /bits.update put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of panel entry.
%
% ( ) => ( width )
%
/panel.bits.width {
  /xmenu xmenu.bits def

  pmenu.width
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.bits.update {
  /xmenu xmenu.bits def

  pmenu.panel.update
} def


