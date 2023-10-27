#!/bin/bash
# https://www.willhaley.com/blog/debian-arm-qemu/

SCRIPT_NAME=$(basename $0)
DO_INSTALL=false
QEMU="sudo qemu-system-x86_64"
QEMU_COMMON_ARGS="-enable-kvm -cpu host -smp 4 -m 2048 -nic user -nic tap"

function help() {
  printf "USAGE: $SCRIPT_NAME [-h] --hd <disk> {[--install <iso>],[--kernel <vmlinuz> --initrd <initrd>]} [--external-hds <<disk1>,<disk2>,...>]\n"
  printf "Options:\n"
  printf "\t-h: prints this message\n"
  printf "\t--hd <disk>: the disk image to use as rootfs; eg. tests_disk.img\n"
  printf "\t--install <iso>: install the iso on the specified <disk>; eg. debian-12.2.0-amd64-DVD-1.iso\n"
  printf "\t--kernel <vmlinuz>: vmlinuz image of the kernel to run; used just when install is not specified; eg. vmlinuz-5.15.0-43-generic\n"
  printf "\t--initrd <initrd>: initrd image of the kernel to run; used just when install is not specified; eg. initrd.img-5.15.0-43-generic\n"
  printf "\t--external-hds <<disk1>,<disk2>,...>: comma separated list of extra disks to mount\n" 
}

function validation_failed() {
  echo "Error: $1"
  echo
  help
  exit 1
}

function check_null_arg() {
  local ARG_TO_CHECK=$1
  local ARG_NAME=$2

  if [ -z $ARG_TO_CHECK ]; then
    validation_failed "missing argument $ARG_NAME"
  fi
}

function get_list_of_disks() {
  local list=""
 
  if [[ -z $1 ]]; then
    echo
    return
  fi

  if ! echo ${1} | grep "," &> /dev/null; then
    echo $1
    return
  fi

  local counter=1
 
  while true; do
    local disk=$(echo $1 | cut -d, -f${counter})

    if [[ -z $disk ]]; then
      break
    fi

    list="${list} ${disk}"
    counter=$((counter+1))
  done

  echo $list
}

function validate_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
    --hd)
      check_null_arg "$2" "<disk>"
      HD="$2"
      local qemu_rootfs_disk="-drive file=${HD},format=raw,index=0,media=disk"
      # QEMU_COMMON_ARGS="${QEMU_COMMON_ARGS} ${qemu_rootfs_disk}" 
      QEMU_COMMON_ARGS="${QEMU_COMMON_ARGS} ${qemu_rootfs_disk}" 
      shift 2
      ;;
    --install)
      check_null_arg "$2" "<iso>"
      ISO="$2"
      DO_INSTALL=true
      shift 2
      ;;
    --kernel)
      check_null_arg "$2" "<vmlinuz>"
      KERNEL="$2"
      shift 2
      ;;
    --initrd)
      check_null_arg "$2" "<initrd>"
      INITRD="$2"
      shift 2
      ;;
    --external-hds)
      check_null_arg "$2" "<disk1>"
      EXTRA_DISKS=$(get_list_of_disks ${2})
      # TODO append extra disk options to QEMU_COMMON_ARGS
      shift 2
      ;;
    -h)
      help
      exit 0
      ;;
    *)
      shift;;
    esac
  done

  if ! $DO_INSTALL; then
    check_null_arg "$KERNEL" "--kernel <vmlinuz>"
    check_null_arg "$INITRD" "--initrd <initrd>"
    local kernel_args="-kernel $KERNEL -initrd $INITRD"
    QEMU_COMMON_ARGS="${QEMU_COMMON_ARGS} ${kernel_args}"
  else
    QEMU_COMMON_ARGS="${QEMU_COMMON_ARGS} -cdrom ${ISO}"
  fi

  if [[ -z $HD ]]; then
    clear
    echo "Missing hd image, do you want to create one? (Y/n)"
    read reply
    
    if [[ $reply = "y" ]] || [[ $reply = "Y" ]]; then
      printf "Insert disk name: "
      read HD
      printf "\nInsert disk_size (GB): "
      read DISK_SIZE

      if [[ -z $HD ]] || [[ -z $DISK_SIZE ]]; then
        echo "Error: invalid arguments"
        echo "Aborting..."
        exit 1
      fi
      
      qemu-img create $HD ${DISK_SIZE}G
      mkfs.ext4 $HD
      local qemu_rootfs_disk="-drive file=${HD},format=raw,index=0,media=disk"
      QEMU_COMMON_ARGS="${QEMU_COMMON_ARGS} ${qemu_rootfs_disk} -append 'root=/dev/sda1 console=ttyS0'" 
    else
      echo "Aborting..."
      exit 0
    fi
  fi

}
function run() {

  if $DO_INSTALL; then
    $QEMU $QEMU_COMMON_ARGS
  else
    $QEMU $QEMU_COMMON_ARGS -append 'root=/dev/sda1'
  fi
}

validate_args $@
run

# Install ISO
#sudo qemu-system-x86_64 -enable-kvm -cpu host -smp 4 -m 2048 -nic user -nic tap  -drive file=$SDK_IMG,format=raw,index=0,media=disk -cdrom $ISO 

# With qemu sdk
# Remeber: once you have an image with qemu installed you have to launch it and get vmlinuz and initrd
# sudo qemu-system-x86_64 -enable-kvm -cpu host -smp 4 -m 2048 -nic user -nic tap -kernel $KERNEL -initrd $INITRD -drive file=$SDK_IMG,format=raw,index=0,media=disk -nographic -append 'root=/dev/sda1 console=ttyS0' 

# Mounting multiple disk...
#sudo qemu-system-x86_64 -enable-kvm -cpu host -smp 2 -m 1024 -nic user -nic tap -kernel vmlinuz-6.1.0-7-amd64 -initrd initrd.img-6.1.0-7-amd64 -drive file=$ROOTFS,format=raw,index=0,media=disk -drive file=$SDKS_PATH/$SDK_IMG.img,format=raw,id=sdb1 -drive file=$SDKS_PATH/"$SDK_IMG"_last.img,format=raw,id=sdc1 -nographic -append 'root=/dev/sda1 console=ttyS0' 
