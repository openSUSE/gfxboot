% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Driver update dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show driver update.
%
% ( ) => ( )
%
/dud.redraw {
  update.pos exch pop 0 exch moveto currentpoint
  txt_dud_ready strsize 7 add exch pop clip.size pop exch
  image

  do_driverupdate {
    black setcolor
    currentfont font.normal setfont
    update.pos moveto currentpoint
    frame_color dark_frame_color
    txt_dud_ready strsize 6 add exch 16 add exch
    drawborder4
    moveto 8 3 rmoveto txt_dud_ready white setcolor show
    setfont
  } if
} def

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Toggle driver update.
%
% ( ) => ( )
%
/panel.dud {
  do_driverupdate .undef eq {
    /do_driverupdate 1 def
    1 updatedisk
  }
  {
    /do_driverupdate .undef def
    0 updatedisk
  } ifelse

  dud.redraw

  "driverupdate" help.setcontext
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of driver update entry.
%
% ( ) => ( width )
%
/panel.dud.width {
  txt_driver_update strsize pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.dud.update {
  panel.text.moveto

  txt_driver_update show
} def


