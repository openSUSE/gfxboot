% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Boot loader splash code.
%
% config.welcome: type of welcome animation
%   0: no splash
%   1: 'welcome' texts fade-in
%   2: rolling cd
%   3: light bulb fade-in
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.

/.b_init	 0 def
/.b_done	 1 def
/.b_run		 2 def

/burn time 16 shl 1193180 div 60 div 60 mod { false } { true } ifelse def

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Init splash.
%
% ( ) ==> ( )
%
/bsplash.init {
  /bsplash.list [
    config.welcome 2 le {
      config.welcome 2 eq { [ /b1.init /b1.done /b1.run ] } if
      [ /b2.init /b2.done /b2.run ]
    } if
    config.welcome 3 eq {
      [ /b3.init /b3.done /b3.run ]
      burn { [ /b4.init /b4.done /b4.run ] } if
    } if
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

  config.welcome 3 eq { "off.jpg" } { "welcome.jpg" } ifelse findfile /splash.file over def setimage

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
    config.welcome 2 le { 1500000 usleep } if
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

  b2_text .undef eq { return } if

  /b2_text_tmp b2_text imgsize 0 0 moveto savescreen def

  560 120 moveto
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

  % blend b2_text_tmp over b2_buf, store result in b2_buf
  0 0 moveto
  b2_text_tmp b2_idx b2_start sub 20 mul 255 min b2_buf blend

  560 120 moveto b2_buf restorescreen

  false

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Init.
%
% ( array ) ==> ( )
%
/b3.init {
  pop

  /b3_ok false def

  /b3_on "on.jpg"
    findfile dup .undef ne {
      dup setimage 200 0 400 600 unpackimage exch free
    } if
  def

  /b3_off "off.jpg"
    findfile dup .undef ne {
      dup setimage 200 0 400 600 unpackimage exch free
    } if
  def

  b3_on .undef eq { return } if
  b3_off .undef eq { return } if

  /b3_tmp b3_on imgsize 0 0 moveto savescreen def

  /b3_idx 0 def
  /b3_start 0 def
  /b3_steps 30 def

  /b3_ok true def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Cleanup.
%
% ( array ) ==> ( )
%
/b3.done {
  pop

  b3_ok not { return } if

  /b3_on xfree
  /b3_off xfree
  /b3_tmp xfree

  /b3_ok false def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Run animation.
%
% Return true when finished.
%
% ( array ) ==> ( true|false )
%
/b3.run {
  pop

  b3_ok not { true return } if

  /b3_idx inc

  b3_idx b3_start b3_steps add gt { true return } if

  b3_idx b3_start lt { false return } if

  b3_tmp b3_off over length memcpy
  0 0 moveto
  b3_on b3_idx b3_start sub 15 mul 255 min b3_tmp blend

  200 0 moveto b3_tmp restorescreen

  false

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Init.
%
% ( array ) ==> ( )
%
/b4.init {
  pop

  /b4_ok false def

  /b4_glow "glow.jpg"
    findfile dup .undef ne {
      dup setimage 200 0 400 600 unpackimage exch free
    } if
  def

  b4_glow .undef eq { return } if

  /b4_tmp b4_glow imgsize 0 0 moveto savescreen def

  /b4_idx 0 def
  /b4_start 40 def
  /b4_steps 30 def

  /b4_ok true def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Cleanup.
%
% ( array ) ==> ( )
%
/b4.done {
  pop

  b4_ok not { return } if

  /b4_glow xfree
  /b4_tmp xfree

  /b4_ok false def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Run animation.
%
% Return true when finished.
%
% ( array ) ==> ( true|false )
%
/b4.run {
  pop

  b4_ok not { true return } if

  /b4_idx inc

  b4_idx b4_start b4_steps add gt { true return } if

  b4_idx b4_start lt { false return } if

  /b4_val b4_idx b4_start sub 20 mul 255 min def

  b4_val 255 lt {
    b4_tmp b3_on over length memcpy
    0 0 moveto
    b4_glow b4_val b4_tmp blend
  } {
    b4_tmp b3_off over length memcpy
  } ifelse

  200 0 moveto b4_tmp restorescreen

  false

} def


