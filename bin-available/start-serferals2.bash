#!/bin/bash

readonly _SERFERALS_BIN="${HOME}/s/serferals"
readonly _SERFERALS_DEF_PATH_I=('/pool/torrent/_active-user/work/')
readonly _SERFERALS_DEF_PATH_O='/pool/media/video/'

#
# output a compiled text string using a passed format and any number of replacement arguments
# (this function uses a printf-style argument api)
#
out_text() {
  printf -- "${@}"
}

#
# get the output type text for the given output type
#
get_type_iden() {
  case "${1:-info}" in
    i|I|info|INFO) out_text 'i' ;;
    a|A|asks|ASKS) out_text 'a' ;;
    w|W|warn|WARN) out_text 'w' ;;
    f|F|fail|FAIL) out_text 'f' ;;
    c|C|crit|CRIT) out_text 'c' ;;
  esac
}

#
# get the output type text for the given output type
#
get_type_text() {
  case "${1:-info}" in
    i) out_text 'info' ;;
    a) out_text 'asks' ;;
    w) out_text 'warn' ;;
    f) out_text 'fail' ;;
    c) out_text 'crit' ;;
  esac
}

#
# get the output style type text color for the given output type
#
get_type_styr() {
  case "${1:-info}" in
    i)   out_text '1;94' ;;
    a)   out_text '1;92' ;;
    w)   out_text '1;93' ;;
    f|c) out_text '1;91' ;;
  esac
}

#
# get the output style character for the given output type
#
get_char_text() {
  case "${1:-info}" in
    i)   out_text '--' ;;
    a)   out_text '>>' ;;
    w)   out_text '##' ;;
    f|c) out_text '!!' ;;
  esac
}

#
# get the output style character color for the given output type
#
get_char_styr() {
  case "${1:-info}" in
    i)   out_text '97;44' ;;
    a)   out_text '97;42' ;;
    w)   out_text '97;43' ;;
    f|c) out_text '97;41' ;;
  esac
}

#
# output styled text with script name and the current unixtime (with 4-digit nanosecond precision)
#
out_pre() {
  local type="${1:-info}"
  local char
  local code

  case "${type}" in
    info) char='--'; code='4'; ;;
    asks) char='>>'; code='2'; ;;
    warn) char='##'; code='3'; ;;
    fail) char='!!'; code='1'; ;;
  esac

  out_text '\e[38;5;236m(\e[38;5;238m%s\e[38;5;236m@\e[38;5;238m%.04f\e[38;5;236m) \e[97;4%dm %s \e[0m \e[1;9%dm%s\e[0m ' \
    'serferals' \
    "$(date +%s\.%N)" \
    "${code}" \
    "${type,,}" \
    "${code}" \
    "${char,,}"
}

#
# output 
#
out_type() {
  local type_ident="$()"
  local type="${1:-info}"
  local char
  local code

  case "${type}" in
    info) char='--'; code='4'; ;;
    asks) char='>>'; code='2'; ;;
    warn) char='##'; code='3'; ;;
    fail) char='!!'; code='1'; ;;
  esac

  out_text '\e[38;5;236m(\e[38;5;238m%s\e[38;5;236m@\e[38;5;238m%.04f\e[38;5;236m) \e[97;4%dm %s \e[0m \e[1;9%dm%s\e[0m ' \
    'serferals' \
    "$(date +%s\.%N)" \
    "${code}" \
    "${type,,}" \
    "${code}" \
    "${char,,}"
}

out_line() {
  out_type "${1}"
  printf -- "${@:2}"
}

ask_confirmation() {
  local -a answer_y=(y Y)
  local -a answer_n=(n N)
  local    answer_d="${1:-y}"
  local    answer_t=''
  local    question="${2:-do you want to continue}"
  local    replaces="${@:3}"

  case "${answer_d}" in
    y|Y) answer_t=' [Y/n]' ;;
    n|N) answer_t=' [y/N]' ;;
  esac

  while true; do
    out_type asks
    read -n 1 -p "$(printf -- "${question}" "${replaces[@]}")${answer_t}? " answer_u

    [[ "${answer_u}" != '' ]] && printf '\n'

    for a in "${answer_y[@]}"; do
      if [[ ${a} == ${answer_u} ]]; then
        return 0
      fi
    done

    for a in "${answer_n[@]}"; do
      if [[ ${a} == ${answer_u} ]]; then
        return 1
      fi
    done

    if [[ ${answer_u} == '' ]] && ([[ ${answer_d} == 'y' ]] || [[ ${answer_d} == 'Y' ]]); then
      return 0
    fi

    out warn 'the provided user response of "%s" is not valid: use only "n" for no and "y" for yes ...\n' "${answer_u}"
  done
}

run_serferals() {
  local    o="${1}"
  local -a i=("${@:2}")

  if [[ ! -e ${_SERFERALS_BIN} ]]; then
    out fail 'unable to locate the "serferals" executable file at its expected location of "%s" (ensure it is placed there and then continue here) ...' "${_SERFERALS_BIN}"
    return 1
  fi

  "${_SERFERALS_BIN}" -vvv -s -o "${o}" "${i[@]}"

  [[ $? -eq 0 ]] && return 0 || return 1
}

main() {
  while true; do
    clear

    printf '\n'
    printf '##\n'
    printf '## robfrawley/serferals\n'
    printf '## interactive prompts for running serferals in a loop\n'
    printf '##\n'
    printf '\n'

    read -p 'Are you ready to run serferals interactively [(Y)/N]? '

    read -a _INPUT_PATHS -t 120 -p 'Input files path [/path/to/input/files]: '
  done
}

main
