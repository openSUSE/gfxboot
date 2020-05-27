% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% extra language switch button
%
% Iterate through the locales in config.extralang.locales array.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Initialize.
%
% ( ) ==> ( )
%
/extralang.init {
  /extralang.current 0 def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Get index in language menu.
%
% ( ) ==> ( )
%
/extralang.index {
  0 1 lang.items length 1 sub {
    lang.items over get config.extralang.locales extralang.current get eq { return } { pop } ifelse
  } for
  0
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Get language name.
%
% ( ) ==> ( )
%
/extralang.name {
  config.extralang.locales extralang.current get lang.getdefname
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Set a new language.
%
% ( ) ==> ( )
%
/extralang.update {
  xmenu.lang .xm_current extralang.index put
  lang.update
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Activate selected language.
%
% And also move to next language in list.
%
% ( ) => ( )
%
/panel.extralang {
  extralang.update
  % go to next language
  /extralang.current extralang.current 1 add config.extralang.locales length mod def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of panel entry.
%
% ( ) => ( width )
%
/panel.extralang.width {
  extralang.name strsize pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.extralang.update {
  panel.text.moveto
  extralang.name show.rtl
} def
