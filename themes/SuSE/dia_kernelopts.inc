% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Kernel options dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%
/kernelopts.default 0 def

/kernelopts.options [
  ""
  "apm=off acpi=off mce=off barrier=off ide=nodma idewait=50 i8042.nomux psmouse.proto=bare irqpoll pci=nommconf"
  "acpi=off"
  "nolapic"
] def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build kernelopts list.
%
% ( ) ==> ( )
%
/kernelopts.init {
  /xmenu.kernelopts .xm_size array def

  /xmenu xmenu.kernelopts def

  xmenu .xm_current kernelopts.default put
  xmenu .xm_list [
    "Default"
    "Safe Settings"
    "No ACPI"
    "No Local APIC"
  ] put
  xmenu .xm_title "Kernel" put

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update kernelopts mode.
%
% ( ) ==> ( )
%
/kernelopts.update {
  /xmenu xmenu.kernelopts def

  /window.action actRedrawPanel def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show kernelopts menu.
%
% ( ) => ( )
%
/panel.kernelopts {
  "main" help.setcontext

  window.xmenu
  dup .xmenu xmenu.kernelopts put
  dup .xmenu.update /kernelopts.update put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of panel entry.
%
% ( ) => ( width )
%
/panel.kernelopts.width {
  /xmenu xmenu.kernelopts def

  pmenu.width
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.kernelopts.update {
  /xmenu xmenu.kernelopts def

  pmenu.panel.update
} def


