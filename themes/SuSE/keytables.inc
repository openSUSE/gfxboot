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
%% include keymap.es.inc
%% include keymap.fr.inc
%% include keymap.de.inc
%% include keymap.el.inc
%% include keymap.it.inc
%% include keymap.ja.inc
%% include keymap.hu.inc
%% include keymap.ru.inc
%% include keymap.sk.inc
%% include keymap.sl.inc
%% include keymap.sv.inc

% must not be empty
/keymaps [
  [ "ar" .undef    ]
  [ "bn" .undef    ]
  [ "bg" .undef    ]
  [ "cs" keymap.cs ]
  [ "en" .undef    ]
  [ "es" keymap.es ]
  [ "fr" keymap.fr ]
  [ "de" keymap.de ]
  [ "el" keymap.el ]
  [ "it" keymap.it ]
  [ "ja" keymap.ja ]
  [ "hu" keymap.hu ]
  [ "ru" keymap.ru ]
  [ "sk" keymap.sk ]
  [ "sl" keymap.sl ]
  [ "sv" keymap.sv ]
] def


