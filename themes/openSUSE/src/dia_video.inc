% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Video mode selection dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
% video mode array fields
/.vm_mode    0 def
/.vm_flags   1 def
/.vm_options 2 def
/.vm_label   3 def
/.vm_width   4 def
/.vm_height  5 def

% .vm_flags:
% 
% bit 0: is vbe mode
%     1: supported display res
%

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

% position of smode menu
/.video_smode_menu 3 def

% buffer for translated menu string
/video.submenu.smode.buf 64 string def
/video.submenu.smode {
  xmenu.smode .xm_title get exec "\x09\x09%s" video.submenu.smode.buf sprintf
  video.submenu.smode.buf
} def


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
% Check if display supports that resolution.
%
% ( video_mode_list_entry ) ==> ( true|false )
%
/video.resok {
  false exch

  0 2 video.res length 1 sub {
    over over over
    .vm_height get rot .vm_width get rot video.res exch get eq
    rot 1 add video.res exch get rot eq and
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

  "ddc" findfile test1
  /video.res [ displaysizes ] def

  % build list of video modes
  /video.modes.list [
    [ -1 0 "textmode=1" /txt_text_mode     0 0 ]	% special: text mode
    [ -2 0 "nomodeset"  /txt_video_no_kms  1 0 ]	% special: no KMS (width = 1 to make it sort)
    [ -3 0 ""           /txt_kernel_default 2 0 ]	% special: no video options (width = 2 to make it sort)
    % position must agree to .video_smode_menu!
    [ -4 0 ""           /video.submenu.smode 3 0 ]	% special: smode menu

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
            over 576 ge and		% height >= 576
            2 index 1024 ge and		% width >= 1024
          { 1 "" "" 5 -2 roll ] } { pop pop pop pop } ifelse
        } ifelse
      } for

      % no modes added? -> try 8 bit
      dup .vm_mode get -2 eq vm_color_bits 8 ne and {
        /vm_color_bits 8 def
      } {
        exit
      } ifelse
    } loop

    % add display sizes

    video.res length {
      0 2 video.res length 1 sub {
        [
          exch 0 2 "" "" 5 -1 roll
          video.res over get exch video.res exch 1 add get
        ]
      } for
    } if

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
        dup .vm_mode get 0 ge {		% ensure it's not the first entry
          over .vm_width get over .vm_width get eq
          2 index .vm_height get 2 index .vm_height get eq and {
            over .vm_mode get over .vm_mode get max 2 index .vm_mode rot put
            over .vm_flags get over .vm_flags get or 2 index .vm_flags rot put
            free
          } if
        } if
      } forall
    ]
    video.modes.list free
  def

  % create mode strings & menu labels

  true

  video.modes.list {
    dup .vm_flags get 3 and {
      dup .vm_options 64 string put
      dup .vm_label 32 string put

      % add separating line before first entry
      over {
        dup .vm_label get "\x09" exch sprintf
        exch pop false exch
      } if

      dup .vm_flags get 1 and {
        dup .vm_mode get 0x200 add over .vm_options get "vga=0x%x " exch sprintf
      } if

      dup .vm_flags get 2 and {
        dup .vm_height get over .vm_width get 2 index .vm_options get "video=%dx%d " exch dup length add sprintf
      } if

      dup .vm_flags get 2 and 0 eq {
        dup .vm_label get "\x01" exch dup length add sprintf
      } if

      dup .vm_height get over .vm_width get 2 index .vm_label get "%d x %d" exch dup length add sprintf
    } if

    pop
  } forall

  pop

  % create menu

  /video.modes.text [
    video.modes.list { .vm_label get } forall
  ] def

  % add to menu

  xmenu .xm_list video.modes.text put
  xmenu .xm_title /txt_video_mode put

  % select largest mode the monitor supports

  boot_failsafe 4 and { 0 0 } { monitorsize } ifelse
  exch 1024 max exch 768 max		% at least 1024x768

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

  % 'default' entry
  xmenu .xm_current 2 put

  -1
  video.modes.list {
    exch 1 add exch

    dup .vm_width get 4 index le
    exch .vm_height get 3 index le and {
      xmenu .xm_current 2 index put
    } if

  } forall
  pop

  % FIXME: force 'default' entry
  xmenu .xm_current 2 put

  pop pop

  % needed because menu is only attached to video menu - it must be initialized somewhere
  smode.init
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update video mode.
%
% ( ) ==> ( )
%
/video.update {
  /xmenu xmenu.video def

  xmenu .xm_current get .video_smode_menu eq {
    xmenu .xm_current over .xm_last get put
    panel.smode
  } {
    /window.action actRedrawPanel def
  } ifelse
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

  % set location of smode menu
  xmenu.smode .xm_panel_x xmenu.video .xm_panel_x get put
} def


