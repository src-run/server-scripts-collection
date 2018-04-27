#!/bin/bash

function out_error() {
  local format="ERROR: ${1}"
  shift

  printf "${format}\n" $@
}

function out_line_l1() {
  local format="${1}"
  shift

  printf "${format}\n" $@
}

function out_line_l2() {
  local format=" • ${1}"
  shift

  printf "${format}\n" $@
}

function out_confirmation() {
  local format="${1} [y/n]: "
  shift

  while true; do
    printf "${format}" $@
    read confirmation_result

    case "${confirmation_result}" in
      [yY]|[yY][Ee][Ss])
        return 0
        ;;
      [nN]|[n|N][O|o])
        return 1
        ;;
      *)
        out_line_l1
        out_error 'Invalid input: enter "y" or "yes" to indicate the affirmative and "n" or "no" to indicate negation.'
        ;;
    esac
  done
}

function out_usage() {
  printf 'Usage: ./%s <file>\n' "$(basename ${BASH_SOURCE})"
}

function mag_file_from_link() {
  echo "$(echo ${1} | grep -oE '=([^=&]+)' | head -n2 | tail -n 1 | grep -oE '[A-Za-z].+$')"
}

function mag_write() {
  local magnet="${1}"
  local magbin="$(which magnet-queue)"

  ${magbin} "${magnet}" &> /dev/null

  if [[ $? -eq 0 ]]; then
    out_line_l2 'Loading magnet: %s' "$(mag_file_from_link "${magnet}")"
  else
    out_error 'Unable to load magnet: %s (%s)' "$(mag_file_from_link "${magnet}")" "${magnet}"
  fi
}

function mag_cleanup() {
  local file="${1}"

  out_confirmation 'Would you like the %s magnet file removed?' "${file}"

  if [[ $? -eq 0 ]]; then
    rm "${file}"
    if [[ $? -eq 0 ]]; then
      out_line_l2 'Removed %s magnet file...' "${file}"
    else
      out_error 'Unable to remove %s magnet file!' "${file}"
    fi
  else
    out_line_l2 'Keeping %s magnet file...' "${file}"
  fi
}

function mag_fetch() {
  local magnet="${1}"

  mag_write "${magnet}"
}

function main() {
  local file="${1:-x}"

  if [[ "${file}" == "x" ]]; then
    out_error 'You must specify a file path as the first argument!'
    out_usage
    exit 255
  fi

  if [[ ! -f "${file}" ]]; then
    out_error 'File "%s" does not exist.' "${file}"
    out_usage
    exit 255
  fi

  out_line_l1 'Importing %d magnets from %s magnet file...' "$(cat "${file}" | wc -l)" "${file}"

  for m in $(cat ${file}); do
    mag_fetch "${m}"
  done

  mag_cleanup "${file}"
}

main $@
