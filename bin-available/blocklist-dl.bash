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

BLOCKLIST_URL_LINK='http://list.iblocklist.com/?list=bt_level2&fileformat=cidr&archiveformat=gz'
BLOCKLIST_EXT_TYPE='cidr'
BLOCKLIST_DIR_BASE='/pool/torrent/blocklist-comprehensive'
BLOCKLIST_OUT_ROOT="${BLOCKLIST_DIR_BASE}/src"
BLOCKLIST_LOG_ROOT="${BLOCKLIST_DIR_BASE}/var"
BLOCKLIST_TMP_ROOT="${BLOCKLIST_DIR_BASE}/tmp"

#
# internal variables
#

BLOCKLIST_OUT="${BLOCKLIST_OUT_ROOT}/blocklist.${BLOCKLIST_EXT_TYPE}.txt"
BLOCKLIST_LOG="${BLOCKLIST_LOG_ROOT}/blocklist.${BLOCKLIST_EXT_TYPE}.log"

function nuller()
{
  local nullable=${1:-$(</dev/stdin)}

  printf '[NULLABLE] => "%s"\n' "${nullable}"
}

printf 'a fun little error message!' @> >(nuller)
printf 'a fun little error message!' 2>&1 1> >(nuller)
printf 'a fun little error message!' 1>&2 2> >(nuller)
exit
function fmt_date()
{
    local format="${1}"

    if [[ -n ${format} ]]; then
        date +"${format}" 2> /dev/null | awk '{$1=$1};1' 2> /dev/null

        return $?
    fi

    return 1
}

function get_date()
{
    local detail="${1:-1}"
    local f_year='%Y'
    local format='%m-%d'

    [[ ${detail} -eq 1 ]] && format="${f_year}:${format}"

    fmt_date "${format}"

    return $?
}

function get_time()
{
    local detail="${1:-1}"
    local format=''

    local f_h_24='%H'
    local f_m_24='%M'
    local f_s_24='%S'
    local f_n_24='%N'
    local f_p_24=''
    local fmt_24="${f_h_24}:${f_m_24}"

    local f_h_12='%I'
    local f_m_12='%M'
    local f_s_12='%S'
    local f_n_12='%N'
    local f_p_12='%p'
    local fmt_12="${f_h_12}:${f_m_24}"

    [[ ${detail} -eq 1  ]] && fmt_24="${fmt_24}"
    [[ ${detail} -eq 2  ]] && fmt_24="${fmt_24}:${f_s_24}"
    [[ ${detail} -eq 3  ]] && fmt_24="${fmt_24}:${f_s_24}.${f_n_24}"

    [[ ${detail} -eq -1 ]] && fmt_12="${fmt_12} ${f_p_12}"
    [[ ${detail} -eq -2 ]] && fmt_12="${fmt_12}:${f_s_12} ${f_p_12}"
    [[ ${detail} -eq -3 ]] && fmt_12="${fmt_12}:${f_s_12}.${f_n_12} ${f_p_12}"

    if [[ ${detail} -ge 0 ]]; then
        format="${fmt_24}"
    else
        format="${fmt_12}"
    fi

    fmt_date "${format}"

    return $?
}

function get_unix()
{
    local detail="${1:-1}"
    local f_nans='%N'
    local format="%s"

    [[ ${detail} -eq 1  ]] && format+=".${f_nans}"
    [[ ${detail} -eq -1 ]] && format="${f_nans}"

    fmt_date "${format}"

    return $?
}

printf '[get_date  ] => "%s"\n' "$(get_date)"
printf '[get_time  ] => "%s"\n' "$(get_time)"
printf '[get_unix  ] => "%s"\n' "$(get_unix)"
printf '[get_unix:1] => "%s"\n' "$(get_unix 1)"
printf '[get_unix:1] => "%s"\n' "$(get_unix 0)"

exit

#date +%Y-%m-%d\ \@\ %H:%M:%S\ \(%s\.%N\)

function out_sect()
{
    local format=" [ ${1^^} ] "
    shift

    printf "${format}\n" "$@" | tee -a "${BLOCKLIST_LOG}"
}

function out_info()
{
    local format="${1}"
    shift

    printf " • ${format}\n" "$@" | tee -a "${BLOCKLIST_LOG}"
}

function out_warn()
{
    local format="${1}"
    shift

    printf " ! [WARN] ${format}\n" "$@" | tee -a "${BLOCKLIST_LOG}"

    exit 255
}

function log_init()
{
    out_sect 'LOG-RUN @ "%s"' "$(date)"
    printf '\n[RUN @ "%s"]\n' "$(date)" >> "${BLOCKLIST_LOG}"
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

    log_init
    out_sect 'Updating blocklist:' "${BLOCKLIST_URL_LINK}"
    out_info 'Logged blocklist stat: %s' "${BLOCKLIST_LOG}"

    if [[ ! -d "${path}" ]]; then
        mkdir -p "${path}"

        if [[ $? -ne 0 ]]; then
            out_warn 'Unable to create temporary working directory "%s"!' "${path}"
        fi
    fi

    if [[ -f "${file}" ]]; then
        rm "${file}"

        if [[ $? -ne 0 ]]; then
            out_warn 'Unable to remove old temporary working file "%s"!' "${file}"
        fi
    fi

    out_info 'Fetch blocklist link: "%s"' "${BLOCKLIST_URL_LINK}"

    wget -q -O "${file}" "${BLOCKLIST_URL_LINK}"

    if [[ $? -ne 0 ]]; then
        out_warn 'Unable to download blocklist "%s"!' "${BLOCKLIST_URL_LINK}"
        exit
    fi

    local size="$(gzip -dc "${file}" | grep -E '^[0-9]' | wc -l)"

    if [[ ${size} -eq 0 ]]; then
        out_warn 'Unable to create blocklist as download contains 0 lines!'
        exit
    fi

    out_info 'Write blocklist file: "%s" (%d lines)' "${BLOCKLIST_OUT}" ${size}

    gzip -dc "${file}" | grep -E '^[0-9]' | sort -u > "${BLOCKLIST_OUT}"

    if [[ $? -ne 0 ]]; then
        out_warn 'Unable to parse downloaded blocklist "%s"!' "${path}"
    fi

    out_info 'Clean temporary data: "%s"' "${path}"

    rm -fr "${path}"

    if [[ $? -ne 0 ]]; then
        out_warn 'Unable to remove temporary working path "%s"!' "${path}"
    fi
}

main "${1:-x}"

