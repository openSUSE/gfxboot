#! /bin/sh


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function tst_cdrom {
  src="test/$1"
  dst="$tmp/$1"
  img="$tmp/cd.iso"
  dosrc="$tmp/.dosemurc.cdrom"
  vm_src=test/vm
  vm_tmp=tmp/vm.cdrom

  rm -f $img $dosrc
  rm -rf $vm_tmp

  isodir=boot/loader
  mkdir -p $dst/$isodir
  test/pisolinux /$isodir <test/isolinux.bin >$dst/$isodir/isolinux.bin
  cp -a $src/* $dst/$isodir
  cp -a $logo $dst/$isodir/bootlogo

  echo "$dst/$isodir/isolinux.bin 1" >$tmp/cd_sort

  mkisofs -o $img -J -r -sort $tmp/cd_sort \
    -b $isodir/isolinux.bin -c $isodir/boot.catalog \
    -publisher "SUSE Products GmbH" \
    -no-emul-boot -boot-load-size 4 -boot-info-table $dst

  rm -f $tmp/cd_sort

  if [ "$program" = dosemu ] ; then
    perl -p -e "s:<image>:`pwd`/$img:g" test/dosemurc.cdrom >$dosrc
    xdosemu -Q -f $dosrc "$@"
  elif [ "$program" = vmware ] ; then
    cp -a $vm_src $vm_tmp
    perl -pi -e "s:<image>:`pwd`/$img:g" $vm_tmp/gfxboot.vmx
    vmware -qx $vm_tmp/gfxboot.vmx
  elif [ "$program" = olddosemu ] ; then

    sw 0 ln -snf /etc/dosemu.conf.cdrom /etc/dosemu.conf
    ln -snf /var/lib/dosemu/global.conf.cdrom /var/lib/dosemu/global.conf
    ln -snf `pwd`/$img /var/lib/dosemu/cdrom

    xdos $*

#    rm -f /var/lib/dosemu/cdrom

    ln -snf /var/lib/dosemu/global.conf.normal /var/lib/dosemu/global.conf
    sw 0 ln -snf /etc/dosemu.conf.normal /etc/dosemu.conf

  fi

}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function tst_boot {
  src="test/$1"
  dst="$tmp/$1"
  img="$tmp/floppy.img"
  dosrc="$tmp/.dosemurc.floppy"

  rm -f $img $dosrc

  mkdir -p $dst
  cp -a $src/* $dst
  cp -a $logo $dst/bootlogo
  rm -f $dst/lilo.conf

  dd if=/dev/zero of="$img" bs=36b count=80
  mke2fs -F -m 0 "$img"
  sw 0 mount -oloop=/dev/loop7 "$img" /mnt
  sw 0 cp -a $dst/* /mnt
  sw 0 rmdir /mnt/lost+found
  sw 0 test/lilo -C $src/lilo.conf -m /mnt/map
  sw 0 umount /mnt
  sw 0 losetup -d /dev/loop7 2>/dev/null

  if [ "$program" = dosemu ] ; then
    perl -p -e "s:<image>:`pwd`/$img:g" test/dosemurc.floppy >$dosrc
    xdosemu -f $dosrc "$@"
  fi

}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function tst_floppy {
  src="test/cdrom"
  dst="$tmp/$1"
  img="$tmp/floppy.img"
  dosrc="$tmp/.dosemurc.floppy"

  rm -f $img $tmp/bootdisk* $dosrc

  mkdir -p $dst
  cp -a $src/* $dst
  cp -a $logo $dst/bootlogo

  sw 0 test/mkbootdisk --syslinux=test/syslinux --out=$tmp/bootdisk $dst

  sw 0 chown --reference=tmp $tmp/bootdisk*

  ln -snf bootdisk1 $img

  if [ "$program" = dosemu ] ; then
    perl -p -e "s:<image>:`pwd`/$img:g" test/dosemurc.floppy >$dosrc
    xdosemu -f $dosrc "$@"
  fi

}



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function usage {
  echo "usage: tst what [theme] [program]"
  exit 1
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

while getopts bhip:t: opt ; do
  case $opt in
    \:|\?|h) usage
      ;;

    b) logo=boot
      ;;

    i) logo=install
      ;;

    p) program=$OPTARG
      ;;

    t) theme=$OPTARG
      ;;
  esac
done
shift $(($OPTIND - 1))

[ "$what" ] || what=$1
[ "$what" ] || what=cdrom

[ "$theme" ] || theme=$2
[ "$theme" ] || theme=SuSE

[ "$program" ] || program=$3
[ "$program" ] || program=dosemu

if [ ! "$logo" ] ; then
  logo=boot
  [ "$what" = install -o "$what" = cdrom ] && logo=install
fi

[ "$logo" = "boot" ] && logo="themes/$theme/boot/message"
[ "$logo" = "install" ] && logo="themes/$theme/install/bootlogo"

[ -x mkbootmsg ] || {
  echo "error: mkbootmsg missing. Try make."
  exit 2
}

make BINDIR=../../ -C themes/$theme || exit

[ -f "$logo" ] || logo="themes/$theme/bootlogo"

if [ ! "$what" -o ! -d "test/$what" -o ! -f "$logo" ] ; then
  usage
fi

tmp=tmp
mkdir -p "$tmp" || exit
rm -rf "$tmp/$what" || exit
mkdir "$tmp/$what"

if [ "$what" = cdrom ] ; then
  tst_cdrom cdrom
elif [ "$what" = boot ] ; then
  tst_boot boot
elif [ "$what" = floppy ] ; then
  tst_floppy floppy
fi

