#!/usr/bin/env zsh

function out_text()
{
    printf -- "${@}"
}

function out_line()
{
    out_text "${1}\n" "${@:2}"
}

function get_self_name()
{
    out_text '%s' "${$(
        readlink -e -n -- "${(%):-%x}"
    ):t:r}"
}

function get_type_char()
{
    case "${1}" in
        'warn')   out_text '%s' '##' ;;
        'fail')   out_text '%s' '!!' ;;
        'info'|*) out_text '%s' '->' ;;
    esac
}

function out_type_pref()
{
    local type_name="${1}"
    local unix_time="$(date +%s\.%N)"

    out_text '(%s @ %.02f) %s %s ' "$(get_self_name)" "${unix_time}" "${type_name:l}" "$(get_type_char "${type_name:l}")"
}

function out_type_text()
{
    local    type="${1}"
    local    text="${2}"
    local -a args=("${@:3}")

    out_type_pref "${type}"
    out_text "${text}" "${(@v)args}"
}

function out_type_line()
{
    out_type_text "${1}" "${2}" "${@:3}"
    out_line
}

function resolve_log_file()
{
    local pool_ident="${1}"
    local temp_tplts="zpool-scrub-status_${pool_ident}-XXXXXX.log"

    mktemp -u -t "${temp_tplts}" 2> /dev/null || \
        out_text '%s' "${temp_tplts}"
}

function resolve_tic_time()
{
    local sleep_time="${SLEEP_TIME:-20}"

    out_text '%d' "${sleep_time}"
}

function resolve_zfs_stat()
{
    local pool_ident="${1}"

    zpool status "${pool_ident}" 2>&1
}

function cleanup_time_string()
{
    sed -E 's/0 (days|hrs|mins), //g' <<< "${1:-$(</dev/stdin)}" \
        | sed -E 's/\b1 (day|hour|min|sec)s\b/1 \1/g' \
        | sed -E 's/\b0*([0-9]+\.[0-9]+)/\1/g' \
        | sed -E 's/\b([0-9]+\.[0-9][1-9])[0]{1}\b/\1/g' \
        | sed -E 's/\b([0-9]+\.[0-9])[0]{2}\b/\1/g'
}

function cleanup_line_finals()
{
    sed -E 's/([^,]{1}.{1})\b[0]+\.[0]+[ ]+(hrs?)/\1unknown \2/g' <<< "${1:-$(</dev/stdin)}" \
        | sed -E 's/\b0[A-Z] repaired/no repairs/g'
}

function is_scrub_in_progress()
{
    if ! grep 'scan: scrub in progress' <<< "$(resolve_zfs_stat "${1}")" &> /dev/null; then
        return 1
    fi
}

function resolve_scrub_size()
{
    grep -E '[0-9\.]+[A-Z] scanned at [0-9\.]+.{,3}' <<< "${1}" \
        | sed -E 's/[ \t]*([0-9\.]+[A-Z]) scanned at ([0-9\.]+[A-Z]\/[a-z]), ([0-9\.]+[A-Z]) [^0-9]+ ([0-9\.]+[A-Z]\/[a-z]), ([0-9\.]+[A-Z]).*/\3 of \5 @ \2/g' \
        | cleanup_time_string
}

function resolve_scrub_repr()
{
    grep -oE '[0-9\.]+[A-Z] repaired' <<< "${1}" \
        | grep -oE '[0-9\.]+[A-Z]'
}

function resolve_scrub_time()
{
    local    hours=0
    local -a parts=("$(
        grep -E '[0-9\.]+% done, .+' <<< "${1}" \
            | grep -oE '[0-9]+ days?' \
            | grep -oE '[0-9]+'
    )" "${(@s/:/)$(
        grep -E '[0-9\.]+% done, .+' <<< "${1}" \
            | grep -oE '[0-9]+:[0-9]+:[0-9]+'
    )}")

    if [[ "${#parts[@]}" -ne 4 ]]; then
        parts=(0 0 0 0)
    fi

    out_text '%d days, %02d.%03d hrs' "${parts[1]}" "${parts[2]}" "${$(
        bc <<< "scale=6; ${parts[3]} / 60" | grep -oE '[0-9]*$'
    ):0:3}" | cleanup_time_string
}

