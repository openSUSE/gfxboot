% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Some basic definitions.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% some key codes
/keyEsc       0x0000001b def
/keyEnter     0x0000000d def
/keyTab       0x00000009 def
/keyShiftTab  0x0f000000 def
/keyF1        0x3b000000 def
/keyF2        0x3c000000 def
/keyF3        0x3d000000 def
/keyF4        0x3e000000 def
/keyF5        0x3f000000 def
/keyF6        0x40000000 def
/keyF7        0x41000000 def
/keyF8        0x42000000 def
/keyF9        0x43000000 def
/keyF10       0x44000000 def
/keyF11       0x85000000 def
/keyF12       0x86000000 def
/keyHome      0x47000000 def
/keyUp        0x48000000 def
/keyPgUp      0x49000000 def
/keyLeft      0x4b000000 def
/keyRight     0x4d000000 def
/keyEnd       0x4f000000 def
/keyDown      0x50000000 def
/keyPgDown    0x51000000 def
/keyIns       0x52000000 def
/keyDel       0x53000000 def
/keyShiftF1   0x54000000 def
/keyShiftF2   0x55000000 def
/keyShiftF3   0x56000000 def
/keyShiftF4   0x57000000 def
/keyShiftF5   0x58000000 def
/keyShiftF6   0x59000000 def
/keyShiftF7   0x5a000000 def
/keyShiftF8   0x5b000000 def
/keyShiftF9   0x5c000000 def
/keyShiftF10  0x5d000000 def
/keyShiftF11  0x87000000 def
/keyShiftF12  0x88000000 def
/keyCtrlF1    0x5e000000 def
/keyCtrlF2    0x5f000000 def
/keyCtrlF3    0x60000000 def
/keyCtrlF4    0x61000000 def
/keyCtrlF5    0x62000000 def
/keyCtrlF6    0x63000000 def
/keyCtrlF7    0x64000000 def
/keyCtrlF8    0x65000000 def
/keyCtrlF9    0x66000000 def
/keyCtrlF10   0x67000000 def
/keyAltF1     0x68000000 def
/keyAltF2     0x69000000 def
/keyAltF3     0x6a000000 def
/keyAltF4     0x6b000000 def
/keyAltF5     0x6c000000 def
/keyAltF6     0x6d000000 def
/keyAltF7     0x6e000000 def
/keyAltF8     0x6f000000 def
/keyAltF9     0x70000000 def
/keyAltF10    0x71000000 def
/keyCtrlLeft  0x73000000 def
/keyCtrlRight 0x74000000 def
/keyCtrlEnd   0x75000000 def
/keyCtrlDown  0x76000000 def
/keyCtrlHome  0x76000000 def
/keyCtrlUp    0x84000000 def
/keyStatus    0xff000000 def

/statusAlt    0x0208 def
/statusAltL   0x0200 def
/statusAltR   0x0008 def
/statusCtrl   0x0104 def
/statusShift  0x0003 def

/CapsLock { 0x417 cvp getbyte 0x40 and 0 ne } def


% input object fields
/.inp_x		 0 def		% x pos
/.inp_y		 1 def		% y pos
/.inp_back	 2 def		% background pixmap
/.inp_buf	 3 def		% input buffer
/.inp_buf_len	 4 def		% input buffer length
/.inp_int	 5 def		% internal state array, see below
% optional fields
/.inp_hidden	 6 def		% hidden buffer
/.inp_label	 7 def		% input field label
/.inp_visible	 8 def		% field is visible
/.inp_show	 9 def		% field should be visible

/.inp_int_cur		0 def	% current edit char offset
/.inp_int_cursor	1 def	% cursor pos (pixel)
/.inp_int_shift		2 def	% input line shifted (pixel)
/.inp_int_flags		3 def	% bit 0: cursor visible
/.inp_int_saved_cursor	4 def	% saved cursor background

% boot loader

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% bootloader - boot loader type
%
% group: system
%
% ( -- int1 )
%
% int1: boot loader type (0: lilo, 1:syslinux/isolinux, 2: grub)
%
/bootloader sysconfig getbyte def

