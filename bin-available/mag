#!/bin/bash

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
  local output_root="${2:-/pool/torrent/magnets/}"

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

main $@
