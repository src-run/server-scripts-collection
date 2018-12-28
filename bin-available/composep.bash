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
# define general information (name)
#
COMPOSEP_INFO_NAME=composep

#
# define general information (name)
#
COMPOSEP_INFO_LINK='github.com/src-run/bash-server-scripts'

#
# define version string (major)
#
COMPOSEP_VERS_MAJOR=1

#
# define version string (minor)
#
COMPOSEP_VERS_MINOR=0

#
# define version string (patch)
#
COMPOSEP_VERS_PATCH=0

#
# define version string (extra)
#
COMPOSEP_VERS_EXTRA=rc1

#
# define author info (name)
#
COMPOSEP_AUTH_NAME='Rob Frawley 2nd'

#
# define author info (mail)
#
COMPOSEP_AUTH_MAIL='rmf@src.run'

#
# define author info (link)
#
COMPOSEP_AUTH_LINK='src.run'

#
# define license info (name)
#
COMPOSEP_COPY_NAME='MIT'

#
# define license info (link)
#
COMPOSEP_COPY_LINK='src-run.mit-license.org'

#
# resolve the script name
#
function get_script_name {
    basename "${BASH_SOURCE}"
}

#
# exit script with optional message
#
function do_exit {
    local exit_code="${1:-255}"
    local exit_desc="${2:-}"

    if [[ ! -z "${exit_desc}" ]]; then
        write_line "${exit_desc}"
    fi

    exit ${exit_code}
}

#
# output (write) text using printf notation
#
function write_text {
    local format="${1}"
    shift

    printf "${format}" "${@}"
}

#
# output new line
#
function write_newline {
    local count="${1:-1}"

    for i in $(seq 1 ${count}); do
        write_text '\n'
    done
}

#
# output (write) line of text using printf notation
#
function write_line {
    local format="${1}"
    shift

    write_text "${format}" "${@}"
    write_newline
}

#
# write line prefix details
#
function write_line_pref {
    local type="${1:-INFO}"
    local char="${2:---}"
    local char_color_bg="${3:-green}"
    local type_color_bg="${4:-$char_color_bg}"
    local char_color_fg="${5:-white}"
    local type_color_fg="${6:-white}"

    if [[ ${type_color_fg} == ${type_color_bg} ]]; then
        case "${type_color_fg}" in
            white)
                type_color_fg=black
                ;;
            black )
                type_color_fg=white
                ;;
            * )
                type_color_fg=white
                ;;
        esac
    fi

    if [[ ${char_color_fg} == ${char_color_bg} ]]; then
        case "${char_color_fg}" in
            white)
                char_color_fg=black
                ;;
            black )
                char_color_fg=white
                ;;
            * )
                char_color_fg=white
                ;;
        esac
    fi
    case "${type_color_bg}" in
        yellow )
            case "${type_color_fg}" in
                white)
                    type_color_fg=black
                    ;;
            esac
            ;;
    esac

    case "${char_color_bg}" in
        yellow )
            case "${char_color_fg}" in
                white)
                    char_color_fg=black
                    ;;
            esac
            ;;
    esac

    out_custom \
        '(' \
        'fg:black style:bold style:dim'
    out_custom \
        "$(get_script_name)" \
        'fg:white'
    out_custom \
        ')' \
        'fg:black style:bold style:dim'
    out_custom \
        " $(date +%s.%N | grep -oE '[0-9]{7}\.[0-9]{3}') " \
        'fg:black style:bold style:dim'

    out_custom \
        " ${char} " \
        "fg:${char_color_bg} bg:${char_color_fg} style:bold style:reverse"
    out_custom \
        " ${type} " \
        "fg:${type_color_bg} bg:${type_color_fg} style:bold style:reverse style:dim"

    out_custom \
        ' --> ' \
        'fg:white style:bold style:dim'
}

