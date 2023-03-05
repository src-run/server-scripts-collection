#!/usr/bin/env zsh

function out_info()
{
    local    head_text="${1}"
    local    find_path="${2}"
    local    logs_path="${3}"
    local    call_exec="${4}"
    local -a call_args=("${@:5}")

    printf -- '## Configuration:\n'
    printf -- ' - FIND_PATH => "%s"\n' "${find_path}"
    printf -- ' - LOGS_PATH => "%s"\n' "${logs_path}"
    #printf -- ' - CALL_EXEC => "%s"\n' "${call_exec}"
    printf -- ' - CALL_ARGS => "%s"\n' "${(@v)call_args:0:1}"
    printf -- '             => "%s"\n' "${(@v)call_args:2}"
    printf -- '## %s\n' "${head_text}"
}

function main()
{
    local    find_path="${1:-}"
    local    logs_path="${2:-/pool/var/fdupes$(sed -E 's/\//__/g' <<< "${find_path}").log}"
    local    call_exit=0
    local    call_exec="$(command -v fdupes)"
    local -a call_args=(
        "${call_exec}"
        '--recurse'
        '--noempty'
        '--nohidden'
        '--size'
        "${find_path}"
    )

    out_info 'Running operations:' "${find_path}" "${logs_path}" "${call_exec}" "${(@v)call_args}"

    if [[ -z "${call_exec}" ]] || [[ ! -e "${call_exec}" ]]; then
        printf 'FAIL_TEXT[Unable to locate a suitable "fdupes" executable!]\n'
        exit 1
    fi

    if [[ -z "${find_path}" ]]; then
        printf 'FAIL_TEXT[No search path provided!]\n'
        exit 1
    fi

    if [[ ! -d "${find_path}" ]]; then
        printf 'FAIL_TEXT[Provided search path is not a directory!]\n'
        exit 1
    fi

    "${(@v)call_args}" | tee "${logs_path}"
    call_exit="${?}"

    out_info \
        "$(
            printf -- 'Completed operations: (%s)' \
                "$(
                    if [[ "${call_exit}" -eq 0 ]]; then
                        printf -- 'success'
                    else
                        printf -- 'failure [code: %s]' "${call_exit}"
                    fi
                )"
        )" \
        "${find_path}" \
        "${logs_path}" \
        "${call_exec}" \
        "${(@v)call_args}"

    #fdupes --recurse --noempty --nohidden --size "${D}" | tee "/pool/var/fdupes$(sed -E 's/\//__/g' <<< "${D}").log"
}

main "${@}"
