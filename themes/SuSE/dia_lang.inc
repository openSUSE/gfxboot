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
%  [ "ar" "\u064a\u0628\u0631\u0639" ]
  [ "ar" "\ufef2\ufe91\ufeae\ufecb" ]
  [ "bn" "Bengali" ]
  [ "bg" "Български" ]
  [ "cs" "Čeština" ]
  [ "cy_GB" "Welsh" ]
  [ "ds" "Dansk" ]
  [ "en" "English" ]
  [ "fr" "Français" ]
  [ "de" "Deutsch" ]
  [ "es" "Español" ]
  [ "el" "Ελληνικά" ]
  [ "he" "תירבע" ]
  [ "it" "Italiano" ]
  [ "ja" "日本語" ]
  [ "hu" "Magyar" ]
  [ "ko" "한글" ]
  [ "lt" "Lietuvių" ]
  [ "nl" "Nederlands" ]
  [ "nb" "Norsk" ]
  [ "pl" "Polski" ]
  [ "pt_PT" "Português" ]
  [ "pt_BR" "Português (Brasil)" ]
  [ "pa" "Punjabi" ]
  [ "ro" "Romanian" ]
  [ "ru" "Русский" ]
  [ "sk" "Slovenčina" ]
  [ "sl" "Slovenščina" ]
  [ "sv" "Svenska" ]
  [ "tr" "Türkçe" ]
  [ "uk" "Українська" ]
  [ "zh_CN" "简体中文" ]
  [ "zh_TW" "繁體中文 (中國臺灣)" ]
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

  % make menu smaller if there are more than 19 language entries
  lang.items length 19 gt {
    xmenu .xm_vspace 1 put
  } if

  % start with current lang

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


