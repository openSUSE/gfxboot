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
/.km.id     1 def
/.km.map    2 def

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
  [ "Arabic"                  "arabic"               .undef       ]
  [ "Belgian"                 "be-latin1"            .undef       ]
  [ "Canadian (Multilingual)" "cn-latin1"            .undef       ]
  [ "Croatian"                "croat"                .undef       ]
  [ "Czech"                   "cz-us-qwertz"         keymap.cs_CZ ]
  [ "Czech (qwerty)"          "cz-lat2-us"           .undef       ]
  [ "Danish"                  "dk"                   keymap.da_DK ]
  [ "Dutch"                   "nl"                   .undef       ]
  [ "Dvorak"                  "dvorak"               .undef       ]
  [ "English (UK)"            "uk"                   .undef       ]
  [ "English (US)"            "us"                   .undef       ]
  [ "Estonian"                "et"                   keymap.et_EE ]
  [ "Finnish"                 "fi-latin1"            .undef       ]
  [ "French"                  "fr-latin1"            keymap.fr_FR ]
  [ "French (Canada)"         "cf"                   .undef       ]
  [ "German"                  "de-latin1-nodeadkeys" keymap.de_DE ]
  [ "German (Switzerland)"    "sg-latin1"            .undef       ]
  [ "Greek"                   "gr"                   keymap.el_GR ]
  [ "Hungarian"               "hu"                   keymap.hu_HU ]
  [ "Icelandic"               "is-latin1"            .undef       ]
  [ "Italian"                 "it"                   keymap.it_IT ]
  [ "Japanese"                "jp106"                keymap.ja_JP ]
  [ "Khmer"                   "khmer"               .undef        ]
  [ "Korean"                  "korean"              .undef        ]
  [ "Lithuanian"              "lt.baltic"           .undef        ]
  [ "Norwegian"               "no-latin1"            keymap.nb_NO ]
  [ "Polish"                  "Pl02"                 keymap.pl_PL ]
  [ "Portuguese"              "pt-latin1"            keymap.pt_PT ]
  [ "Portuguese (Brazil)"     "br-abnt2"             keymap.pt_BR ]
  [ "Russian"                 "ruwin_alt-UTF-8"      keymap.ru_RU ]
  [ "Serbian"                 "sr-cy"                .undef       ]
  [ "Slovak"                  "sk-qwertz"            keymap.sk_SK ]
  [ "Slovak (qwerty)"         "sk-qwerty"            .undef       ]
  [ "Slovene"                 "slovene"              keymap.sl_SI ]
  [ "Spanish"                 "es"                   keymap.es_ES ]
  [ "Spanish (Latin America)" "la-latin1"            .undef       ]
  [ "Swedish"                 "sv-latin1"            keymap.sv_SE ]
  [ "Tajik"                   "tj"                   .undef       ]
  [ "Turkish"                 "trq"                  keymap.tr_TR ]
  [ "Ukrainian"               "ua"                   .undef       ]
] def


