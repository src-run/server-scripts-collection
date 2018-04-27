#!/bin/bash

# exit on error
#set -e

##
## VARIABLE ASSIGNMENTS
##

# apt variables
APT_LOG="/tmp/apt-upgrade-${RANDOM}.log"
APT_BIN="$(which apt-get)"
APT_FAST_BIN="$(which apt-fast)"
APT_USE_BIN="${APT_BIN}"
APT_OPTS=""
APT_OPTS_UPDATE=""
APT_VERBOSE=0

# behavior variables
DRY_RUN=0
DRY_RUN_REAL=0
ASK_ACTIONS=0
RUN_PURGE=1
RUN_UPDATE=1
RUN_UPGRADE=1
RUN_REMOVE=1

# internal variables
VERSION="0.2.1"

##
## FUNCTION DEFINITIONS
##

# get script basename
function getScriptName()
{
  basename "$(realpath "${BASH_SOURCE[0]}")"
}

# write version information
function writeVersion()
{
  printf 'apt-upgrader version %s (%s)\n' "${VERSION}" "$(getScriptName)"

  exit 0
}

# write usage information
function writeUsage() {
  printf 'Usage: ./%s [OPTIONS]\n' "$(getScriptName)"
  echo -en "\t--version       Show the script version.\n"
  echo -en "\t--help          Show this help text.\n"
  echo -en "\t--ask           Do not assume \"yes\" and instead prompt during upgrade/autoremove.\n"
  echo -en "\t--no-update     Do not update apt cache prior to upgrade.\n"
  echo -en "\t--no-upgrade    Do not upgrade apt packages.\n"
  echo -en "\t--no-autoremove Do not auto-remove previously automatically installed packages.\n"
  echo -en "\t--no-purge      Do not purge packages when auto-removing them.\n"
  echo -en "\t--fast          Use apt-fast in place of apt-get to speed up the operation by enabling simultaneous package downloads.\n"
  echo -en "\t--dry-run       Run operations normally but pass the '--dry-run' option to the apt front-end.\n"
  echo -en "\t--dry-run-real  Run operations normally but make no calls to the apt front-end at all.\n"
  echo -en "\t--verbose       Show output of apt command on stdin (default behavior redirects apt output to the log file only).\n"
  echo -en "\t--log=PATH      Write update/upgrade/autoremove actions to the specified log path.\n"

  exit 0
}

# write script information
function writeScriptName()
{
  logLine 'APT-UPGRADER (VERSION %s) [%s]' "${VERSION}" "$(getScriptName)"
  logLine '  [license]="MIT License <https://rmf.mit-license.org>"'
  logLine '  [authors]="Rob Frawley 2nd <rmf@src.run>"'
  printf '\n'
}

# ensure script is run as root
function enforceRunAsRootUser()
{
  if [[ "$EUID" -ne 0 ]]; then
    logError "This script must be run as root. Try \"sudo\" perhaps?"
  fi
}

# write log text entry (no newline)
function logText() {
  local format="${1}"
  shift

  printf "${format}" "$@" | tee -a "${APT_LOG}"
}

# write log line entry (with newline)
function logLine() {
  local format="${1}"
  shift

  logText "${format}\n" "$@"
}

# output message error
function logError() {
  logLine "[ERROR] %s (exiting...)" "${1}"
  exit -1
}

