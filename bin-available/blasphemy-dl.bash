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
  printf 'Usage: ./%s <file> <pass> [<user>]\n' "$(basename ${BASH_SOURCE})"
}

function write_config() {
  local user="${1}"
  local pass="${2}"
  local save="${3}"
  local file="${4}"

  out_line_l1 'Runtime configuration values...'

  out_line_l2 'Download path : "%s"' "${save}"
  out_line_l2 'Instructions  : "%s" (%d)' "${file}" "$(cat "${file}" | wc -l)"
  out_line_l2 'Credentials   : "%s":"%s"' "${user}" "${pass}"
}

function do_downloads() {
  local user="${1}"
  local pass="${2}"
  local save="${3}"
  local file="${4}"

  out_line_l1 'Performing asset download on %d images...' "$(cat "${file}" | wc -l)"

  for l in $(cat ${file}); do
    fetch_link "${l}" "${user}" "${pass}" "${save}"
  done
}

function fetch_link() {
  local link="${1}"
  local base="${link##*/}"
  local user="${2}"
  local pass="${3}"
  local path="${4}"
  local file="${path}/${base}"
  local pwd="$(pwd)"
  local wgetbin="$(which wget)"

  ${wgetbin} --quiet --user "${user}" --password "${pass}" -O "${file}" "${link}" &> /dev/null

  if [[ $? -eq 0 ]]; then
    sleep 0.1
    out_line_l2 '%s [%s]' "$(basename "${file}")" "$(du -h ${file} | cut -f1)"
  else
    out_error 'Failed to download "%s" asset!' "${link}"
  fi
}

function file_cleanup() {
  local file="${1}"

  out_confirmation 'Would you like the %s file removed?' "${file}"

  if [[ $? -eq 0 ]]; then
    rm "${file}"
    if [[ $? -eq 0 ]]; then
      out_line_l2 'Removed %s text file...' "${file}"
    else
      out_error 'Unable to remove %s text file!' "${file}"
    fi
  else
    out_line_l2 'Keeping %s text file...' "${file}"
  fi
}

function main() {
  local file="${1:-x}"
  local pass="${2:-x}"
  local user="${3:-x}"
  local save="$(pwd)"

  if [[ "${file}" == "x" ]]; then
    out_error 'An instruction file must be provided as the first argument!'
    out_usage
    exit 255
  fi

  if [[ ! -f "${file}" ]]; then
    out_error 'Instruction file "%s" does not exist!' "${file}"
    exit 255
  fi

  if [[ 0 -eq "$(cat "${file}" | wc -l)" ]]; then
    out_error 'Instruction file "%s" does not contain any links!' "${file}"
    exit 255
  fi

  if [[ "${pass}" == "x" ]]; then
    out_error 'You must specify the user password for digital blasphemy!'
    out_usage
    exit 255
  fi

  if [[ "${user}" == "x" ]]; then
    user="robfrawley"
  fi

  if [[ ! -d "${save}" ]]; then
    out_error 'The download save directory path does not exist!'
    exit 255
  fi

  if [[ ! -w "${save}" ]]; then
    out_error 'The download save directory path is not writable!'
    exit 255
  fi

  write_config "${user}" "${pass}" "${save}" "${file}"
  do_downloads "${user}" "${pass}" "${save}" "${file}"
  file_cleanup "${file}"
}

main $@
