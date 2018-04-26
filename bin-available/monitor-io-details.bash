#!/bin/bash

while true; do
  clear

  echo -e "\n--- [disk usage (kb): $(date +"%Y-%m-%d@%H:%M:%S.%N")]\n"
  iostat -k -x sda sdb sdc sdd sde sdf sdg sdh sdi sdj | tail -n12

  echo -e "\n--- [disk usage (mb): $(date +"%Y-%m-%d@%H:%M:%S.%N")]\n"
  iostat -m -x sda sdb sdc sdd sde sdf sdg sdh sdi sdj | tail -n12

  sleep 1.5
done
