% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Driver update dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/.dud_yes	0 def
/.dud_no	1 def
/.dud_file	2 def
/.dud_url	3 def

/dud.last .dud_no def

/dud.options [
  "dud=1"
  ""
  .undef
  .undef
] def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build driver update menu.
%
% ( ) ==> ( )
%
/dud.init {
  /xmenu.dud .xm_size array def

  /xmenu xmenu.dud def

  /input.edit.dud_file [ 127 string ] def
  /input.edit.dud_url [ 127 string ] def

  dud.read.config

  xmenu .xm_current dud.last put
  xmenu .xm_list [ /txt_yes /txt_no /txt_file dud.url.name ] put

  xmenu .xm_title /txt_driver_update put
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update driver update mode.
%
% ( ) ==> ( )
%
/dud.update {
  /xmenu xmenu.dud def

  xmenu .xm_current get dup .dud_file eq over .dud_url eq or {
    dud.dialog
  } if
  /window.action actRedrawPanel def
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


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/dud.dialog {

  /dia window.dialog def

  dia .text "" put

  xmenu .xm_current get

  dup .dud_file eq {
    dia .title txt_driver_update2 put

    % Must all be of same size!
    dia .ed.list 1 array put
    dia .ed.buffer.list input.edit.dud_file put
    dia .ed.text.list [ txt_dud_file_msg ] put
  } if

  dup .dud_url eq {
    dia .title "Download Driver Update" put

    % Must all be of same size!
    dia .ed.list 1 array put
    dia .ed.buffer.list input.edit.dud_url put
    dia .ed.text.list [ "Enter Driver Update URL\n" ] put
  } if

  pop

  dia .ed.focus 0 put
  dia .ed.width 300 put

  dia .buttons [
    button.ok button.default actNothing button.setaction
    button.cancel button.notdefault actNothing button.setaction
    config.rtl { exch } if
  ] put

  dia window.init
  dia window.show

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Read default values.
%
% ( -- )
%
/dud.read.config {
  dud.default
  dup "yes"  eq { /dud.last .dud_yes def } if
  dup "no"   eq { /dud.last .dud_no def } if
  dup "file" eq { /dud.last .dud_file def } if
  dup "url"  eq { /dud.last .dud_url def } if
  pop

  input.edit.dud_file 0 get dud.file strcpy pop
  input.edit.dud_url  0 get dud.url  strcpy pop

  dud.url.name "" eq { /dud.url.name "URL" def } if

} def
