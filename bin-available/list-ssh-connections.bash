#!/bin/bash

function out_line() {
  local text="${1}"
  local type="${2:-info}"
  local newline="${3:-true}"

  printf '%s %s [%s] %s' "$(basename "${BASH_SOURCE}" .bash)" "$(date +%y%m%d%H%M.%N)" "${type^^}" "${text}"

  if [[ "${newline}" == "true" ]]; then
    printf "\n"
  fi
}

function out_crit() {
  local text="${1}"
  local stop="${2:-}"

  out_line "${text}" CRIT

  if [[ "${stop}" -gt 0 ]]; then
    exit ${stop}
  fi
}

function out_info() {
  local text="${1}"
  local newline="${2:-true}"

  out_line "${text}" info "${newline}"
}

function out_record() {
  local text="${1}"
  local i="${2}"

  out_line "${text}" "$(printf '%04d' ${i})"
}

function main() {
#  if [[ ${EUID} -ne 0 ]]; then
#    out_crit "Cannot fetch connections without elevated privileges. Use sudo or su to root user..." 1
#  fi

  out_info "Filtering all active connections (this could take some time) ... " "false"

  local records="$(sudo netstat -atp 2> /dev/null | grep -E 'ESTABLISHED [0-9]+/sshd:' | awk '{printf "hostport=[%s] gateway=[%s] user=[%s]\n", $4, $5, $8}')"

  if [[ $? -ne 0 ]]; then
    printf "ERROR\n"
    out_crit "Failed to fetch connections using netstat!" 255
  fi

  printf "OKAY\n"

  local recordSize=$(echo ${records} | wc -l 2> /dev/null)

  if [[ ! ${recordSize} -gt 0 ]]; then
    out_crit "Found no active ssh connections." 254
  fi

  out_info "$(printf 'Listing %d active sshd connection records:' ${recordSize})"

  while IFS= read -r r; do
    out_record "${r}"
  done <<< "${records}"
}

main
