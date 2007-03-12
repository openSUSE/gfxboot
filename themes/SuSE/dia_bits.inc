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

  32+64bit_source {
    64bit {
      /bits.default 1 def
      xmenu .xm_list [ "32bit" "64bit" ] put
    } if
  } if

  % no '64' suffix
  32bit_boot_dir 64bit_boot_dir ne {
    bits.suffix 1 .undef put
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


