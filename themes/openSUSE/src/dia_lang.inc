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
  [ "af_ZA" "us"                   false "Afrikaans" ]						% Afrikaans
% [ "ar_EG" "arabic"               true  "\u064a\u0628\u0631\u0639" ]				% Arabic
  [ "ar_EG" "arabic"               true  "\ufef2\ufe91\ufeae\ufecb" ]				% Arabic
  [ "ast_ES" "es"                  false "Asturianu" ]						% Asturian
  [ "bg_BG" "us"                   false "Български" ]						% Bulgarian
  [ "bn_BD" "us"                   false "\u09ac\u09be\u0982\u09b2\u09be" ]			% Bengali
  [ "bs_BA" "us"                   false "Bosanski" ]						% Bosnian
  [ "ca_ES" "es"                   false "Català" ]						% Catalan
  [ "cs_CZ" "cz"                   false "Čeština" ]						% Czech
  [ "cy_GB" "us"                   false "Cymraeg" ]						% Welsh
  [ "da_DK" "dk"                   false "Dansk" ]						% Danish
  [ "de_DE" "de-nodeadkeys"        false "Deutsch" ]						% German
  [ "el_GR" "gr"                   false "Ελληνικά" ]						% Greek
  [ "en_GB" "uk"                   false "English (UK)" ]					% English
  [ "en_US" "us"                   false "English (US)" ]					% English
  [ "es_ES" "es"                   false "Español" ]						% Spanish
  [ "et_EE" "et"                   false "Eesti" ]						% Estonian
  [ "fa_IR" "us"                   true "\ufbfd\ufeb4\u0631\ufe8e\ufed3" ]			% Farsi
  [ "fi_FI" "fi"                   false "Suomi" ]						% Finnish
  [ "fr_FR" "fr"                   false "Français" ]						% French
  [ "gl_ES" "es"                   false "Galego" ]						% Galician
  [ "ka_GE" "us"                   false "ქართული" ]						% Kartuli
  [ "gu_IN" "us"                   false "\u0a97\u0ac1\u0a9c\u0ab0\u0abe\u0aa4\u0ac0" ]		% Gujarati
  [ "he_IL" "us"                   false "תירבע" ]						% Hebrew
% [ "hi_IN" "us"                   false "\u0939\u093f\u0928\u094d\u0926\u0940" ]		% Hindi
  [ "hi_IN" "us"                   false "\u0939\u093f\u0902\u0926\u0940" ]			% Hindi
  [ "hr_HR" "hr"                   false "Hrvatski" ]						% Croatian
  [ "hu_HU" "hu"                   false "Magyar" ]						% Hungarian
  [ "id_ID" "us"                   false "Bahasa Indonesia" ]					% Indonesian
  [ "it_IT" "it"                   false "Italiano" ]						% Italian
  [ "ja_JP" "jp"                   false "日本語" ]						% Japanese
  [ "jv_ID" "us"                   false "Basa Jawa" ]						% Javanese
  [ "kk_KZ" "us"                   false "Қазақша" ]						% Kazakh
% [ "km_KH" "khmer"                false "\u1781\u17d2\u1798\u17c2\u179a" ]			% Khmer
  [ "km_KH" "khmer"                false "Khmer" ]						% Khmer
  [ "ko_KR" "kr"                   false "한글" ]						% Korean
  [ "ky_KG" "us"                   false "Кыргызча" ]						% Kirghiz
  [ "lo_LA" "us"                   false "\u0e9e\u0eb2\u0eaa\u0eb2\u0ea5\u0eb2\u0ea7" ]		% Lao
  [ "lt_LT" "lt"                   false "Lietuvių" ]						% Lithuanian
  [ "mk_MK" "us"                   false "Македонски" ]						% Macedonian
  [ "mr_IN" "us"                   false "\u092e\u0930\u093e\u0920\u0940" ]			% Marathi
  [ "nb_NO" "no"                   false "Norsk" ]						% Norwegian
  [ "nl_NL" "us"                   false "Nederlands" ]						% Dutch
  [ "nn_NO" "no"                   false "Nynorsk" ]						% Nynorsk
  [ "pa_IN" "us"                   false "\u0a2a\u0a70\u0a1c\u0a3e\u0a2c\u0a40" ]		% Punjabi
  [ "pl_PL" "pl"                   false "Polski" ]						% Polish
  [ "pt_BR" "br"                   false "Português (Brasil)" ]					% Portuguese (Brazilian)
  [ "pt_PT" "pt"                   false "Português" ]						% Portuguese
  [ "ro_RO" "us"                   false "Română" ]						% Romanian
  [ "ru_RU" "ruwin_alt-UTF-8"      false "Русский" ]						% Russian
  [ "si_LK" "us"                   false "\u0dc3\u0dd2\u0d82\u0dc4\u0dbd" ]			% Sinhala
  [ "sk_SK" "sk"                   false "Slovenčina" ]						% Slovak
  [ "sl_SI" "si"                   false "Slovenščina" ]					% Slovenian
  [ "sr_RS" "sr-cy"                false "Srpski" ]						% Serbian
  [ "sv_SE" "se"                   false "Svenska" ]						% Swedish
  [ "ta_IN" "us"                   false "\u0ba4\u0bae\u0bbf\u0bb4\u0bcd" ]			% Tamil
  [ "tg_TJ" "tj_alt-UTF8"          false "тоҷикӣ" ]						% Tadjik
  [ "th_TH" "us"                   false "\u0e20\u0e32\u0e29\u0e32\u0e44\u0e17\u0e22" ] 	% Thai
  [ "tr_TR" "tr"                   false "Türkçe" ]						% Turkish
  [ "uk_UA" "ua-urf"               false "Українська" ]						% Ukrainian
  [ "vi_VN" "us"                   false "Tiếng Việt" ]						% Vietnamese
  [ "wa_BE" "be"                   false "Walon" ]						% Walloon
  [ "xh_ZA" "us"                   false "isiXhosa" ]						% Xhosa
  [ "zh_CN" "us"                   false "简体中文" ]						% Simplified Chinese
  [ "zh_TW" "us"                   false "繁體中文 (台灣)" ]					% Traditional Chinese
  [ "zu_ZA" "us"                   false "isiZulu" ]						% Zulu
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
      /txt_keyboard
    } if

  ] def

  /lang.submenu.idx keymap.submenu { lang.names length 1 sub } { -1 } ifelse def

  0 seteotchar

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

  % As we have submenus and separation lines, attach empty arrays to menu
  % structure to be filled later.
  %
  % Arrays must have as many entries as there are menu items.
  xmenu .xm_submenus lang.names length array put
  xmenu .xm_attr lang.names length array put

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

  % Attach keyboard menu to last entry (lang.submenu.idx).
  % This is controllable via gfxboot.cfg setting (keymap.submenu var).
  keymap.submenu {
    xmenu.lang .xm_submenus get lang.submenu.idx xmenu.keymap put
    % add separation line
    xmenu.lang .xm_attr get lang.submenu.idx 1 put
  } if
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


