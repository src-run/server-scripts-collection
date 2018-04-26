#!/bin/bash

while true; do
  clear

  echo -e "\n--- [disk statistics: $(date +"%Y-%m-%d@%H:%M:%S.%N")]\n"
  sudo vmstat -d

  echo -e "\n--- [disk summary: $(date +"%Y-%m-%d@%H:%M:%S.%N")]\n"
  sudo vmstat -D

  sleep 1.5
done
