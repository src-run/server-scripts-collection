#!/usr/bin/env zsh

#function out_text() { printf -- "${@}" }
#function out_line() { out_text "${@}"; out_text '\n' }
#function out_text_type() { out_text '%.04f [ %s ] %s ...' "$(date +%s\.%N)" "${1}" "$(out_text "${@:2}")" }
#function out_line_type() { out_text_type "${@}"; out_text '\n' }
#function out_line_asks() { out_text '%.04f [ %s ] %s? [y\N]: ' "$(date +%s\.%N)" '??' "$(out_text "${@}")" }
#function out_line_info() { out_line_type '--' "${@}" }
#function out_line_note() { out_line_type '##' "${@}" }
#function out_line_warn() { out_line_type '!-' "${@}" }
#function out_line_fail() { out_line_type '!!' "${@}" }

declare -r UNIX_BEG_SET=("$(date +%s\.%N)")
declare -a UNIX_END_SET=()
declare -r SLEEP_SECOND=20
declare -r IONICE_CLASS="${1:-0}"
declare -r IONICE_GROUP="${2:-0}"
declare -r BACKUP_PATHS=("${@:3}")
declare -r SRCS_RM_PATH='/pool/'
declare -r DEST_RM_PATH='/tank/pool/'
declare -r LG_ROOT_PATH='/tank/rsync-logs'
declare -a RS_CALL_OPTS=(
    '--recursive'
    '--verbose'
    '--human-readable'
    '--progress'
    '--links'
    #'--copy-unsafe-links'
    #'--keep-dirlinks'
    '--owner'
    '--group'
    '--perms'
    '--devices'
    '--specials'
    '--times'
    '--force'
    '--delete'
    '--delete-before'
    '--max-delete' '0'
    '--ignore-errors'
    '--sparse'
    '--info' 'progress2'
    '--stats'
)

j=1
for (( i=1; i<=${#BACKUP_PATHS[@]}; i=i+2 )); do
    declare RS_PATH_SRCS="${SRCS_RM_PATH}${BACKUP_PATHS[${i}]/${SRCS_RM_PATH}/}"

    [[ -n ${BACKUP_PATHS[$(( i + 1 ))]} ]] \
        && declare RS_PATH_DEST="${DEST_RM_PATH}${BACKUP_PATHS[$(( i + 1 ))]/${DEST_RM_PATH}/}" \
        || declare RS_PATH_DEST="${DEST_RM_PATH}${RS_PATH_SRCS/${SRCS_RM_PATH}/}"

    declare LG_CALL_PATH="${LG_ROOT_PATH}_$(
        sed -E 's/\//-/g' <<< "${BACKUP_PATHS[${i}]/${SRCS_RM_PATH}/}" | sed -E 's/(^-|-$)//g'
    )_$(
        date +%Y%m%d-%H%M
    ).log"

    clear
    printf '\n##\n## [date_time] => "%s"\n## [elapsed_s] => "%s"\n## [back_numb] => "%02d / %02d"\n' \
        "$(date)" \
        "$(($(date +%s\.%N) - ${UNIX_BEG_SET[1]}))" \
        "${j}" \
        "$((${#BACKUP_PATHS[@]} / 2))"

    printf '## [nice_io_c] => "%s" (classname: %s)\n' \
        "${IONICE_CLASS}" \
        "$(
            case "${IONICE_CLASS}" in
                0) printf 'none' ;;
                1) printf 'realtime' ;;
                2) printf 'best-effort' ;;
                3) printf 'idle' ;;
                *) printf 'undefined' ;;
            esac
        )"

    printf '## [nice_io_g] => "%s" (priority : %s)\n' \
        "${IONICE_GROUP}" \
        "$(
            if [[ ${IONICE_CLASS} -ne 1 ]] && [[ ${IONICE_CLASS} -ne 2 ]]; then
                printf 'unavailable'
            else
                case "${IONICE_CLASS}" in
                    0|1) printf 'highest' ;;
                    2  ) printf 'high' ;;
                    3|4) printf 'middle' ;;
                    5  ) printf 'low' ;;
                    6|7) printf 'lowest' ;;
                    *  ) printf 'undefined' ;;
                esac
            fi
        )"

    printf '## [srcs_path] => "%s"      (copy mode: %s)\n' \
        "${RS_PATH_SRCS}" \
        "$(
            if [[ ${RS_PATH_SRCS} =~ /$ ]]; then
                printf 'src path sub-folders'
            else
                printf 'src path included'
            fi
        )"

    printf '## [dest_path] => "%s" (copy mode: %s)\n' \
        "${RS_PATH_DEST}" \
        "$(
            if [[ ${RS_PATH_DEST} =~ /$ ]]; then
                printf 'src path sub-folders'
            else
                printf 'src path included'
            fi
        )"

    printf '## [logs_file] => "%s"\n' \
        "${LG_CALL_PATH}"

    printf '## [call_opts] => "%s"\n##\n\n' \
        "$(
            fold --spaces --width=$(($(tput cols) - 20)) <<< "--log-file \"${LG_CALL_PATH}\" ${RS_CALL_OPTS[*]} \"${RS_PATH_SRCS}\" \"${RS_PATH_DEST}\"" \
                | sed -e '2,$s/^/##                "/' -e '$!s/[ ]*$/''"/g'
        )"

    printf -- '?? Continue using the above enumerated configuration values? [y/N]: '

    if [[ -n ${RSYNC_NON_INTERACTIVE} ]] && [[ ${RSYNC_NON_INTERACTIVE} -ge 1 ]]; then
        printf -- '(automatically continuing in non-interactive mode)\n'
    elif ! read -s -q; then
        printf -- '(continuing)\n'
    fi

    printf -- '\n-- Performing backup in %d seconds ...' \
        "${SLEEP_SECOND}"

    for z in {1..${SLEEP_SECOND}}; do
        printf '.'
        sleep 1
    done

    printf '\n\n'

    sudo \
        ionice \
            -c "${IONICE_CLASS}" \
            -n "${IONICE_GROUP}" \
            2> /dev/null \
        rsync \
            --log-file "${LG_CALL_PATH}" \
            "${RS_CALL_OPTS[@]}" \
            "${RS_PATH_SRCS}" \
            "${RS_PATH_DEST}"

    printf -- '\n## Completed operation(s) %d of %d ...\n' \
        "${j}" \
        "$((${#BACKUP_PATHS[@]} / 2))"

    j=$((j + 1))
done
