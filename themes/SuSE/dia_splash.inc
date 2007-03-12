% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Splash mode selection dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/splash.default 2 def

/splash.options [
  "splash=0"
  "splash=verbose"
  "splash=silent"
] def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build splash list.
%
% ( ) ==> ( )
%
/splash.init {
  /xmenu.splash .xm_size array def

  /xmenu xmenu.splash def

  xmenu .xm_current splash.default put
  xmenu .xm_list [ "Native" "Verbose" "Silent" ] put

  pmenu.init
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update splash mode.
%
% ( ) ==> ( )
%
/splash.update {
  /xmenu xmenu.splash def

  /window.action actRedrawPanel def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show splash menu.
%
% ( ) => ( )
%
/panel.splash {
  "startup" help.setcontext

  window.xmenu
  dup .xmenu xmenu.splash put
  dup .xmenu.update /splash.update put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of panel entry.
%
% ( ) => ( width )
%
/panel.splash.width {
  /xmenu xmenu.splash def

  pmenu.width
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.splash.update {
  /xmenu xmenu.splash def

  pmenu.panel.update
} def


