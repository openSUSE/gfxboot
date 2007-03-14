% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Profile selection dialog.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Some global vars.
%

% fallback if we can't parse "profiles"
/profile.options	[ "" ] def
/profile.items		[ "Broken Profiles" ] def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Parse "profiles" file.
%
% ( ) ==> ( )
%
/profile.parsedata {
  /pf.tmp.datalen profile.data length def
  /pf.tmp.str profile.data cvs def
 
  /profile.default 0 def

  pf.tmp.datalen 0 eq { return } if
  pf.tmp.str pf.tmp.datalen 1 sub get '\n' ne { return } if

  '\n' seteotchar

  /profile.items [

    /pf.tmp.len 0 def
    /pf.tmp.cnt 0 def
    {
      pf.tmp.str pf.tmp.len add strdup
      dup dup length 0 put
      /pf.tmp.len over length 1 add pf.tmp.len add def

      dup 0 get '*' eq { 1 add /profile.default pf.tmp.cnt def } if

      pf.tmp.len pf.tmp.datalen ge { exit } if

      /pf.tmp.cnt inc
    } loop

  ] def

  ' ' seteotchar

  /profile.options [

     profile.items {
       dup length add
       dup 0 0 put
       1 add
     } forall

  ] def

  0 seteotchar

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Build profile list.
%
% ( ) ==> ( )
%
/profile.init {
  /xmenu.profile .xm_size array def
  /xmenu xmenu.profile def

  profile.parsedata

  xmenu .xm_current profile.default put
  xmenu .xm_list profile.items put
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Update profile.
%
% ( ) ==> ( )
%
/profile.update {
  /xmenu xmenu.profile def

  /window.action actRedrawPanel def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show profile menu.
%
% ( ) => ( )
%
/panel.profile {
  "profile" help.setcontext

  window.xmenu
  dup .xmenu xmenu.profile put
  dup .xmenu.update /profile.update put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of panel entry.
%
% ( ) => ( width )
%
/panel.profile.width {
  /xmenu xmenu.profile def

  pmenu.width
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.profile.update {
  /xmenu xmenu.profile def

  pmenu.panel.update
} def


