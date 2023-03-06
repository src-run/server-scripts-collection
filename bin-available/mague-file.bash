#!/usr/bin/env bash

##
## This file is part of the `src-run/bash-server-scripts` project.
##
## (c) https://github.com/src-run/bash-server-scripts/graphs/contributors
##
## For the full copyright and license information, please view the LICENSE.md
## file that was distributed with this source code.
##

function process_file()
{
  local -r file_path="${1}"
  local -r exec_path="${2}"

  if [[ ! -e "${file_path}" ]] || [[ ! -r "${file_path}" ]]; then
    printf -- '[ERROR] File "%s" does not exist or is not readable!\n' "${file_path}"
    return 1
  fi

  mapfile -t < "${file_path}"

  for l in "${MAPFILE[@]}"; do
    if [[ "${l:0:7}" == 'magnet:' ]]; then
      "${exec_path}" "${l}"
    fi
  done
}

function main() {
  local -a file_list=("${@}")
  local -r exec_name='mague-args'
  local -r exec_path="$(
    command -v "${exec_name}" \
      || printf -- '%s/%s.bash' "$(dirname "$(readlink -m "${0}")")" "${exec_name}"
  )"

  if [[ ! -e "${exec_path}" ]] || [[ ! -x "${exec_path}" ]]; then
    printf -- '[ERROR] Sub-command executable "%s" does not exist or is not executable!\n' "${exec_path:-${exec_name}}"
    return 1
  fi

  for f in "${file_list[@]}"; do
    process_file "${f}" "${exec_path}"
  done
}

main "${@}"
