% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% System restore entry.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show restore popup.
%
% ( ) => ( )
%
/panel.restore {
  restore_popup
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of restore entry.
%
% ( ) => ( width )
%
/panel.restore.width {
  "System Restore" strsize pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.restore.update {
  panel.text.moveto

  "System Restore" show.rtl
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show restore popup.
%
% ( ) ==> ( )
%
/restore_popup {
  window.dialog

  dup .title "Restore popup title" put
  dup .text "Going to restore.\nYou're sure?" put
  dup .buttons [
    button.ok button.default actRestore button.setaction
    button.cancel button.notdefault actNothing button.setaction
    config.rtl { exch } if
  ] put
  dup window.init
      window.show

} def