#
# output script about information
#
function write_about {
    local verbose="${1:-false}"
    local style_head='fg:white bg:black style:reverse style:bold'
    local style_norm='fg:black bg:white style:reverse style:dim'
    local style_bold='fg:white bg:black style:bold'
    local out_vers="${COMPOSEP_VERS_MAJOR}.${COMPOSEP_VERS_MINOR}.${COMPOSEP_VERS_PATCH}"
    local out_auth="${COMPOSEP_AUTH_NAME}"
    local out_copy="${COMPOSEP_COPY_NAME}"
    local out_link="${COMPOSEP_INFO_LINK}"

    [[ -n "${COMPOSEP_VERS_EXTRA}" ]] && out_vers+="-${COMPOSEP_VERS_EXTRA}"

    if [[ ${verbose} == 'true' ]]; then
        out_vers+=' (semver.org)'
        out_auth+=" <${COMPOSEP_AUTH_MAIL}> (${COMPOSEP_AUTH_LINK})"
    fi

    write_newline

    out_custom " ${COMPOSEP_INFO_NAME^^} " "${style_head}"
    out_custom ' version'                  "${style_norm}"
    out_custom " ${out_vers}"              "${style_bold}"
    out_custom ' by'                       "${style_norm}"
    out_custom " ${out_auth}"              "${style_bold}"
    out_custom ' under'                    "${style_norm}"
    out_custom " ${out_copy}"              "${style_bold}"
    out_custom ' license'                  "${style_norm}"

    if [[ ${verbose} == 'true' ]]; then
        out_custom " (${COMPOSEP_COPY_LINK})" "${style_bold}"
        out_custom ' with hosting on' "${style_norm}"
        out_custom " ${out_link}"     "${style_bold}"
    fi

    write_newline 2
}

#
# write line header
#
function write_line_head {
    local head="${1}"
    local text="${2}"
    local type="${3:-INFO}"
    local char="${4:---}"
    local color_pref="${5:-green}"
    local color_head="${6:-green}"
    local color_text="${7:-white}"

    write_line_pref "${type}" "${char}" "${color_pref}"
    out_custom "${head}:" "fg:${color_head}"
    out_custom " ${text}"   "fg:${color_text}"
    write_newline
}

