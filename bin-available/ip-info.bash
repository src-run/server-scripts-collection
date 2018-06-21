#!/bin/bash

##
## This file is part of the `src-run/user-scripts-server` project.
##
## (c) Rob Frawley 2nd <rmf@src.run>
##
## For the full copyright and license information, please view the LICENSE.md
## file that was distributed with this source code.
##

#
# do not suppress errors by default
#
IP_INFO_OUTPUT_ERROR_SUPPRESS=0

#
# resolve the script name
#
function get_script_name()
{
    basename "${BASH_SOURCE}"
}

#
# output new line
#
function write_newline()
{
    printf '\n'
}

#
# output error message to stderr
#
function write_error()
{
    local message="${1}"
    local do_exit="${2:--1}"

    if [[ ${IP_INFO_OUTPUT_ERROR_SUPPRESS} -ne 1 ]]; then
        printf '[ERROR] %s\n' "${message}" >&2
    fi

    if [[ ${do_exit} -ne -1 ]]; then
        exit ${do_exit}
    fi
}

#
# output script usage information
#
function write_usage()
{
    printf 'Usage:\n  ./%s ARGUMENTS [INTERFACE_NAME]\n\nArguments:\n' "$(get_script_name)"
    printf '  -i --interface=NAME  specify one or more interface names\n'
    printf '  -l --list            list information for all resolvable interfaces\n'
    printf '  -6 --ipv6            resolve the IP version 6 address\n'
    printf '  -r --remote          resolve the remote IP address (only supports IPv4)\n'
    printf '  -c --no-remote-cache disable caching of remote IP address\n'
    printf '  -m --minimal         output minimal information (IP only)\n'
    printf '  -q --minimal-quiet   output minimal information (IP only) and ignore any errors\n'
    printf '  -V --verbose         output verbose information (IP, scope, level, and interface)\n'
    printf '  -h --help            output this help information\n'
    printf '  -v --version         output the version information\n'
}

#
# resolve the local ipv4 address
#
function get_address_local_v6()
{
    local interface="${1}"
    local address=$(ip -6 -br addr show ${interface} 2> /dev/null | grep -E -o '[a-f0-9]+::([a-f0-9]+:?)+/[0-9]+' 2> /dev/null)

    if [[ ${PIPESTATUS[0]} -eq 0 ]];
    then
        echo "${address}"
    fi
}

#
# resolve the local ipv6 address
#
function get_address_local_v4()
{
    local interface="${1}"
    local address=$(ip -4 -br addr show $interface 2> /dev/null | grep -E -o '(UNKNOWN|UP|DOWN)\s+[0-9]+\.([0-9]+\.?)+' 2> /dev/null | awk '{print $2}' 2> /dev/null)

    if [[ ${PIPESTATUS[0]} -eq 0 ]];
    then
        echo "${address}"
    fi
}

#
# checks if a cache file is written to disk
#
function is_cache_file_written()
{
    local file="${1}"

    [[ -f "${file}" ]] && echo 1 || echo 0
}

#
# checks if a cache file is "fresh" (not expired)
#
function is_cache_file_fresh()
{
    local file="${1}"
    local time=$(date +%s)

    [[ $(is_cache_file_written "${file}") -eq 1 ]] && \
        [[ $((${time} - $(stat -c %Y "${file}" 2> /dev/null || echo 300))) -lt 300 ]] && \
        echo 1 || \
        echo 0
}

#
# prune stale cache files by removing them
#
function prune_stale_cache_files()
{
    local path="${1}"

    find "${path}" -name "*.cache" -print0 2> /dev/null | while read -d $'\0' file
    do
        if [[ $(is_cache_file_fresh "${file}") -eq 0 ]]; then
            rm "${file}" 2> /dev/null
        fi
    done
}

#
# resolve the remote address from cache
#
function get_cached_remote_address()
{
    local full="${1}"
    local path="$(dirname "${full}")"
    local file="$(basename "${full}")"

    if [[ ! -d "${path}" ]]; then
        mkdir -p "${path}"

        if [[ $? -ne 0 ]]; then
            return
        fi
    fi

    prune_stale_cache_files "${path}"

    if [[ $(is_cache_file_fresh "${full}") -eq 1 ]]; then
        cat "${full}" 2> /dev/null
    fi
}

#
# assign the remote address from cache
#
function set_cached_remote_address()
{
    local file="${1}"
    local address_r="${2}"

    echo "${address_r}" > "${file}" 2> /dev/null
}

