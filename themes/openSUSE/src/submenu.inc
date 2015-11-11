% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Submenu handling.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% submenu entries are entries that have a label starting with '->FOO ' (note
% the space) where FOO is an arbitrary string identifying the submenu.
%
% Menu entries that have an 'append' entry '->BAR' link to submenu BAR.
%
% As there are spaces in labels required to make this work, use the 'menu
% label' statement in syslinux.

% submenu entries must start with this string, followed by an arbitrary identifier
/submenu.tag "->" def

% submenues are stacked here
/submenu.list 8 array def
/submenu.list.index 0 def

% the current submenu
/submenu.current .undef def

% array mapping submenu indices to global menu indices
/submenu.menuidx.list [ ] def

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Enter submenu.
%
% ( submenu_label ) ==> ( )
%
/submenu.enter {
  submenu.list.index submenu.list length ge { pop return } if

  % append space
  dup length 1 add string exch "%s " 2 index sprintf

  /submenu.current over def
  submenu.list submenu.list.index rot put
  /submenu.list.index submenu.list.index 1 add def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Leave submenu.
%
% ( ) ==> ( submenu_label )
%
/submenu.leave {
  submenu.list.index 0 eq { .undef return } if
  /submenu.list.index submenu.list.index 1 sub def
  submenu.list submenu.list.index get
  submenu.list submenu.list.index .undef put
  /submenu.current
    submenu.list.index 0 eq { .undef } { submenu.list submenu.list.index 1 sub get } ifelse
  def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Create menu.texts and menu.args from orig.menu.texts and orig.menu.args.
%
% ( ) ==> ( )
%
/submenu.build {
  /menu.texts [
    0 1 orig.menu.texts length 1 sub {
      dup submenu.showentry {
        orig.menu.texts exch get
      } { pop } ifelse
    } for
  ] def

  /menu.args [
    0 1 orig.menu.args length 1 sub {
      dup submenu.showentry {
        orig.menu.args exch get
      } { pop } ifelse 
    } for
  ] def

  /submenu.menuidx.list [
    0 1 orig.menu.texts length 1 sub {
      dup submenu.showentry not { pop } if
    } for
  ] def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Determine if this entry should be shown (i.e. is in current submenu).
%
% ( entry_idx ) ==> ( true|false )
%
/submenu.showentry {
  /sm_idx exch def
  sm_idx orig.menu.texts length lt {
    orig.menu.texts sm_idx get
    submenu.current {
      submenu.current strstr 1 eq
    } {
      submenu.tag strstr 1 ne
    } ifelse
  } {
    false
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Map current submenu index to global menu index.
% (Needed to tell the bootloader where we are.)
%
% ( submenu_idx ) ==> ( menu_idx )
%
/submenu.menuidx {
  dup submenu.menuidx.list length lt {
    submenu.menuidx.list exch get
  } if
} def

