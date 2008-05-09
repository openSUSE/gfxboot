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
/.la.rtl    1 def
/.la.name   2 def

/lang.defaultnames [
  [ "af_ZA" false "Afrikaans" ]						% Afrikaans
% [ "ar_EG" true  "\u064a\u0628\u0631\u0639" ]				% Arabic
  [ "ar_EG" true  "\ufef2\ufe91\ufeae\ufecb" ]				% Arabic
  [ "bg_BG" false "Български" ]						% Bulgarian
  [ "bn_BD" false "\u09ac\u09be\u0982\u09b2\u09be" ]			% Bengali
  [ "bs_BA" false "Bosanski" ]						% Bosnian
  [ "ca_ES" false "Català" ]						% Catalan
  [ "cs_CZ" false "Čeština" ]						% Czech
  [ "cy_GB" false "Cymraeg" ]						% Welsh
  [ "da_DK" false "Dansk" ]						% Danish
  [ "de_DE" false "Deutsch" ]						% German
  [ "el_GR" false "Ελληνικά" ]						% Greek
  [ "en_GB" false "English (UK)" ]					% English
  [ "en_US" false "English (US)" ]					% English
  [ "es_ES" false "Español" ]						% Spanish
  [ "et_EE" false "Eesti" ]						% Estonian
  [ "fi_FI" false "Suomi" ]						% Finnish
  [ "fr_FR" false "Français" ]						% French
  [ "gl_ES" false "Galego" ]						% Galician
  [ "gu_IN" false "\u0a97\u0ac1\u0a9c\u0ab0\u0abe\u0aa4\u0ac0" ]	% Gujarati
  [ "he_IL" false "תירבע" ]						% Hebrew
% [ "hi_IN" false "\u0939\u093f\u0928\u094d\u0926\u0940" ]		% Hindi
  [ "hi_IN" false "\u0939\u093f\u0902\u0926\u0940" ]			% Hindi
  [ "hr_HR" false "Hrvatski" ]						% Croatian
  [ "hu_HU" false "Magyar" ]						% Hungarian
  [ "id_ID" false "Bahasa Indonesia" ]					% Indonesian
  [ "it_IT" false "Italiano" ]						% Italian
  [ "ja_JP" false "日本語" ]						% Japanese
% [ "km_KH" false "\u1781\u17d2\u1798\u17c2\u179a" ]			% Khmer
  [ "km_KH" false "Khmer" ]						% Khmer
  [ "ko_KR" false "한글" ]						% Korean
  [ "lt_LT" false "Lietuvių" ]						% Lithuanian
  [ "mk_MK" false "Македонски" ]					% Macedonian
  [ "mr_IN" false "\u092e\u0930\u093e\u0920\u0940" ]			% Marathi
  [ "nb_NO" false "Norsk" ]						% Norwegian
  [ "nl_NL" false "Nederlands" ]					% Dutch
  [ "pa_IN" false "\u0a2a\u0a70\u0a1c\u0a3e\u0a2c\u0a40" ]		% Punjabi
  [ "pl_PL" false "Polski" ]						% Polish
  [ "pt_BR" false "Português (Brasil)" ]				% Portuguese (Brazilian)
  [ "pt_PT" false "Português" ]						% Portuguese
  [ "ro_RO" false "Română" ]						% Romanian
  [ "ru_RU" false "Русский" ]						% Russian
  [ "si_LK" false "\u0dc3\u0dd2\u0d82\u0dc4\u0dbd" ]			% Sinhala
  [ "sk_SK" false "Slovenčina" ]					% Slovak
  [ "sl_SI" false "Slovenščina" ]					% Slovenian
  [ "sr_CS" false "Srpski" ]						% Serbian
  [ "sv_SE" false "Svenska" ]						% Swedish
  [ "ta_IN" false "\u0ba4\u0bae\u0bbf\u0bb4\u0bcd" ]			% Tamil
  [ "th_TH" false "\u0e20\u0e32\u0e29\u0e32\u0e44\u0e17\u0e22" ] 	% Thai
  [ "tr_TR" false "Türkçe" ]						% Turkish
  [ "uk_UA" false "Українська" ]					% Ukrainian
  [ "vi_VN" false "Tiếng Việt" ]					% Vietnamese
  [ "wa_BE" false "Walon" ]						% Walloon
  [ "xh_ZA" false "isiXhosa" ]						% Xhosa
  [ "zh_CN" false "简体中文" ]						% Simplified Chinese
  [ "zh_TW" false "繁體中文 (台灣)" ]					% Traditional Chinese
  [ "zu_ZA" false "isiZulu" ]						% Zulu
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

  ] def

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
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update language.
%
% ( ) ==> ( )
%
/lang.update {
  /xmenu xmenu.lang def

  lang.items xmenu .xm_current get get
  dup
  setlang { /window.action actRedraw def } if
  setkeymap
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
} def


