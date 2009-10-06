% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Keyboard mappings.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% keymap layout (diff to us map):
%
% key_code, plain, shift, altgr
%

/.km.name   0 def
/.km.locale 1 def
/.km.id     2 def
/.km.map    3 def

%% include ../keymaps/keymap.cs_CZ.inc
%% include ../keymaps/keymap.da_DK.inc
%% include ../keymaps/keymap.de_DE.inc
%% include ../keymaps/keymap.et_EE.inc
%% include ../keymaps/keymap.el_GR.inc
%% include ../keymaps/keymap.es_ES.inc
%% include ../keymaps/keymap.fr_FR.inc
%% include ../keymaps/keymap.hu_HU.inc
%% include ../keymaps/keymap.it_IT.inc
%% include ../keymaps/keymap.ja_JP.inc
%% include ../keymaps/keymap.nb_NO.inc
%% include ../keymaps/keymap.pl_PL.inc
%% include ../keymaps/keymap.pt_BR.inc
%% include ../keymaps/keymap.pt_PT.inc
%% include ../keymaps/keymap.ru_RU.inc
%% include ../keymaps/keymap.sk_SK.inc
%% include ../keymaps/keymap.sl_SI.inc
%% include ../keymaps/keymap.sv_SE.inc
%% include ../keymaps/keymap.tr_TR.inc

% array must not be empty
/keymaps [
  [ "Arabic"                  "ar_EG" "arabic"               .undef       ]
  [ "Belgian"                 "wa_BE" "be-latin1"            .undef       ]
  [ "Canadian (Multilingual)" "fr_FR" "cn-latin1"            .undef       ]
  [ "Croatian"                "hr_HR" "croat"                .undef       ]
  [ "Czech"                   "cs_CZ" "cz-us-qwertz"         keymap.cs_CZ ]
  [ "Czech (qwerty)"          "cs_CZ" "cz-lat2-us"           .undef       ]
  [ "Danish"                  "da_DK" "dk"                   keymap.da_DK ]
  [ "Dutch"                   "nl_NL" "nl"                   .undef       ]
  [ "Dvorak"                  "*"     "dvorak"               .undef       ]
  [ "English (UK)"            "en_GB" "uk"                   .undef       ]
  [ "English (US)"            "en_US" "us"                   .undef       ]
  [ "Estonian"                "et_EE" "et"                   keymap.et_EE ]
  [ "Finnish"                 "fi_FI" "fi-latin1"            .undef       ]
  [ "French"                  "fr_FR" "fr-latin1"            keymap.fr_FR ]
  [ "French (Canada)"         "fr_FR" "cf"                   .undef       ]
  [ "German"                  "de_DE" "de-latin1-nodeadkeys" keymap.de_DE ]
  [ "German (Switzerland)"    "de_DE" "sg-latin1"            .undef       ]
  [ "Greek"                   "el_GR" "gr"                   keymap.el_GR ]
  [ "Hungarian"               "hu_HU" "hu"                   keymap.hu_HU ]
  [ "Icelandic"               "*"     "is-latin1"            .undef       ]
  [ "Italian"                 "it_IT" "it"                   keymap.it_IT ]
  [ "Japanese"                "ja_JP" "jp106"                keymap.ja_JP ]
  [ "Khmer"                   "km_KH" "khmer"               .undef        ]
  [ "Korean"                  "ko_KR" "korean"              .undef        ]
  [ "Lithuanian"              "lt_LT" "lt.baltic"           .undef        ]
  [ "Norwegian"               "nb_NO" "no-latin1"            keymap.nb_NO ]
  [ "Polish"                  "pl_PL" "Pl02"                 keymap.pl_PL ]
  [ "Portuguese"              "pt_PT" "pt-latin1"            keymap.pt_PT ]
  [ "Portuguese (Brazil)"     "pt_BR" "br-abnt2"             keymap.pt_BR ]
  [ "Russian"                 "ru_RU" "ruwin_alt-UTF-8"      keymap.ru_RU ]
  [ "Serbian"                 "sr_RS" "sr-cy"                .undef       ]
  [ "Slovak"                  "sk_SK" "sk-qwertz"            keymap.sk_SK ]
  [ "Slovak (qwerty)"         "sk_SK" "sk-qwerty"            .undef       ]
  [ "Slovene"                 "sl_SI" "slovene"              keymap.sl_SI ]
  [ "Spanish"                 "es_ES" "es"                   keymap.es_ES ]
  [ "Spanish (Latin America)" "es_ES" "la-latin1"            .undef       ]
  [ "Swedish"                 "sv_SE" "sv-latin1"            keymap.sv_SE ]
  [ "Tajik"                   "tg_TJ" "tj"                   .undef       ]
  [ "Turkish"                 "tr_TR" "trq"                  keymap.tr_TR ]
  [ "Ukrainian"               "uk_UA" "ua"                   .undef       ]
] def


