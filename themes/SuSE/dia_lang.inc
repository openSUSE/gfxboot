% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Language selection dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build language list.
%
% ( ) ==> ( )
%
/keytable.init {
  /tmp.kt [ keymaps { 1 get } forall ] def

  /xmenu.keytable .xm_size array def

  /xmenu xmenu.keytable def

  xmenu .xm_current keymaps.default put
  xmenu .xm_list tmp.kt put

  % start with current lang

  /tmp.kt 0 def
  keymaps {
    0 get config.lang eq { xmenu .xm_current tmp.kt put exit } if
    /tmp.kt tmp.kt 1 add def
  } forall

  pmenu.init
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update language.
%
% ( ) ==> ( )
%
/keytable.update {
  /xmenu xmenu.keytable def

  keymaps xmenu .xm_current get get 0 get setlang { /window.action actRedraw def } if
  /config.keymap keymaps xmenu .xm_current get get 2 get def

  % Why? --> see dia_install.inc; same there.
  window.action actRedraw eq { pmenu.update } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show language menu.
%
% ( ) => ( )
%
/panel.keytable {
  "keytable" help.setcontext

  window.xmenu
  dup .xmenu xmenu.keytable put
  dup .xmenu.update /keytable.update put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of panel entry.
%
% ( ) => ( width )
%
/panel.keytable.width {
  /xmenu xmenu.keytable def

  pmenu.width
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.keytable.update {
  /xmenu xmenu.keytable def

  pmenu.panel.update
} def


