% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Video mode selection dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
% video mode array fields (as returned by getvideomode)
/.vm_mode   0 def
/.vm_width  1 def
/.vm_height 2 def
/.vm_ok     3 def	% monitor supports it

% We have kernel splash images for at least these sizes.
/video.splashsizes [
   640  480
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

  % test for modes we want
  % ( with height ) => ( true|false )
  /video.supported {
    false
    2 index 640 eq 2 index 480 eq and or
    2 index 800 eq 2 index 600 eq and or
    exch pop exch pop
  } def 

  % build mode list
  /video.modes.list [
    % text mode
    [ 0 0 0 1 ]
    % fb modes
    videomodes 0 gt {
      0 1 videomodes 1 sub { 
        dup getvideomode pop rot pop video.supported { [ exch getvideomode ] } { pop } ifelse
      } for
    } if
  ] def

  % array for menu labels
  /video.modes.text video.modes.list length array def

  % insert labels into menu
  xmenu .xm_list video.modes.text put 

  % always accept 800x600

  video.modes.list {
    dup .vm_width get 800 eq
    over .vm_height get 600 eq
    and { .vm_ok 1 put } { pop } ifelse
  } forall

  % sort video.modes.list

  video.modes.list length 1 gt {
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

  0 1 video.modes.list length 1 sub {
    video.modes.text exch
    dup video.modes.list exch get
    dup .vm_width get 0 eq {
      pop "Text Mode" put
    } {
      32 string dup rot
      dup .vm_height get exch .vm_width get
      "%d x %d" 4 -1 roll sprintf
      put
    } ifelse
  } for

  % select first mode
  xmenu .xm_current 0 put

  % select largest mode the monitor supports

  0 1 video.modes.list length 1 sub {
    video.modes.list over get
    dup .vm_ok get 0 gt exch video.havesplash and {
      xmenu .xm_current rot put
    } {
      pop
    } ifelse
  } for

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