#
# resolve the remote address
#
function get_address_remote()
{
    local bind="${1}"
    local cache_file="/tmp/ip-info/${bind}.cache"
    local use_cache="${2}"
    local address_r=""

    if [[ "${use_cache}" -eq 1 ]]; then
        address_r="$(get_cached_remote_address "${cache_file}")"
    fi

    if [[ "${address_r}" != "" ]]; then
        printf 'cache:%s' "${address_r}"
    else
        address_r=$(wget http://ipecho.net/plain -O - -q --bind-address="${bind}" 2> /dev/null)

        if [[ ${PIPESTATUS[0]} -ne 0 ]];
        then
            return
        fi

        if [[ "${use_cache}" -eq 1 ]]; then
            set_cached_remote_address "${cache_file}" "${address_r}"
        fi

        printf 'fresh:%s' "${address_r}"
    fi

    if [[ "${use_cache}" -eq 0 ]] && [[ $(is_cache_file_written "${cache_file}") -eq 1 ]]; then
        rm "${cache_file}"
    fi
}

function write_address()
{
    local scope="${1}"
    local interface="${2}"
    local address="${3}"
    local ip_scope="${4}"
    local output_level="${5}"
    local address_type="${6:-fresh}"

    if [[ ${output_level} -eq 0 ]];
    then
        printf '%s\n' "${address}"
        return
    fi

    if [[ ${output_level} -eq 1 ]];
    then
        printf '[%s] %s\n' "${interface}" "${address}"
        return
    fi

    printf '[%s] %s (%s IPv%d) ' "${interface}" "${address}" "${scope}" "${ip_scope}"

    if [[ "${address_type}" == "cache" ]]; then
        printf '[cached] '
    fi

    printf '\n'

}

function write_address_local()
{
    local interface="${1}"
    local address_l="${2}"
    local ip_scope="${3}"
    local output_level="${4}"

    write_address local "${interface}" "${address_l}" "${ip_scope}" "${output_level}"
}

function write_address_remote()
{
    local interface="${1}"
    local address_l="${2}"
    local ip_scope="${3}"
    local output_level="${4}"
    local use_cache="${5}"
    local address_raw=$(get_address_remote "${address_l}" "${use_cache}")
    local address_type="${address_raw:0:5}"
    local address_r="${address_raw:6}"

    if [[ "${address_r}" == "" ]]; then
        write_error "$(printf 'Failed to resolve remote address for "%s" interface.' "${interface}")"
        return
    fi

    write_address remote "${interface}" "${address_r}" "${ip_scope}" "${output_level}" "${address_type}"
}

function write_interface_information()
{
    local interface="${1}"
    local ip_scope="${2}"
    local ip_level="${3}"
    local output_level="${4}"
    local use_cache="${5}"
    local address_l="$([[ ${ip_level} -eq 6 ]] && get_address_local_v6 "${interface}" || get_address_local_v4 "${interface}")"

    if [[ "${address_l}" == "" ]]; then
        write_error "$(printf 'Failed to resolve local address for "%s" interface.' "${interface}")"
        return
    fi

    if [[ "${ip_scope}" == "local" ]];
    then
        write_address_local "${interface}" "${address_l}" "${ip_level}" "${output_level}"
    else
        write_address_remote "${interface}" "${address_l}" "${ip_level}" "${output_level}" "${use_cache}"
    fi
}

function main()
{
    local interfaces=()
    local do_list_interfaces=0
    local ip_scope="local"
    local ip_level=4
    local output_level=1
    local use_cache=1

    while [[ $# -gt 0 ]] && [[ ."-${1}" = .--* ]];
    do
        opt="${1}"
        shift

        case "$opt" in
            "--" )
                break 2
                ;;
            -l | --list )
                do_list_interfaces=1
                ;;
            -i=* | --interface=* )
                interfaces+=("${opt#*=}")
                do_list_interfaces=0
                ;;
            -6 | --ipv6 )
                ip_level=6
                ;;
            -r | --remote )
                ip_scope=remote
                ;;
            -c | --no-remote-cache )
                use_cache=0
                ;;
            -q | --minimal-quiet )
                IP_INFO_OUTPUT_ERROR_SUPPRESS=1
                ;;
            -m | --minimal )
                output_level=0
                ;;
            -V | --verbose )
                output_level=2
                ;;
            -v | --version )
                printf '%s version 1.0.0\n' "$(get_script_name)"
                exit
                ;;
            -h | --help )
                write_usage
                exit
                ;;
            * )
                write_usage
                write_newline
                write_error "$(printf 'Invalid option provided: "%s"' "${opt}")" 255
                ;;
        esac

        if [[ ${s} -eq 1 ]];
        then
            shift
        fi
    done

    if [[ "${do_list_interfaces}" -eq 1 ]]; then
        IP_INFO_OUTPUT_ERROR_SUPPRESS=1
    fi

    while [[ $# -gt 0 ]];
    do
        interfaces+=("${1}")
        do_list_interfaces_act=0
        do_list_interfaces_all=0
        shift
    done

    if [[ ${do_list_interfaces} -eq 1 ]]; then
        for interface in $(ip -br link | grep -E -o '^[a-z0-9]+\s+(UP|UNKNOWN)' | awk '{print $1}')
        do
            interfaces+=("${interface}")
        done
    fi

    if [[ ${#interfaces[@]} -eq 0 ]];
    then
        write_usage
        write_newline
        write_error 'An interface name (directly or using arguments), or a list argument must be provided.'
    fi

    for name in "${interfaces[@]}"
    do
        write_interface_information "${name}" "${ip_scope}" "${ip_level}" "${output_level}" "${use_cache}"
    done
}

main "$@"
