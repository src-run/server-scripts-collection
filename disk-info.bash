#!/bin/bash

# options for lsblk command
LSBLK_BIN="$(which lsblk)"
LSBLK_OPTS="${1:-NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL}"

# get script basename
function scriptBasename() {
  echo "$(basename $(realpath $BASH_SOURCE))"
}

# ensure script is run as root
function enforceRoot() {
  if [[ "$EUID" -ne 0 ]]; then
    writeError "This script must be run as root. Try \"sudo\" perhaps?"
  fi
}

# output message line
function writeLine() {
  echo -en "\n$(scriptBasename) [$(date +%s)] ${1}\n"
}

# output message error
function writeError() {
  writeLine "ERROR: ${1}"
  exit -1
}

# ensure running as root and run command!
enforceRoot
${LSBLK_BIN} -o ${LSBLK_OPTS}