/lilo     bootloader 0 eq def
/syslinux bootloader 1 eq def
/grub     bootloader 2 eq def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% boot_failsafe - failsafe options the user selected (bitmask)
%
% group: system
%
% ( -- int1 )
%
% int1: option bitmask
%   bit 0: SHIFT pressed
%   bit 1: no graphics
%   bit 2: no monitor detection
%
/boot_failsafe sysconfig 3 add getbyte def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% bootdrive - drive the BIOS booted from
%
% group: system
%
% ( -- int1 )
%
% int1: BIOS drive id
%
/bootdrive sysconfig 5 add getbyte def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% mediatype - type of media we booted from
%
% group: system
%
% ( -- int1 )
%
% int1: media type (0 disk, 1 floppy, 2 cdrom)
%
/mediatype sysconfig 2 add getbyte def

/m_disk   0 def
/m_floppy 1 def
/m_cdrom  2 def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% biosmem - BIOS reported memory size
%
% group: mem
%
% ( -- int1 )
%
% int1: total memory size according to BIOS
%
/biosmem sysconfig 20 add getdword def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% sectorsize - sector size
%
% group: mem system
%
% ( -- int1 )
%
% int1: sector size in bytes
%
/sectorsize
  1
  sysconfig 1 add getbyte
  20 min	% max. 1 MB
  dup 0 eq { pop 9 } if
  shl
def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% getinfo - type of info box
%
% group: system
%
% ( int1 -- int2 )
%
% int1: type of info box we have to show
% int2: some data
%
% Note: really weird, should be replaced by something more obvious.
%
/getinfo {
  2 shl
  sysconfig 12 add exch add getdword
} def


% bool values
/true     0 0 eq def
/false    0 0 ne def

% type values
/t_none		 0 def
/t_int		 1 def
/t_unsigned	 2 def
/t_bool		 3 def
/t_string	 4 def
/t_code		 5 def
/t_ret		 6 def
/t_prim		 7 def
/t_sec		 8 def
/t_dict_idx	 9 def
/t_array	10 def
/t_end		11 def
/t_ptr		12 def

