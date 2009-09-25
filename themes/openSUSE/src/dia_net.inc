% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% network setup dialogs.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/.net_no	0 def
/.net_dhcp	1 def
/.net_static	2 def

/net.default .net_no def
/net.config_type .undef def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build menu list.
%
% ( ) ==> ( )
%
/net.init {
  /xmenu.net .xm_size array def

  /xmenu xmenu.net def

  xmenu .xm_list [ /txt_no_network "DHCP" /txt_manual_network ] put

  xmenu .xm_title /txt_network_config put

  xmenu .xm_current net.default put

  /input.net.static [ 5 { 127 string } repeat ] def

  % just once (see install.init)
  /net.init { } def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update network selection menu.
%
% ( ) ==> ( )
%
/net.update {
  /xmenu xmenu.net def

  /net.config_type xmenu .xm_current get def

  xmenu .xm_current get .net_static eq {
    net.dialog
  } if

  /window.action actRedrawPanel def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show net selection menu.
%
% ( ) => ( )
%
/panel.net {
  "net" help.setcontext

  window.xmenu
  dup .xmenu xmenu.net put
  dup .xmenu.update /net.update put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of panel entry.
%
% ( ) => ( width )
%
/panel.net.width {
  /xmenu xmenu.net def

  pmenu.width
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.net.update {
  /xmenu xmenu.net def

  pmenu.panel.update
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/net.dialog {
  /dia window.dialog def

  dia .text "" put

  dia .title txt_manual_network_title put

  % ip, netmask, gateway, dns nameserver, domain

  % Must all be of same size!
  dia .ed.list 5 array put
  dia .ed.buffer.list input.net.static put
  dia .ed.text.list [ txt_host_ip txt_netmask txt_gateway_ip txt_nameservers txt_domain ] put

  dia .ed.focus 0 put
  dia .ed.width 300 put

  dia .buttons [
    button.ok button.default actNothing button.setaction
    button.cancel button.notdefault /net.static.abort button.setaction
    config.rtl { exch } if
  ] put

  dia window.init
  dia window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/net.static.abort {
  xmenu.net .xm_current over .xm_last get put
  actNothing
} def


