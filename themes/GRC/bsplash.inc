% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Boot loader splash code.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.

/.b_x		 0 def
/.b_y		 1 def
/.b_dx		 2 def
/.b_dy		 3 def
/.b_steps	 4 def
/.b_mask	 5 def
/.b_count	 6 def
/.b_w		 7 def
/.b_h		 8 def
/.b_back	 9 def
/.b_tmp1	10 def
/.b_tmp2	11 def

/bsplash.list [
  [ 680  45 -30   0 10 "text2a.pcx"  -1 0 0 .undef .undef .undef  ]
  [ 680  95 -30   0 10 "text2b.pcx"  -1 0 0 .undef .undef .undef  ]
  [ 680 145 -30   0 10 "text2c.pcx"  -1 0 0 .undef .undef .undef  ]
  [  55  50  30   0 10 "text1.pcx"   -7 0 0 .undef .undef .undef  ]
  [ 320 280   0   0 10 "text3.pcx"  -10 0 0 .undef .undef .undef  ]
  [  90 415   0  20 10 "text4a.pcx" -15 0 0 .undef .undef .undef  ]
  [  90 485   0   0 10 "text4b.pcx" -15 0 0 .undef .undef .undef  ]
  [  90 535   0 -20 10 "text4c.pcx" -15 0 0 .undef .undef .undef  ]
] def

/bsplash_cnt 10 def

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Init splash.
%
% ( ) ==> ( )
%
/bsplash.init {
  bsplash.list {
    dup .b_mask get readimage over .b_mask rot put
    dup .b_mask get dup .undef ne {
      imgsize
      2 index .b_h rot put
      over .b_w rot put

      dup .b_x get over .b_y get moveto
      dup .b_w get over .b_steps get 2 index .b_dx get abs mul add
      over .b_h get 2 index .b_steps get 3 index .b_dy get abs mul add
      savescreen over .b_back rot put

      dup .b_w get 1 sub over .b_h get 1 sub savescreen over .b_tmp1 rot put
      dup .b_w get 1 sub over .b_h get 1 sub savescreen over .b_tmp2 rot put
    } {
      pop
    } ifelse
    pop
  } forall
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Free splash memory.
%
% ( ) ==> ( )
%
/bsplash.free {
  bsplash.list {
    dup .b_mask get free dup .b_mask .undef put
    dup .b_back get free
    dup .b_tmp1 get free
    dup .b_tmp2 get free
    pop
  } forall
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

  bsplash.skip not { 400000 usleep } if

  bsplash.skip not {
    {
      0 usleep
      bsplash.skip { exit } if
      bsplash.run { exit } if
    } loop
  } if

  % bsplash.free

  setimage

  splash.file free /splash.file .undef def

} def


% Run splash animations. Return 'true' when done.
%
% ( ) ==> ( true|false )
%
/bsplash.run {
  /bsplash_cnt bsplash_cnt 1 sub def
  bsplash_cnt 0 lt
  return


  true

  bsplash.list {
    dup .b_mask get .undef ne over .b_count get .undef ne and {
      exch pop false exch

      dup .b_count get 1 add over .b_count rot put

      % count runs from  0 ... steps inclusive

      dup .b_count get 0 ge {

        % copy background
        dup .b_dx get over .b_count get mul 10 div
          over .b_dx get 2 index .b_steps get mul 10 div neg 0 max add
        over .b_dy get 2 index .b_count get mul 10 div
          2 index .b_dy get 3 index .b_steps get mul 10 div neg 0 max add
        moveto
        dup .b_back get 0xff 2 index .b_tmp1 get blend

        % we need 2 copies
        dup .b_tmp2 get over .b_tmp1 get over length memcpy

        % draw text
        0 0 moveto 0x333333 over .b_mask get 2 index .b_tmp1 get blend
        1 1 moveto white over .b_mask get 2 index .b_tmp1 get blend

        % blend result with background
        0 0 moveto dup .b_tmp1 get over .b_count get 255 mul 2 index .b_steps get div 2 index .b_tmp2 get blend

        % show result
        dup .b_x get over .b_dx get 2 index .b_count get mul 10 div add
          over .b_dx get 2 index .b_steps get mul 10 div neg 0 max add
        over .b_y get 2 index .b_dy get 3 index .b_count get mul 10 div add
          2 index .b_dy get 3 index .b_steps get mul 10 div neg 0 max add
        moveto
        dup .b_tmp2 get restorescreen

      } if

      dup .b_count get over .b_steps get eq { dup .b_count .undef put } if
    } if
    pop
  } forall

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
/bsplash.skip false def


