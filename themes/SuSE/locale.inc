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
  16 string dup config.lang "texts.%s" 2 index sprintf findfile exch free
  dup .undef eq {
    config.lang length 2 gt {
      pop 16 string
      dup config.lang 1 get config.lang 0 get "texts.%c%c" 3 index sprintf findfile exch free
      dup {
        /config.lang 2 string
          config.lang 1 get config.lang 0 get "%c%c" 3 index sprintf
        def
      } if
    } if
  } if
  dup .undef eq { pop "texts.en" findfile } if
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