# run apt front-end command with logging
function runAction()
{
  local action="${1}"
  local options="${2:-x}"
  local returnCode=""

  if [[ "${options}" == "x" ]]; then
    options="${APT_OPTS}"
  fi

  logLine 'Running apt-%s operation:' "${action}"
  logLine '  [running-apt-act]="%s"' "${action}"
  logLine '  [running-apt-cmd]="%s %s %s 2>&1 | sed -u -e "'"s/^/    -> /"'" | tee -a %s' "${APT_USE_BIN}" "${action}" "${options}" "${APT_LOG}"

  export DEBIAN_FRONTEND=noninteractive

  if [[ ${DRY_RUN_REAL} -ne 1 ]] && [[ ${APT_VERBOSE} -eq 1 ]]; then
    logLine '  [running-apt-out]=|'
    ${APT_USE_BIN} "${action}" ${options} 2>&1 | sed -u -e 's/^/    -> /' | tee -a "${APT_LOG}"
    returnCode=${PIPESTATUS[0]}
  elif [[ ${DRY_RUN_REAL} -ne 1 ]]; then
    ${APT_USE_BIN} "${action}" ${options} 2>&1 | sed -u -e 's/^/    -> /' | tee -a "${APT_LOG}" &> /dev/null
    returnCode=${PIPESTATUS[0]}
  fi

  local aptMsgText='  [running-apt-msg]'
  local aptRetText='  [running-apt-ret]'

  if [[ ${DRY_RUN_REAL} -eq 1 ]]; then
    logLine '%s="simulated"' "${aptMsgText}"
  elif [[ ${returnCode} -eq 0 ]]; then
    logLine '%s="success"' "${aptMsgText}"
    logLine '%s="0"' "${aptRetText}"
  else
    logLine '%s="failure"' "${aptMsgText}"
    logLine '%s="%s"' "${aptRetText}" "${returnCode}"
  fi

  printf '\n'
}

# log apt front-end command skipped with logging
function logSkipped()
{
  local action="${1}"

  logLine '  ---'
  logLine '  [skipped-apt-act]="%s"' "${action}"
}

# return extended apt options with leading whitespace removed
function extendAptOpts()
{
  echo "${APT_OPTS} ${1}" | sed -e 's/^[ \t]*//'
}

##
## CONFIGURE ENVIRONMENT
##

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

    --fast)
      APT_USE_BIN="${APT_FAST_BIN}"
      ;;

    --ask)
      ASK_ACTIONS=1
      ;;

    --log=*)
      APT_LOG="${arg#*=}"
      ;;

    --dry-run)
      DRY_RUN=1
      ;;

    --dry-run-real)
      DRY_RUN_REAL=1
      ;;

    --verbose)
      APT_VERBOSE=1
      ;;

    --version)
      writeVersion
      ;;

    *)
      writeUsage
      exit 0
      ;;
  esac
done

##
## MAIN()
##

# write script info, ensure running as root, clear log file
writeScriptName
enforceRunAsRootUser

# add yes argument to apt opts if not asked to ask
if [[ ${ASK_ACTIONS} -eq 0 ]]; then
  APT_OPTS="$(extendAptOpts "--yes")"
  APT_OPTS_UPDATE="$(extendAptOpts "--yes")"
fi

# add dry run to apt opts if option passed
if [[ ${DRY_RUN} -eq 1 ]]; then
  APT_OPTS="$(extendAptOpts "--dry-run")"
fi

logLine 'Resolved the following runtime configuration values:'
logLine '  [apt-front-end-opt]="%s"' "${APT_OPTS}"
logLine '  [apt-front-end-bin]="%s"' "${APT_USE_BIN}"
if [[ ${APT_VERBOSE} -eq 1 ]]; then logLine '  [apt-front-end-out]="'"enabled"'"'; else logLine '  [apt-front-end-out]="'"disabled"'"'; fi
if [[ ${ASK_ACTIONS} -eq 1 ]]; then logLine '  [apt-front-end-ask]="'"enabled"'"'; else logLine '  [apt-front-end-ask]="'"disabled"'"'; fi
logLine '  [apt-action-log-to]="%s"' "${APT_LOG}"
printf '\n'

# run update operations
if [[ ${RUN_UPDATE} -eq 1 ]]; then
  runAction 'update' "${APT_OPTS_UPDATE}"
else
  logSkipped 'update'
fi

# run upgrade operations
if [[ ${RUN_UPGRADE} -eq 1 ]]; then
  runAction 'upgrade'
else
  logSkipped 'upgrade'
fi

# run autoremove operations
if [[ ${RUN_PURGE} -eq 1 ]]; then
  APT_OPTS="$(extendAptOpts "--purge")"
fi

if [[ ${RUN_REMOVE} -eq 1 ]]; then
  runAction "autoremove"
else
  logSkipped 'autoremove'
fi

# let the use know we've completed!
logLine 'Completed requested apt front-end operations (logged to "%s").' "${APT_LOG}"

# EOF
