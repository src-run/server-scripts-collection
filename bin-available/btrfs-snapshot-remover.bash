#!/bin/bash

function out_prefix() {
  echo "$(date +"%k%M%S.%N") [$(basename $BASH_SOURCE .bash)]"
}

function out_error() {
  echo "$(out_prefix) Error $1"
  exit
}

function out_info() {
  echo "$(out_prefix) $1"
}

function enforce_root() {
  if [[ "$EUID" -ne 0 ]]; then
    out_error "This script must be run as root. Try \"sudo\" perhaps?"
  fi
}

function main() {
  enforce_root

  local days="$1"
  local bin="$(which apt-btrfs-snapshot)"

  if [[ "$bin" == "" ]]; then
    our_error "Cannot locate 'apt-btrfs-snapshot' executable"
  fi

  out_info "Using $bin to delete snapshots older than ${days} days..."
  $bin delete-older-than ${days}d
}

main "${1:-30}"
