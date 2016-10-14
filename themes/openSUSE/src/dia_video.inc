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

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Create sort key for video modes.
%
% ( vm_index -- sort_index )
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
% ( vm_index_1 vm_index_2 -- )
%
/vmsortexch {
  over video.modes.list exch get
  over video.modes.list exch get
  video.modes.list
  5 -1 roll rot put
  video.modes.list 3 1 roll put
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Initialize video mode menu and its submenus.
%
% ( -- )
%
/video.init {
  /xmenu.video .xm_size array def

  /xmenu xmenu.video def

  % for testing, you can inject a DDC data blob
  "ddc" findfile test1

  % Display resolutions that should be offered besides those the VESA BIOS knows.
  %
  % The reason is that the VESA BIOS list is often rather limited and e.g. omits
  % 16:10 or 16:9 modes.
  %
  % You can add whatever you want here; duplicates will be removed later.
  /video.res [
    % the actually detected display size(s)
    displaysizes

    % add anything that crosses your mind
    1024 768
    1680 1050
    1920 1080
    1920 1200
  ] def

  % Build list of VESA BIOS modes.
  %
  % Each mode is an array with .vm_* entries (see top of file).
  /video.modes.list [

    % add VBE modes >= 1024 x 576

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
      dup [ eq vm_color_bits 8 ne and {
        /vm_color_bits 8 def
      } {
        exit
      } ifelse
    } loop

    % add any extra modes

    video.res length {
      0 2 video.res length 1 sub {
        [
          exch 0 2 "" "" 5 -1 roll
          video.res over get exch video.res exch 1 add get
        ]
      } for
    } if

  ] def

  % sort video mode list (by display width, then height)

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

  /video.modes.list
    [
      /tmp_is_first true def
      video.modes.list {
        % if it's the 1st entry, just keep it
        % else, add a new entry only if different
        tmp_is_first {
          /tmp_is_first false def
        } {
          over .vm_width get over .vm_width get eq
          2 index .vm_height get 2 index .vm_height get eq and {
            over .vm_mode get over .vm_mode get max 2 index .vm_mode rot put
            over .vm_flags get over .vm_flags get or 2 index .vm_flags rot put
            free
          } if
        } ifelse
      } forall
    ]
    video.modes.list free
  def

  % create menu labels ("width x height")

  video.modes.list {
    dup .vm_label 32 string put
    dup .vm_height get over .vm_width get 2 index .vm_label get "%d x %d" exch dup length add sprintf

    pop
  } forall

  % build submenus

  % installer resolutions (set via 'xmode' option)
  /video.modes.installer [
    [ -1 0 ""           /txt_kernel_default 0 0 ]

    video.modes.list { } forall
  ] def

  % kms text console resolutions (set via 'video' option)
  /video.modes.console [
    [ -1 0 ""           /txt_kernel_default 0 0 ]
    [ -2 0 "nomodeset"  /txt_video_no_kms   0 0 ]

    video.modes.list { } forall
  ] def

  % VESA BIOS framebuffer mode (set via 'VGA' option)
  %
  % Not every mode is a VESA BIOS mode - see video.res comment above.
  /video.modes.bios [
    [ -1 0 ""           /txt_kernel_default 0 0 ]

    video.modes.list {
      % keep only modes with VBE mode number
      dup .vm_mode get 0 eq { pop } if
    } forall
  ] def

  % construct the 3 screen size submenus

  % Note: as we have separation lines, attach empty arrays to .xm_attr field.

  /xmenu.video.installer .xm_size array def
  /xmenu.video.console .xm_size array def
  /xmenu.video.bios .xm_size array def

  xmenu.video.installer .xm_list [ video.modes.installer { .vm_label get } forall ] put
  xmenu.video.installer .xm_attr xmenu.video.installer .xm_list get length array put
  % line above 2nd entry
  xmenu.video.installer .xm_attr get 1 1 put
  xmenu.video.installer .xm_title "Installer Size" put
  xmenu.video.installer .xm_current 0 put

  xmenu.video.console .xm_list [ video.modes.console { .vm_label get } forall ] put
  xmenu.video.console .xm_attr xmenu.video.console .xm_list get length array put
  % line above 3rd entry
  xmenu.video.console .xm_attr get 2 1 put
  xmenu.video.console .xm_title "Text Console Size" put
  xmenu.video.console .xm_current 0 put

  xmenu.video.bios .xm_list [ video.modes.bios { .vm_label get } forall ] put
  xmenu.video.bios .xm_attr xmenu.video.bios .xm_list get length array put
  % line above 2nd entry
  xmenu.video.bios .xm_attr get 1 1 put
  xmenu.video.bios .xm_title "Video BIOS Size" put
  xmenu.video.bios .xm_current 0 put

  % create screen mode submenu

  /xmenu.video.hc .xm_size array def
  xmenu.video.hc .xm_list [ "Default" "High Contrast" "White on Black" "Cyan on Black" ] put
  xmenu.video.hc .xm_title "Color Mode" put
  xmenu.video.hc .xm_current 0 put

  % now build the video mode menu out of the submenus above

  /video.submenu.list [
    xmenu.video.installer
    xmenu.video.console
    xmenu.video.bios
    .undef
    xmenu.video.hc
    .undef
  ] def

  xmenu .xm_list [
    "Installer Size"
    "Text Console Size"
    "Video BIOS Size"
    /txt_text_mode
    "Color Mode"
    "Screen Reader"
  ] put

  % As we have checkmarks, attach empty array to menu to hold checkmark states.
  /video.checkmarks xmenu .xm_list get length array def

  % keep track where checkmarks are
  /vm.text_mode.idx 3 def
  /vm.screen_reader.idx 5 def

  % set initial values
  video.checkmarks vm.text_mode.idx false put
  video.checkmarks vm.screen_reader.idx false put

  % attach checkmark array to menu
  xmenu .xm_checkmarks video.checkmarks put

  % attach submenu array to menu
  xmenu .xm_submenus video.submenu.list put

  % we also need an array for separation line positions...
  xmenu .xm_attr xmenu .xm_list get length array put

  % line before 4th entry ("text mode")
  xmenu .xm_attr get 3 1 put

  % screen reader entry needs a callback when state is changed
  % (will call video.speak)
  xmenu .xm_attr get vm.screen_reader.idx 0x100 put

  xmenu .xm_title /txt_video_mode put

  % 'default' entry
  xmenu .xm_current 0 put
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update video mode.
%
% Called when a video mode entry is selected.
%
% ( -- )
%
/video.update {
  /xmenu xmenu.video def

  video.submenu.list xmenu .xm_current get get dup {
    video.submenu
    /window.action actRedrawPanel def
  } {
    pop
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show video menu.
%
% ( -- )
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
% Called to calulate panel layout.
%
% ( -- width )
%
% Note: we need to do some tricks here as we want to show the 'installer
% size' in the panel. So we switch to the xmenu.video.installer menu
% temporarily. But we need to keep the original menu title.
%
/panel.video.width {
  /tmp_title xmenu.video.installer .xm_title get def
  xmenu.video.installer .xm_title xmenu.video .xm_title get put

  /xmenu xmenu.video.installer def

  pmenu.width

  xmenu.video.installer .xm_title tmp_title put

  /xmenu xmenu.video def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel -- )
%
% Note: we need to do some tricks here as we want to show the 'installer
% size' in the panel. So we switch to the xmenu.video.installer menu
% temporarily. But we need to keep the original menu title.
%
/panel.video.update {
  /tmp_title xmenu.video.installer .xm_title get def
  xmenu.video.installer .xm_title xmenu.video .xm_title get put

  /xmenu xmenu.video.installer def

  pmenu.panel.update

  xmenu.video .xm_panel_x xmenu.video.installer .xm_panel_x get put

  xmenu.video.installer .xm_title tmp_title put

  /xmenu xmenu.video def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Switch to submenu.
%
% ( submenu -- )
%
/video.submenu {
  % set location of submenu to that of main menu
  dup .xm_panel_x xmenu.video .xm_panel_x get put

  % we don't have anything better yet
  "videomode" help.setcontext

  window.xmenu
  dup .xmenu 4 -1 roll put
  dup .xmenu.update /video.submenu.update put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% What to do when submenu is closed.
%
% ( -- )
%
/video.submenu.update {
  /window.action actRedrawPanel def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Get current high contrast setting.
%
% This returns the string to add to the boot options (or .undef if nothing
% should be added).
%
% ( -- string )
%
/video.hc.current {
  xmenu.video.hc .xm_current get
  % 0 = default
  dup 0 gt {
    [ "" "highcontrast" "white-black" "cyan-black" ] exch get "screenmode=%s" video.hc.current.buf sprintf
    video.hc.current.buf
  } {
    pop .undef
  } ifelse
} def
% static buffer for return value
/video.hc.current.buf 64 string def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Get current text mode setting.
%
% This returns the string to add to the boot options (or .undef if nothing
% should be added).
%
% ( -- string )
%
/video.textmode.current {
  video.checkmarks vm.text_mode.idx get {
    "textmode=1"
  } {
    .undef
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Get current kms setting.
%
% This returns the string to add to the boot options (or .undef if nothing
% should be added).
%
% ( -- string )
%
/video.kms.current {
  xmenu.video.console .xm_current get
  % 0 = default
  dup 0 eq {
    pop .undef
  } {
    video.modes.console exch get
    dup .vm_options get "" ne {
      .vm_options get
    } {
      dup .vm_width get exch .vm_height get "video=%dx%d" video.kms.current.buf sprintf
      video.kms.current.buf
    } ifelse
  } ifelse
} def
% static buffer for return value
/video.kms.current.buf 64 string def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Get current installer size setting.
%
% This returns the string to add to the boot options (or .undef if nothing
% should be added).
%
% ( -- string )
%
/video.installer_size.current {
  xmenu.video.installer .xm_current get
  % 0 = default
  dup 0 eq {
    pop .undef
  } {
    video.modes.installer exch get
    dup .vm_width get exch .vm_height get "xvideo=%dx%d" video.installer_size.current.buf sprintf
    video.installer_size.current.buf
  } ifelse
} def
% static buffer for return value
/video.installer_size.current.buf 64 string def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Get current VESA BIOS setting.
%
% This returns the string to add to the boot options (or .undef if nothing
% should be added).
%
% ( -- string )
%
/video.vbe.current {
  xmenu.video.bios .xm_current get
  % 0 = default
  dup 0 eq {
    pop .undef
  } {
    video.modes.bios exch get
    .vm_mode get 0x200 add "vga=0x%x" video.vbe.current.buf sprintf
    video.vbe.current.buf
  } ifelse
} def
% static buffer for return value
/video.vbe.current.buf 64 string def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Callback function when screen reader entry is selected.
%
% Reads the current screen reader state and either activates or deactivates
% the reader.
%
% ( -- )
/video.speak {
  video.checkmarks vm.screen_reader.idx get {
    /v_impaired 1 def
    /config.talk true def
    load_talk_dialog
  } {
    /v_impaired 0 def
    /config.talk false def
  } ifelse
} def

