#!/bin/bash

while true; do

  clear

  sudo zfs list
  echo -en "\n---\n\n"

  sudo zpool list
  echo -en "\n---\n\n"

  sudo zfs get compressratio pool/media
  echo -en "\n---\n\n"

  sudo zpool iostat pool
  echo -en "\n---\n\n"

  sudo zpool status pool

  sleep 10

done