function resolve_scrub_elap()
{
    local now="$(date +%s)"
    local beg="$(
        date --date="$(
            grep -oE 'in progress since .+' <<< "${1}" 2> /dev/null \
                | sed -E 's/in progress since //g' \
                | sed -E 's/[ ]+/ /g'
        )" +%s 2> /dev/null || out_text '%d' "${now}"
    )"
    local len="$((${now} - ${beg}))"
    local day="$((${len} / 86400))"

    if [[ "${day}" -gt 0 ]]; then
        len="$((len - (day * 86400)))"
    fi

    local -a hrs=("${(@s/./)$(
        awk '{printf "%.03f", $1 / 3600}' <<< "${len}"
    )}")

    out_text '%d days, %02d.%03d hrs' "${day}" "${hrs[1]}" "${hrs[2]:0:3}" | cleanup_time_string
}

function resolve_scrub_perc()
{
    local -a percent_set=("${(@s/./)$(
        grep -E '[0-9\.]+% done, .+' <<< "${1}" 2> /dev/null \
            | grep -E -o '[0-9\.]+%' \
            | sed -E 's/%//g'
    )}")

    if [[ "${#percent_set[@]}" -ne 2 ]]; then
        percent_set=("${(@s/./)0.00}")
    fi

    out_text '%02d.%02d%%' "${percent_set[1]}" "${percent_set[2]}"
}

function resolve_pool_names()
{
    local -a finals_named=()
    local -a select_names=()
    local -a passed_names=("${@}")
    local -a online_names=("${(@f)$(
        zpool list -H | awk '{print $1}'
    )}")

    for p in "${(@v)passed_names}"; do
        for o in "${(@v)online_names}"; do
            [[ "${p}" == "${o}" ]] && select_names+=("${o}")
        done
    done

    if [[ "${#select_names[@]}" -eq 0 ]]; then
        select_names=("${(@v)online_names}")
    fi

    for p in "${(@v)select_names}"; do
        is_scrub_in_progress "${p}" \
            && finals_named+=("${p}")
    done

    out_line '%s' "${(@v)finals_named}"
}

function resolve_pool_max_len()
{
    local max_len=0

    for v in "${@}"; do
        [[ "${#v}" -gt "${max_len}" ]] && max_len="${#v}"
    done

    out_text '%d' "${max_len}"
}

function do_sleep_time()
{
    local sleep_time="${1}"

    out_text ' ...'

    for i in {1..${sleep_time}}; do
        sleep 1
        #[[ $((${i} % 2)) -eq 0 ]] && out_text '.'
    done

    out_line
}

function get_scrub_stats_for_pool()
{
    local pool_ident_name="${1}"
    local pool_ident_mlen="${2}"
    local pool_stats_text="$(resolve_zfs_stat "${pool_ident_name}")"

    if ! is_scrub_in_progress "${pool_ident_name}"; then
        return 1
    fi

    local pool_scrub_size="$(resolve_scrub_size "${pool_stats_text}")"
    local pool_scrub_time="$(resolve_scrub_time "${pool_stats_text}")"
    local pool_scrub_elap="$(resolve_scrub_elap "${pool_stats_text}")"
    local pool_scrub_perc="$(resolve_scrub_perc "${pool_stats_text}")"
    local pool_scrub_repr="$(resolve_scrub_repr "${pool_stats_text}")"

    out_type_text 'info' '[ %'${pool_ident_mlen}'s: %s ] scanned %s (%s repaired); %s remaining (%s elapsed)' \
        "${pool_ident_name}" \
        "${pool_scrub_perc}" \
        "${pool_scrub_size}" \
        "${pool_scrub_repr}" \
        "${pool_scrub_time}" \
        "${pool_scrub_elap}" \
            | cleanup_line_finals

    return 0
}

function get_scrub_stats_all_asked()
{
    local -a pool_names=("${(@f)$(resolve_pool_names "${@}")}")
    local    temp_stats

    for p in "${(@v)pool_names}"; do
        if temp_stats="$(get_scrub_stats_for_pool "${p}" "$(
            resolve_pool_max_len "${(@v)pool_names}"
        )")"; then out_line '%s' "${temp_stats}"; fi
    done
}

function out_scrub_stats()
{
    local -a pool_names=("${(@f)$(resolve_pool_names "${@}")}")
    local -a call_lines=("${(@f)$(get_scrub_stats_all_asked "${@}")}")

    if [[ ${#call_lines[@]} -eq 0 ]]; then
        out_type_text 'warn' 'no pools are activly scrubbing'
        do_sleep_time "$(resolve_tic_time)"
        return
    fi

    for i in {1..${#call_lines[@]}}; do
        out_text '%s' "${call_lines[${i}]}"
        [[ "${i}" -lt "${#call_lines[@]}" ]] && out_line
    done

    do_sleep_time "$(resolve_tic_time)"
}

function main()
{
    while true; do
        out_scrub_stats "${@}"
    done
}

main "${@}"
