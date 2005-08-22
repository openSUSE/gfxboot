% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Some basic definitions.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% some key codes
/keyEsc       0x0000001b def
/keyEnter     0x0000000d def
/keyTab       0x00000009 def
/keyShiftTab  0x00800009 def
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

% boot loader
/lilo     bootloader 0 eq def
/syslinux bootloader 1 eq def
/grub     bootloader 2 eq def

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
% Show string right aligned.
%
% ( string ) ==> ( )
%
/showright {
  dup strsize pop neg 0 rmoveto show
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


