% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Driver update dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/dud.default 1 def

/dud.options [
  "dud=1"
  ""
] def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build driver update menu.
%
% ( ) ==> ( )
%
/dud.init {
  /xmenu.dud .xm_size array def

  /xmenu xmenu.dud def

  xmenu .xm_current dud.default put
  xmenu .xm_list [ "Yes" "No" ] put

  xmenu .xm_title /txt_driver_update put

  pmenu.init
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update driver update mode.
%
% ( ) ==> ( )
%
/dud.update {
  /xmenu xmenu.dud def

  /window.action actRedrawPanel def

  pmenu.update
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show driver update menu.
%
% ( ) => ( )
%
/panel.dud {
  "driverupdate" help.setcontext

  window.xmenu
  dup .xmenu xmenu.dud put
  dup .xmenu.update /dud.update put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of panel entry.
%
% ( ) => ( width )
%
/panel.dud.width {
  /xmenu xmenu.dud def

  pmenu.width
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.dud.update {
  /xmenu xmenu.dud def

  pmenu.panel.update
} def


