#!/bin/bash

declare -A BINARY_MAPTO_NICE
declare -A BINARY_MAPTO_IONICE

BINARY_MAPTO_NICE['/usr/lib/plexmediaserver/Plex Transcoder']="-19"
BINARY_MAPTO_IONICE['/usr/lib/plexmediaserver/Plex Transcoder']="1 4"

function set_nice_for_binary()
{
    local bin="${1}"
    local lvl="${2}"

    for pid in $(pidof "${bin}"); do
        printf 'Setting nice priority to "%d" for "%s" with PID "%d" ... ' "${lvl}" "${bin}" "${pid}"
        renice -n "${lvl}" -p "${pid}" &> /dev/null
        [ $? -eq 0 ] && echo "OK" || echo "FAILURE"
    done
}

function set_ionice_for_binary()
{
    local bin="${1}"
    local lvl=(${2})
    local lvlClass="${lvl[0]}"
    local lvlLevel="${lvl[1]}"

    for pid in $(pidof "${bin}"); do
        printf 'Setting ionice priority to "%d@%d" for "%s" with PID "%d" ... ' "${lvlClass}" "${lvlLevel}" "${bin}" "${pid}"
        ionice -c "${lvlClass}" -n "${lvlLevel}" -p "${pid}" &> /dev/null
        [ $? -eq 0 ] && echo "OK" || echo "FAILURE"
    done
}

function main()
{
    local sleepSeconds="${1}"

    while true; do
        for binary in "${!BINARY_MAPTO_NICE[@]}"; do
            set_nice_for_binary "${binary}" "${BINARY_MAPTO_NICE["${binary}"]}"
        done

        for binary in "${!BINARY_MAPTO_IONICE[@]}"; do
            set_ionice_for_binary "${binary}" "${BINARY_MAPTO_IONICE["${binary}"]}"
        done

        printf 'Sleeping for "%d" seconds...\n' "${sleepSeconds}"
        sleep ${sleepSeconds}
    done
}

main ${1:-2}
