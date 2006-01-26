% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Video mode selection dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
% video mode array fields
/.vm_mode   0 def
/.vm_width  1 def
/.vm_height 2 def

% We have kernel splash images for at least these sizes.
/video.splashsizes [
     0    0	% special: for text mode
     1    0	% special: for VESA mode
   800  600
  1024  768
  1280 1024
] def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Create sort key for video modes.
%
% ( vm_index )  ==> ( sort_index )
%
/vmsortindex {
  video.modes.list exch get
  dup
  .vm_width get 16 shl
  exch .vm_height get add
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Swap video mode entries.
% (Helper for video mode sorting.)
%
% ( vm_index_1 vm_index_2 )  ==> ( )
%
/vmsortexch {
  over video.modes.list exch get
  over video.modes.list exch get
  video.modes.list
  5 -1 roll rot put
  video.modes.list 3 1 roll put
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Check if we have a splash in that resolution.
%
% ( video_mode_list_entry ) ==> ( true|false )
%
/video.havesplash {
  false exch

  0 2 video.splashsizes length 1 sub {
    over over over
    .vm_height get rot .vm_width get rot video.splashsizes exch get eq
    rot 1 add video.splashsizes exch get rot eq and
    { exch pop true exch exit } if
  } for

  pop

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build video mode list.
%
% ( ) ==> ( )
%
/video.init {
  /xmenu.video .xm_size array def

  /xmenu xmenu.video def

  % build list of video modes
  /video.modes.list [
    [ -1 0 0 ]	% special: text mode
    [ -2 1 0 ]	% special: VESA mode (width = 1 to make it sort)

    % first, try 16 bit
    /vm_color_bits 16 def

    {
      0 1 videomodes {
        videomodeinfo dup .undef eq {
          pop pop pop pop
        } {
          [
            over 0xbfff and 6 2 roll
            0x4000 and			% fb support
            exch vm_color_bits eq and	% color bits
            over 600 ge and		% height >= 600
            2 index 800 ge and		% width >= 800
          { ] } { pop pop pop pop } ifelse
        } ifelse
      } for

      % no modes added? -> try 8 bit
      dup 0 get -2 eq vm_color_bits 8 ne and {
        /vm_color_bits 8 def
      } {
        exit
      } ifelse
    } loop

  ] def

  % sort video.modes.list

  video.modes.list length 3 gt {
    0 1 video.modes.list length 2 sub {
      dup 1 add 1 video.modes.list length 1 sub {
        over vmsortindex over vmsortindex gt {
          over over vmsortexch
        } if
        pop
      } for
      pop
    } for
  } if

  % create mode strings

  /video.modes.text [
    video.modes.list {
      dup .vm_width get
      dup 0 eq {
        pop pop "Text Mode"
      } {
        dup 1 eq {
          pop pop "VESA"
        } {
          exch .vm_height get exch "%d x %d" 32 string dup 5 1 roll sprintf
        } ifelse
      } ifelse
    } forall
  ] def

  % add to menu

  xmenu .xm_list video.modes.text put

  % select largest mode the monitor supports

  monitorsize exch 800 max exch 600 max		% at least 800x600

  xmenu .xm_current -1 put
  video.modes.list {
    dup .vm_width get 3 index le
    over .vm_height get 3 index le and
    exch video.havesplash and {
      xmenu .xm_current over over get 1 add put
    } {
      exit
    } ifelse

  } forall

  pop pop

  pmenu.init
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update video mode.
%
% ( ) ==> ( )
%
/video.update {
  /xmenu xmenu.video def

  /window.action actRedrawPanel def

  pmenu.update
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show video menu.
%
% ( ) => ( )
%
/panel.video {
  "videomode" help.setcontext

  window.xmenu
  dup .xmenu xmenu.video put
  dup .xmenu.update /video.update put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of video entry.
%
% ( ) => ( width )
%
/panel.video.width {
  /xmenu xmenu.video def

  pmenu.width
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.video.update {
  /xmenu xmenu.video def

  pmenu.panel.update
} def


