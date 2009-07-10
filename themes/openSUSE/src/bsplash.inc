% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Boot loader splash code.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.

/.b_init	 0 def
/.b_done	 1 def
/.b_run		 2 def

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Init splash.
%
% ( ) ==> ( )
%
/bsplash.init {
  /bsplash.list [
    config.welcome 2 eq { [ /b1.init /b1.done /b1.run ] } if
    [ /b2.init /b2.done /b2.run ]
  ] def

  bsplash.list { dup .b_init get exec } forall
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Free splash memory.
%
% ( ) ==> ( )
%
/bsplash.free {
  bsplash.list { dup .b_done get exec } forall
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show boot loader splash.
%
% ( ) ==> ( )
%
/bsplash.show {
  currentimage

  % "/boot/i386/loader/xxx" chdir

  "welcome.jpg" findfile /splash.file over def setimage

  0 0 moveto 0 0 image.size image

  % "/boot/i386/loader" chdir

  bsplash.init

  bsplash.skip not { 100000 usleep } if

  bsplash.skip not {
    {
      0 usleep
      bsplash.skip { exit } if
      bsplash.run { exit } if
    } loop
  } if

  bsplash.free

  setimage

  /splash.file xfree

} def


% Run splash animations. Return 'true' when done.
%
% ( ) ==> ( true|false )
%
/bsplash.run {
  true

  bsplash.list { dup .b_run get exec and } forall
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Just wait.
%
% ( ) ==> ( )
%
/bsplash.done {
  bsplash.skip not {
    1500000 usleep
  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Check if we should skip the intro.
%
% ( ) ==> ( true|false )
%
/bsplash.skip {
  % any key pressed?
  getkey 0xffff and {
    /bsplash.skip true def
    true
  } {
    false
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Init.
%
% ( array ) ==> ( )
%
/b1.init {
  pop

  /b1_ok false def

  /b1_cd "cd.jpg" readimage def
  /b1_cd_mask "cd_a.jpg" readimage def

  b1_cd .undef eq b1_cd_mask .undef eq or { return } if

  /b1_cd_tmp b1_cd imgsize 0 0 moveto savescreen def

  20 350 moveto
  /b1_orig 300 150 savescreen def
  /b1_buf 300 150 savescreen def

  /b1_idx 0 def
  /b1_steps 20 def

  /b1_ok true def
} def


/b1_x [ 0  2  6 15 25 37 51 67 83 98 113 125 136 144 148 150 ] def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Cleanup.
%
% ( array ) ==> ( )
%
/b1.done {
  pop

  b1_ok not { return } if

  /b1_cd xfree
  /b1_cd_mask xfree
  /b1_cd_tmp xfree

  /b1_orig xfree
  /b1_buf xfree

  /b1_ok false def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Run animation.
%
% Return true when finished.
%
% ( array ) ==> ( true|false )
%
/b1.run {
  pop

  b1_ok not { true return } if

  /b1_idx inc

  b1_idx b1_steps gt { true return } if

  b1_buf b1_orig over length memcpy

  b1_cd_tmp b1_cd_mask over length memcpy
  0 255 b1_idx 20 mul sub 0 max b1_cd_tmp blend

  /b1_dx_cur b1_x b1_idx aget dup .undef eq { pop 150 } if def

  150 0 moveto
  b1_cd b1_cd_tmp b1_buf blend

  150 b1_dx_cur 2 div sub 0 moveto
  b1_cd b1_cd_tmp b1_buf blend

  150 b1_dx_cur sub 0 moveto
  b1_cd b1_cd_tmp b1_buf blend


  20 350 moveto b1_buf restorescreen

  false

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Init.
%
% ( array ) ==> ( )
%
/b2.init {
  pop

  /b2_ok false def

  /b2_text "text.jpg" readimage def
  % /b2_spot "spotlite.jpg" readimage def

  b2_text .undef eq { return } if

  /b2_text_tmp b2_text imgsize 0 0 moveto savescreen def
  % /b2_spot_tmp b2_spot imgsize 0 0 moveto savescreen def

  600 160 moveto
  /b2_orig b2_text imgsize savescreen def
  /b2_buf b2_text imgsize savescreen def

  /b2_idx 0 def
  /b2_start 10 def
  /b2_steps 20 def

  /b2_ok true def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Cleanup.
%
% ( array ) ==> ( )
%
/b2.done {
  pop

  b2_ok not { return } if

  /b2_text xfree
  /b2_text_tmp xfree

  /b2_orig xfree
  /b2_buf xfree

  /b2_ok false def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Run animation.
%
% Return true when finished.
%
% ( array ) ==> ( true|false )
%
/b2.run {
  pop

  b2_ok not { true return } if

  /b2_idx inc

  b2_idx b2_start b2_steps add gt { true return } if

  b2_idx b2_start lt { false return } if

  b2_buf b2_orig over length memcpy

  b2_text_tmp b2_text over length memcpy
  0 255 b2_idx b2_start sub 20 mul sub 0 max b2_text_tmp blend

  % b2_spot_tmp b2_spot over length memcpy
  % 0 255 b2_idx b2_start sub 20 mul sub 0 max b2_spot_tmp blend

  % 0 0 moveto
  % 0x80ff80 b2_spot_tmp b2_buf blend
  0 0 moveto
  0xffffff b2_text_tmp b2_buf blend

  600 160 moveto b2_buf restorescreen

  false

} def


