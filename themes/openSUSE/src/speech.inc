% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Speech related function.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


/.talk_text  0 def
/.talk_sound 1 def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% ( text -- )
%
/speak {
  % skip leading TABs
  { dup 0 get '\x09' le { 1 add } { exit } ifelse } loop

  /last.spoken xfree
  /last.spoken over strdup def

  dup _speak { pop return } if
  dup __ dup rot ne { _speak } if pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Say text.
%
% ( str -- bool )
%
%  str: text
% bool: sound sample found
%
/_speak {
  talk_array {
    dup .talk_text get 2 index eq {
      .talk_sound get wav.playlater
      pop true return
    } {
      pop
    } ifelse
  } forall
  pop
  false
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Load sound samples.
%
% ( -- )
%
/load_talk {
  /talk_file "en.tlk" findfile def

  talk_file .undef eq { return } if

  talk_file getdword 0x692741e8 ne { return } if

  talk_array .undef ne {
    talk_array { free } forall
  } if

  /talk_array xfree

  /talk_array [
    0 1 talk_file 4 add getdword 1 sub {
      [
        exch 8 mul 8 add talk_file add
        dup getdword talk_file add cvs
        exch 4 add getdword talk_file add
      ]
    } for
  ] def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Load sound samples.
%
% ( -- )
%
/load_talk_dialog {
  window.dialog
  dup .title "Just a second..." put
  dup .text "Please wait while speech files are being loaded..." put
  dup window.init window.show

  load_talk
  config.volume sound.setvolume 

  window.done

  % do it only once
  /load_talk_dialog { } def
} def


