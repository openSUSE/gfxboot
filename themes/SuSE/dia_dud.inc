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

/dud.default .dud_no def

/dud.options [
  "dud=1"
  ""
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

  xmenu .xm_current dud.default put
  xmenu .xm_list [ /txt_yes /txt_no /txt_file ] put

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

  xmenu .xm_current get dup .dud_file eq {
    dud.dialog
  } {
    /window.action actRedrawPanel def
  } ifelse

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


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/dud.dialog {

  /dia window.dialog def

  dia .text "" put

  xmenu .xm_current get

  dup .dud_file eq {
    input.edit.dud_file .undef eq {
      /input.edit.dud_file [ 127 string ] def
    } if

    dia .title "Driver Update" put

    % Must all be of same size!
    dia .ed.list 1 array put
    dia .ed.buffer.list input.edit.dud_file put
    dia .ed.text.list [ txt_dud_file_msg ] put
  } if

  pop

  dia .ed.focus 0 put
  dia .ed.width 300 put

  dia .buttons [
    button.ok button.default actNothing button.setaction
    button.cancel button.notdefault actNothing button.setaction
  ] put

  dia window.init
  dia window.show

} def


