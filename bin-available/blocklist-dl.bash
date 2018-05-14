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
# configuration variables
#

BLOCKLIST_URL="http://list.iblocklist.com/?list=bt_level2&fileformat=cidr&archiveformat=gz"
BLOCKLIST_EXT_TYPE="cidr"
BLOCKLIST_OUT_ROOT="/tmp"
BLOCKLIST_LOG_ROOT="/tmp"
BLOCKLIST_TMP_ROOT="/tmp"

#
# internal variables
#

BLOCKLIST_OUT="${BLOCKLIST_OUT_ROOT}/blocklist.${BLOCKLIST_EXT_TYPE}.txt"
BLOCKLIST_LOG="${BLOCKLIST_LOG_ROOT}/blocklist.${BLOCKLIST_EXT_TYPE}.log"

function log_start()
{
    printf '\n[RUN @ "%s"]\n' "$(date)" >> "${BLOCKLIST_LOG}"
}

function out_title()
{
    local format="${1^^}"
    shift

    printf "${format}\n" "$@" | tee -a "${BLOCKLIST_LOG}"
}

function out_info()
{
    local format="${1}"
    shift

    printf " • ${format}\n" "$@" | tee -a "${BLOCKLIST_LOG}"
}

function out_error()
{
    local format="${1}"
    shift

    printf " • [ERROR] ${format}\n" "$@" | tee -a "${BLOCKLIST_LOG}"

    exit 255
}

function main()
{
    local path="${BLOCKLIST_TMP_ROOT}/blocklist-download-temporary-work"
    local file="${path}/$(basename "${BLOCKLIST_OUT}" .txt).gz"
    local cust="${1}"

    if [[ "x${cust}" != "xx" ]]; then
        BLOCKLIST_OUT="${cust}.${BLOCKLIST_EXT_TYPE}.txt"
        BLOCKLIST_LOG="${cust}.${BLOCKLIST_EXT_TYPE}.log"
    fi

    local logRoot="$(dirname "${BLOCKLIST_LOG}")"

    if [[ ! -d "${logRoot}" ]]; then
        mkdir -p "${logRoot}"

        if [[ $? -ne 0 ]]; then
            out_info '[WARNING] Unable to use custom log path: %s' "${BLOCKLIST_LOG}"

            BLOCKLIST_LOG="/tmp/blocklist.${BLOCKLIST_EXT_TYPE}.log"

            out_info '[WARNING] Using system temporary path instead for logs: %s' "${BLOCKLIST_LOG}"
        fi
    fi

    log_start
    out_title 'Updating blocklist:' "${BLOCKLIST_URL}"
    out_info 'Logged blocklist stat: %s' "${BLOCKLIST_LOG}"

    if [[ ! -d "${path}" ]]; then
        mkdir -p "${path}"

        if [[ $? -ne 0 ]]; then
            out_error 'Unable to create temporary working directory "%s"!' "${path}"
        fi
    fi

    if [[ -f "${file}" ]]; then
        rm "${file}"

        if [[ $? -ne 0 ]]; then
            out_error 'Unable to remove old temporary working file "%s"!' "${file}"
        fi
    fi

    out_info 'Fetch blocklist link: "%s"' "${BLOCKLIST_URL}"

    wget -q -O "${file}" "${BLOCKLIST_URL}"

    if [[ $? -ne 0 ]]; then
        out_error 'Unable to download blocklist "%s"!' "${BLOCKLIST_URL}"
        exit
    fi

    local size="$(gzip -dc "${file}" | grep -E '^[0-9]' | wc -l)"

    if [[ ${size} -eq 0 ]]; then
        out_error 'Unable to create blocklist as download contains 0 lines!'
        exit
    fi

    out_info 'Write blocklist file: "%s" (%d lines)' "${BLOCKLIST_OUT}" ${size}

    gzip -dc "${file}" | grep -E '^[0-9]' | sort -u > "${BLOCKLIST_OUT}"

    if [[ $? -ne 0 ]]; then
        out_error 'Unable to parse downloaded blocklist "%s"!' "${path}"
    fi

    out_info 'Clean temporary data: "%s"' "${path}"

    rm -fr "${path}"

    if [[ $? -ne 0 ]]; then
        out_error 'Unable to remove temporary working path "%s"!' "${path}"
    fi
}

main "${1:-x}"

