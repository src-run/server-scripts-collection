#!/bin/bash

while true; do

  clear

  echo -e "\n--- [zfs list: $(date +"%Y-%m-%d@%H:%M:%S.%N")]\n"
  sudo zfs list

  echo -e "\n--- [zpool list: $(date +"%Y-%m-%d@%H:%M:%S.%N")]\n"
  sudo zpool list

  echo -e "\n--- [zpool compress ratio: $(date +"%Y-%m-%d@%H:%M:%S.%N")]\n"
  sudo zfs get compressratio pool/media

  echo -e "\n--- [zpool iostat: $(date +"%Y-%m-%d@%H:%M:%S.%N")]\n"
  sudo zpool iostat pool | tail -n3

  echo -e "\n--- [zpool status: $(date +"%Y-%m-%d@%H:%M:%S.%N")]\n"
  sudo zpool status pool

  sleep 10

done
