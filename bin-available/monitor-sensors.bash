#!/bin/bash

# exit on error
set -e

# internal variables
VERSION="0.1.0"
SENSORS_BIN="$(which sensors)"
LEVCTL_BIN="#(which levctl)"

# behavior variables
COLOR_MODE=1
COLOR_OFFSET=0
POLLING_TIME=30

# get script base name
function scriptBasename() {
  echo "$(basename $(realpath $BASH_SOURCE))"
}

# display script usage
function writeUsage() {
  echo -en "Usage: ./$(scriptBasename) [OPTIONS]\n"
  echo -en "\t--version  Show the script version.\n"
  echo -en "\t--help     Show this help text.\n"
  echo -en "\t-D         Disable automatic color changing.\n"
  echo -en "\t-s=SECONDS Polling time in seconds.\n"
}

function coloring() {
  local r=255
  local b=255
  local g=255

  if [[ ${COLOR_MODE} -eq 0 ]]; then
    echo "200,0,255"
  elif [[ ${COLOR_MODE} -eq 1 ]]; then
    r="$(echo ${r} - 255 + ${COLOR_OFFSET} | bc)"
    b="$(echo ${b} - ${COLOR_OFFSET} | bc)"
    g="255"
  elif [[ ${COLOR_MODE} -eq 2 ]]; then
    r="255"
    b="$(echo ${b} - 255 + ${COLOR_OFFSET} | bc)"
    g="$(echo ${g} - ${COLOR_OFFSET} | bc)"
  elif [[ ${COLOR_MODE} -eq 3 ]]; then
    r="$(echo ${r} - ${COLOR_OFFSET} | bc)"
    b="255"
    g="$(echo ${g} - 255 + ${COLOR_OFFSET} | bc)"
  fi

  echo "${r},${b},${g}"
}

# parse script arguments
for arg in "$@"
do
  case $arg in
    --help)
      writeUsage
      exit 0
      ;;
    --version)
      writeVersion
      exit 0
      ;;
    -D)
      COLOR_MODE=0
      ;;
    -s=*)
      POLLING_TIME="${arg#*=}"
      ;;
  esac
done

#while true; do
#  for r in $(seq 15 140); do
#    for b in $(seq 60 140); do
#      for g in $(seq 15 140); do
#        clear
#        sensors
#        COLOR="$(((255 - ${r}))),$(((255 - ${b}))),${g}"
#        sudo levctl -c ${COLOR}
#        echo -en "\n---\n\nnzxt-kraken-color = {\n  ${COLOR}\n}"
#        sleep ${POLLING_TIME}
#      done
#    done
#  done
#done

function colorSelect() {
  echo $(top -b -d0.1 -n4| awk '/Cpu/ {i=($8*255)/100; printf "%d,%d,0\n",255-i,i;fflush()}' | tail -n 1)
#  echo "220,5,140"
}

while true
do
  clear
  sensors
  echo -en "---\n\nnzxt-kraken-pump = "
  COLOR=$(colorSelect)
#  COLOR=$(coloring)
  sudo levctl -c ${COLOR}
  echo -en "\n---\n\nnzxt-kraken-color = {\n  ${COLOR}\n}"
#  COLOR_OFFSET="$(((${COLOR_OFFSET} + 1)))"
#  if [[ "${COLOR_OFFSET}" == "255" ]]; then
#    COLOR_MODE=$((($COLOR_MODE + 1)))
#    COLOR_OFFSET=0
#  fi
#  if [[ "${COLOR_MODE}" == "4" ]]; then
#    COLOR_MODE=1
#  fi
  sleep ${POLLING_TIME}
done
