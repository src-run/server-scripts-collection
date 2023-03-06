#!/usr/bin/env bash

readonly MAGNET_QUEUE_SCR_REL_PATH="${BASH_SOURCE[0]}"
readonly MAGNET_QUEUE_SCR_ABS_PATH="$(
  printf "r='${MAGNET_QUEUE_SCR_REL_PATH}'; printf '%%s' \"\${r:A}\"" | zsh
)"
readonly MAGNET_QUEUE_SCR_DIR_PATH="$(dirname "${MAGNET_QUEUE_SCR_ABS_PATH}")"

printf 'MAGNET_QUEUE_SCR_REL_PATH[%s]\n' "${MAGNET_QUEUE_SCR_REL_PATH}"
printf 'MAGNET_QUEUE_SCR_ABS_PATH[%s]\n' "${MAGNET_QUEUE_SCR_ABS_PATH}"
printf 'MAGNET_QUEUE_SCR_DIR_PATH[%s]\n' "${MAGNET_QUEUE_SCR_DIR_PATH}"

