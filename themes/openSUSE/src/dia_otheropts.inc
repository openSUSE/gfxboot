% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Various kernel options dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/otheropts.default 0 def

config.init "/sbin/init" eq { /config.init "" def } if
config.init "/bin/systemd" eq { /otheropts.default 1 def } if
config.init "/bin/sh" eq { /otheropts.default 2 def } if

/otheropts.xtra
  config.init "" ne
  config.init "/bin/systemd" ne and
  config.init "/bin/sh" ne and
def

/otheropts.options [
  ""
  "init=/bin/systemd"
  "init=/bin/sh"
  otheropts.xtra {
    100 string dup config.init "init=%s" rot sprintf
    /otheropts.default 3 def
  } if
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
    otheropts.xtra { config.init } if
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


