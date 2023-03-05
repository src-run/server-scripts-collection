#!/usr/bin/env zsh

FFMPEG_BIN='/opt/ffmpeg-sources/bin/ffmpeg'
FFPRBE_BIN='/opt/ffmpeg-sources/bin/ffprobe'
MDINFO_BIN="$(command -v mediainfo)"

function get_audio_track()
{
    local video_file="${1}"

    "${FFPRBE_BIN}" "${video_file}" 2>&1 \
        | grep Stream \
        | grep Audio \
        | grep -oE '[0-9]:[0-9]' \
        | head -n1

    return "${?}"
}

function get_log_file()
{
    local item_file="${1}"
    local logs_path="${2}"
    local find_path="${3}"
    local item_relt="${item_file/${find_path}\//}"
    local logs_file="${logs_path}/$(sed -E 's/\//___/g' <<< "${item_relt}").log"

    printf -- '%s' "${logs_file}"
}

function check_video_logs()
{
    local    check_file="${1}"
    local -a check_list=(
        '[eE]rror'
        'Invalid data'
        'does not contain any stream'
        'could not find sync byte'
        'Error while decoding stream'
        'non-existing PPS [0-9]+ referenced'
        'At least one output file must be specified'
    )

    for c in "${(@v)check_list}"; do
        if grep -E '('"${c}"')' "${check_file}" &> /dev/null; then
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

    sudo rm "${check_file}" &> /dev/null
    touch "${check_file}"

    "${FFMPEG_BIN}" "${(@v)ffmpeg_opts}" - > "${check_file}" 2>&1

    if ! check_video_logs "${check_file}"; then
        printf -- '[FAIL]\n'
    else
        printf -- '[OKAY]\n'
        rm "${check_file}"
    fi
}

function main()
{
    local find_path="${1}"
    local logs_path="$(printf -- '%s/.checks' "${find_path}")"

    if ! [[ -d "${find_path}" ]]; then
        printf -- 'ERROR: Invalid input path of "%s"\n' "${find_path}"
        exit 1
    fi

    if ! mkdir -p "${logs_path}"; then
        printf -- 'ERROR: Unable to create results path of "%s"\n' "${logs_path}"
    fi

    find "${find_path}" -type f | while read -r file; do
        if mediainfo "${file}" | grep '^Video$' &> /dev/null; then
            printf 'Processing video: "%s" ... ' "${file/${find_path}\//}"
            check_video_file "${file}" "${logs_path}" ${find_path}
        fi
    done
}

main "${@}"
