% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% window code
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


% public words:
%
% window.dialog		( ) ==> ( window )
%   - create a new dialog
%
% window.init		( window ) ==> ( )
%   - initialize window
%
% window.show		( window ) ==> ( )
%   - draw window
%
% window.current	( ) ==> ( window )
%   - the top level window
%
% window.action		( ) ==> ( action )
%   - recent window action
%
% window.input		( key_in ) ==> ( key_out )
%   - handle keyboard input
%
% window.done		( ) ==> ( )
%   - close top level window
%
%
% constants:
%   - window.action
%       actNothing	- do nothing
%       actExit		- leave boot menu
%       actCloseInfo	- close info window
%       actPassword	- password entered
%       actStart	- boot kernel
%       actEject	- eject CD
%       actPowerOff	- turn computer off
%       actReboot	- reboot computer
%       actRedraw	- redraw everything
%       actNoClose	- don't close dialog (it's a flag)
%


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% window related global variables
%

% all open windows are stacked here
/window.list 8 array def
/window.list.index 0 def

% the top level window
% /window.current

% action selected by closing window
/window.action actNothing def

% window field definitions
/widget.size 0 def
/newfield { widget.size def /widget.size widget.size 1 add def } def

/.type           newfield
/.x              newfield
/.y              newfield
/.width          newfield
/.height         newfield
/.width.min      newfield
/.position       newfield
/.color.fg       newfield
/.color.bg       newfield
/.font           newfield
/.saved          newfield
/.title          newfield
/.title.fg       newfield
/.title.bg       newfield
/.title.height   newfield
/.text           newfield
/.text.x         newfield
/.text.y         newfield
/.buttons        newfield
/.button.y       newfield
/.ed             newfield
/.ed.font        newfield
/.ed.list        newfield
/.ed.buffer.list newfield
/.ed.text.list   newfield
/.ed.width       newfield
/.ed.focus       newfield
/.ed.pw_field    newfield
/.xmenu          newfield
/.xmenu.update   newfield
/.dont_free      newfield

% window types
/t_dialog 100 def
/t_help   101 def
/t_main   102 def
/t_xmenu  103 def

