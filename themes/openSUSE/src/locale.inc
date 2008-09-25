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

  /config.rtl config.lang lang.getrtl def

  % clear old help texts
  /help.messages xfree

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
% ( locale|keymap ) ==> ( )
%
/setkeymap {
  config.keymap.name over eq { pop return } if
  /config.keymap.name exch def

  config.keymap.id config.keymap.name eq { return } if

  /config.keymap .undef def
  /config.keymap.id .undef def

  keymaps {
    dup .km.id get config.keymap.name eq
    over .km.locale get config.keymap.name eq or {
      dup .km.map get /config.keymap exch def
      .km.id get /config.keymap.id exch def
    } { pop } ifelse
  } forall

  config.keymap.id .undef eq {
    keymaps {
      dup .km.locale get config.keymap.name locale.cmp {
        dup .km.map get /config.keymap exch def
        .km.id get /config.keymap.id exch def
      } { pop } ifelse
    } forall
  } if

  config.keymap.id .undef eq {
    /config.keymap.id "en_US" def
  } if

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Look up keymap in languale locale list.
%
% ( locale ) ==> ( keymap|locale )
%
/getkeymapfromlocale {
  /kbd.tmp exch def
  /kbd.tmp.locale .undef def

  lang.defaultnames {
    dup .la.locale get kbd.tmp eq { .la.keymap get /kbd.tmp.locale exch def exit } { pop } ifelse
  } forall

  kbd.tmp.locale .undef eq {
    lang.defaultnames {
      dup .la.locale get kbd.tmp locale.cmp { .la.keymap get /kbd.tmp.locale exch def exit } { pop } ifelse
    } forall
  } if

  kbd.tmp.locale .undef ne { /kbd.tmp kbd.tmp.locale def } if

  kbd.tmp
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Find texts for current language.
%
% ( ) ==> ( )
%
/findtexts {
  /texts.file xfree

  config.lang "%s.tr" locale.findfile
  dup .undef eq { pop "en_US" "%s.tr" locale.findfile } if

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

  config.lang "translations.%s" locale.findfile dup {

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


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Read locale-specific file.
%
% ( str1 str2 -- ptr1 )
%
% str1: locale
% str2: file name template (like "foo.%s")
% ptr1:  buffer with file data (or .undef)
%
/locale.findfile {
  over length over length add string

  rot strdup rot

  over over 4 index sprintf 2 index findfile

  dup .undef eq {
    pop
    exch
    dup "_" strstr dup {
      1 sub
      over exch 0 put
      exch
      over over 4 index sprintf 2 index findfile
    } {
      pop exch .undef
    } ifelse
  } if

  exch pop exch free exch free
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Compare two locale names.
%
% ( str1 str2 -- int1 )
%
% str1: locale1
% str2: locale2
% int1: 0 = no match, 1 = loose match, 2 = identical
%
/locale.cmp {
  over over eq { pop pop 2 return } if

  currenteotchar '_' seteotchar

  rot strdup rot strdup

  over over eq rot free exch free

  exch seteotchar

  { 1 } { 0 } ifelse
} def


