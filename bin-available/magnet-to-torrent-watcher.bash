#!/bin/bash

#
# configuration variables
#
WATCH_TICK=1
WATCH_ECHO_TICK=20
MAGNET_BIN="$(which magnet-to-torrent-writer)"
MAGNET_LOG="/tmp/magnet-to-torrent-watcher_${RANDOM}.log"

#
# output torrent watch directory
#
function get_output_root()
{
  local root="${HOME}/.torrent-watch-path"

  if [[ -f "${root}" ]]; then
    cat "${root}" 2> /dev/null
  else
    printf './'
  fi
}

#
# get the magnet files root
#
function get_magnet_root()
{
  local root="${HOME}/.torrent-magnets-path"

  if [[ -f "${root}" ]]; then
    cat "${root}" 2> /dev/null
  else
    printf './'
  fi
}

#
# get a list of the magnet files that exist
#
function get_magnet_files() {
  echo $(ls $(get_magnet_root)*.magnet 2> /dev/null)
}

#
# get a count of the magnet files that exist
#
function get_magnet_count() {
  echo $(ls -l $(get_magnet_root)*.magnet 2> /dev/null | wc -l)
}

#
# display magnet information
#
function out_resolve_info() {
  local magnet_link="${1}"
  local torrent_out="$(basename ${2})"
  local magnet_file="${3}"

  printf 'Resolving "%s" to "%s" ' "${magnet_file}" "${torrent_out}"
}

#
# display magnet resolution result information
#
function out_resolve_done() {
  local mag2tor_pid=${1}
  local magnet_file="${2}"

  printf '(spawned as %d)\n' ${mag2tor_pid}
  mv "${magnet_file}" "${magnet_file}.resolved"
}

#
# run resoler operation on provided magnet link and output to torrent file
#
function run_resolve_file() {
  local magnet_link="${1}"
  local torrent_out="${2}"

  ${MAGNET_BIN} -m "${magnet_link}" -o "${torrent_out}" &> ${MAGNET_LOG} &

  echo "$!"
}

#
# resolve magnet link to torrent file
#
function run_resolve() {
  local verbose="0"
  local magnet_file="${1}"
  local magnet_link="$(cat "${magnet_file}")"
  local torrent_out="$(get_output_root)$(basename ${magnet_file} .magnet).torrent"

  cd "$(get_output_root)"

  out_resolve_info "${magnet_link}" "${torrent_out}" "${magnet_file}"
  local pid=$(run_resolve_file "${magnet_link}" "${torrent_out}")
  out_resolve_done ${pid} "${magnet_file}"
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
# display background state if any spawned processes running
#
function do_background_state() {
  local bg_count="$(ps aux | grep "[m]agnet2torrent" | wc -l)"
  local job_p="jobs"

  if [[ "${bg_count}" -eq 1 ]]; then
    job_p="job"
  fi

  if [[ "${bg_count}" -eq 0 ]]; then
    return
  fi

  printf '(%d background %s)...' "${bg_count}" "${job_p}"
}

#
# run paused or waiting state
#
function do_pause_state() {
  local wait=0

  while [[ $(get_magnet_count) -eq 0 ]]; do
    if [[ ${wait} -eq 0 ]]; then
      printf 'Sleeping...'
      do_background_state
    elif [[ ${wait} -eq ${WATCH_ECHO_TICK} ]]; then
      printf '...'
      do_background_state
      wait=0
    fi

    sleep ${WATCH_TICK}
    wait=$(((${wait} + 1)))
  done

  printf 'waking (found %d new magnet links)...\n' $(get_magnet_count)
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
  done
}

#
# go!
#
main
