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

    export NO_COLOR=1
    export AV_LOG_FORCE_NOCOLOR=1

    "${FFPRBE_BIN}" "${video_file}" 2>&1 \
        | grep 'Stream' 2> /dev/null \
        | grep 'Audio'  2> /dev/null \
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
    local logs_file="${logs_path}/$(
        sed -E 's/\//___/g' <<< "${item_relt:-.checks.log}" 2> /dev/null
    ).log"

    pft '%s' "${logs_file}"
}

function check_video_logs()
{
    local    check_file="${1}"
    local -a goods_list=(
        '\b0 decoding errors'
    )
    local -a error_list=(
        'error number -?[0-9]+ occurred'
        'invalid data'
        'does not contain any stream'
        'could not find sync byte'
        'error while decoding stream'
        'non-existing PPS [0-9]+ referenced'
        'at least one output file must be specified'
        'error'
    )

    for search in "${(@v)goods_list}"; do
        if grep -i -E '('"${search}"')' "${check_file}" &> /dev/null; then
            return 0
        fi
    done

    for search in "${(@v)error_list}"; do
        if grep -i -E '('"${search}"')' "${check_file}" &> /dev/null; then
            return 1
        fi
    done

    return 0
}

function get_ffmpeg_opts()
{
    local    video_file_path="${1}"
    local    video_audio_map=''
    local -a ffmpeg_opts_beg=(
        '-nostdin'
        '-v' 'error'
        '-i' "${video_file_path}"
    )
    local -a ffmpeg_opts_end=(
        '-f' 'null'
    )

    if video_audio_map="$(get_audio_track "${video_file_path}")"; then
        ffmpeg_opts_beg+=(
            '-map' "${video_audio_map}"
        )
    fi

    for v in "${(@v)ffmpeg_opts_beg}" "${(@v)ffmpeg_opts_end}"; do
        pfl '%s' "${v}"
    done
}

function check_video_file()
{
    local    video_file="${1}"
    local    check_file="$(get_log_file "${1}" "${2}" "${3}")"
    local -a ffmpeg_opts=("${(@f)$(
        get_ffmpeg_opts "${video_file}"
    )}")

    for v in "${(@v)ffmpeg_opts}"; do
        pfl 'ARG[%s]' "${v}"
    done

    return

    if [[ -e "${check_file}" ]] && [[ ! -f "${check_file}" ]]; then
        pfl '[FAIL:INIT(FILE)]'
        return 1
    fi

    if ! rm --interactive=never -f "${check_file}" &> /dev/null || ! touch "${check_file}"; then
        pfl '[FAIL:INIT(MAKE)]'
        return 1
    fi

    #"${FFMPEG_BIN}" ${(v)ffmpeg_opts} - 2>&1 | tee "${check_file}" &> /dev/null
    #echo "CALL[ ( \"${FFMPEG_BIN}\" ""${(@v)ffmpeg_opts}"" '-' 2>&1 ) > \"${check_file}\" ]"

    export NO_COLOR=1
    export AV_LOG_FORCE_NOCOLOR=1

    echo -n "[CALL:\"${FFMPEG_BIN}\" ""${(@v)ffmpeg_opts}"" '-' &> \"${check_file}\"]"

    if ! "${FFMPEG_BIN}" "${(@v)ffmpeg_opts}" '-' &> "${check_file}"; then
        pfl '[FAIL:CALL]'
        return 1
    fi

    if ! sync "${check_file}" &> /dev/null; then
        pfl '[FAIL:LOGS(SYNC)]'
        return 1
    fi

    sleep 0.5

    if ! check_video_logs "${check_file}"; then
        pfl '[FAIL:LOGS(TEXT)]'
        return 1
    fi

    #if ! rm --interactive=never -f "${check_file}" 2> /dev/null; then
    #    pfl '[OKAY:WARN(RM)]'
    #    return 1
    #fi

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

