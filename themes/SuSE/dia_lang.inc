% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Language selection dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%

% fallback if there is no "languages"
/lang.items [ "en" ] def
/lang.names [ "English" ] def

/.la.locale 0 def
/.la.rtl    1 def
/.la.name   2 def

/lang.defaultnames [
  [ "af_ZA" false "Afrikaans" ]
% [ "ar_EG" true  "\u064a\u0628\u0631\u0639" ]
  [ "ar_EG" true  "\ufef2\ufe91\ufeae\ufecb" ]
  [ "bg_BG" false "Български" ]
  [ "bn_BD" false "\u09ac\u09be\u0982\u09b2\u09be" ]		% Bengali
  [ "bs_BA" false "Bosanski" ]
  [ "ca_ES" false "Català" ]
  [ "cs_CZ" false "Čeština" ]
  [ "cy_GB" false "Cymraeg" ]
  [ "da_DK" true  "Dansk" ]
  [ "de_DE" false "Deutsch" ]
  [ "el_GR" false "Ελληνικά" ]
  [ "en_GB" false "English (UK)" ]
  [ "en_US" false "English (US)" ]
  [ "es_ES" false "Español" ]
  [ "et_EE" false "Eesti" ]
  [ "fi_FI" false "Suomi" ]
  [ "fr_FR" false "Français" ]
  [ "gu_IN" false "\u0a97\u0ac1\u0a9c\u0ab0\u0abe\u0aa4\u0ac0" ]	% Gujarati
  [ "he_IL" false "תירבע" ]
% [ "hi_IN" false "\u0939\u093f\u0928\u094d\u0926\u0940" ]	% Hindi
  [ "hi_IN" false "\u0939\u093f\u0902\u0926\u0940" ]	% Hindi
  [ "hr_HR" false "Hrvatski" ]
  [ "hu_HU" false "Magyar" ]
  [ "id_ID" false "Bahasa Indonesia" ]
  [ "it_IT" false "Italiano" ]
  [ "ja_JP" false "日本語" ]
% [ "km_KH" false "\u1781\u17d2\u1798\u17c2\u179a" ]		% Khmer
  [ "km_KH" false "Khmer" ]
  [ "ko_KR" false "한글" ]
  [ "lt_LT" false "Lietuvių" ]
  [ "mk_MK" false "Македонски" ]
  [ "mr_IN" false "\u092e\u0930\u093e\u0920\u0940" ]		% Marathi
  [ "nb_NO" false "Norsk" ]
  [ "nl_NL" false "Nederlands" ]
  [ "pa_IN" false "\u0a2a\u0a70\u0a1c\u0a3e\u0a2c\u0a40" ]	% Punjabi
  [ "pl_PL" false "Polski" ]
  [ "pt_BR" false "Português (Brasil)" ]
  [ "pt_PT" false "Português" ]
  [ "ro_RO" false "Română" ]
  [ "ru_RU" false "Русский" ]
  [ "sk_SK" false "Slovenčina" ]
  [ "sl_SI" false "Slovenščina" ]
  [ "sr_CS" false "Srpski" ]
  [ "sv_SE" false "Svenska" ]
  [ "ta_IN" false "\u0ba4\u0bae\u0bbf\u0bb4\u0bcd" ]		% Tamil
  [ "tr_TR" false "Türkçe" ]
  [ "uk_UA" false "Українська" ]
  [ "vi_VN" false "Tiếng Việt" ]
  [ "xh_ZA" false "isiXhosa" ]
  [ "zh_CN" false "简体中文" ]
  [ "zh_TW" false "繁體中文 (台灣)" ]
  [ "zu_ZA" false "isiZulu" ]
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

  pmenu.init
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


