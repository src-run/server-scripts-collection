#!/bin/bash

readonly _SERFERALS_BIN="${HOME}/s/serferals"
readonly _SERFERALS_DEF_PATH_I=('/pool/torrent/_active-user/work/')
readonly _SERFERALS_DEF_PATH_O='/pool/media/video/'

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

  printf '\e[38;5;236m(\e[38;5;238m%s\e[38;5;236m@\e[38;5;238m%.04f\e[38;5;236m) \e[97;4%dm %s \e[0m \e[1;9%dm%s\e[0m ' \
    'serferals' \
    "$(date +%s\.%N)" \
    "${code}" \
    "${type,,}" \
    "${code}" \
    "${char,,}"
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
    out_pre asks
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

    out_pre warn
    printf 'the provided user response of "%s" is not valid: use only "n" for no and "y" for yes ...\n' "${answer_u}"
  done
}

ask_confirmation y 'are you ready to run serferalls interactively'
printf 'Return code: "%d"\n' "$?"
exit
run_serferals() {
  local    o="${1}"
  local -a i=("${@:2}")

  if [[ ! -e ${_SERFERALS_BIN} ]]; then
    printf '[serferals] !! CRIT - Unable to locate an executable serferals binary at "%s" ...' "${b}"
    return 255
  fi

  "${_SERFERALS_BIN}" -vvv -s -o "${o}" "${i[@]}"
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