% actions
/actNothing           0 def
/actExit              1 def
/actCloseInfo         2 def
/actPassword          3 def
/actStart             4 def
/actEject             5 def
/actPowerOff          6 def
/actRedraw            7 def
/actRedrawPanel       8 def
/actInstallOK         9 def
/actInstallCancel    10 def
/actReboot           11 def
/actNoClose       0x100 def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Create new dialog window.
%
% ( ) ==> ( window )
%
/window.dialog {
  widget.size array
  dup .type t_dialog put
  dup .position 8 put		% centered at 8/10 of screen height
  dup .x 0 put
  dup .y 0 put
  dup .width.min 0 put
  dup .color.fg black put
  dup .color.bg lightgray put
  dup .font font.normal put
  dup .title.fg white put
  dup .title.bg title.bg put
  dup .title.height help.title.height put
  dup .text.x 12 put
  dup .text.y help.title.height 10 add put
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Handle keyboard input.
%
% ( key_in ) ==> ( key_out )
%
/window.input {
  window.current .undef ne {
    window.current .type get
    dup t_dialog eq { exch dialog.input exch } if
    dup t_help eq { exch help.input exch } if
    dup t_main eq { exch main.input exch } if
    dup t_xmenu eq { exch xmenu.input exch } if
    pop

    % maybe there is an editable input field
    dup 0 ne {
      window.current .ed get .undef ne {
        window.current .ed.font get setfont
        window.current .color.fg get setcolor
        window.current .ed get exch edit.input
        0
      } if
    } if

    % only top level window gets input
    pop 0

  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Initialize window.
%
% ( window ) ==> ( )
%
/window.init {
  dup .type get
  dup t_dialog eq { pop dialog.init return } if
  dup t_help eq { pop help.init return } if
  dup t_main eq { pop main.init return } if
  dup t_xmenu eq { pop xmenu.init return } if
  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show window.
%
% ( window ) ==> ( )
%
/window.show {
  dup .type get
  dup t_dialog eq { pop dialog.show return } if
  dup t_help eq { pop help.show return } if
  dup t_main eq { pop main.show return } if
  dup t_xmenu eq { pop xmenu.show return } if
  pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Add window to list.
%
% ( window ) ==> ( )
%
/window.push {
  window.list.index window.list length ge { pop return } if
  /window.current over def
  window.list window.list.index rot put
  /window.list.index window.list.index 1 add def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Remove window from list.
%
% ( ) ==> ( window )
%
/window.pop {
  window.list.index 0 eq { .undef return } if
  /window.list.index window.list.index 1 sub def
  window.list window.list.index get
  window.list window.list.index .undef put
  /window.current
    window.list.index 0 eq { .undef } { window.list window.list.index 1 sub get } ifelse
  def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Close top level window.
%
% ( ) ==> ( )
%
/window.done {
  window.current .undef ne {
    window.current dup .type get
    dup t_help eq { help.done } if
    pop
    % restore saved background and free bg image
    dup .saved get .undef ne {
      dup .x get 1 sub over .y get 1 sub moveto
      dup .saved get dup restorescreen free
      dup .saved .undef put
    } if
    % free input field memory
    dup .ed get .undef ne {
      dup .ed get 2 get free		% background
      dup .ed get free
      dup .ed .undef put
    } if
    dup .ed.list get dup {
      { dup 2 get free 2 .undef put } forall
    } { pop } ifelse
    pop
    % remove it from window list
    window.pop
    % free buttons & button list
    dup .buttons get
      dup .undef ne {
        dup length 0 gt {
          dup length 1 sub 0 1 rot {
            over exch get free
          } for
        } if
      } if
      free
    % free window
    dup .dont_free get { pop } { free } ifelse
  } if
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Handle keyboard input.
%
% ( key_in ) ==> ( key_out )
%
/dialog.input {
  dup 0 eq { return } if

  /window.buttons window.current .buttons get def

  window.buttons .undef ne { window.buttons length {

    dup keyEnter eq {
      window.buttons window.findselected
      over over get 7 get /window.action exch def get
      dup button.press 100000 usleep
      window.action actNoClose and {
        window.action dialog.specialaction { button.show } if
      } {
        pop window.done
      } ifelse
      pop 0
    } if

    window.current .ed.list get {
      dup keyDown eq over keyTab eq or {
        window.current .ed.focus get
        window.current .ed.list get over get edit.hidecursor

        1 add window.current .ed.list get length mod
        window.current .ed.focus 2 index put
        window.current .ed.list get exch get edit.showcursor
        pop 0
      } if

      dup keyUp eq over keyShiftTab eq or {
        window.current .ed.focus get
        window.current .ed.list get over get edit.hidecursor

        1 sub window.current .ed.list get length exch over add exch mod
        window.current .ed.focus 2 index put
        window.current .ed.list get exch get edit.showcursor
        pop 0
      } if

%      dup keyTab eq {
%        window.findselected 1 add window.buttons length mod
%        window.selectbutton
%        pop 0
%      } if

    } {
      dup keyTab eq over keyRight eq or over keyDown eq or {
        window.findselected 1 add window.buttons length mod
        window.selectbutton
        pop 0
      } if

      dup keyLeft eq over keyUp eq or {
        window.findselected window.buttons length 1 sub add window.buttons length mod
        window.selectbutton
        pop 0
      } if
    } ifelse

    dup window.findkey dup 0 ge {
      window.buttons exch
      over over get 7 get /window.action exch def get
      dup button.press 100000 usleep
      window.action actNoClose and {
        window.action dialog.specialaction { button.show } if
      } {
        pop window.done
      } ifelse
      pop 0
    } {
      pop
    } ifelse

  } if } if


  % maybe there are input fields
  dup 0 ne {
    window.current .ed.list get dup {
      window.current .ed.font get
        window.current .ed.focus get window.current .ed.pw_field get eq { pwmode } if
        setfont
      window.current .color.fg get setcolor

      window.current .ed.focus get get exch edit.input
      0
    } { pop } ifelse
  } if

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Find selected button.
%
% ( ) ==> ( button_idx )
%
/window.findselected {
  0
  0 1 window.buttons length 1 sub {
    dup
    window.buttons exch get 5 get
    {
      exch pop exit
    } {
      pop
    } ifelse
  } for
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Find button for key.
%
% ( key ) ==> ( button_idx )
%
% button_idx = -1 if not found
%
/window.findkey {
  /window.key exch def
  -1
  window.key 0 eq { return } if
  0 1 window.buttons length 1 sub {
    dup
    window.buttons exch get 6 get window.key eq
    {
      exch pop exit
    } {
      pop
    } ifelse
  } for
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Select button.
%
% ( button_idx ) ==> ( )
%
/window.selectbutton {
  window.findselected
  over over eq {
    pop pop
  } {
    window.buttons exch get button.notdefault button.show
    window.buttons exch get button.default button.show
  } ifelse
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Initialize dialog window.
%
% ( window ) ==> ( )
%
/dialog.init {
  /dialog.tmp exch def

  dialog.tmp .font get setfont

  dialog.tmp .text get dup "" ne { strsize } { pop 0 0 } ifelse
  /dialog.height exch dialog.tmp .text.y get 10 add add def
  /dialog.width exch dialog.tmp .text.x get 1 add 2 mul add dialog.tmp .width.min get max def

  /dialog.width dialog.tmp .title get strsize pop dialog.tmp .text.x get 1 add 2 mul add dialog.width max def

  dialog.tmp .ed.text.list get dup {
    /dialog.width
      dialog.tmp .ed.width get dialog.tmp .text.x get 1 add 2 mul add 8 add dialog.width max
    def
    {
      exec strsize
      /dialog.height exch dialog.height add def
      /dialog.width exch dialog.tmp .text.x get 1 add 2 mul add dialog.width max def
    } forall
  } { pop } ifelse

  dialog.tmp .ed.buffer.list get dup {
    length lineheight 10 add mul /dialog.height exch dialog.height add def
  } { pop } ifelse

  /window.buttons dialog.tmp .buttons get def

  /dialog.button.y dialog.height 5 add def

  window.buttons .undef ne { window.buttons length {
    /dialog.height window.buttons 0 get 3 get dialog.button.y add 8 add def
  } if } if

  /dialog.y screen.size exch pop dialog.tmp .position get mul 10 div dialog.height sub 2 div def

  window.buttons .undef ne { window.buttons length {
    10
    0 1 window.buttons length 1 sub {
      window.buttons exch get
      dup 1 dialog.button.y dialog.y add put
      2 get 10 add add
    } for

    dialog.width max /dialog.width exch def
  } if } if

  /dialog.x screen.size pop dialog.width sub 2 div def

  window.buttons .undef ne { window.buttons length {
    % calculate button x positions
    dialog.width 0
    0 1 window.buttons length 1 sub {
      window.buttons exch get 2 get add
    } for
    sub window.buttons length 1 add div
    dialog.x over add
    0 1 window.buttons length 1 sub {
      window.buttons exch get
      over over 0 rot put
      2 get add over add
    } for
    pop pop
  } if } if

  % store values

  dialog.tmp
  dup .x dialog.x put
  dup .y dialog.y put
  dup .width dialog.width put
  dup .height dialog.height put
      .button.y dialog.button.y put

  /dialog.tmp .undef def
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw dialog window.
%
% ( window ) ==> ( )
%
/dialog.show {
  /dialog.tmp exch def

  % put into list early, so drawing functions can access it there
  dialog.tmp window.push

  % now start drawing

  dialog.tmp .x get 1 sub dialog.tmp .y get 1 sub moveto
  white black
  dialog.tmp .width get 2 add dialog.tmp .height get 2 add
  over over
  savescreen
  dialog.tmp .saved rot put
  drawborder

  dialog.tmp .color.bg get setcolor
  dialog.tmp .x get dialog.tmp .y get moveto
  dialog.tmp .width get dialog.tmp .height get fillrect

  dialog.tmp .title.bg get setcolor
  dialog.tmp .x get 1 add dialog.tmp .y get 1 add moveto
  dialog.tmp .width get 2 sub dialog.tmp .title.height get 1 sub fillrect

  dialog.tmp .x get 10 add dialog.tmp .y get 3 add moveto
  dialog.tmp .title.fg get setcolor
  dialog.tmp .title get show

  dialog.tmp .color.fg get setcolor
  dialog.tmp .x get dialog.tmp .y get moveto
  dialog.tmp .text.x get dialog.tmp .text.y get rmoveto
  dialog.tmp .text get show

  dialog.tmp .ed.text.list get dup {
    /dialog.tmp.idx 0 def
    {
      exec
      show
      dialog.tmp .ed.buffer.list get dialog.tmp.idx get

      dup {

        3 7 rmoveto

        /dialog.tmp.buf dialog.tmp .ed.list get dialog.tmp.idx get def

        dialog.tmp.buf {
          /dialog.tmp.doinit false def
          dialog.tmp.buf 2
            dialog.tmp .ed.width get fontheight 2 add savescreen
          put
        } {
          /dialog.tmp.doinit true def
          /dialog.tmp.buf [
            currentpoint
            dialog.tmp .ed.width get fontheight 2 add savescreen
            0 0
            0 0 0
          ] def
        } ifelse

        dialog.tmp.buf 3 2 index put
        dialog.tmp.buf 4 rot cvp length put

        dialog.tmp .ed.list get dialog.tmp.idx dialog.tmp.buf put

        currentcolor
        currentpoint over 1 sub over 2 sub moveto
        black white dialog.tmp .ed.width get 2 add fontheight 5 add drawborder
        moveto -3 lineheight 10 add 7 sub rmoveto
        setcolor

        dialog.tmp.doinit {
          dialog.tmp.buf "" edit.init
        } {
          % we really need a redraw function...
          currentfont
          % hide text in password fields
          dialog.tmp.idx dialog.tmp .ed.pw_field get eq {
            dialog.tmp .ed.font get pwmode setfont
          } if
          dialog.tmp.buf dup 3 get edit.init
          setfont
        } ifelse
        dialog.tmp .ed.focus get dialog.tmp.idx ne { dialog.tmp.buf edit.hidecursor } if

      } { pop } ifelse

      /dialog.tmp.idx inc
    } forall
  } { pop } ifelse

  dialog.tmp .buttons get .undef ne { dialog.tmp .buttons get length {
    0 1 dialog.tmp .buttons get length 1 sub {
      dialog.tmp .buttons get exch get button.show
    } for
  } if } if

  /dialog.tmp .undef def

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Do something without closing the window.
%
% ( action ) ==> ( true|false )
%
% Returns whether the window still exists.
%
/dialog.specialaction {
  actNoClose not and

  true exch

  dup actEject eq {
    bootdrive eject pop
  } if

  dup actPowerOff eq {
    poweroff
  } if

  dup actReboot eq {
    reboot
  } if

  dup actInstallOK eq {
    install.ok
    exch not exch
  } if

%  dup actInstallCancel eq {
%    install.cancel
%    exch not exch
%  } if

  pop
} def


