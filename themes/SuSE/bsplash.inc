% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Boot loader splash code.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.

/.b1_init	 0 def
/.b1_done	 1 def
/.b1_run	 2 def
/.b1_start	 3 def
/.b1_end	 4 def
/.b1_x		 5 def
/.b1_y		 6 def
/.b1_x0	 	 7 def
/.b1_dx		 8 def
/.b1_pic_name	 9 def
/.b1_mask_name	10 def
/.b1_count	11 def
/.b1_pic	12 def
/.b1_mask	13 def
/.b1_back	14 def
/.b1_w		15 def
/.b1_h		16 def
/.b1_tmp1	17 def
/.b1_tmp2	18 def

/.b2_init	 0 def
/.b2_done	 1 def
/.b2_run	 2 def
/.b2_start	 3 def
/.b2_end	 4 def
/.b2_x		 5 def
/.b2_y		 6 def
/.b2_x0	 	 7 def
/.b2_dx		 8 def
/.b2_pic_name	 9 def
/.b2_grad_name	10 def
/.b2_count	11 def
/.b2_pic	12 def
/.b2_grad	13 def
/.b2_back	14 def
/.b2_w		15 def
/.b2_h		16 def
/.b2_tmp1	17 def
/.b2_tmp2	18 def

/bsplash.list [
  % [ /b1.init /b1.done /b1.run  0 10   0   0    0  10 "cd.jpg" "cd_a.jpg" 8 { .undef } repeat ]

  [ /b2.init /b2.done /b2.run  0 16 540 260    0  25 "w1.jpg" "grad1.jpg" 8 { .undef } repeat ]
  [ /b2.init /b2.done /b2.run  2 18 540 310    0  25 "w2.jpg" "grad1.jpg" 8 { .undef } repeat ]
  [ /b2.init /b2.done /b2.run  4 20 540 360    0  25 "w3.jpg" "grad1.jpg" 8 { .undef } repeat ]
  [ /b2.init /b2.done /b2.run  6 22 540 410    0  25 "w4.jpg" "grad1.jpg" 8 { .undef } repeat ]
  [ /b2.init /b2.done /b2.run 10 50 540 460  400 -10 "w5.jpg" "grad2.jpg" 8 { .undef } repeat ]
  [ /b2.init /b2.done /b2.run  8 24 540 510    0  25 "w6.jpg" "grad1.jpg" 8 { .undef } repeat ]
] def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Init splash.
%
% ( ) ==> ( )
%
/bsplash.init {
  bsplash.list { dup .b2_init get exec } forall
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Free splash memory.
%
% ( ) ==> ( )
%
/bsplash.free {
  bsplash.list { dup .b2_done get exec } forall
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show boot loader splash.
%
% ( ) ==> ( )
%
/bsplash.show {
  currentimage

  "welcome.jpg" findfile /splash.file over def setimage

  0 0 moveto 0 0 image.size image

  bsplash.init

  bsplash.skip not { 200000 usleep } if

  bsplash.skip not {
    {
      0 usleep
      bsplash.skip { exit } if
      bsplash.run { exit } if
    } loop
  } if

  bsplash.free

  setimage

  splash.file free /splash.file .undef def

} def


% Run splash animations. Return 'true' when done.
%
% ( ) ==> ( true|false )
%
/bsplash.run {
  true

  bsplash.list { dup .b2_run get exec and } forall
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
% Init array.
%
% ( array ) ==> ( )
%
/b1.init {
  dup .b1_count -1 put
  dup .b1_pic_name get readimage over .b1_pic rot put
  dup .b1_mask_name get readimage over .b1_mask rot put

  dup .b1_pic get .undef eq
  over .b1_mask get .undef eq or {
    .b1_count .undef put
    return
  } if

  dup .b1_pic get imgsize
  2 index .b1_h rot put over .b1_w rot put

  dup .b1_x get over .b1_y get moveto

  dup .b1_w get over .b1_h get savescreen over .b1_back rot put

  % just a buffer
  dup .b1_w get over .b1_h get savescreen over .b1_tmp1 rot put
  dup .b1_w get over .b1_h get savescreen over .b1_tmp2 rot put

  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Cleanup.
%
% ( array ) ==> ( )
%
/b1.done {
  dup .b1_pic get free
  dup .b1_mask get free
  dup .b1_back get free
  dup .b1_tmp1 get free
  dup .b1_tmp2 get free

  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Run animation.
%
% Return true when finished.
%
% ( array ) ==> ( true|false )
%
/b1.run {
  dup .b1_count get .undef eq { pop true return } if

  dup .b1_count get 1 add over .b1_count rot put

  dup .b1_count get over .b1_start get lt { pop false return } if

  % count runs from  .b1_start ... .b1_end inclusive

  dup .b1_tmp2 get over .b1_back get over length memcpy

  0 0 moveto
  dup .b1_mask get 0 2 index .b1_tmp1 get blend
  dup .b1_mask get over .b1_count get 255 mul 2 index .b1_end get div 2 index .b1_tmp1 get blend

  dup .b1_pic get over .b1_tmp1 get 2 index .b1_tmp2 get blend

  
  dup .b1_x get over .b1_y get moveto
  dup .b1_tmp2 get restorescreen




  dup .b1_count get over .b1_end get eq { dup .b1_count .undef put } if

  pop

  false

  dtrace

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Init array.
%
% ( array ) ==> ( )
%
/b2.init {
  dup .b2_count -1 put
  dup .b2_pic_name get readimage over .b2_pic rot put
  dup .b2_grad_name get readimage over .b2_grad rot put

  dup .b2_pic get .undef eq
  over .b2_grad get .undef eq or {
    .b2_count .undef put
    return
  } if

  dup .b2_pic get imgsize
  2 index .b2_h rot put over .b2_w rot put

  dup .b2_x get over .b2_y get moveto

  dup .b2_w get over .b2_h get savescreen over .b2_back rot put

  % just a buffer
  dup .b2_w get over .b2_h get savescreen over .b2_tmp1 rot put
  dup .b2_w get over .b2_h get savescreen over .b2_tmp2 rot put

  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Cleanup.
%
% ( array ) ==> ( )
%
/b2.done {
  dup .b2_pic get free
  dup .b2_grad get free
  dup .b2_back get free
  dup .b2_tmp1 get free
  dup .b2_tmp2 get free

  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Run animation.
%
% Return true when finished.
%
% ( array ) ==> ( true|false )
%
/b2.run {
  dup .b2_count get .undef eq { pop true return } if

  dup .b2_count get 1 add over .b2_count rot put

  dup .b2_count get over .b2_start get lt { pop false return } if

  % count runs from  .b2_start ... .b2_end inclusive

  dup .b2_count get over .b2_start get sub over .b2_dx get mul over .b2_x0 get add 0 moveto
  dup .b2_grad get 0xff 2 index .b2_tmp1 get blend

  dup .b2_tmp2 get over .b2_back get over length memcpy

  0 0 moveto
  white over .b2_pic get 2 index .b2_tmp2 get blend

  0 0 moveto
  dup .b2_back get over .b2_tmp1 get 2 index .b2_tmp2 get blend

  dup .b2_x get over .b2_y get moveto
  dup .b2_tmp2 get restorescreen

  dup .b2_count get over .b2_end get eq { dup .b2_count .undef put } if

  pop

  false

} def


