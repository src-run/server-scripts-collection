#!/bin/bash

#
# configuration variables
#
WATCH_DIR="/pool/torrent/watch/"
WATCH_TICK=1
MAGNET_DIR="/pool/torrent/magnets/"
MAGNET_BIN="$HOME/scripts/bin-available/magnet2torrent"
MAGNET_LOG="/tmp/magnet-to-torrent-watcher.log"

#
# get a list of the magnet files that exist
#
function get_magnet_files() {
  echo $(ls ${MAGNET_DIR}*.magnet 2> /dev/null)
}

#
# get a count of the magnet files that exist
#
function get_magnet_count() {
  echo $(ls -l ${MAGNET_DIR}*.magnet 2> /dev/null | wc -l)
}

#
# perform sleep for tick duration
#
function do_sleep() {
  sleep ${WATCH_TICK}
}

#
# display magnet information
#
function out_resolve_info() {
  local magnet_link="${1}"
  local torrent_out="$(basename ${2})"
  local magnet_file="${3}"

  echo "[RESOLVING \"${magnet_file}\"]"
  echo "  - Magnet Link : \"${magnet_link}\""
  echo "  - Output Path : \"${torrent_out}\""
}

#
# display magnet resolution result information
#
function out_resolve_done() {
  local mag2tor_ret=${1}
  local magnet_file="${2}"

  echo -en "  - Result "

  if [[ ${mag2tor_ret} -eq 0 ]]; then
    echo "OKAY : \"Renaming magnet file to ${magnet_file}.resolved\""
    mv "${magnet_file}" "${magnet_file}.resolved"
  else
    echo "FAIL : \"Renaming magnet file to ${magnet_file}.errored\""
    mv "${magnet_file}" "${magnet_file}.errored"
  fi
}

#
# run resoler operation on provided magnet link and output to torrent file
#
function run_resolve_file() {
  local magnet_link="${1}"
  local torrent_out="${2}"

  ${MAGNET_BIN} -m "${magnet_link}" -o "${torrent_out}" &> ${MAGNET_LOG}

  return $?
}

#
# resolve magnet link to torrent file
#
function run_resolve() {
  local verbose="0"
  local magnet_file="${1}"
  local magnet_link="$(cat "${magnet_file}")"
  local torrent_out="${WATCH_DIR}$(basename ${magnet_file} .magnet).torrent"

  cd "${WATCH_DIR}"

  out_resolve_info "${magnet_link}" "${torrent_out}" "${magnet_file}"
  run_resolve_file "${magnet_link}" "${torrent_out}"
  out_resolve_done $? "${magnet_file}"
}

#
# run resolve on available magnet links
#
function do_magnet_loop() {
  for f in $(get_magnet_files); do
    run_resolve "${f}"
  done
}

#
# out pause start (to inform the user we are in waiting state)
#
function out_pause_start() {
  echo -en "[WAITING FOR INPUTS]\n  -"
}

#
# output pause steps (to indicate the script is still running)
#
function out_pause_continue() {
  echo -en "-"
}

#
# run paused or waiting state
#
function do_pause_state() {
  local wait=0

  while [[ $(get_magnet_count) -eq 0 ]]; do
    if [[ ${wait} -eq 0 ]]; then
      out_pause_start
    elif [[ ${wait} -eq 30 ]]; then
      out_pause_continue
      wait=0
    fi

    do_sleep
    wait=$(((${wait} + 1)))
  done

  echo -en "\n"
}

#
# the main function
#
function main() {
  while true; do
    if [[ $(get_magnet_count) -gt 0 ]]; then
      do_magnet_loop
    else
      do_pause_state
    fi

    do_sleep
  done
}

#
# go!
#
main
