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
  [ "Czech"        "cs_CZ" "czech"        keymap.cs_CZ ]
  [ "Danish"       "da_DK" "danish"       keymap.da_DK ]
  [ "German"       "de_DE" "german"       keymap.de_DE ]
  [ "Estonian"     "et_EE" "estonian"     keymap.et_EE ]
  [ "English-US"   "en_US" "english-us"   .undef       ]
  [ "Greek"        "el_GR" "greek"        keymap.el_GR ]
  [ "Spanish"      "es_ES" "spanish"      keymap.es_ES ]
  [ "French"       "fr_FR" "french"       keymap.fr_FR ]
  [ "Hungarian"    "hu_HU" "hungarian"    keymap.hu_HU ]
  [ "Italian"      "it_IT" "italian"      keymap.it_IT ]
  [ "Japanese"     "ja_JP" "japanese"     keymap.ja_JP ]
  [ "Norwegian"    "nb_NO" "norwegian"    keymap.nb_NO ]
  [ "Polish"       "pl_PL" "polish"       keymap.pl_PL ]
  [ "Portugese-BR" "pt_BR" "portugese-br" keymap.pt_BR ]
  [ "Portugese"    "pt_PT" "portugese"    keymap.pt_PT ]
  [ "Russian"      "ru_RU" "russian"      keymap.ru_RU ]
  [ "Slovak"       "sk_SK" "slovak"       keymap.sk_SK ]
  [ "Slovene"      "sl_SI" "slovene"      keymap.sl_SI ]
  [ "Swedish"      "sv_SE" "swedish"      keymap.sv_SE ]
  [ "Turkish"      "tr_TR" "turkish"      keymap.tr_TR ]
] def


