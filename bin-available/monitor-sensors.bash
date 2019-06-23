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

function colorSelect() {
  echo $(top -b -d0.1 -n4| awk '/Cpu/ {i=($8*255)/100; printf "%d,%d,0\n",255-i,i;fflush()}' | tail -n 1)
}

while true
do
  clear
  echo -e "\n--- [coretemp-isa-0000 sensors: $(date +"%Y-%m-%d@%H:%M:%S.%N")]\n"; \
    sensors coretemp-isa-0000 | tail -n11 | head -n 10 | sed -rn 's/^([^:]+):\s+([^(]+)\s+\(([^)]+)\).*$/\1\t\2\t\3/p' | sed -e's/  */ /g' | awk -F"\t" '{ printf "%-19s=> %-10s(%s)\n", $1, $2, $3 }'; \
    echo -e "\n--- [nct6791-isa-0290 sensors: $(date +"%Y-%m-%d@%H:%M:%S.%N")]\n"; \
    sensors nct6791-isa-0290 | tail -n30 | head -n28 | sed -rn 's/^([^:]+):\s+([^(]+)\s+\(([^)]+)\).*$/\1\t\2\t\3/p' | sed -e's/  */ /g' | awk -F"\t" '{ printf "%-19s=> %-10s(%s)\n", $1, $2, $3 }';
#  echo -e "\n--- [nzxt-kraken-pump: $(date +"%Y-%m-%d@%H:%M:%S.%N")]\n";
  COLOR=$(colorSelect)
#  sudo levctl -c "${COLOR}" | head -n4 | tail -n3 | sed -rn 's/^[ \t]*"([^"]+)": ([^,]+),?/\1\t\2/p' | sed -e's/_/ /g' | sed 's/[^ ]\+/\L\u&/g' | awk -F"\t" '{ printf "%-19s=> %-10s\n", $1, $2 }'
#  printf "Hex Color          => %s\n" "${COLOR}"
  sleep ${POLLING_TIME}
done
