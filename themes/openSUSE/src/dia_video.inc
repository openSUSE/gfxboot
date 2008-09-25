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
  1024  600
  1024  768
  1280  800
  1280 1024
  1400 1050
  1600 1200
  1680 1050
  1920 1200
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
      dup .vm_mode get -2 eq vm_color_bits 8 ne and {
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

  % remove duplicates
  % (assumes text or vesa entry to be first)

  /video.modes.list
    [
      video.modes.list {
        dup .vm_mode get 0 gt {		% ensure it's not the first entry
          over .vm_width get over .vm_width get eq
          2 index .vm_height get 2 index .vm_height get eq and {
            free
          } if
        } if
      } forall
    ]
    video.modes.list free
  def

  % create mode strings

  /video.modes.text [
    video.modes.list {
      dup .vm_width get
      dup 0 eq {
        pop pop /txt_text_mode
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
  xmenu .xm_title /txt_video_mode put

  % select largest mode the monitor supports

  boot_failsafe 4 and { 0 0 } { monitorsize } ifelse
  exch 800 max exch 600 max		% at least 800x600

  % ATI quirk: avoid 1280x1024, older chips (<= 8MB, max res 1280x1024) use
  % interlaced there

  video.modes.list dup length 1 sub get
  dup .vm_width get 1280 eq exch .vm_height get 1024 eq and {
    video.memory 0x2000 le {
      video.oem "ATI " strstr 1 eq {
        exch 1024 min exch 768 min	% down to 1024x768
      } if
    } if
  } if 

  xmenu .xm_current -1 put

  -1
  video.modes.list {
    exch 1 add exch

    dup .vm_width get 4 index le
    over .vm_height get 4 index le and
    exch video.havesplash and {
      xmenu .xm_current 2 index put
    } if

  } forall
  pop

  pop pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update video mode.
%
% ( ) ==> ( )
%
/video.update {
  /xmenu xmenu.video def

  /window.action actRedrawPanel def
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


