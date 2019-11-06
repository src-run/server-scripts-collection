#!/bin/bash

function out_line {
    local 
}

function main {
    local deb_file="${1}"
    local deb_opts="${@:2}"

    if [[ -z "${deb_file}" ]]; then
}

if [[ ${#} -eq 0 ]]; then
  printf 'Usage: ./$0 [DEB-PKG-FILE-NAME]\n'
  exit 255
fi

if [[ ${#} -gt 1 ]]; then
  sudo gdebi --option="${@:2}" "${1}"

sudo gdebi --with-depends --tool apt ${@}

if [[ $? -eq 0 ]]; then
  printf 'Finished package install with options "%s"...\n' "${@}"
else
  printf 'FAILED package install with options "%s"...\n' "${@}"
  exit 255
fi
