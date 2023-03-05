#!/bin/bash

function absolute_int() {
  tr -d - <<< "${1}" 2>/dev/null
}

function print_txt() {
  if [[ $# -gt 0 ]]; then
    printf -- "${@}" 2>/dev/null
  fi
}

function print_int() {
  echo -ne "$(print_txt "${@}")"
}

function print_nls() {
  for i in $(seq 1 "$(absolute_int "${1:-1}")"); do
    print_txt '\n'
  done
}

function print_end() {
  print_txt "${@}"
  print_nls
}

function cli_style() {
  _get @ctl:auto-reset "${@}"
}

function str_repeat() {
  local str="${1}"
  local num="${2:-1}"

  for i in $(seq 1 ${num}); do
    print_txt "${str}"
  done
}

function resolve_printer_type_name() {
  case "${1,,}" in
    c|c[a-z]*) print_txt 'crit' ;;
    f|f[a-z]*) print_txt 'fail' ;;
    e|e[a-z]*) print_txt 'fail' ;;
    w|w[a-z]*) print_txt 'warn' ;;
    n|n[a-z]*) print_txt 'note' ;;
    i|i[a-z]*) print_txt 'info' ;;
    d|d[a-z]*) print_txt 'debg' ;;
    *)         print_txt 'unkn' ;;
  esac
}

function resolve_printer_type_char() {
  case "${1}" in
    crit) print_txt '!' ;;
    fail) print_txt '!' ;;
    warn) print_txt '#' ;;
    note) print_txt '+' ;;
    info) print_txt '-' ;;
    debg) print_txt '-' ;;
    *)    print_txt '=' ;;
  esac
}

function compile_printer_self_name() {
  local type="${1}"
  local name="${2:-${BASH_SOURCE[0]}}"
  local temp

  if ! temp="$(realpath -e "${name}" 2>/dev/null)"; then
    temp="$(readlink -e "${name}" 2>/dev/null)"
  fi

  cli_style @style:bold @fg:black "[$(
    basename \
      "${temp:-${name}}" \
      "$(
        grep -oE '\.[a-z0-9]+$' <<< "${temp:-${name}}" 2>/dev/null\
      )" 2>/dev/null || print_txt "${name}"
  )]"
}

function compile_printer_time_frac() {
  local type="${1}"
  local prec="${2:-4}"
  local time="$(
    print_txt \
      "$(print_txt '%%.0%df' "${prec}")" \
      "$(date +%s\.%N)"
  )"

  cli_style @style:bold @fg:black "(${time})"
}

function compile_printer_defs_type() {
  local type="${1}"
  local decs='@fg:white @bg:black @style:bold'

  case "${1}" in
    crit) decs='@fg:white @bg:red' ;;
    fail) decs='@fg:black @bg:red' ;;
    warn) decs='@fg:black @bg:yellow' ;;
    note) decs='@fg:white @bg:magenta @style:bold' ;;
    info) decs='@fg:white @bg:blue @style:bold' ;;
    debg) decs='@fg:black @bg:white' ;;
  esac

  cli_style ${decs} " ${type^^} "
}

function compile_printer_defs_char() {
  local type="${1}"
  local char="$(resolve_printer_type_char "${type}")"
  local decs='@fg:white'

  case "${1}" in
    crit) decs='@fg:red @style:bold' ;;
    fail) decs='@fg:red' ;;
    warn) decs='@fg:yellow @style:bold' ;;
    note) decs='@fg:magenta @style:bold' ;;
    info) decs='@fg:blue @style:bold' ;;
    debg) decs='@fg:white @style:bold' ;;
  esac

  cli_style ${decs} "$(str_repeat "${char}" 3)"
}

function print_def() {
  def_type="$(resolve_printer_type_name "${1}")"

  print_int '%s %s %s %s %s' \
    "$(compile_printer_self_name "${def_type}")" \
    "$(compile_printer_time_frac "${def_type}")" \
    "$(compile_printer_defs_type "${def_type}")" \
    "$(compile_printer_defs_char "${def_type}")" \
    "$(print_txt "${@:2}")"
}

function print_def_n() {
  print_def "${@}"
  print_nls
}

function print_def_info_n() {
  print_def_n info "${@}"
}

function print_def_fail_n() {
  print_def_n fail "${@}"
}

