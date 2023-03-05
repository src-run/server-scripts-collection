#!/usr/bin/env bash

declare -A _NAME_CACHE_MAP=()
declare -A _SIZE_CACHE_MAP=()

function out_text { printf -- "${@}"; }
function out_newl { out_text '\n'; }
function out_line { out_text "${1}\n" "${@:2}"; }
function out_head { out_line "## ${1}" "${@:2}"; }
function out_hdef { out_head '%s => "%s"' "${1^^}" "$(out_text "${@:2}")"; }

function str_sub {
  local str="${1:-$(</dev/stdin)}"
  local beg="${2:-0}"
  local end="${3:-$((${#str} - 1))}"

  (out_text "${str:${beg}:${end}}") 2> /dev/null
}

function arr_maps_printf {
  for val in "${@:2}"; do
    out_text "${1}" "${val}"
  done
}

function resolve_interface_addr_type {
  declare    type_reqrd="${1}"
  declare    call_value=''
  declare    call_ilist=''
  declare -A call_olist=(
    [r]='-r'
    [l]=''
  )
  declare -a interfaces=(
    eno1
    enp0s0
    enp1s0
    enp2s0
    enp3s0
    enp4s0
    enp5s0
    enp6s0
    enp7s0
    enp8s0
  )

  case "${type_reqrd:l}" in
    r|remote ) call_ilist=r ;;
    l|local|*) call_ilist=l ;;
  esac

  for i_name in "${interfaces[@]}"; do
    if call_value="$(ip-info -i=${i_name} -m -q ${call_olist[${call_ilist}]})"; then
      if [[ "${call_value}" =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; then
        break
      fi
    fi
  done

  out_text '%s' "${call_value}"
}

function resolve_interface_addr_type_l {
  resolve_interface_addr_type 'l'
}

function resolve_interface_addr_type_r {
  resolve_interface_addr_type 'r'
}

function do_display_heading {
  local -a names=("${@}")

  out_newl
  out_head
  out_head

  out_hdef \
    name \
    'RTO Backup Archive Extraction Progress'

  out_hdef \
    date \
    "$(date)"

  out_head

  out_hdef \
    dist \
    '%s (%s)' \
    "$(lsb_release -d | cut -f2 )" \
    "$(lsb_release -c | cut -f2)"

  out_hdef \
    kern \
    '%s %s (%s)' \
    "$(uname -s)" \
    "$(uname -r)" \
    "$(uname -i)"

  out_hdef \
    host \
    '%s (%s)' \
    "$(hostname -f)" \
    "$(
        hostname -a | \
          sed -E 's/[ ]+/\n/g' | \
          sed -E 's/^ip6-//g' | \
          sort -r | \
          uniq | \
          xargs
      )"

  out_hdef \
    addr \
    '%s (%s)' \
    "$(resolve_interface_addr_type_l)" \
    "$(resolve_interface_addr_type_r)"

  out_head

  out_hdef \
    data \
      "$(str_sub '' '0' '-2' <<< "$(arr_maps_printf '%s, ' "${names[@]}")")"

  out_head
  out_head

  out_newl
}

function do_filecal_sizings {
  echo 
  #"${R:-Compiling first-run statistics...}"; sleep 10; R="$(sudo du -h --max-depth=0 ./home ./home-rto-d.tar.xz)"; done
}

function is_existing {
  [[ -e "${1}" ]] || return 1
}

function get_name_resolver_cmd {
  local -a resolver_list=(realpath readlink)
  local    resolver_path

  for resolver_name in "${resolver_list[@]}"; do
    if resolver_path="$(command -v "${resolver_name}" 2> /dev/null)"; then
      break
    fi
  done

  if [[ ! -n ${resolver_path} ]] || [[ ! -e ${resolver_path} ]]; then
    return 1
  fi

  out_line "${resolver_path}"
}

function obj_name_exists {
  local -a fs_names=("${@}")
  local    fs_temps
  local    resolver

  if resolver="$(get_name_resolver_cmd)"; then
    for i in $(seq 0 $(( ${#fs_names[@]} - 1 ))); do
      if fs_temps="$("${resolver}" -e "${fs_names[${i}]}" 2> /dev/null)"; then
        fs_names[${i}]="${fs_temps}"
      fi
    done
  fi

  for name in "${fs_names[@]}"; do
    is_existing "${name}" && out_line "${name}"
  done
}

function main {
  local -a parms=("${@}")
  local -a names=()

  mapfile -t names < <(obj_name_exists "${parms[@]}")

  do_display_heading "${names[@]}"
  exit

  while true; do
    do_display_heading "${names[@]}"
    do_filecal_sizings
  done
}

main "${@}"

_NAME_CACHE_MAP=()
_SIZE_CACHE_MAP=()
