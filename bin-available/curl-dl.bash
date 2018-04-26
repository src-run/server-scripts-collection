#!/bin/bash

ask() {
    # https://djm.me/ask
    local prompt default reply

    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n "$1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read reply </dev/tty

        # Default?
        if [ -z "$reply" ]; then
            reply=$default
        fi

        # Check if the reply is valid
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

DL_URL="${1:-x}"
DL_FILE="${2:-x}"

if [[ "${DL_URL}" == "x" ]]; then
  echo -e "Usage:\n\t${BASH_SOURCE} remote_url [local_name]"
  exit 255
fi

if [[ "${DL_FILE}" == "x" ]]; then
  DL_FILE="curl-dl-${RANDOM}.ext"
  DL_FILE_SUGGEST="$(echo "${DL_URL}" | grep -o -E '[^/]+\.(mkv|mp4|avi)')"

  if [[ "${DL_FILE_SUGGEST}" != "" ]]; then
    if ask "[ASKS] Use local file name suggestion \"${DL_FILE_SUGGEST}\" parsed from remote url?"; then
      DL_FILE="${DL_FILE_SUGGEST}"
    fi
  fi
fi

if [[ -f "${DL_FILE}" ]]; then
  if ask "[ASKS] Output file \"${DL_FILE}\" already exists; remove local file before beginning new download?"; then
    printf 'Removing file "%s" from disk ... ' "${DL_FILE}"
    rm "${DL_FILE}" && echo 'done.' || echo 'error!'
  fi
fi

printf '[INFO] Downloading "%s" from "%s" ...\n' "${DL_FILE}" "${DL_URL}"

curl --retry 4 --retry-delay 2 --retry-connrefused -L -# --xattr -o "${DL_FILE}" "${DL_URL}"

DL_RET="$?"

if [[ "${DL_RET}" != "0" ]]; then
  printf '[FAIL] Failed download of "%s" from "%s"!\n' "${DL_FILE}" "${DL_URL}"
  exit 255
fi

function get_file_size() {
  ls -lah "${1}" | grep -o -E 'rmf rmf [0-9]+(\.[0-9]+)?[a-zA-Z]+' | awk '{ print $3 }'
}

printf '[OKAY] Completed download of "%s" (size: %s) from "%s" ...\n' "${DL_FILE}" "$(get_file_size "${DL_FILE}")" "${DL_URL}"
