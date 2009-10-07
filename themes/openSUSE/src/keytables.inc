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

%% include ../keymaps/keymap.Pl02.inc
%% include ../keymaps/keymap.be-latin1.inc
%% include ../keymaps/keymap.br-abnt2.inc
%% include ../keymaps/keymap.cf.inc
%% include ../keymaps/keymap.cn-latin1.inc
%% include ../keymaps/keymap.croat.inc
%% include ../keymaps/keymap.cz-lat2-us.inc
%% include ../keymaps/keymap.cz-us-qwertz.inc
%% include ../keymaps/keymap.de-latin1-nodeadkeys.inc
%% include ../keymaps/keymap.dk.inc
%% include ../keymaps/keymap.dvorak.inc
%% include ../keymaps/keymap.es.inc
%% include ../keymaps/keymap.et.inc
%% include ../keymaps/keymap.fi-latin1.inc
%% include ../keymaps/keymap.fr-latin1.inc
%% include ../keymaps/keymap.gr.inc
%% include ../keymaps/keymap.hu.inc
%% include ../keymaps/keymap.is-latin1.inc
%% include ../keymaps/keymap.it.inc
%% include ../keymaps/keymap.jp106.inc
%% include ../keymaps/keymap.la-latin1.inc
%% include ../keymaps/keymap.lt.baltic.inc
%% include ../keymaps/keymap.nl.inc
%% include ../keymaps/keymap.no-latin1.inc
%% include ../keymaps/keymap.pt-latin1.inc
%% include ../keymaps/keymap.ruwin_alt-UTF-8.inc
%% include ../keymaps/keymap.sg-latin1.inc
%% include ../keymaps/keymap.sk-qwerty.inc
%% include ../keymaps/keymap.sk-qwertz.inc
%% include ../keymaps/keymap.slovene.inc
%% include ../keymaps/keymap.sr-cy.inc
%% include ../keymaps/keymap.sv-latin1.inc
%% include ../keymaps/keymap.tj.inc
%% include ../keymaps/keymap.trq.inc
%% include ../keymaps/keymap.ua.inc
%% include ../keymaps/keymap.uk.inc

% array must not be empty
/keymaps [
  [ "Arabic"                  "arabic"               .undef                      ]
  [ "Belgian"                 "be-latin1"            keymap.be-latin1            ]
  [ "Canadian (Multilingual)" "cn-latin1"            keymap.cn-latin1            ]
  [ "Croatian"                "croat"                keymap.croat                ]
  [ "Czech"                   "cz-us-qwertz"         keymap.cz-us-qwertz         ]
  [ "Czech (qwerty)"          "cz-lat2-us"           keymap.cz-lat2-us           ]
  [ "Danish"                  "dk"                   keymap.dk                   ]
  [ "Dutch"                   "nl"                   keymap.nl                   ]
  [ "Dvorak"                  "dvorak"               keymap.dvorak               ]
  [ "English (UK)"            "uk"                   keymap.uk                   ]
  [ "English (US)"            "us"                   .undef                      ]
  [ "Estonian"                "et"                   keymap.et                   ]
  [ "Finnish"                 "fi-latin1"            keymap.fi-latin1            ]
  [ "French"                  "fr-latin1"            keymap.fr-latin1            ]
  [ "French (Canada)"         "cf"                   keymap.cf                   ]
  [ "German"                  "de-latin1-nodeadkeys" keymap.de-latin1-nodeadkeys ]
  [ "German (Switzerland)"    "sg-latin1"            keymap.sg-latin1            ]
  [ "Greek"                   "gr"                   keymap.gr                   ]
  [ "Hungarian"               "hu"                   keymap.hu                   ]
  [ "Icelandic"               "is-latin1"            keymap.is-latin1            ]
  [ "Italian"                 "it"                   keymap.it                   ]
  [ "Japanese"                "jp106"                keymap.jp106                ]
  [ "Khmer"                   "khmer"                .undef                      ]
  [ "Korean"                  "korean"               .undef                      ]
  [ "Lithuanian"              "lt.baltic"            keymap.lt.baltic            ]
  [ "Norwegian"               "no-latin1"            keymap.no-latin1            ]
  [ "Polish"                  "Pl02"                 keymap.Pl02                 ]
  [ "Portuguese"              "pt-latin1"            keymap.pt-latin1            ]
  [ "Portuguese (Brazil)"     "br-abnt2"             keymap.br-abnt2             ]
  [ "Russian"                 "ruwin_alt-UTF-8"      keymap.ruwin_alt-UTF-8      ]
  [ "Serbian"                 "sr-cy"                keymap.sr-cy                ]
  [ "Slovak"                  "sk-qwertz"            keymap.sk-qwertz            ]
  [ "Slovak (qwerty)"         "sk-qwerty"            keymap.sk-qwerty            ]
  [ "Slovene"                 "slovene"              keymap.slovene              ]
  [ "Spanish"                 "es"                   keymap.es                   ]
  [ "Spanish (Latin America)" "la-latin1"            keymap.la-latin1            ]
  [ "Swedish"                 "sv-latin1"            keymap.sv-latin1            ]
  [ "Tajik"                   "tj"                   keymap.tj                   ]
  [ "Turkish"                 "trq"                  keymap.trq                  ]
  [ "Ukrainian"               "ua"                   keymap.ua                   ]
] def

