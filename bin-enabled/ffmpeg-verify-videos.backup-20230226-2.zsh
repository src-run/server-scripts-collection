#!/usr/bin/env zsh

FFMPEG_BIN='/opt/ffmpeg-sources/bin/ffmpeg'
FFPRBE_BIN='/opt/ffmpeg-sources/bin/ffprobe'
MDINFO_BIN="$(command -v mediainfo)"

function pft()
{
    printf -- "${@}" 2> /dev/null
}

function pfl()
{
    pft "${1}\n" "${@:2}"
}

function get_audio_track()
{
    local video_file="${1}"

    "${FFPRBE_BIN}" "${video_file}" 2>&1 \
        | grep Stream 2> /dev/null \
        | grep Audio  2> /dev/null \
        | grep -oE '[0-9]:[0-9]' 2> /dev/null \
        | head -n1 2> /dev/null

    return "${?}"
}

function get_log_file()
{
    local item_file="${1}"
    local logs_path="${2}"
    local find_path="${3}"

    local item_relt="${item_file/${find_path}\//}"
    local logs_file="${logs_path}/$(sed -E 's/\//___/g' <<< "${item_relt}" 2> /dev/null).log"

    pft '%s' "${logs_file}"
}

function check_video_logs()
{
    local    check_file="${1}"
    local -a goods_list=(
        '^[0-9]+ frames successfully decoded, 0 decoding errors$'
    )
    local -a error_list=(
        '[eE]rror'
        'Invalid data'
        'does not contain any stream'
        'could not find sync byte'
        'Error while decoding stream'
        'non-existing PPS [0-9]+ referenced'
        'At least one output file must be specified'
    )

    for search in "${(@v)goods_list}"; do
        if grep -E '('"${search}"')' "${check_file}" &> /dev/null; then
            return 0
        fi
    done

    for search in "${(@v)error_list}"; do
        if grep -E '('"${search}"')' "${check_file}" &> /dev/null; then
            return 1
        fi
    done

    return 0
}

function check_video_file()
{
    local    video_file="${1}"
    local    check_file="$(get_log_file "${1}" "${2}" "${3}")"
    local    audio_track=''
    local -a ffmpeg_opts=(
        '-v' 'error'
        '-i' "${video_file}"
        '-f' 'null'
    )

    if audio_track="$(get_audio_track "${video_file}")"; then
        ffmpeg_opts+=('-map' "${audio_track}")
    fi

    if [[ -e "${check_file}" ]] && [[ ! -f "${check_file}" ]]; then
        pfl '[FAIL:SETUP(A)]'
        return 1
    fi

    if ! rm -f "${check_file}" &> /dev/null || ! touch "${check_file}"; then
        pfl '[FAIL:SETUP(B)]'
        return 1
    fi

    #"${FFMPEG_BIN}" ${(v)ffmpeg_opts} - 2>&1 | tee "${check_file}" &> /dev/null
    #echo "CALL[ ( \"${FFMPEG_BIN}\" ""${(@v)ffmpeg_opts}"" '-' 2>&1 ) > \"${check_file}\" ]"

    if ! ( "${FFMPEG_BIN}" "${(@v)ffmpeg_opts}" '-' 2>&1 ) > "${check_file}"; then
        pfl '[FAIL]'
        return 1
    fi

    if ! check_video_logs "${check_file}"; then
        pfl '[FAIL]'
        return 1
    fi

    if ! rm -f "${check_file}" 2> /dev/null; then
        pfl '[OKAY:ERROR(RM)]'
        return 1
    fi

    pfl '[OKAY]'
}

function main()
{
    local find_path="${1}"
    local logs_path="$(
        pft '%s/.checks' "${find_path}"
    )"

    if ! [[ -d "${find_path}" ]]; then
        pfl 'ERROR: Invalid input path of "%s"' "${find_path}"
        return 1
    fi

    if ! mkdir -p "${logs_path}"; then
        pfl 'ERROR: Unable to create results path of "%s"' "${logs_path}"
        return 1
    fi

    find "${find_path}" -type f | while read -r file; do
        if mediainfo "${file}" | grep '^Video$' &> /dev/null; then
            pft 'Processing video: "%s" ... ' "${file/${find_path}\//}"
            check_video_file "${file}" "${logs_path}" ${find_path}
        fi
    done
}

main "${@}"

