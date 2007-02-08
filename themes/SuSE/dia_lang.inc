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
/.la.name   1 def
/lang.defaultnames [
  [ "af_ZA" "Afrikaans" ]
  % [ "ar_EG" "\u064a\u0628\u0631\u0639" ]
  [ "ar_EG" "\ufef2\ufe91\ufeae\ufecb" ]
  [ "bg_BG" "Български" ]
  [ "bn_BD" "\u09ac\u09be\u0982\u09b2\u09be" ]		% Bengali
  [ "bs_BA" "Bosanski" ]
  [ "ca_ES" "Català" ]
  [ "cs_CZ" "Čeština" ]
  [ "cy_GB" "Cymraeg" ]
  [ "da_DK" "Dansk" ]
  [ "de_DE" "Deutsch" ]
  [ "el_GR" "Ελληνικά" ]
  [ "en_GB" "English (UK)" ]
  [ "en_US" "English (US)" ]
  [ "es_ES" "Español" ]
  [ "et_EE" "Eesti" ]
  [ "fi_FI" "Suomi" ]
  [ "fr_FR" "Français" ]
  [ "gu_IN" "\u0a97\u0ac1\u0a9c\u0ab0\u0abe\u0aa4\u0ac0" ]	% Gujarati
  [ "he_IL" "תירבע" ]
  % [ "hi_IN" "\u0939\u093f\u0928\u094d\u0926\u0940" ]	% Hindi
  [ "hi_IN" "\u0939\u093f\u0902\u0926\u0940" ]	% Hindi
  [ "hr_HR" "Hrvatski" ]
  [ "hu_HU" "Magyar" ]
  [ "id_ID" "Bahasa Indonesia" ]
  [ "it_IT" "Italiano" ]
  [ "ja_JP" "日本語" ]
  % [ "km_KH" "\u1781\u17d2\u1798\u17c2\u179a" ]		% Khmer
  [ "km_KH" "Khmer" ]
  [ "ko_KR" "한글" ]
  [ "lt_LT" "Lietuvių" ]
  [ "mk_MK" "Македонски" ]
  [ "mr_IN" "\u092e\u0930\u093e\u0920\u0940" ]		% Marathi
  [ "nb_NO" "Norsk" ]
  [ "nl_NL" "Nederlands" ]
  [ "pa_IN" "\u0a2a\u0a70\u0a1c\u0a3e\u0a2c\u0a40" ]	% Punjabi
  [ "pl_PL" "Polski" ]
  [ "pt_BR" "Português (Brasil)" ]
  [ "pt_PT" "Português" ]
  [ "ro_RO" "Română" ]
  [ "ru_RU" "Русский" ]
  [ "sk_SK" "Slovenčina" ]
  [ "sl_SI" "Slovenščina" ]
  [ "sr_CS" "Srpski" ]
  [ "sv_SE" "Svenska" ]
  [ "ta_IN" "\u0ba4\u0bae\u0bbf\u0bb4\u0bcd" ]		% Tamil
  [ "tr_TR" "Türkçe" ]
  [ "uk_UA" "Українська" ]
  [ "vi_VN" "Tiếng Việt" ]
  [ "xh_ZA" "isiXhosa" ]
  [ "zh_CN" "简体中文" ]
  [ "zh_TW" "繁體中文 (台灣)" ]
  [ "zu_ZA" "isiZulu" ]
] def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Get language name.
%
% Returns locale if not found.
%
% ( locale ) ==> ( name )
%
/lang.getdefname {
  lang.defaultnames {
    dup .la.locale get 2 index eq { .la.name get exch pop exit } { pop } ifelse
  } forall
  % try a loose match
  lang.defaultnames {
    dup .la.locale get 2 index locale.cmp { .la.name get exch pop exit } { pop } ifelse
  } forall
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

  % Why? --> see dia_install.inc; same there.
  window.action actRedraw eq { pmenu.update } if
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


