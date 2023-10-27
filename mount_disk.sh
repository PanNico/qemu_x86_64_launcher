#!/bin/bash

#!/bin/sh
#https://www.howtogeek.com/devops/how-to-mount-a-qemu-virtual-disk-image/

if [[ -z $1 ]]; then
  echo "Error: missing disk name; eg. r2_sdk.img"
  exit 1
fi

if [[ -z $2 ]]; then
  echo "Error: offset."
  exit 1
fi

IMG=$1 #Must be the rootfs and there is no boot partition
OFFSET=$2

MOUNT_DIR=$(mktemp -d)

sudo mount -o loop,offset=$((OFFSET*512)) $IMG $MOUNT_DIR

if [[ $? != 0 ]]; then
  echo "Mount failed!"
  exit 0
fi

echo "Image mounted in ${MOUNT_DIR}"

