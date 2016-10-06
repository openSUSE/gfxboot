% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% screen mode dialog
%
% default vs. high-contrast
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/.smode_default	0 def
/.smode_high	1 def

/smode.default .smode_default def
/smode.config_type .undef def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build menu list.
%
% ( ) ==> ( )
%
/smode.init {
  /xmenu.smode .xm_size array def

  /xmenu xmenu.smode def

  xmenu .xm_list [ "Default" "High-Contrast" ] put

  xmenu .xm_title "Sceen Mode" put

  xmenu .xm_current smode.default put

  % just once (see video.init)
  /smode.init { } def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update screen mode menu.
%
% ( ) ==> ( )
%
/smode.update {
  /xmenu xmenu.smode def

  /smode.config_type xmenu .xm_current get def

  /window.action actRedrawPanel def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show screen update menu.
%
% ( ) => ( )
%
/panel.smode {
  "smode" help.setcontext

  window.xmenu
  dup .xmenu xmenu.smode put
  dup .xmenu.update /smode.update put
  dup window.init
      window.show
} def


