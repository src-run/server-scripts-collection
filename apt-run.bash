#!/bin/bash

# exit on error
set -e

# apt variables
APT_LOG="/tmp/apt-upgrade.log"
APT_BIN="$(which apt-get)"
APT_OPTS=""

# behavior variables
ASK_ACTIONS=0
RUN_PURGE=1
RUN_UPDATE=1
RUN_UPGRADE=1
RUN_REMOVE=1

# internal variables
VERSION="0.1.0"

# get script basename
function scriptBasename() {
  echo "$(basename $(realpath $BASH_SOURCE))"
}

# display script usage
function usage() {
  echo -en "Usage: ./$(scriptBasename) [OPTIONS]\n"
  echo -en "\t--version       Show the script version.\n"
  echo -en "\t--help          Show this help text.\n"
  echo -en "\t--ask           Do not assume \"yes\" and instead prompt during upgrade/autoremove.\n"
  echo -en "\t--no-update     Do not update apt cache prior to upgrade.\n"
  echo -en "\t--no-upgrade    Do not upgrade apt packages.\n"
  echo -en "\t--no-autoremove Do not auto-remove previously automatically installed packages.\n"
  echo -en "\t--no-purge      Do not purge packages when auto-removing them.\n"
  echo -en "\t--log=PATH      Write update/upgrade/autoremove actions to the specified log path.\n"
}

# display script info
function writeInfo() {
  echo "APT RUN (version ${VERSION})"
  echo "MIT License <https://rmf.mit-license.org>"
  echo "Rob Frawley 2nd <rmf@src.run>"
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

# clear (rm and touch) log file
function logClear() {
  rm ${APT_LOG}
  touch ${APT_LOG}
}

# wrtie log action to log file
function logAction() {
  echo "$(scriptBasename) [$(date +%s)] ACTION: ${1}" >> ${APT_LOG}
}

# parse script arguments
for arg in "$@"
do
  case $arg in
    --no-purge)
      RUN_PURGE=0
      ;;

    --no-update)
      RUN_UPDATE=0
      ;;

    --no-upgrade)
      RUN_UPGRADE=0
      ;;

    --no-autoremove)
      RUN_REMOVE=0
      ;;

    --ask)
      ASK_ACTIONS=1
      ;;

    --log=*)
      APT_LOG="${arg#*=}"
      ;;

    --version)
      echo "$(scriptBasename) ${VERSION}"
      exit 0
      ;;

    *)
      usage
      exit 0
      ;;
  esac
done

# write script info, ensure running as root, clear log file
writeInfo
enforceRoot
logClear

# add yes argument to apt opts if not asked to ask
if [[ ${ASK_ACTIONS} -eq 0 ]]; then
  APT_OPTS="${APT_OPTS} --yes"
fi

# run update operations
if [[ ${RUN_UPDATE} -eq 1 ]]; then
  writeLine "Running update (${APT_BIN} update ${APT_OPTS} 2>&1 | tee -a ${APT_LOG})..."
  logAction "update"
  ${APT_BIN} update ${APT_OPTS} 2>&1 | tee -a ${APT_LOG}
else
  writeLine "Skipping update..."
fi

# run upgrade operations
if [[ ${RUN_UPGRADE} -eq 1 ]]; then
  writeLine "Running upgrade (${APT_BIN} upgrade ${APT_OPTS} 2>&1 | tee -a ${APT_LOG})..."
  logAction "upgrade"
  ${APT_BIN} upgrade ${APT_OPTS} 2>&1 | tee -a ${APT_LOG}
else
  writeLine "Skipping upgrade..."
fi

# run autoremove operations
if [[ ${RUN_PURGE} -eq 1 ]]; then
  APT_OPTS="${APT_OPTS} --purge"
fi

if [[ ${RUN_REMOVE} -eq 1 ]]; then
  writeLine "Running autoremove (${APT_BIN} autoremove ${APT_OPTS} 2>&1 | tee -a ${APT_LOG})..."
  logAction "autoremove"
  ${APT_BIN} autoremove ${APT_OPTS} 2>&1 | tee -a ${APT_LOG}
else
  writeLine "Skipping autoremove..."
fi

# let the use know we've completed!
writeLine "Completed operations! (logged to ${APT_LOG})"

# EOF
