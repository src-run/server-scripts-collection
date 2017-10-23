#!/bin/bash

BACKUP_TIME="$(date +%s)"
BACKUP_LOGS="/tmp/rsync-backup.log"
BACKUP_PATH="/pool/backup/twoface-rsync"
BACKUP_ENTRIES=(
  "/var/lib/plexmediaserver"
  "/home/rmf/scripts"
  "/home/rmf/repositories"
)

#
# ensure script is run as root
#
function enforce_root() {
  if [[ "$EUID" -ne 0 ]]; then
    out_error "This script must be run as root. Try \"sudo\" perhaps?"
    exit 255
  fi
}

#
# output error
#
function out_error() {
  local format="[ERROR] ${1}"
  shift

  printf "${format}\n" $@ | tee -a "${BACKUP_LOGS}"
}

#
# output line of text
#
function out_line() {
  local format="${1}"
  shift

  printf "${format}\n" $@ | tee -a "${BACKUP_LOGS}"
}

#
# output action error
#
function out_action_error() {
  local format=" • [ERROR] ${1}"
  shift

  printf "${format}\n" $@ | tee -a "${BACKUP_LOGS}"
}

#
# output action line of text
#
function out_action_line() {
  local format=" • ${1}"
  shift

  printf "${format}\n" $@ | tee -a "${BACKUP_LOGS}"
}

#
# check configuration
#
function do_config_check() {
  local size=${#BACKUP_ENTRIES[@]}

  if [[ ${size} -eq 0 ]]; then
    out_error "No backup path entries found in configuration array!"
    exit 255
  fi

  local size="$((${#BACKUP_PATH} - 1))"

  if [[ "${BACKUP_PATH:$size:1}" == "/" ]]; then
    BACKUP_PATH="${BACKUP_PATH:0:$size}"
  fi

  if [[ ! -d "${BACKUP_PATH}" ]]; then
    mkdir -p "${BACKUP_PATH}"

    if [[ ! -d "${BACKUP_PATH}" ]]; then
      out_error 'Unable to create backup destination path %s' "${BACKUP_PATH}"
    fi
  fi

  out_line 'Initiating backup operations (found %d configuration entries):' "${#BACKUP_ENTRIES[@]}"
}

#
# perform rsync backup operation
#
function do_rsync_backup() {
  local path="${1}"
  local log="$(dirname "${BACKUP_LOGS}")/$(basename "${BACKUP_LOGS}" .log).rsync.${BACKUP_TIME}.log"
  local bin="$(which rsync)"
  local opt="-r -a -A -X -i --log-file=${log}"
  local cmd="${bin} ${opt} ${path} ${BACKUP_PATH}/${BACKUP_TIME}"

  ${cmd} &> /dev/null

  if [[ $? -ne 0 ]]; then
    out_action_error 'Encountered an rsync error while running "%s" command' "${cmd}"
  fi
}

#
# perform backup operation on config entry
#
function do_path_backup() {
  local path="${1}"
  local size="$((${#path} - 1))"

  if [[ "${path:$size:1}" == "/" ]]; then
    path="${path:0:$size}"
  fi

  if [[ ! -d "${path}" ]]; then
    out_action_error 'Skipping non-existant path for "%s" backup configuration entry...' "${path}"
    return
  fi

  out_action_line 'Performing backup operations for "%s" backup configuration entry...' "${path}"

  do_rsync_backup "${path}"
}

#
# perform backup operation on config array
#
function do_path_backups() {
  for path in "${BACKUP_ENTRIES[@]}"; do
    do_path_backup "${path}"
  done
}

#
# main
#
function main() {
  enforce_root
  do_config_check
  do_path_backups
}

#
# go!
#
main $@