#
# compile output text from format with sprintf arguments and support for optional
# enumerated variables
#
function compile_output_text {
    local form="${1}"
    shift
    local text
    local text_vars=()
    local text_args=()

    for a in "${@}"; do
        if [[ "${a:0:2}" == '${' ]] && [[ "${a:$((${#a} - 1)):1}" == '}' ]]; then
            text_vars+=("${a:2:$((${#a} - 3))}")
        else
            text_args+=("${a}")
        fi

        shift
    done

    if [[ ${#text_args[@]} -gt 0 ]]; then
        text="$(write_text "${form^}" "${text_args[@]}")"
    else
        text="${form^}"
    fi

    if [[ ${#text_vars[@]} -gt 0 ]]; then
        if [[ ${text:$((${#text} - 1)):1} =~ [\.] ]]; then
            text="${text:0:$((${#text} - 1))}"
        fi

        text+=": "

        for v in "${text_vars[@]}"; do
            text+="\"${v}\", "
        done

        text="${text:0:$((${#text} - 2))}"
    fi

    if [[ ${text:$((${#text} - 1)):1} =~ [^\.\?\!] ]]; then
        text+="."
    fi

    write_text "${text}"
}

#
# output informational message to STDOUT
#
function write_info {
    write_line_head \
        "${1^}" \
        "$(compile_output_text "${2}" "${@:3}")" \
        'INFO' \
        '--' \
        'magenta' \
        'white'
}

#
# output note-type message to STDOUT
#
function write_note {
    write_line_head \
        "${1^}" \
        "$(compile_output_text "${2}" "${@:3}")" \
        'INFO' \
        '--' \
        'green' \
        'green'
}

#
# output warning message to STDERR
#
function write_warn {
    >&2 write_line_head \
        "${1^}" \
        "$(compile_output_text "${2}" "${@:3}")" \
        'WARN' \
        '##' \
        'yellow' \
        'yellow'
}

#
# output failure message to STDERR
#
function write_fail {
    >&2 write_line_head \
        "${1^}" \
        "$(compile_output_text "${2}" "${@:3}")" \
        'FAIL' \
        '!!' \
        'red' \
        'red'
}

#
# output critical failure message to STDERR and exit script
#
function write_crit {
    >&2 write_line_head \
        "${1^}" \
        "$(compile_output_text "${2}" "${@:3}")" \
        'FAIL' \
        '!!' \
        'red' \
        'red'

    >&2 write_line_head \
        'Terminating script execution' \
        'The script will be immediately halted (with 255 exit status code) due to the previously described critical failure!' \
        'EXIT' \
        'XX' \
        'yellow' \
        'yellow'

    do_exit 255
}

#
# locate php executable path by version number
#
function php_ver_which {
    local name="${1}"
    local path

    if path="$(which "php${name}")"; then
        write_text '%s' "${path}"
        return 0
    fi

    return 1
}

#
# list available php versions and executable paths
#
function php_ver_list {
    local path

    for v in $(ls -1 /usr/{bin,local/bin}/php* 2> /dev/null | grep -oE '[0-9]+\.[0-9]+$' 2> /dev/null | sort --version-sort 2> /dev/null | uniq 2> /dev/null); do
        if path="$(php_ver_which "${v}")"; then
            write_line '%s:%s' "${v}" "${path}"
        fi
    done
}

#
# list available php major versions and executable paths
#
function php_ver_list_majors {
    local vers=()
    local path
    local name

    vers+=($(
       php_ver_list \
            | grep -o -E '^[0-9]' 2> /dev/null \
            | sort --version-sort 2> /dev/null \
            | uniq 2> /dev/null
    ))

    for v in "${vers[@]}"; do
        if name="$(php_ver_find_by_major "${v}")"; then
            if path="$(php_ver_which "${name}")"; then
                write_line '%s/%s:%s' "${v}" "${name}" "${path}"
            fi
        fi
    done
}

function php_ver_find_by_major {
    local major=${1}
    local found

    for v in $(ls -1 /usr/{bin,local/bin}/php* 2> /dev/null | grep -oE '[0-9]+\.[0-9]+$' 2> /dev/null | sort --version-sort 2> /dev/null | uniq 2> /dev/null); do
        if [[ ${v:0:1} == ${major} ]]; then
            found=${v}
        fi
    done

    if [[ -z ${found} ]]; then
        return 1
    else
        write_text "${found}"
    fi
}

function write_usage_header {
    local header="${1}"

    out_custom "${header^^}" 'style:bold' && \
        write_newline
}

function write_usage_action_ver {
    local ver_string="${1}"
    local ver_id="${ver_string%%:*}"

    write_text '  %-2s | %-3s | %-10s' \
        $(php_ver_id_short "${ver_id}") \
        ${ver_id} \
        "$(php_ver_id_long "${ver_id}")"

    out_custom \
        "$(php_ver_desc_long "${ver_string#*:}")" \
        'style:dim'

    write_newline
}

function write_usage_action_ver_major {
    local ver_string="${1}"
    local ver_string_n1="${ver_string%%:*}"
    local ver_alias="${ver_string_n1%%/*}"
    local ver_id="${ver_string_n1#*/}"

    write_text '  %-1s ----------> %-7s' \
        $(php_ver_id_short "${ver_alias}") \
        "${ver_id}"

    out_custom \
        "$(php_ver_alias_desc_long "${ver_alias}" "${ver_id}" "${ver_string#*:}")" \
        'style:dim'

    write_newline
}

function write_usage_arg {
    local arg_name="${1}"
    shift
    local arg_long="${1}"
    shift
    local arg_type="${1}"
    local arg_type_optional=0
    shift
    local num_desc=1
    local arg_long_typed="${arg_long}"

    if [[ "${arg_type:0:1}" == "!" ]]; then
        arg_type_optional=1
        arg_type="${arg_type:1}"
    fi

    if \
        [[ ! -z "${arg_type}" ]] && \
        [[ "${arg_type}" != "null" ]]; \
    then
        if [[ ${arg_type_optional} -eq 1 ]]; then
            arg_long_typed="${arg_long}[=${arg_type^^}]"
        else
            arg_long_typed="${arg_long}=${arg_type^^}"
        fi
    fi

    write_text "  -${arg_name:0:1} --$(printf '%-16s' "${arg_long_typed}")"

    for line in "${@}"; do
        if [[ ${num_desc} -gt 1 ]]; then
            printf '                       '
        fi

        out_custom "${line}" 'style:dim'
        write_newline
        num_desc=$((${num_desc} + 1))
    done
}

function write_usage_desc {
    for line in "${@}"; do
        out_custom "  ${line}" 'style:dim'
        write_newline
    done
}

function php_ver_id_short {
    local v="${1}"

    write_text "$(sed -E 's/[^0-9]//g' <<< "${v}")"
}

function php_ver_id_long {
    local v="${1}"

    write_text "php${v}"
}

function php_ver_desc_long {
    local p="${1}"

    write_text 'Located at "%s" (%s)' \
        "${p}" \
        "$(
            "${p}" --version 2> /dev/null \
                | head -n 1 2> /dev/null \
                | sed -E 's/^(PHP )([^ ]+)(.+)$/\2/' 2> /dev/null
        )"
}

function php_ver_alias_desc_long {
    local alias="${1}"
    local ident="${2}"
    local which="${3}"

    write_text 'Aliased to "%s" (%s)' \
        "${which}" \
        "$(
            "${which}" --version 2> /dev/null \
                | head -n 1 2> /dev/null \
                | sed -E 's/^(PHP )([^ ]+)(.+)$/\2/' 2> /dev/null
        )"
}

#
# output script usage information
#
function write_usage {
    write_about

    write_usage_header 'Description'
    write_usage_desc \
        'This script acts as a simple wrapper to the normal Composer executable and enabled easily' \
        'managing systems with multiple versions of PHP all installed globally side-by-side. After' \
        'the first and only argument of the PHP version to use, all additional arguments are passed' \
        'directly to the Compoaser executable. The desired PHP version will also be detected by' \
        'reading in a .php-v file containing the version string either in the current directory or' \
        'in the user home directory.'

    write_newline
    write_usage_header 'Usage'
    write_line '  ./%s [PHP_VERSION] [RUNTIME_ARGUMENTS] -- [COMPOSER_ARGUMENTS]' "$(get_script_name)"

    write_newline
    write_usage_header 'Versions'

    for v in $(php_ver_list); do
        write_usage_action_ver "${v}"
    done

    write_newline
    write_usage_header 'Aliases'

    for v in $(php_ver_list_majors); do
        write_usage_action_ver_major "${v}"
    done

    write_newline
    write_usage_header 'Arguments'
    write_usage_arg 'a' 'auto-ver' 'file' \
        'Specify a file path location containing the desired PHP version'\
        'identifier to use as the runtime for the Composer executable. By'\
        'default this file is searched for as ".php-v" first within the'\
        'current working directory followed by the user home directory.'
    write_usage_arg 'N' 'no-auto-ver' 'null' \
        'Disable the automatic search for a auto version file as ".php-v"'\
        'within the current working directory and the user home directory.'
    write_usage_arg 'h' 'help' 'null' \
        'Display the help information for this script (what you are reading).'
    write_usage_arg 'v' 'version' 'null' \
        'Display the version information for this script.'
    write_usage_arg 'V' 'version-extra' 'null' \
        'Display the verbose version information for this script.'
    write_newline
}

function check_php_version_input {
    local input="${1}"
    local ident

    if [[ ${#input} -eq 1 ]]; then
        if ! ident="$(php_ver_find_by_major ${input})"; then
            return 1
        fi
    fi

    for p in $(php_ver_list); do
        if [[ ${input} == "${p%%:*}" ]] || [[ ${input} == $(php_ver_id_short "${p%%:*}") ]] || [[ ${input} == $(php_ver_id_long "${p%%:*}") ]]; then
            ident="${p%%:*}"
            break
        fi
    done

    if [[ -z ${ident} ]]; then
        return 1
    fi

    write_text "${ident}"
}

#
# main function
#
function main {
    local code_ret_int
    local php_bin_path
    local php_ver_name
    local php_ver_file="{${PWD},${HOME}}/.php-v"
    local php_ver_file_disabled=0
    local php_ver_file_contents
    local composer_arguments
    local composer_bin

    while [[ $# -gt 0 ]]; do
        opt="${1}"
        shift

        case "${opt}" in
            -- )
                composer_arguments="${@}"
                break 2
            ;;
            -a=* | --auto-ver=* )
                php_ver_file="${opt#*=}"
                write_note \
                    'Parsing argument' \
                    'Assigning the automatic PHP version detection file path (overwriting default behavior) to provided value' \
                    "\${${php_ver_file}}"
            ;;
            -N | --no-auto-ver )
                php_ver_file_disabled=1
                write_note \
                    'Toggling feature' \
                    'Disabling the automatic PHP version detection file search for ".php-v" due to passed argument' \
                    '${--no-auto-ver}'
            ;;
            -v | --version )
                write_about false
                exit
            ;;
            -V | --version-extra )
                write_about true
                exit
            ;;
            -h | --help )
                write_usage
                exit
            ;;
            * )
                if php_ver_name="$(check_php_version_input "${opt}")"; then
                    write_note \
                        'Version selection' \
                        'Assigning the active PHP runtime version (using the passed explicit version or fuzzy alias argument)' \
                        "\${${opt} -> ${php_ver_name}}"
                    continue
                else
                    write_crit \
                        'Invalid argument' \
                        'An unsupported command line argument was provided' \
                        "\${${opt}}"
                fi
            ;;
        esac

        if [[ ${s} -eq 1 ]]; then
            shift
        fi
    done

    if [[ -z "${php_ver_name}" ]]; then
        for file in $(ls -1 {${PWD},${HOME}}/.php-v 2> /dev/null | uniq 2> /dev/null); do
            if [[ -r "${file}" ]]; then
                if [[ $(cat "${file}" 2> /dev/null | grep -oE '^.+$' 2> /dev/null | wc -l 2> /dev/null) -eq 0 ]]; then
                    write_warn \
                        'Invalid version file' \
                        'Failed to parse the version string within your automatic version detection file (empty contents)' \
                        "\${${file}}"
                    continue
                fi

                if [[ $(cat "${file}" 2> /dev/null | grep -oE '^.+$' 2> /dev/null | wc -l 2> /dev/null) -ne 1 ]]; then
                    write_warn \
                        'Invalid version file' \
                        'Failed to parse the version string within your automatic version detection file (too many lines)' \
                        "\${${file}}"
                    continue
                fi

                if ! php_ver_file_contents="$(cat "${file}" | grep -oE '^[0-9]+(\.[0-9](\.[0-9])?)?$' 2> /dev/null)"; then
                    write_warn \
                        'Invalid version file' \
                        'Failed to parse the version string within your automatic version detection file (invalid contents)' \
                        "\${${file}}"
                    continue
                fi

                if php_ver_name="$(check_php_version_input "${php_ver_file_contents}")"; then
                    write_note \
                        'Version selection' \
                        "Assigning the active PHP runtime version (using the version or alias in ${file})" \
                        "\${${php_ver_file_contents} -> ${php_ver_name}}"
                    break
                else
                    write_warn \
                        'Invalid version file' \
                        'Failed to parse the version string within your automatic version detection file (invalid version)' \
                        "\${${file}}"
                fi
            fi
        done
    fi

    if [[ -z "${php_ver_name}" ]]; then
        php_ver_name="$(
            php_ver_list \
                | tail -n 1 2> /dev/null \
                | grep -oE '^[0-9]\.[0-9]' 2> /dev/null
        )"
        write_note \
            'Version selection' \
            'Assigning the active PHP runtime version to the latest installed version (no explicit version was passed as an argument)' \
            "\${${php_ver_name}}"
    fi

    if ! php_bin_path="$(php_ver_which "${php_ver_name}")"; then
        write_crit \
            'Version find path' \
            'Failed to locate the absolute PHP executable path for the runtime version assigned' \
            "\${${php_ver_name}}"
    fi

    write_note \
        'Wrapping external' \
        'Executing the external Composer binary using the following command' \
        "\${$(sed -E 's/[ ]$//g' <<< "${php_bin_path} $(which composer) ${composer_arguments}")}"

    if ! composer_bin="$(which composer)"; then
        write_crit \
            'Wrapping external' \
            'Failed to locate the absolute Composer executable path!'
    fi

    "${php_bin_path}" "${composer_bin}" ${composer_arguments}

    code_ret_int=$?

    if [[ ${code_ret_int} -eq 0 ]]; then
        write_note \
            'Resulting external' \
            'The externally executed Composer binary exited with a zero return status code (signally a likely success)'
    else
        write_warn \
            'Resulting external' \
            'The externally executed Composer binary exited with a non-zero return status code (signally a likely error)' \
            "\${${code_ret_int}}"
    fi
}

#
# internal variables
#
readonly _SELF_PATH="$(dirname "$(readlink -m "${0}")")"

#
# configuration
#
if [[ -z "${BRIGHT_LIBRARY_PATH}" ]]; then
    BRIGHT_LIBRARY_PATH="${_SELF_PATH}/../lib/bright-library/bright.bash"
fi

#
# check for required bright library dependency
#
if [[ ! -f "${BRIGHT_LIBRARY_PATH}" ]]; then
    printf 'Failed to source required dependency: bright-library (%s)\n' \
        "${BRIGHT_LIBRARY_PATH}"
    exit 255
fi

#
# source bright library dependency
#
source "${BRIGHT_LIBRARY_PATH}"

#
# setup bright library configuration
#
BRIGHT_AUTO_NL=0

#
# go!
#
main "$@"
