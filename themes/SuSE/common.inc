% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Main part.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% max command line length
/cmdlinelength 512 def

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Install source is 64bit?
%
% ( ) ==> ( true|false )
%
/64bit_source {
  % 64 bit dir exists and is != 32 bit dir
  64bit_boot_dir 32bit_boot_dir ne
  64bit_boot_dir .undef ne and
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Are we a dvd?
%
% ( ) ==> ( true|false )
%
/is_dvd {
  % check only once
  is_dvd.result .undef ne { is_dvd.result return } if

  /is_dvd.result
    mediatype m_cdrom eq {
      0x10 readsector
      dup 0x50 add getdword exch free
      9 shr % iso size in MB
      720 gt % assume dvd if > 720 MB
    } {
      false
    } ifelse
  def

  is_dvd.result return
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Install source is 32 & 64bit?
%
% ( ) ==> ( true|false )
%
/32+64bit_source {
  32bit_boot_dir .undef ne
  % uncomment next line to automatically warn about 32bit software on 64bit machines, too
  % 64bit_boot_dir .undef ne and
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Enough memory?
%
% ( ) ==> ( true|false )
%
/enough_mem {
  biosmem 4 20 shl lt
  biosmem mem.check 20 shl ge or
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Check if there are boot directories for 32 & 64bit.
%
% Assumes 32bit to be in *i386* and 64bit in *x86_64*.
%
% ( ) ==> ( )
%
/check_arch_boot_dir {
  getcwd dup .undef ne {
    /64bit.tmp 256 string def

    dup "i386" strstr 0 ne over "x86_64" strstr 0 ne or {
      dup "i386" strstr {
        /32bit_boot_dir exch def
        /64bit_boot_dir 32bit_boot_dir "i386" "x86_64" strreplace
      } {
        /64bit_boot_dir exch def
        /32bit_boot_dir 64bit_boot_dir "x86_64" "i386" strreplace
      } ifelse

      dup "%s/isolinux.cfg" 64bit.tmp sprintf
      64bit.tmp filesize .undef ne { def } { free pop } ifelse

    } {
      /32bit_boot_dir over def
      /64bit_boot_dir exch def
    } ifelse

    64bit.tmp free

    % font.normal setfont
    % 0 400 moveto 32bit_boot_dir print
    % 0 420 moveto 64bit_boot_dir print dtrace

  } {
    pop
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% input event handling
%
% ( key ) ==> ( input_buffer menu_entry action )
%
% key
%  bit 0-7	ascii
%  bit 8-15	scan code
%  bit 16-32	status bits (ctrl, shift...)
%
% action
%    0:		ok, stay in input loop
%    1:		switch to text mode
%  >=2:		start linux
%
/KeyEvent {
  % timeout

  dup 0 eq { boot.buf buildcmdline 2 return } if

  debug 4 ge {
    % print keycode somewhere
    -1 settransparentcolor
    black setcolor
    500 0 moveto dup print "  " print
  } if

  dup 0xff00 and 16 shl over 0xff and dup 0xe0 eq { pop 0 } if add /key exch def
  16 shr 0xffff and /keystat exch def

  key keyTab eq keyStatus statusShift and 0 ne and {
    /key keyShiftTab def
  } if

  key

  config.keymap { mapkey } if

  dup 0xffffff and dup { exch } if pop

  debug 4 ge {
    % print mapped key somewhere
    -1 settransparentcolor
    black setcolor
    500 20 moveto dup print "  " print
  } if

  ptheme {
    % reverse direction
    /p.xmas.dx p.xmas.dx neg def

    key keyF9 eq
    key keyF7 eq or {
      % call super penguin
      p.call.super
    } {
      key keyF1 ge
      key keyF10 le and {
        % read something
        /p.read.timer rand 0x31 and neg -30 add def
      } if
    } ifelse

  } if

  % some special keys
  debug.input

  % put key through normal input queue
  window.input

  pop

  window.action actExit eq {
    /window.action actNothing def
    "" -1 1 return
  } if

  window.action actCloseInfo eq {
    /window.action actNothing def
    % cd change dialog
    info.type 5 eq info.type 6 eq or {
      % 'chdir' triggers fs metadata re-read
      getcwd dup .undef ne { chdir } { pop } ifelse
    } if

    "" -1 3 return
  } if

  window.action actPassword eq {
    /window.action actNothing def
    password.dialog {
      password.dialog .ed.buffer.list get 0 get
    } { "" } ifelse
    -1 3 return
  } if

  window.action actStart eq
  window.action actReallyStart eq or {
    /really_start window.action actReallyStart eq def
    /window.action actNothing def
    /load_error false def

    syslinux really_start not and {
      menu.texts menu.entry 0 max menu.texts length 1 sub min get
      dup "mem.min[%s]" mem.min sprintf
      "mem.msg[%s]" mem.msg sprintf

      enough_mem not {
        nomem_popup
        boot.buf menu.entry 0 return
      } if

      menu.texts menu.entry get "restore" eq {
        restore_system
        "" -1 0 return
      } if
    } if

    % some tricks to make it possible to review the complete command line
    debug 3 ge xxx.cmdline .undef eq and {
      /window.action actNothing def

      boot.buf buildcmdline /xxx.menu exch def /xxx.cmdline exch def

      /dia window.dialog def
      dia .title "Kernel command line" put
      dia .text "" put
      % Must all be of same size!
      dia .ed.list 1 array put
      dia .ed.buffer.list [ xxx.cmdline ] put
      dia .ed.text.list [ "All options\n" ] put

      dia .ed.focus 0 put
      dia .ed.width 600 put
      dia .ed.font font.normal put
      dia .buttons
        [ button.ok button.default actStart button.setaction ]
      put
      dia window.init
      dia window.show

      boot.buf menu.entry 0
    } {
      xxx.cmdline .undef ne {
        xxx.cmdline xxx.menu
        /xxx.cmdline .undef def
      } {
        boot.buf buildcmdline
      } ifelse
      2 return
    } ifelse
  } if

  window.action actRedraw eq {
    /window.action actNothing def
    main.redraw
  } if

  window.action actRedrawPanel eq {
    /window.action actNothing def
    panel.show
  } if

  window.action actInstallOK eq {
    /window.action actNothing def
    install.ok
  } if

  window.action actInstallCancel eq {
    /window.action actNothing def
    install.cancel
  } if

  boot.buf menu.entry 0
} def


/bc.cmd cmdlinelength string def
/mem.min 128 string def
/mem.msg 256 string def

% ( option_string ) ==> ( cmdline menu_entry )
%
% grub:
%   just return
%
% syslinux & lilo:
%   check if the commmand line starts with the current kernel name or
%   "linux"; if not, put the kernel name in front of the command line. (This
%   is to keep compatibility with the old scheme requiring the user to write
%   the kernel name explicitly.)
%
/buildcmdline {
  menu.entry 0 lt { -1 return } if
  menu.entry menu.texts length ge { -1 return } if

  /bc.opts exch def
  /bc.kernel menu.texts menu.entry get def

  grub {

    /bc.addkernel false def

  } {

    /bc.addkernel true def

    [ bc.kernel "linux" ] 0 over length 1 sub 1 exch {
      over exch get

      bc.opts over eq {
        /bc.addkernel false def
      } {
        bc.opts over strstr 1 eq {
           bc.opts over length get ' ' eq {
             /bc.addkernel false def
           } if
        } if
      } ifelse

      pop

      bc.addkernel not { exit } if

    } for

    pop

    % special case: option is identical to label
    bc.kernel "apic" eq
    bc.kernel "noapic" eq or
    bc.kernel "nolapic" eq or {
      /bc.addkernel true def
    } if

  } ifelse

  syslinux {
    /add_suffix xmenu.bits .xm_current get bits.suffix exch get def

    % set new working directory
    xmenu.bits .xm_current get 1 eq { 64bit_boot_dir } { 32bit_boot_dir } ifelse
    dup .undef ne {
      dup getcwd ne { chdir } { pop } ifelse
    } {
      pop
    } ifelse
  } if

  % getcwd 0 300 moveto show trace

  bc.addkernel {
    alt.kernel { alt.kernel } { bc.kernel } ifelse
    dup "linux" eq add_suffix .undef ne and {
      add_suffix exch "%s%s "
    } {
      "%s "
    } ifelse
    bc.cmd sprintf
  } {
    bc.cmd 0 0 put
  } ifelse

  /add_suffix 32 string def

  syslinux {
    video.modes.list xmenu.video .xm_current get get
    dup .vm_mode get 0 ge {
      dup .vm_height get exch .vm_width get
      ",%04d%04d.spl" add_suffix sprintf
    } { pop } ifelse

    % find out splash size for kernel loading progress bar
    add_suffix 1 add filesize dup .undef ne {
      sectorsize 1 sub add sectorsize div /progress_extra exch def
    } {
      pop
      add_suffix 0 0 put	% empty string
    } ifelse
  } if

  cmdline.hidden "" ne {
    add_suffix {
      /bc.tmp cmdline.hidden length add_suffix length add string def
      cmdline.hidden "initrd" bootopt.find dup .undef ne {
        skipnonspaces
        dup
        dup 0 get over 0 0 put
        add_suffix cmdline.hidden "%s%s" bc.tmp sprintf
        0 exch put
        "%s" bc.tmp dup length add sprintf
      } {
        pop
        bc.tmp cmdline.hidden strcpy pop
      } ifelse

      bc.tmp "%s " bc.cmd dup length add sprintf

      bc.tmp free /bc.tmp .undef def
    } {
      cmdline.hidden "%s " bc.cmd dup length add sprintf
    } ifelse

    syslinux {
      % find out initrd size for kernel loading progress bar
      "initrd" filesize dup .undef ne {
        sectorsize 1 sub add sectorsize div /progress_extra exch progress_extra add def
      } {
        pop
      } ifelse
    } if
  } if

  syslinux {
    video.modes.list xmenu.video .xm_current get get .vm_mode get

    dup 0 ge {
      0x200 add "vga=0x%x " bc.cmd dup length add sprintf
    } {
      -1 eq {
        "textmode=1 " bc.cmd dup length add sprintf
      } if
    } ifelse

    config.lang {
      config.lang "en" ne {
        config.lang
          dup "af" eq { pop "af_ZA" } if
          dup "ca" eq { pop "ca_ES" } if
          dup "cy" eq { pop "cy_GB" } if
          dup "et" eq { pop "et_EE" } if
          dup "gu" eq { pop "gu_IN" } if
          dup "hi" eq { pop "hi_IN" } if
          dup "hr" eq { pop "hr_HR" } if
          dup "lt" eq { pop "lt_LT" } if
          dup "mr" eq { pop "mr_IN" } if
          dup "pa" eq { pop "pa_IN" } if
          dup "sr" eq { pop "sr_CS" } if
          dup "ta" eq { pop "ta_IN" } if
          dup "tr" eq { pop "tr_TR" } if
          dup "vi" eq { pop "vi_VN" } if
          dup "xh" eq { pop "xh_ZA" } if
          dup "zu" eq { pop "zu_ZA" } if
        "lang=%s " bc.cmd dup length add sprintf
      } if
    } if

  } if

  xmenu.dud {
    xmenu.dud .xm_current get .dud_file eq {
      input.edit.dud_file 0 get dup "" ne {
        "driverupdate=%s " bc.cmd dup length add sprintf
      } { pop } ifelse
    } {
      dud.options xmenu.dud .xm_current get get dup "" ne {
        "%s " bc.cmd dup length add sprintf
      } { pop } ifelse
    } ifelse
  } if

  xmenu.profile {
    profile.options xmenu.profile .xm_current get get dup "" ne {
      "%s " bc.cmd dup length add sprintf
    } { pop } ifelse
  } if

  xmenu.install {
    install.option "" ne {
      install.option "%s " bc.cmd dup length add sprintf
    } if
  } if

  % complete cmdline
  bc.cmd bc.opts strcat " " strcat pop

  % remove all but last 'vga' option
  {
    bc.cmd "vga" bootopt.find2 .undef eq { exit } if
    bc.cmd "vga" bootopt.remove free
  } loop

  bc.cmd "driverupdate" bootopt.find dup .undef ne {
    % exclude 'driverupdate=0 and driverupdate=1'
    "driverupdate=" length get
    dup '0' ne exch '1' ne and {

      /bc.tmp bc.cmd "driverupdate" bootopt.remove def
      bc.tmp .undef ne {
        /bc.tmp bc.tmp "driverupdate=" length add ',' split bc.tmp free def
        /bc.tmp2 cmdlinelength string def

        bc.tmp2 "initrd=" strcpy pop

        bc.tmp length 0 gt {
          % add '+' to first arg unless it starts with '+' or '-'
          bc.tmp 0 get 0 get
          dup '-' eq {	% remove '-'
            bc.tmp 0 get dup 1 add strdup exch free
            bc.tmp exch 0 exch put
            pop '+'
          } if
          '+' ne {		% add '+'
            bc.tmp 0 get length 1 add string "+" strcat bc.tmp 0 get strcat
            bc.tmp 0 get free bc.tmp exch 0 exch put
          } if

          bc.tmp length 1 sub -1 0 {
            bc.tmp exch get
            bc.tmp2 exch strcat "," strcat pop
          } for
        } if

        bc.tmp dup { free } forall free

        % last 'initrd' option
        /bc.tmp .undef def
        {
          bc.cmd "initrd" bootopt.remove dup .undef ne {
            bc.tmp free /bc.tmp exch def
          } {
            pop exit
          } ifelse
        } loop

        % re-add new 'initrd' option
        bc.tmp {
          bc.tmp2 bc.tmp "initrd=" length add strcat pop
          bc.tmp free
          bc.cmd bc.tmp2 strcat " " strcat pop
        } if
      } if

    } if
  } { pop } ifelse

  % remove final space
  bc.cmd dropspaces

  bc.cmd menu.entry
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( menu_entries_array cmdline_args_array defaultentry ) == > ( )
/MenuInit {
  bsplash.done

  colorbits 8 le {
    0 setcolor 0 0 moveto screen.size fillrect loadpalette
  } if

  init

  /menu.entry -1 def

  /menu.dentry exch def
  /menu.args exch def
  /menu.texts exch def

  window.main
  dup window.init
      window.show

  syslinux {
    32+64bit_source not {

      64bit {
        64bit_source not { notimeout 32bit_popup } if
      } {
        64bit_source { notimeout 64bit_popup } if
      } ifelse

    } if
  } if

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Setup boot option input field.
%
% ( ) == > ( )
%
/bootoptions.init {
  window.current .color.fg get setcolor
  window.current .ed.font get setfont

  boot.ed edit.hidecursor
  menu.args menu.entry get
  menu.texts menu.entry get
  bootpromptmap

  boot.show {
    boot.ed over edit.init
    "" ne { boot.ed ' ' edit.input } if
  } {
    "%s" boot.ed 3 get sprintf
  } ifelse

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Split command line into hidden and normal part.
%
% ( cmdline_args menu_text ) == > ( new_cmdline_args )
%
% alt.kernel is set if a different kernel should be used (this feature should
% no longer be needed).
%
/bootpromptmap {
  /alt.kernel .undef def

  syslinux {
    dup "failsafe" eq
    over "noacpi" eq or
    over "noapic" eq or
    over "nolapic" eq or
    over "apic" eq or
    over "manual" eq or
    over "rescue" eq or
    { /alt.kernel "linux" def } if
  } if

  pop

  /cmdline exch def

  cmdline "showopts" getoption
  dup "" eq {
    cmdline.shown 0 0 put
    pop cmdline "%s" cmdline.shown sprintf
    cmdline.hidden 0 0 put
  } {
    "showopts" length add skipspaces
    "%s" cmdline.shown sprintf
    cmdline "%s" cmdline.hidden sprintf
    cmdline.hidden "showopts" getoption 0 0 put
  } ifelse

  cmdline.shown dropspaces
  cmdline.hidden dropspaces

  cmdline.shown
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Get boot option.
%
% ( cmdline option_name ) ==> ( option_start )
%
/getoption {
  /go.name exch def
  /go.cmdline exch def
  /go.pos 0 def
  {
    go.cmdline go.pos add go.name strstr dup {
       1 sub /go.pos exch def

       go.cmdline go.pos iswordboundary
       go.cmdline go.pos go.name length add iswordboundary
       and {
         go.cmdline go.pos add exit
       } {
         /go.pos go.pos 1 add def
       } ifelse
    } {
      pop "" exit
    } ifelse
  } loop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/redrawmenu {
  menu.text.normal setcolor

  /x menu.start.x def
  /y menu.start.y def

  0 1 menu.visible.entries 1 sub {
   x y moveto currentpoint menu.bar.width menu.bar.height image
   x menu.text.xofs add y menu.text.yofs add moveto
   menu.texts exch menu.shift add get menuitemmap
   currentfont exch font.large setfont show setfont
   /y y menu.item.height add def
  } for

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( entry status ) ==> ( )
%
% status:
%  false	not selected
%  true		selected
%
/MenuSelect {
  /menu.status exch def

  /menu.idx over def

  menu.shift sub
  menu.item.height mul menu.start.y add
  menu.start.x exch
  moveto

  currentpoint
  menu.status {
    menu.bar.color setcolor
    currenttransparency
    ptheme { 120 } { 70 } ifelse settransparency
    menu.bar.width menu.bar.height
    fillrect
    settransparency
  } {
    currentpoint menu.bar.width menu.bar.height image
  } ifelse
  moveto

  menu.text.xofs menu.text.yofs rmoveto
  menu.status {
    menu.text.select
  } {
    menu.text.normal
  } ifelse
  setcolor
  menu.texts menu.idx get menuitemmap
  currentfont exch font.large setfont show setfont

  menu.status {
    % init boot options
    keepbootoptions .undef eq { bootoptions.init } if

    % set help context
    "main" help.setcontext
    menu.texts menu.idx get
    dup help.findpage "" eq {
      pop
    } {
      help.setcontext
    } ifelse
  } if

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( text errorcode ) ==> ( )
% errorcode:
%   0	normal info
%   1	fatal error
%   2	missing file
%   3   disk change
%   4   disk change failed
%   5   ask for cd change
%   6   change cd back to original
%

/info.tmpmsg 256 string def

/InfoBoxInit {
  /info.type exch def
  /info.msg exch def

  window.dialog

  info.type 1 eq {
    dup .title.bg red put
    dup .title txt_error_title put
    dup .buttons
    [
      button.reboot button.default actCloseInfo button.setaction
    ] put
  } {
    dup .title txt_info_title put
    dup .buttons
    [
      button.ok button.default actCloseInfo button.setaction
%      button.cancel button.notdefault actCloseInfo button.setaction
    ] put
  } ifelse

  syslinux info.type 2 eq and {
    dup .title "I/O Error" put
    info.msg "File not found: %s" info.tmpmsg sprintf
    /info.msg info.tmpmsg def
    /load_error true def
  } if

  syslinux info.type 3 eq and {
    dup .title txt_change_disk_title put
    0 getinfo 1 add txt_insert_disk info.tmpmsg sprintf
    /info.msg info.tmpmsg def
  } if

  syslinux info.type 4 eq and {
    dup .title txt_change_disk_title put
    1 getinfo 15 not and {
      0 getinfo 1 add
      txt_insert_disk3 info.tmpmsg sprintf
    } {
      0 getinfo 1 add 1 getinfo 1 add
      txt_insert_disk2 info.tmpmsg sprintf
    } ifelse
    /info.msg info.tmpmsg def
  } if

  syslinux info.type 5 eq and {
    dup .title "Driver Update" put
    info.msg "Insert driver update CD-ROM for\n\"%s\"." info.tmpmsg sprintf
    /info.msg info.tmpmsg def
  } if

  syslinux info.type 6 eq and {
    dup .title "Driver Update" put
    /info.msg "Put the SUSE Linux CD-ROM back into the drive." def
  } if

  dup .text info.msg put

  dup window.init
      window.show

} def



% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% progress bar code


% Show percentage of progress bar.
%
% ( percentage ) ==> ( )
%
/progress.percent {
  0 max 100 min		% so people don't ask silly questions...
  "100%" strsize over neg progress.text.x add progress.text.y moveto
  window.current .color.bg get setcolor
  fillrect  

  "%3u%%" 8 dup string dup 5 1 roll snprintf

  dup strsize pop neg progress.text.x add progress.text.y moveto
  window.current .color.fg get setcolor
  dup show
  free

} def


% Show n-th progress bar symbol.
%
% ( n ) ==> ( )
%
/progress.sym.show {
  /progress.sym.current exch def

  progress.bar.x progress.bar.y moveto
  progress.sym.width progress.sym.current 1 sub mul 1 add 1 rmoveto
  progress.sym.width 2 sub
  progress.bar.height 2 sub
  loading_color setcolor
  fillrect

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( kernel_name ) ==> ( )
/ProgressInit {
  /progress.kname exch def

  boot.ed edit.hidecursor

  /dia window.dialog def

  dia .width.min 330 put
  dia .position 10 put

  dia .title txt_load_kernel_title put
  dia .text
    progress.kname "memtest" eq {
      txt_load_memtest
    } {
      txt_load_kernel
    } ifelse
  put

  dia window.init
  dia window.show

  % now add progress bar

  dia .x get dia .y get moveto
  dia .text.x get dia .text.y get 28 add rmoveto

  /progress.bar.height 19 def
  /progress.bar.width dia .width get 60 sub def

  /progress.sym.width 10 def
  /progress.bar.width
    progress.bar.width progress.sym.width div
    /progress.syms over def progress.sym.width mul
  def

  currentpoint over 1 sub over 2 sub moveto
  black white progress.bar.width 2 add progress.bar.height 4 add drawborder

  /progress.bar.y exch def
  /progress.bar.x exch def

  /progress.text.x progress.bar.x progress.bar.width 37 add add def
  /progress.text.y progress.bar.y progress.bar.height fontheight sub 2 div add def

  /progress.sym.current 0 def

  0 progress.percent

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( ) ==> ( )
/ProgressDone {
  window.done

  load_error {
    /load_error false def
    boot.ed edit.showcursor
  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( max current ) ==> ( )
%
% Note: max is just kernel size (in sectors).
%
/ProgressUpdate {
  exch progress_extra add exch

  over over 100 mul exch 1 max div progress.percent

  progress.syms mul progress.syms 2 div add exch 1 max div

  0 max progress.syms min

  dup progress.sym.current gt {
    progress.sym.current 1 add over 1 exch {
      progress.sym.show
    } for
  } if
  pop

} def

% initrd size (in sectors)
/progress_extra 0 def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( time ) ==> ( )
% /Timer { pop } def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( label correct_password ) ==> ( )
%
/PasswordInit {
  /password.key exch def pop

  /dia window.dialog def

  /password.dialog dia def

  dia .title txt_password_title put
  dia .text "" put

  % Must all be of same size!
  dia .ed.list 1 array put
  dia .ed.buffer.list [ 31 string ] put
  dia .ed.text.list [ txt_password ] put

  dia .ed.focus 0 put

  dia .ed.width 200 put

  dia .ed.font font.normal pwmode put

  dia .buttons
    [ button.ok button.default actPassword button.setaction ]
  put

  dia window.init
  dia window.show

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( password ) ==> ( error )
%
% error:
%   true   password ok
%   false  wrong password
%
% ****** FIXME: test result seems to be unused
%
/PasswordDone {

  password.key eq
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( text ) == > ( new_text )
/menuitemmap {
  translate
  dup "memtest" eq over "memtest86" eq or { pop txt_memtest return } if
  syslinux {
    livecd {
      dup "linux"     eq { pop "SUSE Linux 10.1 LiveCD (english)" return } if
      dup "failsafe"  eq { pop "LiveCD - Safe Settings" return } if
      dup "linux2"    eq { pop "SUSE Linux 10.1 LiveCD (deutsch)" return } if
      dup "failsaf2"  eq { pop "LiveCD - Sichere Einstellungen" return } if
      dup "kde"       eq { pop "LiveCD - KDE" return } if
      dup "gnome"     eq { pop "LiveCD - GNOME" return } if
    } {
      dup "linux"     eq { pop txt_install        return } if
      dup "failsafe"  eq { pop txt_safe_install   return } if
    } ifelse
    dup "live"      eq { pop "SUSE Linux 10.1 LiveCD" return } if
    dup "noacpi"    eq { pop txt_noacpi_install return } if
    dup "noapic"    eq { pop txt_noapic_install return } if
    dup "nolapic"    eq { pop txt_nolapic_install return } if
    dup "apic"      eq { pop txt_apic return } if
    dup "manual"    eq { pop txt_manual_install return } if
    dup "rescue"    eq { pop txt_rescue         return } if
    dup "hwcheck"   eq { pop "Hardware Check"   return } if
    dup "harddisk"  eq { pop txt_boot_harddisk  return } if
    dup "restore"   eq { pop "Restore System"   return } if
  } {
    dup "linux"     eq { pop "Linux"        return } if
    dup "failsafe"  eq { pop txt_safe_linux return } if
    dup "windows"   eq { pop "Windows"      return } if
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( color0 color1 width height ) ==> ( )
/drawborder {
  currentpoint /db.y0 exch def /db.x0 exch def

  /db.y1 exch 1 sub db.y0 add def
  /db.x1 exch 1 sub db.x0 add def
  /db.col1 exch def
  /db.col0 exch def

  db.x0 db.y1 moveto

  db.col0 setcolor
  db.x0 db.y0 lineto db.x1 db.y0 lineto

  db.col1 setcolor
  db.x1 db.y1 lineto db.x0 db.y1 lineto
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( color0 color1 color2 width height ) ==> ( )
% draw frame with shadow
% color0: upper left, color1: lower right, color2: shadow
/drawborder3 {
  currentpoint /db.y0 exch def /db.x0 exch def

  /db.y1 exch 1 sub db.y0 add def
  /db.x1 exch 1 sub db.x0 add def
  /db.col2 exch def
  /db.col1 exch def
  /db.col0 exch def

  db.x0 db.y1 moveto

  db.col0 setcolor
  db.x0 db.y0 lineto db.x1 db.y0 lineto

  db.col1 setcolor
  db.x1 db.y1 lineto db.x0 db.y1 lineto

  db.col2 -1 ne {
    db.col2 setcolor
    1 1 rmoveto
    db.x1 1 add db.y1 1 add lineto
    db.x1 1 add db.y0 1 add lineto
  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ( color0 color1 width height ) ==> ( )
/drawborder4 {
  3 index 4 1 roll rot dup 3 index 3 index
  currentpoint 6 2 roll
  1 1 rmoveto drawborder
  moveto drawborder
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% center text
% ( text width height ) ==> ( )
/centertext {
  3 -1 roll strsize
  4 2 roll
  4 1 roll exch 4 1 roll sub 2 div neg 3 1 roll sub 2 div neg
} def


% Allocate and define a new color.
%
% ( palette ) ==> ( color )
%
/newcolor {
  colorbits 8 le {
    newcolor.count .undef eq { /newcolor.count 0 def } if
    max_image_colors newcolor.count add
    dup rot setpalette
    /newcolor.count newcolor.count 1 add def
  } if
  def
} def


% ( img ) => ( width heigh )
/imgsize {
  dup .undef eq {
    pop 0 0
  } {
    getdword dup
    0xffff and exch 16 shr
  } ifelse
} def


% ( pic pic_a -- )
/showlogo {
  /tmp.sc over imgsize savescreen def

  currentpoint 4 2 roll
  0 0 moveto tmp.sc blend
  moveto tmp.sc restorescreen

  tmp.sc free
} def


% ( file_name ) ==> ( image )
/readimage {
  findfile dup .undef ne {
    dup setimage 0 0 image.size unpackimage exch free
  } if
} def


/init {
  0 0 moveto currentpoint clip.size image

  ptheme { ptheme.init } if

  % set default language
  "lang" findfile dup {
    /tmp over length 1 add 2 max string def
    tmp exch {
      dup ' ' eq over '\n' eq or { pop pop exit } if
      over exch 0 exch put
      1 add
    } forall
    tmp 2 0 put % only short locale name
    tmp dup setlang pop setkeymap
  } {
    pop
    "en" dup setlang pop setkeymap
  } ifelse

  font.large setfont

  /menu.text.xofs      10 def
  /menu.text.yofs       2 def
  /menu.item.height    fontheight dup ptheme { 2 } { 2 } ifelse div add def
  /menu.bar.height     fontheight menu.text.yofs dup add add def

  font.normal setfont

  /menu.text.normal    white             def
  /menu.text.select    black             def
  /boot.text.options   white             def
  /boot.text.normal    white             def
  /infobox.bg          lightgray         def
  /infobox.text.normal black             def

  /menu.bar.color      white       def

  small_layout {
    /frame1.pos  { 120 110 } def
    /frame1.width  400 def
  } {
    /frame1.pos  { 200 192 } def
    /frame1.width  425 def
  } ifelse

  ptheme {
    /frame1.pos  { 210 170 } def
    /frame1.width  365 def
  } if

  /menu.start.x frame1.pos pop 10 add def
  /menu.start.y frame1.pos exch pop 12 add def

  /menu.bar.width frame1.width 20 sub def
  /menu.max.entries 7 def

  /boot.label.len 252 def

  /boot.pos { boot.label.len 10 add ptheme { 480 } { small_layout { 380 } { 490 } ifelse } ifelse } def

  /boot.buf.size cmdlinelength def
  /boot.buf boot.buf.size string def

  % false: no boot options line initially
  /boot.show true def

  /update.pos {
    clip.size pop txt_dud_ready strsize pop sub ptheme { 60 } { 20 } ifelse sub
    clip.size exch pop ptheme { 100 } { 75 } ifelse sub
  } def

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some special debug & test keys.
%
% ( key_in ) ==> ( key_out )
%
/debug.input {
  dup keyShiftF4 eq debug 3 ge and {
    currentcolor black setcolor
    currentpoint 0 0 moveto
    64 string biosmem "mem = %u  " 2 index sprintf dup show free
    moveto setcolor
    pop 0
  } if

  dup keyF8 eq syslinux and {
    kroete.file .undef eq { /kroete.file "kroete.dat" findfile def } if
    kroete.file kroete.dir idle
    /kroete.dir kroete.dir 1 xor def
    pop 0
  } if

  dup keyF9 eq syslinux and {
    .undef 0 idle
    kroete.file free /kroete.file .undef def
    pop 0
  } if

  dup keyShiftF3 eq syslinux and debug 3 ge and {
    currentcolor black setcolor
    currentpoint 0 0 moveto
    "eject  " print bootdrive eject print
    moveto setcolor
    pop 0
  } if

  dup keyShiftF5 eq syslinux and debug 3 ge and {
    currentcolor black setcolor
    currentpoint 100 0 moveto
    bootdrive print
    moveto setcolor
    pop 0
  } if

  dup keyShiftF8 eq debug 3 ge and {
    currentcolor debug 1 and { white } { black } ifelse setcolor

    currentpoint 300 0 moveto
    0 memsize print "/" print print "  " print
    moveto

    currentpoint 300 20 moveto
    1 memsize print "/" print print "  " print
    moveto

    currentpoint 300 40 moveto
    2 memsize print "/" print print "  " print
    moveto

    setcolor
    pop 0
  } if

  dup keyShiftF9 eq debug 3 ge and {
    dumpmem
    pop 0
  } if

  dup keyShiftF10 eq {
    /debug debug 1 add def ""
    pop 0
  } if

  dup keyShiftF11 eq {
    /transp transp 0x10 sub 0 max def

    % /player 0 def
    % player "hapysuse.mod" findfile mod.load
    % 50 sound.setvolume
    % player 0 mod.play
    % /player player 1 add 3 and def

    pop 0
  } if

  dup keyF11 eq debug 1 ge and {

    0 1 screen.size exch pop {
      0 1 screen.size pop {
        over moveto
        currentpoint 8 shl screen.size exch pop div 8 shl exch 8 shl screen.size pop div add
        screen.size add currentpoint add sub 8 shl screen.size add div 2 div 16 shl add
        setcolor
        putpixel
      } for
      pop
    } for

    pop 0
  } if

  dup keyF12 eq debug 3 ge and {
    % mouse support testing

    1 keepmode

    /mouse xxx def
    red setcolor
    mouse .undef eq {
      700 580 moveto "no mouse" show
    } {
      {
        mouse getdword 16 shl 16 shr screen.size pop 2 div add
        mouse getdword 16 shr neg screen.size exch pop 2 div add
        moveto 4 4 fillrect

        mouse 4 add getdword 7 and
        dup 1 and { red setcolor } if
        dup 2 and { blue setcolor } if
        dup 4 and { green setcolor } if

        3 and 3 eq { exit } if

      } loop
    } ifelse
    pop 0
  } if

  dup keyShiftF12 eq {
    /transp transp 0x10 add 0x100 min def
    pop 0
  } if

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show exit popup.
%
% ( ) ==> ( )
%
/exit_popup {
  window.dialog

  dup .title txt_exit_title put
  dup .text txt_exit_dialog put
  dup .buttons [
    button.ok button.default actExit button.setaction
    button.cancel button.notdefault actNothing button.setaction
  ] put
  dup window.init
      window.show

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show help window.
%
% ( ) ==> ( )
%
/show_help {
  window.help
  
  dup window.init
  window.show

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show dvd popup.
%
% ( ) ==> ( )
%
/dvd_popup {
  window.dialog

  dup .title txt_dvd_warning_title put
  dup .text txt_dvd_warning2 put
  dup .buttons [
%    button.eject    button.default    actEject actNoClose or button.setaction
    button.continue button.default actNothing button.setaction
  ] put
  dup window.init
      window.show

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Warn that we are about to install 32bit software on a 64bit system.
%
% ( ) ==> ( )
%
/32bit_popup {
  window.dialog

  dup .title "Cool computer, but..." put
  dup .text "You are about to install 32-bit software on a 64-bit computer." put
  dup .buttons [
    button.continue button.default actNothing button.setaction
  ] put
  dup window.init
      window.show

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Warn that we are about to install 64bit software on a 32bit system.
%
% ( ) ==> ( )
%
/64bit_popup {
  window.dialog

  dup .title "Cool software, but..." put
  dup .text "This is a 32-bit computer. You cannot use 64-bit software on it." put
  dup .buttons [
    button.reboot button.default actReboot actNoClose or button.setaction
  ] put
  dup window.init
      window.show

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Warn that we don't have enough memory.
%
% ( ) ==> ( )
%
/nomem_popup {
  window.dialog

  dup .title "Sorry, but..." put
  dup .text mem.show put
  dup .buttons [
    button.ok button.default actNothing button.setaction
  ] put
  dup window.init
      window.show

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show "power off" popup.
%
% ( ) ==> ( )
%
/power_off {
  window.dialog

  dup .title txt_power_off_title put
  dup .text txt_power_off put
  dup .buttons [
    button.ok     button.notdefault    actPowerOff actNoClose or button.setaction
    button.cancel button.default       actNothing                button.setaction
  ] put
  dup window.init
      window.show

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Restore popup.
%
% ( ) ==> ( )
%
/restore_system {
  window.dialog

  dup .title "Think again..." put
  dup .text

"This will destroy ALL data on your computer.
There is no way back.
Please save everything you might need before you continue!

Are you really sure?"

put
  dup .buttons [
    button.ok     button.notdefault    actReallyStart  button.setaction
    button.cancel button.default       actNothing      button.setaction
  ] put
  dup window.init
      window.show

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Global variables.
%

/ptheme false def

syslinux {
  rand pop rand 4 shr 11 div 0xffff and
    date weekday 5 lt { 15 } { 3 } ifelse
    date month dup 12 eq exch 1 eq or { 1 add 2 div } if
  mod 0 eq

  date
  dup 0x7d50c18 ge over 0x7d60101 le and
  dup 0x7d50c12 eq or
  dup 0x7d50c0b eq or
  dup 0x7d50c06 eq or
  dup 0x7d50c04 eq or
  dup 0x7d50b1b eq or
  exch pop or

  0x417 cvp getbyte 0x40 and 0 ne or
  {
    /ptheme true def
  } if

} if

/ptheme false def

/transp 0x30 def

/testX { 0x417 cvp getbyte 0x10 and 0 ne } def

testX { /ptheme false def } if

800 600 16 findmode setmode not {
  800 600 32 findmode setmode not {
    640 480 16 findmode setmode not {
      640 480 32 findmode setmode not {
        false .end
      } if
    } if
  } if
} if

% /with_transp vscreen.size exch pop screen.size exch pop div 1 gt colorbits 8 gt and def

/clip.size { screen.size } def

/small_layout screen.size pop 640 eq def

ptheme { "pback.jpg" } { "back.jpg" } ifelse findfile
dup .undef eq { pop "back-low.jpg" findfile } if
/background.file over def setimage loadpalette
/max_image_colors image.colors def

% 7 dup 0xffffff setpalette setcolor

% color & font definitions must be global

/black               0x000000          newcolor
/white               0xffffff          newcolor
/blue                0x0000a0          newcolor
/red                 0xc00000          newcolor
/green               0x009000          newcolor
/yellow              0xffff20          newcolor
/lightgray           0xd8deed          newcolor
/dotcolor            0xa9bbcd          newcolor
/lightdotcolor       0xeff2f6          newcolor
/somegreen           0x78a424          newcolor

/lightblue 0x7da3d1 def

%% include theme_colors.inc

/font.normal "16x16.fnt" findfile def
/font.large font.normal def

/cmdline.hidden cmdlinelength string def
/cmdline.shown cmdlinelength string def

/kroete.dir 0 def

/debug 0 def

ptheme small_layout or CapsLock or {
  /bsplash.done { } def
} {
  bsplash.show
} ifelse

check_arch_boot_dir

