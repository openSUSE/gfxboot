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
/panel.dud {
  do_driverupdate .undef eq {
    /do_driverupdate 1 def
    1 updatedisk
    black setcolor
    currentfont font.normal setfont
    update.pos moveto currentpoint
    prog_frame_color dup prog_frame_color2
    update.text strsize 6 add exch 16 add exch
    drawborder3
    moveto 8 3 rmoveto update.text white setcolor show
    setfont
  }
  {
    /do_driverupdate .undef def
    0 updatedisk
    update.pos moveto currentpoint
    update.text strsize 7 add exch 17 add exch
    image
  } ifelse

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