/.value { t_int settype } def
/.undef 0 t_none settype def
/.end 0 t_end settype def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Print string (for debugging).
%
% ( string ) ==> ( )
%
/string.print {
  dup
  currentpoint currentpoint 5 -1 roll strsize image moveto
  show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Print number (for debugging).
%
% ( number ) ==> ( )
%
/number.print {
  32 string
  exch over
  "%08x" exch sprintf
  dup string.print
  free
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Print obj (for debugging).
%
% ( obj ) ==> ( )
%
/obj.print {
  64 string
  exch dup
  .value exch gettype
  "%x:%08x" 3 index sprintf
  dup string.print
  free
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Print (for debugging).
%
% ( obj ) ==> ( )
%
/print {
  dup gettype t_int eq { number.print return } if
  dup gettype t_string eq { string.print return } if
  obj.print
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Convert object to pointer.
%
% ( obj ) ==> ( ptr )
%
/cvp { t_ptr settype } def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Convert object to string.
%
% ( obj ) ==> ( string )
%
/cvs { t_string settype } def


% base num char

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Convert object to number.
%
% ( obj ) ==> ( int )
%
/cvn {
  dup gettype t_string eq {
    1 % sign
    exch dup 0 get '-' eq {
      exch pop 1 add -1 exch
    } if
    10 % initial base
    0 % value
    rot
    {
      dup 'a' ge { 0x20 sub } if
      dup 'X' eq { pop pop pop 16 0 '0' } if
      '0' sub
      dup 9 gt { 7 sub } if
      dup 0 lt over 4 index ge or { pop exit } if
      exch 2 index mul add
    } forall
    exch pop mul
  } {
    t_int settype
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Arguments like snprintf.
%
% ( obj_1 ... obj_n string_1 string_2 ) ==> ( )
%
/sprintf {
  dup cvp length exch snprintf
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Allocate new string.
%
% ( size ) ==> ( string )
/string {
  1 add malloc cvs
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Increment variable.
%
% ( dict_ref ) ==> ( )
%
/inc {
  dup exec 1 add def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Copy src to dst.
%
% Watch overlapping src & dst!
%
% ( dst src ) ==> ( dst )
%
/strcpy {
  "%s" 2 index sprintf
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Duplicate string.
%
% ( string ) ==> ( string )
%
/strdup {
  dup length string exch strcpy
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Concatenate strings.
%
% ( string1 string2 ) ==> ( string1 )
%
/strcat {
  over dup length add exch strcpy pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Test for AltGr.
%
% ( )  ==> ( bool )
%
/is_altGr {
  keystat statusAltR and 0 ne keystat statusAltL and 0 eq and
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Keyboard mapping.
%
% ( key ) ==> ( key )
%
/mapkey {
   dup 24 shr 0xff and /key.code exch def
   is_altGr {
     % bios is too smart...
     key.code 0x78 ge key.code 0x83 le and { /key.code key.code 0x76 sub def } if
   } if
   0 1 config.keymap length 1 sub {
     config.keymap exch get
     dup 0 get key.code eq {
       1
       keystat statusShift and { pop 2 } if
       is_altGr { pop 3 } if
       get
       exch pop
     } {
       pop
     } ifelse
   } for
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Set password mode font property.
%
% ( font ) ==> ( font )
%
/pwmode {
   dup gettype t_ptr eq {
     .value 0x80000000 or t_ptr settype
   } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show one-line string right aligned.
%
% ( string ) ==> ( )
%
/showright1 {
  dup strsize pop neg 0 rmoveto currentpoint rot show currentpoint exch pop exch pop moveto
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show string right aligned.
%
% ( string ) ==> ( )
%
/showright {
  '\n' split
  currentpoint pop
  false 2 index

  % array x not_first? array
  {
    % array x not_first? elem

    over {
      "\n" show
      2 index currentpoint exch pop moveto
    } if

    dup showright1 free

    pop true
  } forall
  pop pop
  free
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show string right/left aligned.
%
% ( string ) ==> ( )
%
/show.rtl {
  config.rtl { showright } { show } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show string centered.
%
% ( string ) ==> ( )
%
/showcenter {
  dup strsize pop 2 div neg 0 rmoveto show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Generate pseudo random number.
% Good enough for boot loader splash screen.
%
% ( ) ==> ( int )
%
/rand {
  rand.start 59 mul 97 add 0x7fffffff and
  /rand.start over def
} def

% start value
/rand.start time def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% ( date ) ==> ( weekday )
%
% (Monday: 0)
%
% d + [26*(m+1)/10] + j + [j/4] + [c/4] - 2 c - 2
%
/weekday {
  dup day exch
  dup year exch
  month dup 2 le { 12 add exch 1 sub exch } if
  1 add 26 mul 10 div
  exch dup
  100 mod dup 4 div add
  exch 100 div dup 4 div exch 2 mul sub
  add add add
  7 mod 12 add
  7 mod
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% ( date ) ==> ( day )
%
/day {
  0xff and
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% ( date ) ==> ( month )
%
/month {
  8 shr 0xff and
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% ( date ) ==> ( year )
%
/year {
  16 shr
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Read CMOS RAM.
%
% ( index ) ==> ( value )
%
/nvram {
  0x70 exch outbyte
  0x71 inbyte
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% readsector - read sector
%
% group: system
%
% ( int1 -- ptr1 )
%
% int1: sector number
% ptr1: buffer with sector data or .undef. Use @free to free the buffer.
%
% Note: does not return on error. Returns .undef if function is not implemented.
%
/readsector {
  _readsector
  dup .undef eq { return } if

  sectorsize malloc dup rot over length memcpy
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% getgfxconfig - get gfxboot config file entry
%
% group: system
%
% ( str1 -- str2 )
%
% str1: key for config entry
% str2: config string (or .undef)
%
/getgfxconfig {
  gfxconfig.data .undef eq {
    "gfxboot.cfg" findfile dup .undef ne {
      dup dup length dup string dup cvp 4 2 roll memcpy exch free
    } {
      pop ""
    } ifelse

    /gfxconfig.data over '\n' split def free

  } if

  currenteotchar '=' seteotchar

  .undef

  gfxconfig.data {

    % overkill because string compare does not honor eotchar
    dup strdup dup 5 index eq {
      dup length exch free 1 add add exch pop exit
    } {
      free pop
    } ifelse

  } forall

  exch seteotchar exch pop

} def

/gfxconfig.data .undef def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Read string from config file and store in variable.
%
% ( key str -- )
%
% Read config value 'key' and copy to 'str' if found.
%
/getgfxconfig.str {
  exch getgfxconfig dup { strcpy } { pop } ifelse pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% split - split string
%
% group:
%
% ( str1 int1 -- array1 )
%
% str1: string
% int1: char
% array1: array of strings
%
/split {

  % split does not work if str1 is in a special memory region (where 
  % 'cvp length' does not work). So we dup it first.

  exch strdup dup rot

  currenteotchar exch seteotchar exch

  [ exch

    {
      dup strdup exch
      dup length add

      dup cvp length 1 le { pop exit } if

      1 add

    } loop

  ]

  exch seteotchar

  exch free

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% join - join array of strings
%
% group:
%
% ( array1 str1 -- str2 )
%
% array1: array of strings
% str1: separator
% str2: complete string
%
/join {
  over length 0 eq { pop pop 0 string return } if

  over length 1 sub over length mul
  2 index { length add } forall
  string

  % note: last element is not followed by separator because it exceeds
  % the destination string size
  rot {
    strcat over strcat
  } forall

  exch pop

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Skip leading non-spaces.
%
% ( string ) ==> ( string )
%
/skipnonspaces {
  { dup 0 get dup 0 ne exch ' ' ne and { 1 add } { exit } ifelse } loop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Skip leading spaces.
%
% ( string ) ==> ( string )
%
/skipspaces {
  { dup 0 get ' ' eq { 1 add } { exit } ifelse } loop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Drop spaces at string end.
% Modifies string!
%
% ( string ) ==> ( )
%
/dropspaces {
  dup length
  dup 0 eq {
    pop pop
  } {
    1 sub
    -1 0 {
      over over get ' ' eq { over exch 0 put } { pop exit } ifelse
    } for
    pop
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Test if string[ofs-1]/string[ofs] is a word boundary.
%
% ( string ofs ) ==> ( true|false )
%
% boundary is either space/non-space or non-space/(space|'=')
%
/iswordboundary {
  dup 0 eq { pop pop true return } if

  add dup 1 sub 0 get exch 0 get

  over ' ' eq over ' ' gt and { pop pop true return } if
  over ' ' gt over dup ' ' eq exch dup '=' eq exch 0 eq or or and { pop pop true return } if

  pop pop false
} def


%% findmode - find video mode number
%
% group: gfx.screen
%
% ( int1 int2 int3 -- int4 )   
%
% int1, int2: width, height
% int3: color bits
% int4: mode number (or .undef)
%
% example
%   1024 768 16 findmode setmode        % 1024x768, 16-bit color mode
%
/findmode {
  0 1 videomodes {
    videomodeinfo dup .undef eq {
      pop pop pop pop
    } {
      % compare width, height, colors
      6 index 4 index eq 6 index 4 index eq and 5 index 3 index eq and {
        7 1 roll 6 { pop } repeat 0xbfff and return
      } {
        pop pop pop pop
      } ifelse
    } ifelse
  } for

  pop pop pop .undef
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Replace substring. Returns newly allocated string.
%
% ( str key value ) ==> ( new_str )
%
% Replaces first occurence of 'key' in str with 'value'.
%
/strreplace {
  2 index 2 index strstr dup 0 ne {
    1 sub
    over length 3 index length sub 4 index length add string
    dup cvp 5 index cvp 3 index memcpy
    dup 6 1 roll over add exch 5 -1 roll exch add
    4 -1 roll length add 3 1 roll "%s%s" exch sprintf
  } {
    pop pop pop strdup
  } ifelse


} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Search for option in cmdline.
% Returns .undef if not found.
%
% ( cmdline option_name ) ==> ( option_start )
%
/bootopt.find {
  /_bo.opt exch def
  /_bo.cmdline exch def

  {
    _bo.cmdline _bo.opt strstr
    dup {
      dup 1 eq {
        true
      } {
        dup 2 sub _bo.cmdline exch get ' ' eq
      } ifelse

      {
        _bo.cmdline over _bo.opt length add 1 sub get
        dup '=' eq
        over ' ' eq or
        exch 0 eq or
      } {
        false
      } ifelse

      _bo.cmdline rot add exch

      {
        1 sub exit
      } {
        /_bo.cmdline exch def
      } ifelse
    } {
      pop
      .undef exit
    } ifelse
  } loop

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Search for second occurence of option in cmdline.
% Returns .undef if not found.
%
% ( cmdline option_name ) ==> ( option_start )
%
/bootopt.find2 {
  over over bootopt.find dup .undef eq {
    pop pop pop .undef
  } {
    1 add rot pop exch bootopt.find
  } ifelse
} def


% Remove option from cmdline. Returns removed option or .undef.
%
% cmdline is modified, option_entry is allocated dynamicyll and must be
% freed later.
%
% ( cmdline option_name -- option_entry )
%
/bootopt.remove {
  bootopt.find dup .undef ne {
    dup
    skipnonspaces dup skipspaces 2 index sub rot rot over sub string over strcpy
    rot rot
    {
      over over exch get
      over over 0 exch put {
        1 add
      } {
        exit
      } ifelse
    } loop
    pop pop
  } if
} def


% Test whether we run in Live-CD mode
%
% (  -- true|false )
%
/livecd {
  /livecd "livecd" getgfxconfig dup .undef ne { 0 ne } { pop false } ifelse def
  livecd
} def


% Mininum required memory in MB.
%
% (  -- int )
%
/mem.check {
  mem.min getgfxconfig dup .undef ne { cvn } { pop 0 } ifelse
} def


% Message to print if we fail minimum memory requirement.
%
% (  -- str1 )
%
/mem.show {
  mem.msg getgfxconfig dup .undef eq { pop "Not enough memory." } if
} def


% List of menu entries with no boot option input field.
%
% (  -- array )
%
/config.nobootoptions {
  "nobootoptions" getgfxconfig dup .undef ne {
    ',' split
  } {
    pop [ ]
  } ifelse
  /config.nobootoptions over def
} def


% List of menu entries which should not get an 'install' option appended.
%
% (  -- array )
%
/config.noinstallopt {
  "noinstallopt" getgfxconfig dup .undef ne {
    ',' split
  } {
    pop [ ]
  } ifelse
  /config.noinstallopt over def
} def


% Penguin theme percentage.
%
% (  -- int )
%
/penguin.percent {
  /penguin.percent "penguin" getgfxconfig dup .undef ne { cvn } { pop 0 } ifelse def
  penguin.percent
} def


% Show welcome splash.
%
% (  -- bool )
%
/config.welcome {
  /config.welcome "welcome" getgfxconfig dup .undef ne { cvn } { pop 0 } ifelse 0 ne def
  config.welcome
} def


% Video memory in kb.
%
% (  -- int )
%
/video.memory {
  /video.memory 0 sysinfo def
  video.memory
} def


% Graphics card OEM info.
%
% (  -- string )
%
/video.oem {
  /video.oem 1 sysinfo strdup def
  video.oem
} def


% Graphics card vendor name.
%
% (  -- string )
%
/video.vendor {
  /video.vendor 2 sysinfo strdup def
  video.vendor
} def


% Graphics card product name.
%
% (  -- string )
%
/video.product {
  /video.product 3 sysinfo strdup def
  video.product
} def


% Graphics card revision.
%
% (  -- string )
%
/video.revision {
  /video.revision 4 sysinfo strdup def
  video.revision
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Free memory.
%
% Like free, but accepts dict entries, too.
%
% ( obj -- )
%
/xfree {
  dup gettype
  t_dict_idx eq {
    dup exec exch .undef def
  } if
  free
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Get array element.
%
% Like get, but returns .undef if index is outside array bounds.
%
% ( array index -- obj )
%
/aget {
  over length over gt { get } { pop pop .undef } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Search for array element.
%
% ( array key -- bool )
%
/iselement {
  false rot {
    2 index eq { pop true exit } if
  } forall
  exch pop
} def


