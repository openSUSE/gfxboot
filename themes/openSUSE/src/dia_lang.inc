% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Language selection dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%

% fallback if there is no "languages"
/lang.items [ "en_US" ] def
/lang.names [ "English (US)" ] def

/.la.locale 0 def
/.la.keymap 1 def
/.la.rtl    2 def
/.la.name   3 def

/lang.defaultnames [
  [ "af_ZA" "en_US" false "Afrikaans" ]						% Afrikaans
% [ "ar_EG" "en_US" true  "\u064a\u0628\u0631\u0639" ]				% Arabic
  [ "ar_EG" "en_US" true  "\ufef2\ufe91\ufeae\ufecb" ]				% Arabic
  [ "bg_BG" "en_US" false "Български" ]						% Bulgarian
  [ "bn_BD" "en_US" false "\u09ac\u09be\u0982\u09b2\u09be" ]			% Bengali
  [ "bs_BA" "en_US" false "Bosanski" ]						% Bosnian
  [ "ca_ES" "en_US" false "Català" ]						% Catalan
  [ "cs_CZ" "czech" false "Čeština" ]						% Czech
  [ "cy_GB" "en_US" false "Cymraeg" ]						% Welsh
  [ "da_DK" "danish" false "Dansk" ]						% Danish
  [ "de_DE" "german" false "Deutsch" ]						% German
  [ "el_GR" "greek" false "Ελληνικά" ]						% Greek
  [ "en_GB" "en_US" false "English (UK)" ]					% English
  [ "en_US" "en_US" false "English (US)" ]					% English
  [ "es_ES" "spanish" false "Español" ]						% Spanish
  [ "et_EE" "estonian" false "Eesti" ]						% Estonian
  [ "fa_IR" "en_US" true "\ufbfd\ufeb4\u0631\ufe8e\ufed3" ]			% Farsi
  [ "fi_FI" "en_US" false "Suomi" ]						% Finnish
  [ "fr_FR" "french" false "Français" ]						% French
  [ "gl_ES" "en_US" false "Galego" ]						% Galician
  [ "ka_GE" "en_US" false "ქართული" ]						% Kartuli
  [ "gu_IN" "en_US" false "\u0a97\u0ac1\u0a9c\u0ab0\u0abe\u0aa4\u0ac0" ]	% Gujarati
  [ "he_IL" "en_US" false "תירבע" ]						% Hebrew
% [ "hi_IN" "en_US" false "\u0939\u093f\u0928\u094d\u0926\u0940" ]		% Hindi
  [ "hi_IN" "en_US" false "\u0939\u093f\u0902\u0926\u0940" ]			% Hindi
  [ "hr_HR" "en_US" false "Hrvatski" ]						% Croatian
  [ "hu_HU" "hungarian" false "Magyar" ]						% Hungarian
  [ "id_ID" "en_US" false "Bahasa Indonesia" ]					% Indonesian
  [ "it_IT" "italian" false "Italiano" ]						% Italian
  [ "ja_JP" "japanese" false "日本語" ]						% Japanese
  [ "jv_ID" "en_US" false "Basa Jawa" ]						% Javanese
% [ "km_KH" "en_US" false "\u1781\u17d2\u1798\u17c2\u179a" ]			% Khmer
  [ "km_KH" "en_US" false "Khmer" ]						% Khmer
  [ "ko_KR" "en_US" false "한글" ]						% Korean
  [ "lo_LA" "en_US" false "\u0e9e\u0eb2\u0eaa\u0eb2\u0ea5\u0eb2\u0ea7" ]	% Lao
  [ "lt_LT" "en_US" false "Lietuvių" ]						% Lithuanian
  [ "mk_MK" "en_US" false "Македонски" ]					% Macedonian
  [ "mr_IN" "en_US" false "\u092e\u0930\u093e\u0920\u0940" ]			% Marathi
  [ "nb_NO" "norwegian" false "Norsk" ]						% Norwegian
  [ "nl_NL" "en_US" false "Nederlands" ]					% Dutch
  [ "pa_IN" "en_US" false "\u0a2a\u0a70\u0a1c\u0a3e\u0a2c\u0a40" ]		% Punjabi
  [ "pl_PL" "polish" false "Polski" ]						% Polish
  [ "pt_BR" "portugese-br" false "Português (Brasil)" ]				% Portuguese (Brazilian)
  [ "pt_PT" "portugese" false "Português" ]						% Portuguese
  [ "ro_RO" "en_US" false "Română" ]						% Romanian
  [ "ru_RU" "russian" false "Русский" ]						% Russian
  [ "si_LK" "en_US" false "\u0dc3\u0dd2\u0d82\u0dc4\u0dbd" ]			% Sinhala
  [ "sk_SK" "slovak" false "Slovenčina" ]					% Slovak
  [ "sl_SI" "slovene" false "Slovenščina" ]					% Slovenian
  [ "sr_CS" "en_US" false "Srpski" ]						% Serbian
  [ "sv_SE" "swedish" false "Svenska" ]						% Swedish
  [ "ta_IN" "en_US" false "\u0ba4\u0bae\u0bbf\u0bb4\u0bcd" ]			% Tamil
  [ "th_TH" "en_US" false "\u0e20\u0e32\u0e29\u0e32\u0e44\u0e17\u0e22" ] 	% Thai
  [ "tr_TR" "turkish" false "Türkçe" ]						% Turkish
  [ "uk_UA" "en_US" false "Українська" ]					% Ukrainian
  [ "vi_VN" "en_US" false "Tiếng Việt" ]					% Vietnamese
  [ "wa_BE" "en_US" false "Walon" ]						% Walloon
  [ "xh_ZA" "en_US" false "isiXhosa" ]						% Xhosa
  [ "zh_CN" "en_US" false "简体中文" ]						% Simplified Chinese
  [ "zh_TW" "en_US" false "繁體中文 (台灣)" ]					% Traditional Chinese
  [ "zu_ZA" "en_US" false "isiZulu" ]						% Zulu
] def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Get language property.
%
% Returns .undef if not found.
%
% ( locale prop ) ==> ( obj )
%
/lang.getprop {
  lang.defaultnames {
    dup .la.locale get 3 index eq { exch get exch pop return } { pop } ifelse
  } forall

  % try a loose match
  lang.defaultnames {
    dup .la.locale get 3 index locale.cmp { exch get exch pop return } { pop } ifelse
  } forall

  pop pop .undef
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Get language name.
%
% Returns locale if not found.
%
% ( locale ) ==> ( name )
%
/lang.getdefname {
  dup
  .la.name lang.getprop
  dup .undef ne { exch } if
  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Check for rtl.
%
% ( locale ) ==> ( bool )
%
/lang.getrtl {
  .la.rtl lang.getprop
  dup .undef eq { pop false } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Parse "languages" file.
%
% ( ) ==> ( )
%
/lang.parsedata {
  /lang.default 0 def

  "languages" findfile dup { /lang.data exch def } { pop return } ifelse

  /la.tmp.datalen lang.data length def
  /la.tmp.str lang.data cvs def
 
  la.tmp.datalen 0 eq { return } if
  la.tmp.str la.tmp.datalen 1 sub get '\n' ne { return } if

  '\n' seteotchar

  /lang.items [

    /la.tmp.len 0 def
    /la.tmp.cnt 0 def
    {
      la.tmp.str la.tmp.len add strdup
      dup dup length 0 put
      /la.tmp.len over length 1 add la.tmp.len add def

      dup 0 get '*' eq { 1 add /lang.default la.tmp.cnt def } if

      la.tmp.len la.tmp.datalen ge { exit } if

      /la.tmp.cnt inc
    } loop

  ] def

  ' ' seteotchar

  /lang.names [

    lang.items {

      dup dup length add

      dup 0 get {
        dup 0 0 put 1 add
        exch pop
      } {
        pop lang.getdefname
      } ifelse

    } forall

    keymap.submenu {
      /lang.submenu.keyboard
    } if

  ] def

  /lang.submenu.idx keymap.submenu { lang.names length 1 sub } { -1 } ifelse def

  0 seteotchar

} def


/lang.submenu.keyboard.buf 64 string def
/lang.submenu.keyboard {
  /txt_keyboard exec "\x09%s" lang.submenu.keyboard.buf sprintf
  lang.submenu.keyboard.buf
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build language list.
%
% ( ) ==> ( )
%
/lang.init {
  /xmenu.lang .xm_size array def
  /xmenu xmenu.lang def

  lang.parsedata

  xmenu .xm_current lang.default put
  xmenu .xm_list lang.names put

  xmenu .xm_title /txt_language put

  % make menu smaller if there are more than 19 language entries
  %lang.items length 19 gt {
  %  xmenu .xm_vspace 2 put
  %} if

  % start with current lang

  /la.tmp.cnt 0 def
  lang.items {
    config.lang locale.cmp { xmenu .xm_current la.tmp.cnt put exit } if
    /la.tmp.cnt inc
  } forall

  /la.tmp.cnt 0 def
  lang.items {
    config.lang eq { xmenu .xm_current la.tmp.cnt put exit } if
    /la.tmp.cnt inc
  } forall

  % needed in case menu is only attached to lang menu
  keymap.init
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update language.
%
% ( ) ==> ( )
%
/lang.update {
  /xmenu xmenu.lang def

  xmenu .xm_current get lang.submenu.idx eq {
    xmenu .xm_current over .xm_last get put
    panel.keymap
  } {
    lang.items xmenu .xm_current get get
    dup
    setlang { /window.action actRedraw def } if
    getkeymapfromlocale setkeymap
    keymap.setdefault
  } ifelse

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show language menu.
%
% ( ) => ( )
%
/panel.lang {
  "keytable" help.setcontext

  window.xmenu
  dup .xmenu xmenu.lang put
  dup .xmenu.update /lang.update put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of panel entry.
%
% ( ) => ( width )
%
/panel.lang.width {
  /xmenu xmenu.lang def

  pmenu.width
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.lang.update {
  /xmenu xmenu.lang def

  pmenu.panel.update

  xmenu.keymap .xm_panel_x xmenu.lang .xm_panel_x get put
} def


