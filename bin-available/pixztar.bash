#!/bin/bash

TAR_OPTS=""
TAR_FILE=""
TAR_PATH=""

if ! TAR_EXEC="$(which tar)"; then
  printf 'Failed to find "tar" binary in path: "%s"...\n' "${PATH}"
  exit 255
fi

if ! PIXZ_EXEC="$(which pixz)"; then
  printf 'Failed to find "pixz" binary in path: "%s"...\n' "${PATH}"
  exit 255
fi


if [[ ${1:0:1} == "-" ]]; then
  TAR_OPTS="${1}"
  shift
fi

if [[ -n ${1} ]]; then
  TAR_FILE="${1}"
  shift
fi

if [[ -n ${1} ]]; then
  TAR_PATH="${1}"
  shift
fi

printf 'CALL[%s]\n' "${TAR_EXEC}" -I"${PIXZ_EXEC}" "${TAR_OPTS}" "${TAR_FILE}" "${TAR_PATH}" "${@}"

IFS_BACK="${IFS}"
IFS='
'

"${TAR_EXEC}" -I"${PIXZ_EXEC}" "${TAR_OPTS}" "${TAR_FILE}" "${TAR_PATH}" "${@}" | while read f; do
  printf 'FILE[%s]\n' "${f}"
done

IFS="${IFS_BACK}"
