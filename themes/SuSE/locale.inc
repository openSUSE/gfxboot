% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Handle translations.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Set language.
%
% ( locale ) ==> ( true|false )
%
/setlang {
  config.lang over eq { pop false return } if

  /config.lang exch def

  /help.messages .undef def

  translation.texts {
    translation.texts dup { free } forall free
    /translation.texts .undef def
  } if

  findtexts

  true
} def



% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Set keyboard map.
%
% ( locale ) ==> ( )
%
/setkeymap {
  config.keymap.locale over eq { pop false return } if

  /config.keymap.locale exch def

  keymaps {
    dup .km.locale get config.keymap.locale eq {
      .km.map get /config.keymap exch def exit
    } { pop } ifelse
  } forall

} def



% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Find texts for current language.
%
% ( ) ==> ( )
%
/findtexts {
  texts.file free /texts.file .undef def
  16 string dup config.lang "%s.tr" 2 index sprintf findfile exch free
  dup .undef eq {
    config.lang length 2 gt {
      pop 16 string
      dup config.lang 1 get config.lang 0 get "%c%c.tr" 3 index sprintf findfile exch free
      dup {
        /config.lang 2 string
          config.lang 1 get config.lang 0 get "%c%c" 3 index sprintf
        def
      } if
    } if
  } if
  dup .undef eq { pop "en.tr" findfile } if
  /texts.file over def
  dup .undef eq { pop 0 cvp } if
  cvs
  /ft.len over cvp length def
  /ft.str exch def
  /ft.pos 0 def

  texts {
    ft.pos ft.str length add ft.len lt {
      ft.str def
      /ft.str ft.str dup length 1 add /ft.pos over ft.pos add def add def
    } {
      "No Texts!" def
    } ifelse
  } forall
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Translate menu entry.
%
% ( text ) ==> ( text )
%
/translate {
  translations.init

  translation.texts length 2 lt { return } if

  0 2 translation.texts length -2 and 1 sub {
    translation.texts over get 2 index eq {
      1 add translation.texts exch get exch pop exit
    } { pop } ifelse 
  } for

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Read menu translations.
%
% ( ) ==> ( )
%
/translations.init {
  translation.texts { return } if

  /translation.texts [ ] def

  config.lang .undef eq { return } if

  tr.tmp .undef eq { /tr.tmp 64 string def } if

  config.lang "translations.%s" tr.tmp sprintf

  tr.tmp findfile dup {

    /la.tmp.datalen over length def
    /la.tmp.str exch cvs def

    la.tmp.datalen 0 eq { return } if
    la.tmp.str la.tmp.datalen 1 sub get '\n' ne { return } if

    '\n' seteotchar
   
    /translation.texts [

      /la.tmp.len 0 def

      {
        la.tmp.str la.tmp.len add strdup
        dup dup length 0 put
        /la.tmp.len over length 1 add la.tmp.len add def

        la.tmp.len la.tmp.datalen ge { exit } if

      } loop

    ] def

    0 seteotchar
  } { pop } ifelse

} def

