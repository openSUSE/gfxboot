% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% keyboard map selection dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%

/keymap.setdefault {
  xmenu.keymap .xm_current

    0
    keymaps {
      .km.id get config.keymap.id eq { exit } if
      1 add
    } forall

    dup keymaps length ge { pop 0 } if

  put

} def

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build menu list.
%
% ( ) ==> ( )
%
/keymap.init {
  /xmenu.keymap .xm_size array def

  /xmenu xmenu.keymap def

  xmenu .xm_list [
    keymaps { .km.name get } forall
  ] put

  xmenu .xm_title "Keyboard" put

  keymap.setdefault

  % just once (see lang.init)
  /keymap.init { } def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update keybaord selection menu.
%
% ( ) ==> ( )
%
/keymap.update {
  /xmenu xmenu.keymap def

  keymaps xmenu .xm_current get get .km.id get setkeymap

  /window.action actRedrawPanel def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show keymap selection menu.
%
% ( ) => ( )
%
/panel.keymap {
  "keymap" help.setcontext

  keymap.setdefault

  window.xmenu
  dup .xmenu xmenu.keymap put
  dup .xmenu.update /keymap.update put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of panel entry.
%
% ( ) => ( width )
%
/panel.keymap.width {
  /xmenu xmenu.keymap def

  pmenu.width
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.keymap.update {
  /xmenu xmenu.keymap def

  pmenu.panel.update
} def


