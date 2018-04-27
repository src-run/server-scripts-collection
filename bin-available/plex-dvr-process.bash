#!/bin/bash

if [[ ${1:-x} == "x" ]]; then
    echo "Usage: ${0} input-video-file"
    exit 255
fi

file_origin="$1"
file_origin_dirname="$(dirname "${file_origin}")"
file_origin_basename="$(basename "${file_origin}" .ts)"
file_output="${file_origin_dirname}/${file_origin_basename}.mkv"
file_lock="/tmp/${file_origin_basename}.lock"
file_log="/tmp/${file_origin_basename}.log"
file_log_verbose="/tmp/${file_origin_basename}.vvv.log"

bin_comskip="/opt/plex-comskip/PlexComskip.py"
opt_comskip=""

bin_ccextractor="/opt/ccextractor/ccextractor"
opt_ccextractor=""

bin_encode="/usr/bin/HandBrakeCLI"
opt_encode="--format mkv --encoder x264 --quality 20 --loose-anamorphic --decomb fast --x264-preset fast --h264-profile high --h264-level 4.1"

bin_setlang="/usr/bin/mkvpropedit"
opt_setlang="--edit track:a1 --set language=eng --edit track:v1 --set language=eng"

function log() {
    printf '[%s] (%s) %s\n' "$(date +%Y%m%d.%H%M%S.%N)" "${file_origin_basename}" "${1}" | tee -a "${file_log}"
}

function log_action() {
    local action="${1}"
    local bin="${2}"
    local opt=${3}

    log "$(printf 'Running %s action: "%s %s"' "${action}" "${bin}" "${opt}")"
}

function lock_pid() {
    echo "$(cat "${file_lock}" 2> /dev/null)"
}

function lock_aquire() {
    local pid=$$

    log "$(printf 'Aquiring lock (PID %s)' "${pid}")"
    echo "${pid}" | tee "${file_lock}"
}

function lock_release() {
    log "$(printf 'Releasing lock (PID %s)' "$(lock_pid)")"
    rm "${file_lock}"
}

function lock_check_wait() {
    while [[ -f "${file_lock}" ]]; do
        log "$(printf 'Found previous lock (PID %s); waiting 10 seconds...' "$(lock_pid)")"
        sleep 10
    done
}

function do_comskip() {
    log_action "comskip" "${bin_comskip}" "\"${file_origin}\" ${opt_comskip}"
    ${bin_comskip} "${file_origin}" ${opt_comskip} | tee -a "${file_log_verbose}"
}

function do_srt_extract() {
    log_action "srt-extract" "${bin_ccextractor}" "\"${file_origin}\" -o \"${file_origin}.srt\" ${opt_ccextractor}"
    ${bin_ccextractor} "${file_origin}" -o "${file_origin}.srt" ${opt_ccextractor} | tee -a "${file_log_verbose}"
}

function do_mkv_encode() {
    log_action "mkv-encode" "${bin_encode}" "-i \"${file_origin}\" -o \"${file_output}\" ${opt_encode}"
    ${bin_encode} -i "${file_origin}" -o "${file_output}" ${opt_encode} | tee -a "${file_log_verbose}"
}

function do_mkv_setlang() {
    log_action "mkv-set-lang" "${bin_setlang}" "\"${file_output}\" ${opt_setlang}"
    ${bin_setlang} "${file_output}" ${opt_setlang} | tee -a "${file_log_verbose}"
}

function main() {
    lock_check_wait
    lock_aquire

    do_comskip
#    do_mkv_encode
    do_srt_extract
#    do_mkv_setlang

    lock_release
}

main

