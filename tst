#! /bin/sh

what=$1
theme=$2

[ "$theme" ] || theme=SuSE

if [ ! "$what" -o ! -x ~/gfxtest/tst.$what ] ; then
  echo "usage: tst what"
  exit
fi

make BINDIR=../../ -C themes/$theme || exit

file=themes/$theme/boot/message
[ "$what" = install -o "$what" = install3 -o "$what" = cdrom ] && file=themes/$theme/install/bootlogo

cp $file ~/gfxtest/bootlogo
cd ~/gfxtest/
./tst.$what

