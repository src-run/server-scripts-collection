#!/bin/bash

function get_output_root()
{
  local config_path="${HOME}/.torrent-magnets-path"

  if [[ -f "${config_path}" ]]; then
    cat "${HOME}/.torrent-magnets-path" 2> /dev/null
  else
    printf './'
  fi
}

function out_error() {
  local message="${1}"
  shift

  printf 'ERROR: %s\n' "$(printf "${message}" $@)"
}

function out_usage() {
  printf 'Usage: ./%s <magnet-link> [<output_root>]\n' "$(basename ${BASH_SOURCE})"
}

function main() {
  local magnet_link="${1:-x}"
  local output_root="$(get_output_root)"

  if [[ ! -w "${output_root}" ]]; then
    out_error 'Output path "%s" is not writable!' "${output_root}"
    out_usage
    exit 255
  fi

  if [[ "${magnet_link}" == "x" ]]; then
    out_error 'You must specify a magnet link as the first argument!'
    out_usage
    exit 255
  fi

  local magnet_file="$(echo ${magnet_link} | grep -oE '=([^=&]+)' | head -n2 | tail -n 1 | grep -oE '[A-Za-z].+$').magnet"
  local magnet_path="${output_root}/${magnet_file}"

  echo "${magnet_link}" > "${magnet_path}"

  if [[ $? -eq 0 ]]; then
    printf 'Writing magnet: %s\n' "${magnet_path}"
  else
    printf 'Error writing magnet: %s\n' "${magnet_path}"
  fi
}

for magnet_link in "$@"; do
  main "${magnet_link}"
done
