% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Keyboard mappings.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% keymap layout (diff to us map):
%
% key_code, plain, shift, altgr
%

/.km.locale 0 def
/.km.map    1 def

%% include keymap.cs.inc
%% include keymap.da.inc
%% include keymap.de.inc
%% include keymap.et_EE.inc
%% include keymap.el.inc
%% include keymap.es.inc
%% include keymap.fr.inc
%% include keymap.hu.inc
%% include keymap.it.inc
%% include keymap.ja.inc
%% include keymap.nb.inc
%% include keymap.pl.inc
%% include keymap.pt_BR.inc
%% include keymap.pt_PT.inc
%% include keymap.ru.inc
%% include keymap.sk.inc
%% include keymap.sl.inc
%% include keymap.sv.inc
%% include keymap.tr.inc

% array must not be empty
/keymaps [
  [ "ar"    .undef       ]
  [ "bg"    .undef       ]
  [ "bn"    .undef       ]
  [ "ca_ES" .undef       ]
  [ "cs"    keymap.cs    ]
  [ "cy_GB" .undef       ]
  [ "da"    keymap.da    ]
  [ "de"    keymap.de    ]
  [ "et_EE" keymap.et_EE ]
  [ "el"    keymap.el    ]
  [ "en_GB" .undef       ]
  [ "en_US" .undef       ]
  [ "es"    keymap.es    ]
  [ "fi"    .undef       ]
  [ "fr"    keymap.fr    ]
  [ "he"    .undef       ]
  [ "hu"    keymap.hu    ]
  [ "it"    keymap.it    ]
  [ "ja"    keymap.ja    ]
  [ "ko"    .undef       ]
  [ "lt"    .undef       ]
  [ "nb"    keymap.nb    ]
  [ "nl"    .undef       ]
  [ "pa"    .undef       ]
  [ "pl"    keymap.pl    ]
  [ "pt_BR" keymap.pt_BR ]
  [ "pt_PT" keymap.pt_PT ]
  [ "ro"    .undef       ]
  [ "ru"    keymap.ru    ]
  [ "sk"    keymap.sk    ]
  [ "sl"    keymap.sl    ]
  [ "sv"    keymap.sv    ]
  [ "tr"    keymap.tr    ]
  [ "uk"    .undef       ]
  [ "vi"    .undef       ]
  [ "zh_CN" .undef       ]
  [ "zh_TW" .undef       ]
] def


