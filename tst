#! /bin/sh


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function tst_isolinux {
  bin="test/syslinux.rpm"
  src="test/$1"
  dst="$tmp/$1"
  img="$tmp/$1.iso"
  dosrc="$tmp/.dosemurc.cdrom"
  vm_src=test/vm
  vm_tmp=tmp/$1.vm
  isolx=$bin/usr/share/syslinux/isolinux.bin

  if [ -z "$program" -o "$program" = dosemu -o "$program" = xdos ] ; then
   isolx=test/isolinux-dosemu.bin
  fi

  rm -rf $dst $vm_tmp
  rm -f $img $dosrc

  isodir=boot/loader
  mkdir -p $dst/$isodir
  test/pisolinux /$isodir <$isolx >$dst/$isodir/isolinux.bin
  cp -a $src/* $dst/$isodir
  cp -a $logo $dst/$isodir/bootlogo
  test/unpack_bootlogo $dst/$isodir

  echo "$dst/$isodir/isolinux.bin 1" >$tmp/cd_sort

  mkisofs -o $img -J -r -sort $tmp/cd_sort \
    -b $isodir/isolinux.bin -c $isodir/boot.catalog \
    -publisher "SUSE Products GmbH" \
    -no-emul-boot -boot-load-size 4 -boot-info-table $dst

  rm -f $tmp/cd_sort

  if [ "$program" = vmware ] ; then
    cp -a $vm_src $vm_tmp
    perl -pi -e "s/^\s*#\s*(floppy0.startConnected)/\$1/" $vm_tmp/gfxboot.vmx
    perl -pi -e "s:<isoimage>:`pwd`/$img:g" $vm_tmp/gfxboot.vmx
    vmware -qx $vm_tmp/gfxboot.vmx
  elif [ "$program" = xdos ] ; then
    sw 0 ln -snf /etc/dosemu.conf.cdrom /etc/dosemu.conf
    ln -snf /var/lib/dosemu/global.conf.cdrom /var/lib/dosemu/global.conf
    ln -snf `pwd`/$img /var/lib/dosemu/cdrom
    xdos $*
    rm -f /var/lib/dosemu/cdrom
    ln -snf /var/lib/dosemu/global.conf.normal /var/lib/dosemu/global.conf
    sw 0 ln -snf /etc/dosemu.conf.normal /etc/dosemu.conf
  else
    if [ -n "$program" -a "$program" != dosemu ] ; then
      echo -e "\n***  Warning: $program not supported - using dosemu  ***\n"
    fi
    perl -p -e "s:<image>:`pwd`/$img:g" test/dosemurc.cdrom >$dosrc
    xdosemu -Q -f $dosrc "$@"
  fi
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function tst_lilo {
  bin="test/lilo.rpm"
  src="test/$1"
  dst="$tmp/$1"
  img="$tmp/$1.img"
  dosrc="$tmp/.dosemurc.floppy"
  vm_src=test/vm
  vm_tmp=tmp/$1.vm

  rm -rf $dst $vm_tmp
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
  sw 0 $bin/sbin/lilo -C $src/lilo.conf -m /mnt/map
  sw 0 umount /mnt
  sw 0 losetup -d /dev/loop7 2>/dev/null

  if [ "$program" = vmware ] ; then
    cp -a $vm_src $vm_tmp
    perl -pi -e "s/^\s*#\s*(ide1:0.startConnected)/\$1/" $vm_tmp/gfxboot.vmx
    perl -pi -e "s:<floppyimage>:`pwd`/$img:g" $vm_tmp/gfxboot.vmx
    vmware -qx $vm_tmp/gfxboot.vmx
  elif [ "$program" = xdos ] ; then
    sw 0 ln -snf /etc/dosemu.conf.floppy /etc/dosemu.conf
    ln -snf `pwd`/$img /var/lib/dosemu/floppyimg
    xdos $*
    rm -f /var/lib/dosemu/floppyimg
    sw 0 ln -snf /etc/dosemu.conf.normal /etc/dosemu.conf
  else
    if [ -n "$program" -a "$program" != dosemu ] ; then
      echo -e "\n***  Warning: $program not supported - using dosemu  ***\n"
    fi
    perl -p -e "s:<image>:`pwd`/$img:g" test/dosemurc.floppy >$dosrc
    xdosemu -f $dosrc "$@"
  fi
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function tst_grub {
  bin="test/grub.rpm"
  src="test/$1"
  dst="$tmp/$1"
  img="$tmp/$1.img"
  vm_src=test/vm
  vm_tmp=tmp/$1.vm

  rm -rf $dst $vm_tmp
  rm -f $img

  mkdir -p $dst
  cp -a $src $dst/grub
  cp $bin/usr/lib/grub/{fat_stage1_5,stage1,stage2} $dst/grub
  cp -a $logo $dst/grub/bootlogo
  sh -c "echo '(fd0) $img' >$dst/grub/device.map"

  test/dosimg $img

  sw 0 mount -oloop "$img" /mnt
  sw 0 cp -r $dst/* /mnt
  echo "setup --prefix=/grub (fd0) (fd0)" | \
  sw 0 $bin/usr/sbin/grub --batch --config-file=/mnt/grub/menu.lst --device-map=/mnt/grub/device.map
  echo

  sw 0 umount /mnt

  if [ -n "$program" -a "$program" != vmware ] ; then
    echo -e "\n***  Warning: $program not supported - using vmware  ***\n"
  fi
  cp -a $vm_src $vm_tmp
  perl -pi -e "s/^\s*#\s*(ide1:0.startConnected)/\$1/" $vm_tmp/gfxboot.vmx
  perl -pi -e "s:<floppyimage>:`pwd`/$img:g" $vm_tmp/gfxboot.vmx
  vmware -qx $vm_tmp/gfxboot.vmx
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function tst_syslinux {
  bin="test/syslinux.rpm"
  src="test/$1"
  dst="$tmp/$1"
  img="$tmp/$1.img"
  dosrc="$tmp/.dosemurc.floppy"
  vm_src=test/vm
  vm_tmp=tmp/$1.vm
  syslx=$bin/usr/bin/syslinux

  if [ -z "$program" -o "$program" = dosemu -o "$program" = xdos ] ; then
    syslx=test/syslinux-dosemu
  fi

  rm -rf $dst $vm_tmp
  rm -f $img* $dosrc

  mkdir -p $dst
  cp -a $src/* $dst
  cp -a $logo $dst/bootlogo

  sw 0 test/mkbootdisk --syslinux=$syslx --out=${img}_ $dst

  sw 0 chown --reference=tmp $img*

  ln -snf $1.img_1 $img

  if [ "$program" = vmware ] ; then
    cp -a $vm_src $vm_tmp
    perl -pi -e "s/^\s*#\s*(ide1:0.startConnected)/\$1/" $vm_tmp/gfxboot.vmx
    perl -pi -e "s:<floppyimage>:`pwd`/$img:g" $vm_tmp/gfxboot.vmx
    vmware -qx $vm_tmp/gfxboot.vmx
  elif [ "$program" = xdos ] ; then
    sw 0 ln -snf /etc/dosemu.conf.floppy /etc/dosemu.conf
    ln -snf `pwd`/$img /var/lib/dosemu/floppyimg
    xdos $*
    rm -f /var/lib/dosemu/floppyimg
    sw 0 ln -snf /etc/dosemu.conf.normal /etc/dosemu.conf
  else
    if [ -n "$program" -a "$program" != dosemu ] ; then
      echo -e "\n***  Warning: $program not supported - using dosemu  ***\n"
    fi
    perl -p -e "s:<image>:`pwd`/$img:g" test/dosemurc.floppy >$dosrc
    xdosemu -f $dosrc "$@"
  fi
}



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function usage {
  echo "usage: tst [-b] [-i] [-p program] [-t theme] what [theme]"
  exit 1
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

while getopts bhil:p:t: opt ; do
  case $opt in
    \:|\?|h) usage
      ;;

    b) logo=boot
      ;;

    i) logo=install
      ;;

    l) lang="DEFAULT_LANG=$OPTARG"
      ;;

    p) program=$OPTARG
      ;;

    t) theme=$OPTARG
      ;;
  esac
done
shift $(($OPTIND - 1))

[ "$what" ] || what=$1
[ "$what" ] || what=isolinux

[ "$theme" ] || theme=$2
[ "$theme" ] || theme=SuSE

[ "$what" = cdrom ] && what=isolinux
[ "$what" = cd ] && what=isolinux
[ "$what" = floppy ] && what=syslinux

[ "$program" = xdosemu ] && program=dosemu

if [ ! "$logo" ] ; then
  logo=boot
  [ "$what" = syslinux -o "$what" = isolinux ] && logo=install
fi

[ "$logo" = "boot" ] && logo="themes/$theme/boot/message"
[ "$logo" = "install" ] && logo="themes/$theme/install/bootlogo"

[ -x mkbootmsg ] || {
  echo "error: mkbootmsg missing. Try make."
  exit 2
}

if [ ! "$what" ] ; then
  echo "What is "\""$what"\""?"
  usage
fi

make BINDIR=../../ -C themes/$theme $lang || exit

[ -f "$logo" ] || logo="themes/$theme/bootlogo"

if [ ! -f "$logo" ] ; then
  echo "no such file: $logo"
  usage
fi

tmp=tmp
mkdir -p "$tmp" || exit

if [ "$what" = isolinux ] ; then
  tst_isolinux syslinux
elif [ "$what" = lilo ] ; then
  tst_lilo lilo
elif [ "$what" = syslinux ] ; then
  tst_syslinux syslinux
elif [ "$what" = grub ] ; then
  tst_grub grub
else
  echo "What is "\""$what"\""?"
  usage
fi

