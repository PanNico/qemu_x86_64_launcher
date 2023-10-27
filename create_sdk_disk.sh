#!/bin/bash

if [ -z $1 ]; then
  echo "Error: missing disk name; eg. r2_sdk.img"
  exit 1
fi

DISK_NAME=$1.img
DISK_SIZE=20G

qemu-img create $DISK_NAME $DISK_SIZE
mkfs.ext4 $DISK_NAME

