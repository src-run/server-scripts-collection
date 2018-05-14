#!/bin/bash

##
## This file is part of the `src-run/user-scripts-server` project.
##
## (c) Rob Frawley 2nd <rmf@src.run>
##
## For the full copyright and license information, please view the LICENSE.md
## file that was distributed with this source code.
##

VERBOSE=false
INTERFACES=()
IP_SCOPE=local
IP_TYPE=4
IP_LIST_UP=0
IP_LIST=0
PRETTY=0

function write_error()
{
    echo >&2 "$1"
}

function write_usage()
{
    printf '\nUsage:\n  ./%s ARGUMENTS [INTERFACE_NAME]\n' "$(basename ${BASH_SOURCE})"
    printf '\nArguments:\n'
    printf '  -i --interface=INTERFACE Specify one or more interfaces to resolve ip information for.\n'
    printf '  -l --list-up             List information for all up interfaces.\n'
    printf '  -L --list-all            List information for all interfaces.\n'
    printf '  -6 --ip-6                Resolve the ip version 6 address.\n'
    printf '  -r --remote              Resolve the remote ip address instead of the local.\n'
    printf '  -p --pretty              Output ip address information with extended information.\n'
    printf '  -h --help                Output this help information.\n'
    printf '  -v --version             Output the version information.\n'
}

function getLocalAddress6()
{
    local interface="${1}"
    local address=$(ip -6 -br addr show ${interface} 2> /dev/null | grep -E -o '[a-f0-9]+[:]+([a-f0-9]+:+?)*' 2> /dev/null)

    if [[ ${PIPESTATUS[0]} -eq 0 ]];
    then
        echo "${address}"
    fi
}

function getLocalAddress4()
{
    local interface="${1}"
    local address=$(ip -4 -br addr show ${interface} 2> /dev/null | grep -E -o '[0-9]+\.([0-9]+\.?)+' 2> /dev/null)

    if [[ ${PIPESTATUS[0]} -eq 0 ]];
    then
        echo "${address}"
    fi
}

function getRemoteAddress()
{
    local bind="${1}"
    local address=$(wget http://ipecho.net/plain -O - -q --bind-address="${bind}" 2> /dev/null)

    if [[ ${PIPESTATUS[0]} -eq 0 ]];
    then
        echo "${address}"
    fi
}

function write_address()
{
    local scope="${1}"
    local interface="${2}"
    local address="${3}"

    if [[ ${PRETTY} -eq 0 ]];
    then
        printf '%s\n' "${address}"
    else
        printf '%s => %s (%s)\n' "${interface}" "${address}" "${scope}"
    fi
}

function write_address_local()
{
    local interface="${1}"
    local address_l="${2}"

    write_address local "${interface}" "${address_l}"
}

function write_address_remote()
{
    local interface="${1}"
    local address_l="${2}"
    local address_r=$(getRemoteAddress "${address_l}")

    if [[ "${address_r}" == "" ]]; then
        write_error "$(printf 'Failed to resolve remote address for "%s" interface.' "${interface}")"
        return
    fi

    write_address remote "${interface}" "${address_r}"
}

function write_interface_info()
{
    local interface="${1}"

    if [[ ${IP_TYPE} -eq 4 ]];
    then
        local address_l=$(getLocalAddress4 "${interface}")
    else
        local address_l=$(getLocalAddress6 "${interface}")
    fi

    if [[ "${address_l}" == "" ]]; then
        write_error "$(printf 'Failed to resolve local address for "%s" interface.' "${interface}")"
        return
    fi

    if [[ ${IP_SCOPE} == local ]];
    then
        write_address_local "${interface}" "${address_l}"
    else
        write_address_remote "${interface}" "${address_l}"
    fi
}

function main()
{
    while [[ $# -gt 0 ]] && [[ ."-${1}" = .--* ]];
    do
        opt="${1}"
        shift

        case "$opt" in
            "--" )
                break 2 ;;
            "-l" | "--list-up" )
                IP_LIST_UP=1 ; IP_LIST=0 ;;
            "-L" | "--list-all" )
                IP_LIST_UP=0 ; IP_LIST=1 ;;
            "-i="* | "--interface="* )
                INTERFACES+=("${opt#*=}") ; IP_LIST=0 ; IP_LIST_UP=0 ;;
            "-6" | "--ip-6" )
                IP_TYPE=6 ;;
            "-r" | "--remote" )
                IP_SCOPE=remote ;;
            "-p" | "--pretty" )
                PRETTY=1 ;;
            "-v" | "--version" )
                printf '%s version 1.0.0\n' "$(basename ${BASH_SOURCE})" ; exit ;;
            * )
                write_error "$(printf 'Invalid option provided: "%s"' "${opt}")" ; write_usage ; exit 255
        esac

        if [[ ${s} -eq 1 ]];
        then
            shift
        fi
    done

    while [[ $# -gt 0 ]];
    do
        INTERFACES+=("${1}")
        IP_LIST_UP=0
        IP_LIST=0
        shift
    done

    if [[ ${IP_LIST_UP} -eq 1 ]]; then
        for interface in $(ip -br link | grep -E -o '^[a-z0-9]+\s+UP' | awk '{print $1}')
        do
            INTERFACES+=("${interface}")
        done
    fi

    if [[ ${IP_LIST} -eq 1 ]]; then
        for interface in $(ip -br link | grep -E -o '^[a-z0-9]+' | awk '{print $1}')
        do
            INTERFACES+=("${interface}")
        done
    fi

    if [[ ${#INTERFACES[@]} -eq 0 ]];
    then
        write_error 'You must provide at least one interface name directly or through the argument option.'
        write_usage
        exit 255
    fi

    for interface in "${INTERFACES[@]}"
    do
        write_interface_info "${interface}"
    done
}

main "$@"
