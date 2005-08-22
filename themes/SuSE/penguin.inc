% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% "Penguins" boot screen.
%
%    Copyright (C) 2001-2002, Raphael Quinet <quinet@gamers.org>
%    Copyright (C) 2005 Steffen Winterfeldt <snwint@suse.de>
%
%    This program is free software; you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation; either version 2 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program; if not, write to the Free Software
%    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
%
% Revision history:
% 2001-11-15 - (xray-blue.config) file derived from xray-green.config
% 2002-01-04 - file derived from xray-blue.config
% 2002-01-05 - keystrokes can influence penguins, added timeout message
% 2002-01-10 - adjusted the speed of the penguins
% 2005-08-21 - reworked graphics for 800x600 @ 16 bit color
%            - reimplemented to fit to current openSUSE layout
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Original comment by Raphael:
%
%     This script is based on those included in SuSE 7.2 and SuSE 7.3, modified
%     by Raphael Quinet.   The walking penguins were extracted from the program
%     "xpenguins" (http://xpenguins.seul.org/), which had borrowed them from the
%     game "Pingus" (http://pingus.seul.org/).  The original "walker" was created
%     by Joel Fauche <joel.fauche@wanadoo.fr>, the "tumbler" was created by Craig
%     Timpany <timpany@es.co.nz>, the "reader" and the "superpenguin" were
%     created by Rob Gietema <tycoon@planetdescent.com>, Robin Hogan
%     <R.J.Hogan@reading.ac.uk> and Brian Chu <chub@stuy.yi.org>.
% 
% Requires the patched syslinux version included in openSUSE 10.0 or later.
%
% For more information on the original work done by Raphael, see:
% http://www.gamers.org/~quinet/lilo/.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -




% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% Panel penguin entry.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show help window.
%
% ( ) => ( )
%
/panel.ptheme {
  /panel panel.short def
  penguin_about_popup
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Return width of panel entry.
%
% ( ) => ( width )
%
/panel.ptheme.width {
  "About" strsize pop
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Redraw panel entry.
%
% ( panel ) => ( )
%
/panel.ptheme.update {
  panel.text.moveto
  "About" show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Show penguin theme 'about' box.
%
% ( ) ==> ( )
%
/penguin_about_popup {
  window.dialog

  dup .title "About" put
  dup .text
"Penguin theme originally made by Raphael Quinet <quinet@gamers.org>.

See http://www.gamers.org/~quinet/lilo/.

Modernized for openSUSE by me <snwint@suse.de>"

  put
  dup .buttons [
    button.ok button.default actRedraw button.setaction
  ] put
  dup window.init
      window.show
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
%
% penguin animations
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

/p.xmas.xmin   192 def
/p.xmas.xmax   556 def
/p.xmas.x      500 def
/p.xmas.y       89 def
/p.xmas.dx      -4 def
/p.xmas.frame    0 def
/p.xmas.frames   8 def
/p.xmas.src.x  252 def
/p.xmas.src.y    0 def
/p.xmas.src.w   32 def
/p.xmas.src.h   45 def


/p.walk.xmin    80 def
/p.walk.xmax   720 def
/p.walk.x      200 def
/p.walk.y      523 def
/p.walk.dx       4 def
/p.walk.frame    0 def
/p.walk.frames   8 def
/p.walk.src.x    3 def
/p.walk.src.y    1 def
/p.walk.src.w   30 def
/p.walk.src.h   30 def

/p.read.timer    0 def
/p.read.frame    0 def
/p.read.frames   4 def
/p.read.src.x  515 def
/p.read.src.y    1 def


/p.fall.ymax   520 def
/p.fall.ymin   -31 def
/p.fall.x      762 def
/p.fall.y        0 def
/p.fall.frame    0 def
/p.fall.frames   8 def
/p.fall.src.x    3 def
/p.fall.src.y   65 def
/p.fall.src.w   30 def
/p.fall.src.h   25 def
/p.fall.dy      -4 def	% for super penguin

/p.super     false def	% show super penguin
/p.super.frames  2 def
/p.super.src.x 644 def
/p.super.src.y   0 def
/p.super.src.h  31 def


/ptheme.init {
  currentimage

  "panim.jpg" findfile dup setimage 0 0 image.size unpackimage /panim.img exch def free
  "panim_a.jpg" findfile dup setimage 0 0 image.size unpackimage /panim_a.img exch def free

  setimage


  % xmas penguin

  % save drawing background
  p.xmas.xmin p.xmas.y moveto
  /p.xmas.back
    p.xmas.xmax p.xmas.xmin sub p.xmas.src.w add p.xmas.dx abs add
    p.xmas.src.h savescreen
  def

  % it just needs the right size
  /p.xmas.single 0 0 moveto p.xmas.src.w p.xmas.dx abs add p.xmas.src.h savescreen def


  % walking penguin

  % save drawing background
  p.walk.xmin p.walk.y moveto
  /p.walk.back
    p.walk.xmax p.walk.xmin sub p.walk.src.w add p.walk.dx abs add
    p.walk.src.h savescreen
  def

  % it just needs the right size
  /p.walk.single 0 0 moveto p.walk.src.w p.walk.dx abs add p.walk.src.h savescreen def


  % falling penguin

  % save drawing background
  /p.fall.back p.fall.x 10 moveto p.fall.src.w p.fall.src.h savescreen def

  % one background line
  /p.fall.back1 p.fall.x 10 moveto p.fall.src.w 1 savescreen def

  % it just needs the right size
  /p.fall.single 0 0 moveto p.fall.src.w p.fall.src.h savescreen def

} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw next Xmas penguin frame.
%
% ( ) ==> ( )
%
/p.xmas.animate {
  p.xmas.dx 0 lt {
    p.xmas.dx p.xmas.x add p.xmas.xmin lt {
      /p.xmas.dx p.xmas.dx neg def
    } if
  } {
    p.xmas.dx p.xmas.x add p.xmas.xmax gt {
      /p.xmas.dx p.xmas.dx neg def
    } if
  }
  ifelse

  /p.xmas.x p.xmas.x p.xmas.dx add def
  /p.xmas.frame p.xmas.frame 1 add p.xmas.frames mod def

  % copy background
  p.xmas.x p.xmas.xmin sub 0 moveto
  p.xmas.back 0xff p.xmas.single blend3

  % add penguin
  p.xmas.src.x p.xmas.src.w p.xmas.frame mul add
  p.xmas.src.y p.xmas.dx 0 gt { p.xmas.src.h add } if moveto
  panim.img panim_a.img p.xmas.single blend3

  % draw
  p.xmas.x p.xmas.y moveto p.xmas.single restorescreen
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw next walking penguin frame.
%
% ( ) ==> ( )
%
/p.walk.animate {
  /p.read.timer p.read.timer 1 add 0 min def

  p.read.timer 0 lt {
    % slow down reading
    p.read.timer 2 mod 0 eq { return } if
    /p.read.frame p.read.frame 1 add p.read.frames mod def
  } {
    p.walk.dx 0 lt {
      p.walk.dx p.walk.x add p.walk.xmin lt {
        /p.walk.dx p.walk.dx neg def
      } if
    } {
      p.walk.dx p.walk.x add p.walk.xmax gt {
        /p.walk.dx p.walk.dx neg def
      } if
    }
    ifelse

    /p.walk.x p.walk.x p.walk.dx add def
    /p.walk.frame p.walk.frame 1 add p.walk.frames mod def
  } ifelse

  % copy background
  p.walk.x p.walk.xmin sub 0 moveto
  p.walk.back 0xff p.walk.single blend3

  p.read.timer 0 lt {
    % add penguin
    p.read.src.x p.walk.src.w p.read.frame mul add
    p.read.src.y
  } {
    % add penguin
    p.walk.src.x p.walk.src.w p.walk.frame mul add
    p.walk.src.y p.walk.dx 0 gt { p.walk.src.h add } if
  } ifelse
  moveto
  panim.img panim_a.img p.walk.single blend3

  % draw
  p.walk.x p.walk.y moveto p.walk.single restorescreen
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw next super penguin frame.
%
% ( ) ==> ( )
%
/p.super.animate {
  p.fall.y p.fall.dy add p.fall.ymin lt {
    /p.fall.y 0 def

    /p.super false def

    return
  } if

  /p.fall.y p.fall.y p.fall.dy add def
  /p.fall.frame p.fall.frame 1 add p.fall.frames mod def

  % copy background
  0 0 moveto
  p.fall.back 0xff p.fall.single blend3

  % add penguin
  p.fall.src.x
  p.fall.src.y p.fall.src.h p.fall.frame mul add moveto
  panim.img panim_a.img p.fall.single blend3

  % draw
  p.fall.x p.fall.y moveto p.fall.single restorescreen
} def


% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Draw falling penguin.
%
% ( timeout time ) ==> ( )
%
/p.timeout.animate {
  dup 0 le {
    /p.super true def
    pop pop

    % it vanishes...
    p.fall.x p.fall.y moveto p.fall.back restorescreen

    p.call.super

    return
  } if

  over sub neg p.fall.ymax mul exch div

  dup p.fall.y gt {
    p.fall.y 1 2 index 1 sub {
      p.fall.x exch moveto p.fall.back1 restorescreen
    } for
  } if
  /p.fall.y exch def
  /p.fall.frame p.fall.frame 1 add p.fall.frames mod def

  % copy background
  0 0 moveto
  p.fall.back 0xff p.fall.single blend3

  % add penguin
  p.fall.src.x p.fall.src.w p.fall.frame mul add
  p.fall.src.y moveto
  panim.img panim_a.img p.fall.single blend3

  % draw
  p.fall.x p.fall.y moveto p.fall.single restorescreen

} def


% call super penguin
/p.call.super {
  /p.super true def

  p.fall.y 0 le {
    /p.fall.y p.fall.ymax def
  } if

  % super penguin has different height
  /p.fall.src.x p.super.src.x def
  /p.fall.src.y p.super.src.y def
  /p.fall.src.h p.super.src.h def

  % and less frames
  /p.fall.frames p.super.frames def

  % change them
  p.fall.back free
  /p.fall.back p.fall.x 10 moveto p.fall.src.w p.fall.src.h savescreen def

  p.fall.single free
  /p.fall.single 0 0 moveto p.fall.src.w p.fall.src.h savescreen def
} def


ptheme {
  % ( time ) ==> ( )
  /Timer {
    dup 3 mod 0 eq { p.xmas.animate } if
    dup 3 mod 1 eq { p.walk.animate } if
    pop
    p.super { p.super.animate } if
  } def

} if