function make_req_path_norm() {
  if [[ ! -d "${1}" ]] && ! mkdir "${1}" &> /dev/null; then
    print_txt '! [FAIL] Could not create required path: "%s"\n' "${1}" && return 255
  fi
}

function make_req_path_dirn() {
  make_req_path_norm "$(
    dirname "${1}" 2>/dev/null || print_txt "${1}"
  )"
}

function read_file_contents() {
  cat "${1}" 2>/dev/null
}

function line_count_of_file() {
  grep -oE ^http <<< "$(read_file_contents "${1}")" 2>/dev/null \
    | wc -l 2>/dev/null
}

function resolve_get_link() {
  sed -E "s/\/[0-9]{3}\//\/${2}\//g" <<< "${1}" 2>/dev/null
}

function resolve_out_path() {
  sed -E "s/https:\/\/splus-phoenix-render.pnimedia.com\/api\/v3\/thumb\/([A-Z]+)\/([^\/]+)\/[0-9]+\/([^\/]+)\/[0-9]{3}\/([A-Z][a-z]+)\.([a-z]+)\?[a-zA-Z]+=([A-Za-z0-9]+)[^\n]+/\1-\2-\3_\4-\6_${2}.\5/g" <<< "${1}" 2>/dev/null
}

function main()
{
  uri_path="${1:-${HOME}/cards.txt}"
  out_root="${2:-${HOME}/downloads-${1:-undefined}/}"
  get_wdth="${3:-10240}"
  log_path="/tmp/.bash-curl-fail-text_$(sed -E 's/[^a-zA-Z0-9\._-]//g' <<< "${BASH_SOURCE[0]}").log"

  for raw_link in $(read_file_contents "${uri_path}"); do
    num_loop="$((${num_loop:-0} + 1))"
    get_link="$(
      resolve_get_link "${raw_link}" "${get_wdth}"
    )"
    out_path="${out_root}/$(
      resolve_out_path "${raw_link}" "${get_wdth}"
    )"

    make_req_path_dirn "${out_path}" || return $?
    make_req_path_dirn "${log_path}" || return $?

    print_txt -- '- [%03d/%03d] "%s" --> "%s" ... ' "${num_loop}" "$(line_count_of_file "${uri_path}")" "${get_link}" "${out_path}"

    [[ -f "${out_path}" ]] && print_txt 'SKIP (%s)\n' "exists" && continue

    curl --silent --show-error --output "${out_path}" "${get_link}" && \
      print_txt 'DONE (%s)\n' "$(du -h "${out_path}" | cut -f1)" || \
      print_txt 'FAIL (%s)\n' "$(cat "${out_path}" | paste -sd " " -)"

    purge_file "${log_path}"
  done

  return 0
}

function unlink_file() {
  if [[ -f "${1}" ]] && ! rm "${1}" &>/dev/null; then
    print_def_fail_n 'Could not unlink file: "%s"' "${1}"
    print_nls
  fi
}

function create_file() {
  print_txt ''
}

#
# internal variables
#
readonly _SELF_PATH="$(dirname "$(readlink -m "${0}")")"

#
# configuration
#
if [[ -z "${BRIGHT_LIBRARY_PATH}" ]]; then
    BRIGHT_LIBRARY_PATH="${_SELF_PATH}/../lib/bright/bright.bash"
fi

#
# check for required bright library dependency
#
if [[ ! -f "${BRIGHT_LIBRARY_PATH}" ]]; then
    print_txt 'Failed to source required dependency: bright-library (%s)\n' \
        "${BRIGHT_LIBRARY_PATH}"
    exit 255
fi

#
# source bright library dependency
#
source "${BRIGHT_LIBRARY_PATH}"

#main "${@}"

print_def_n crit 'this is %d %s of type "%s"...' 1 'message string' crit
print_def_n fail 'this is %d %s of type "%s"...' 1 'message string' fail
print_def_n warn 'this is %d %s of type "%s"...' 1 'message string' warn
print_def_n note 'this is %d %s of type "%s"...' 1 'message string' note
print_def_n info 'this is %d %s of type "%s"...' 1 'message string' info
print_def_n debg 'this is %d %s of type "%s"...' 1 'message string' debg
print_def_n unkn 'this is %d %s of type "%s"...' 1 'message string' unkn
