#! /bin/sh


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function switch_disk {
  disk=$1
  tmp=tmp

  if [ -z "$disk" -o ! -f "$tmp/syslinux.img_$disk" ] ; then
    echo "usage:"
    echo "  tst -d disk_number"
    exit 1
  fi

  dd if="$tmp/syslinux.img_$disk" of="$tmp/syslinux.img" conv=notrunc status=noxfer
}


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

  isodir32=boot/i386/loader
  isodir64=boot/x86_64/loader
  mkdir -p $dst/$isodir32 $dst/$isodir64
  cp $isolx $dst/$isodir32/isolinux.bin
  cp $isolx $dst/$isodir64/isolinux.bin
  test/syslinux.rpm/usr/bin/isolinux-config --base=$isodir32 $dst/$isodir32/isolinux.bin
  test/syslinux.rpm/usr/bin/isolinux-config --base=$isodir64 $dst/$isodir64/isolinux.bin

  cp -a $src/* $dst/$isodir32
  rm -f $dst/$isodir32/{linux,initrd}64
  cp -a $logo $dst/$isodir32/bootlogo
  bin/unpack_bootlogo $dst/$isodir32

  cp -a $src/* $dst/$isodir64
  [ -f $dst/$isodir64/linux64 ] && mv $dst/$isodir64/linux64 $dst/$isodir64/linux
  [ -f $dst/$isodir64/initrd64 ] && mv $dst/$isodir64/initrd64 $dst/$isodir64/initrd
  cp -a $logo $dst/$isodir64/bootlogo
  bin/unpack_bootlogo $dst/$isodir64

  test/2hl --link --quiet $dst

  echo "$dst/$isodir32/isolinux.bin 1" >$tmp/cd_sort
  echo "$dst/$isodir64/isolinux.bin 1" >>$tmp/cd_sort

  rm `find $dst/boot -name \*~`

  # rm -r $dst/boot/x86_64

  mkisofs -o $img -J -r -sort $tmp/cd_sort \
    -b $isodir32/isolinux.bin -c $isodir32/boot.catalog \
    -publisher "SUSE LINUX Products GmbH" \
    -no-emul-boot -boot-load-size 4 -boot-info-table $dst

  rm -f $tmp/cd_sort

  if [ "$program" = vmware ] ; then
    cp -a $vm_src $vm_tmp
    perl -pi -e "s/^\s*#\s*(floppy0.startConnected)/\$1/" $vm_tmp/gfxboot.vmx
    perl -pi -e "s:<isoimage>:`pwd`/$img:g" $vm_tmp/gfxboot.vmx
    vmware -qx $vm_tmp/gfxboot.vmx
  elif [ "$program" = qemu ] ; then
    qemu -cdrom $img
  elif [ "$program" = bd ] ; then
    bd $img
  elif [ "$program" = bochs ] ; then
    bochs -q 'boot: cdrom' "ata0-master: type=cdrom, path=$img, status=inserted" 'log: /dev/null' 'parport1: enabled=0'
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
    [ "`echo $DISPLAY | head -c 1`" = ':' ] || echo '$_X_mitshm = (off)' >>$dosrc
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
  elif [ "$program" = qemu ] ; then
    qemu -boot a -fda $img
  elif [ "$program" = bd ] ; then
    bd $img
  elif [ "$program" = bochs ] ; then
    bochs -q 'boot: a' "floppya: image=$img, status=inserted" 'log: /dev/null' 'ata0-master: type=disk, path=/dev/null' 'parport1: enabled=0'
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
    [ "`echo $DISPLAY | head -c 1`" = ':' ] || echo '$_X_mitshm = (off)' >>$dosrc
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

  if [ "$program" = vmware ] ; then
    cp -a $vm_src $vm_tmp
    perl -pi -e "s/^\s*#\s*(ide1:0.startConnected)/\$1/" $vm_tmp/gfxboot.vmx
    perl -pi -e "s:<floppyimage>:`pwd`/$img:g" $vm_tmp/gfxboot.vmx
    vmware -qx $vm_tmp/gfxboot.vmx
  elif [ "$program" = qemu ] ; then
    qemu -boot a -fda $img
  elif [ "$program" = bd ] ; then
    bd $img
  elif [ "$program" = bochs ] ; then
    bochs -q 'boot: a' "floppya: image=$img, status=inserted" 'log: /dev/null' 'ata0-master: type=disk, path=/dev/null' 'parport1: enabled=0'
  else
    if [ -n "$program" -a "$program" != qemu ] ; then
      echo -e "\n***  Warning: $program not supported - using qemu  ***\n"
    fi
    qemu -boot a -fda $img
  fi
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
  syslx=$bin/usr/bin/syslinux-nomtools

  if [ -z "$program" -o "$program" = dosemu -o "$program" = xdos ] ; then
    syslx=test/syslinux-dosemu
  fi

  rm -rf $dst $vm_tmp
  rm -f $img* $dosrc

  mkdir -p $dst
  cp -a $src/* $dst
  cp -a $logo $dst/bootlogo

  rm -f $dst/*~

  sw 0 test/mkbootdisk --syslinux=$syslx --out=${img}_ $dst

  sw 0 chown --reference=tmp $img*

  cp $dst.img_1 $img

  if [ "$program" = vmware ] ; then
    cp -a $vm_src $vm_tmp
    perl -pi -e "s/^\s*#\s*(ide1:0.startConnected)/\$1/" $vm_tmp/gfxboot.vmx
    perl -pi -e "s:<floppyimage>:`pwd`/$img:g" $vm_tmp/gfxboot.vmx
    vmware -qx $vm_tmp/gfxboot.vmx
  elif [ "$program" = qemu ] ; then
    qemu -boot a -fda $img
  elif [ "$program" = bd ] ; then
    bd $img
  elif [ "$program" = bochs ] ; then
    bochs -q 'boot: a' "floppya: image=$img, status=inserted" 'log: /dev/null' 'ata0-master: type=disk, path=/dev/null' 'parport1: enabled=0'
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
    [ "`echo $DISPLAY | head -c 1`" = ':' ] || echo '$_X_mitshm = (off)' >>$dosrc
    xdosemu -f $dosrc "$@"
  fi
}



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function usage {
  echo "usage: tst [-b] [-i] [-p program] [-t theme] what [theme]"
  exit 1
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

while getopts bd:hil:p:t: opt ; do
  case $opt in
    \:|\?|h) usage
      ;;

    b) logo=boot
      ;;

    d) disk=$OPTARG
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

if [ "$disk" ] ; then
  switch_disk $disk
  exit
fi

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

[ "$BOOTLOGO" ] && logo=$BOOTLOGO

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

