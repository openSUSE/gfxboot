% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Various kernel options dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/otheropts.default 0 def

/otheropts.options [
  ""
  "init=/bin/systemd"
  "init=/bin/sh"
] def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build otheropts list.
%
% ( ) ==> ( )
%
/otheropts.init {
  /xmenu.otheropts .xm_size array def

  /xmenu xmenu.otheropts def

  xmenu .xm_current otheropts.default put
  xmenu .xm_list [
    "System V"
    "Systemd"
    "Shell"
  ] put
  xmenu .xm_title "Init Program" put

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update otheropts mode.
%
% ( ) ==> ( )
%
/otheropts.update {
  /xmenu xmenu.otheropts def

  /window.action actRedrawPanel def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show otheropts menu.
%
% ( ) => ( )
%
/panel.otheropts {
  "main" help.setcontext

  window.xmenu
  dup .xmenu xmenu.otheropts put
  dup .xmenu.update /otheropts.update put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of panel entry.
%
% ( ) => ( width )
%
/panel.otheropts.width {
  /xmenu xmenu.otheropts def

  pmenu.width
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.otheropts.update {
  /xmenu xmenu.otheropts def

  pmenu.panel.update
} def


