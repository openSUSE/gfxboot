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
%% include keymap.de.inc
%% include keymap.es.inc
%% include keymap.ja.inc
%% include keymap.hu.inc
%% include keymap.sk.inc

% must not be empty
/keymaps [
  [ "cs" keymap.cs ]
  [ "en" .undef    ]
%  [ "fr" keymap.fr ]
  [ "de" keymap.de ]
  [ "es" keymap.es ]
%  [ "it" keymap.it ]
  [ "ja" keymap.ja ]
%  [ "ru" keymap.ru ]
  [ "hu" keymap.hu ]
  [ "sk" keymap.sk ]
] def


