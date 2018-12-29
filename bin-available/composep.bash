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
# write text (arguments use printf syntax)
#
function write_text {
    printf -- "${@}"
}

#
# generate precise time-stamp (as UNIX time with nanoseconds)
#
function get_unix_time {
    write_text '%s' "$(date +%s\.%N)"
}

#
# define initialization time (as UNIX time-stamp)
#
COMPOSEP_TIME_INIT=$(get_unix_time)

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
# define default auto-PHP-version selection file
#
COMPOSEP_AUTO_FILE='.php-auto-version'

#
# verbosity level of this wrapper script (-1=quiet, 0=normal, 1=verbose)
#
COMPOSEP_VERBOSITY_SELF=0

#
# verbosity level of external composer executable (-1=quiet, 0=normal,
# 1=verbose, 2=profile)
#
COMPOSEP_VERBOSITY_EXEC=0

#
# generate precise time-stamp (as UNIX time with nanoseconds)
#
function write_unix_time {
    write_text '%.03f' "${1:-$(get_unix_time)}"
}

#
# resolve the script name
#
function write_self_name {
    write_text '%s' "$(basename "${BASH_SOURCE}")"
}

#
# write one newline or number of newlines specified as only argument
#
function write_nl {
    for i in $(seq 1 ${1:-1}); do write_text '\n'; done
}

#
# write text (arguments use similar printf syntax) with color and styling
#
function write_text_styled {
    out_custom \
        "$(
            write_text \
                "${1}" \
                "${@:3}"
        )" \
        "${2:-fg:white}"
}

#
# write line of text (arguments use printf syntax)
#
function write_line {
    write_text "${@}"
    write_nl
}

#
# write line of text text (arguments use similar printf syntax) with color and
# styling
#
function write_line_styled {
    write_text_styled "${@}"
    write_nl
}

#
# sanitize foreground color so it is readable against background color
#
function sanitize_fg_color {
    local fg=${1}
    local bg=${2}

    if [[ ${fg} == ${bg} ]]; then
        case "${fg}" in
            white ) fg=black ;;
            black ) fg=white ;;
            *     ) fg=white ;;
        esac
    fi

    case "${bg}" in
        yellow )
            case "${fg}" in
                white ) fg=black ;;
            esac
            ;;
    esac

    write_text "${fg}"
}

#
# write line prefix details
#
function write_line_pref {
    local type="${1:-info}"
    local char="${2:---}"
    local char_bg_color="${3:-green}"
    local type_bg_color="${4:-$char_bg_color}"
    local char_fg_color="${5:-white}"
    local type_fg_color="${6:-white}"
    local style_dark_l_1='fg:black style:bold style:dim'
    local style_dark_l_2='fg:white style:bold style:dim'

    char_fg_color=$(
        sanitize_fg_color ${char_fg_color} ${char_bg_color}
    )

    type_fg_color=$(
        sanitize_fg_color ${type_fg_color} ${type_bg_color}
    )

    write_text_styled \
        '(' \
        "${style_dark_l_1}"

    write_text_styled \
        "$(write_self_name)" \
        'fg:white'

    write_text_styled \
        ')' \
        "${style_dark_l_1}"

    write_text_styled \
        " $(write_unix_time) " \
        "${style_dark_l_1}"

    write_text_styled \
        " ${char} " \
        "fg:${char_bg_color} bg:${char_fg_color} style:bold style:reverse"

    write_text_styled \
        " ${type} " \
        "fg:${type_bg_color} bg:${type_fg_color} style:reverse style:dim"

    write_text_styled \
        ' --> ' \
        "${style_dark_l_2}"
}

#
# write script about information
#
function write_about {
    local is_verbose="${1:-false}"
    local style_head='fg:white bg:black style:reverse style:bold'
    local style_norm='fg:black bg:white style:reverse style:dim'
    local style_bold='fg:white bg:black style:bold'
    local write_vers="${COMPOSEP_VERS_MAJOR}.${COMPOSEP_VERS_MINOR}.${COMPOSEP_VERS_PATCH}"
    local write_auth="${COMPOSEP_AUTH_NAME}"
    local write_copy="${COMPOSEP_COPY_NAME}"
    local write_link="${COMPOSEP_INFO_LINK}"

    [[ -n "${COMPOSEP_VERS_EXTRA}" ]] && write_vers+="-${COMPOSEP_VERS_EXTRA}"

    if [[ ${is_verbose} == 'true' ]]; then
        write_vers+=' (semver.org)'
        write_auth+=" <${COMPOSEP_AUTH_MAIL}> (${COMPOSEP_AUTH_LINK})"
    fi

    write_nl

    write_text_styled \
        " ${COMPOSEP_INFO_NAME^^} " \
        "${style_head}"

    write_text_styled \
        ' version' \
        "${style_norm}"

    write_text_styled \
        " ${write_vers}" \
        "${style_bold}"

    write_text_styled \
        ' by' \
        "${style_norm}"

    write_text_styled \
        " ${write_auth}" \
        "${style_bold}"

    write_text_styled \
        ' under' \
        "${style_norm}"

    write_text_styled \
        " ${write_copy}" \
        "${style_bold}"

    write_text_styled \
        ' license' \
        "${style_norm}"

    if [[ ${is_verbose} == 'true' ]]; then
        write_text_styled \
            " (${COMPOSEP_COPY_LINK})" \
            "${style_bold}"

        write_text_styled \
            ' with hosting on' \
            "${style_norm}"

        write_text_styled \
            " ${write_link}" \
            "${style_bold}"
    fi

    write_nl 2
}

#
# write line header
#
function write_line_head {
    local head="${1}"
    local text="${2}"
    local type="${3:-info}"
    local char="${4:---}"
    local color_pref="${5:-green}"
    local color_head="${6:-green}"
    local color_text="${7:-white}"

    write_line_pref \
        "${type}" \
        "${char}" \
        "${color_pref}"

    write_text_styled \
        "[${head}]" \
        "fg:${color_head}"

    write_line_styled \
        " ${text}" \
        "fg:${color_text}"
}

#
# compile output text from format with printf arguments and support for optional
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
        text="$(write_text "${form}" "${text_args[@]}")"
    else
        text="${form}"
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
        text+=" ..."
    fi

    write_text "${text}"
}

#
# write informational message to STDOUT
#
function write_info {
    if [[ ${COMPOSEP_VERBOSITY_SELF} -gt -1 ]]; then
        write_line_head \
            "${1}" \
            "$(compile_output_text "${2}" "${@:3}")" \
            'info' \
            '--' \
            'blue' \
            'cyan' \
            'white style:dim'
    fi
}

#
# write note-type message to STDOUT
#
function write_note {
    if [[ ${COMPOSEP_VERBOSITY_SELF} -gt 0 ]]; then
        write_line_head \
            "${1}" \
            "$(compile_output_text "${2}" "${@:3}")" \
            'note' \
            '--' \
            'green' \
            'green' \
            'white style:dim'
    fi
}

#
# write warning message to STDERR
#
function write_warn {
    if [[ ${COMPOSEP_VERBOSITY_SELF} -gt 0 ]]; then
        >&2 write_line_head \
            "${1}" \
            "$(compile_output_text "${2}" "${@:3}")" \
            'warn' \
            '##' \
            'yellow' \
            'yellow'
    fi
}

#
# write failure message to STDERR
#
function write_fail {
    if [[ ${COMPOSEP_VERBOSITY_SELF} -gt -1 ]]; then
        >&2 write_line_head \
            "${1}" \
            "$(compile_output_text "${2}" "${@:3}")" \
            'fail' \
            '!!' \
            'red' \
            'red style:bold' \
            'red'
    fi
}

#
# write critical failure message to STDERR and exit script
#
function write_crit {
    if [[ ${COMPOSEP_VERBOSITY_SELF} -gt -1 ]]; then
        >&2 write_line_head \
            "${1}" \
            "$(compile_output_text "${2}" "${@:3}")" \
            'crit' \
            '!!' \
            'red' \
            'red style:bold' \
            'white style:bold'
    fi

    if [[ ${COMPOSEP_VERBOSITY_SELF} -gt 0 ]]; then
        >&2 write_line_head \
            'terminating command' \
            "$(compile_output_text 'halting script execution (with 255 exit code) due to the previous critical failure')" \
            'exit' \
            'XX' \
            'yellow' \
            'yellow'
    fi

    exit $(get_exit_code_in_arguments "${@:3}")
}

#
# locate exit code in arguments or return default code
#
function get_exit_code_in_arguments {
    local code

    for c in "${@}"; do [[ ${c:0:6} == 'code=' ]] && code=${c:6}; done

    write_text "${code:-255}"
}

#
# locate php executable path by ident version number
#
function locate_php_by_version_ident {
    local name="${1}"
    local path

    if path="$(which "php${name}")"; then
        write_text '%s' "${path}"
        return 0
    fi

    return 1
}

#
# locate php executable path by major version number
#
function locate_php_by_version_major {
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

#
# list available php version idents with their executable paths
#
function list_php_version_idents {
    local path

    for v in $(ls -1 /usr/{bin,local/bin}/php* 2> /dev/null | grep -oE '[0-9]+\.[0-9]+$' 2> /dev/null | sort --version-sort 2> /dev/null | uniq 2> /dev/null); do
        if path="$(locate_php_by_version_ident "${v}")"; then
            write_line '%s:%s' "${v}" "${path}"
        fi
    done
}

#
# list available php version majors with their executable paths
#
function list_php_version_majors {
    local vers=()
    local path
    local name

    vers+=($(
       list_php_version_idents \
            | grep -o -E '^[0-9]' 2> /dev/null \
            | sort --version-sort 2> /dev/null \
            | uniq 2> /dev/null
    ))

    for v in "${vers[@]}"; do
        if name="$(locate_php_by_version_major "${v}")"; then
            if path="$(locate_php_by_version_ident "${name}")"; then
                write_line '%s/%s:%s' "${v}" "${name}" "${path}"
            fi
        fi
    done
}

#
# write help usage header (with optional note/details)
#
function write_usage_header {
    local head="${1^^}"
    local note="${2:-}"

    write_text_styled \
        "${head}" \
        'style:bold'

    if [[ -n ${note} ]]; then
        write_text_styled \
            " (${note,,})" \
            'style:dim'
    fi

    write_nl
}

#
# write usage info version details
#
function write_usage_version {
    write_text_styled \
        "${1}" \
        'style:dim'
}

#
# write usage info ident version details
#
function write_usage_version_ident {
    local ver_string="${1}"
    local ver_id="${ver_string%%:*}"

    write_text '  %-2s | %-3s | %-10s' \
        $(version_ident_sm "${ver_id}") \
        ${ver_id} \
        "$(version_ident_lg "${ver_id}")"

    write_usage_version "$(
        write_package_version_for_ident \
            "${ver_string#*:}"
    )"

    write_nl
}

#
# write usage info alias version details
#
function write_usage_version_alias {
    local ver_input="${1}"
    local ver_parts="${ver_input%%:*}"
    local ver_alias="${ver_parts%%/*}"
    local ver_ident="${ver_parts#*/}"

    write_text "$(
        write_text \
            '  %-1s ' \
            "$(version_ident_sm "${ver_alias}")"
    )"

    write_text_styled \
        '---------->' \
        'fg:black style:dim style:bold'

    write_text "$(
        write_text \
            ' %-7s' \
            "${ver_ident}"
    )"

    write_usage_version "$(
        write_package_version_for_alias \
            "${ver_input#*:}"
    )"

    write_nl
}

function text_remove_padding {
    if [[ -n ${1} ]]; then
        sed -E 's/^[ ]+//g' 2> /dev/null <<< "${1}" | sed -E 's/[ ]+$//g' 2> /dev/null
    fi
}

function text_remove_padding_stdin {
    text_remove_padding "${1:-$(</dev/stdin)}"
}

#
# write wrapped and left padded lines of text
#
function write_wrapped_lines {
    local text
    local pad_size="${2:-2}"
    local pad_text=''
    local cut_size="${1:-$(tput cols)}"
    local cut_diff=$((${cut_size} - ${pad_size}))
    local line_top
    local line_rem

    for l in "${@:3}"; do text+=" ${l}"; done
    for i in $(seq 1 ${pad_size}); do pad_text+=' '; done

    if [[ ${cut_size} -gt 120 ]]; then
        cut_size=120
        cut_diff=$((${cut_size} - ${pad_size}))
    fi

    text="$(text_remove_padding "${text}")"
    line_top="$(fold -s -w${cut_diff} <<< "${text}" 2> /dev/null | head -n1 2> /dev/null | text_remove_padding_stdin)"
    line_rem="$(text_remove_padding "${text:$((${#line_top} + 1))}")"

    write_line "${line_top}"

    if [[ ${line_rem} != "" ]]; then
        write_line "$(fold -s -w$((${cut_size} - ${pad_size})) <<< "${line_rem}" 2> /dev/null | sed "s_^_${pad_text}_" 2> /dev/null)"
    fi

    return
    write_line "{{REM[%s]}}" "${line_rem}"
    return
}

#
# write usage info argument details
#
function write_usage_argument {
    local arg_more=${1}
    shift
    local arg_name="${1}"
    shift
    local arg_long="${1}"
    shift
    local arg_type="${1}"
    local arg_null=0
    shift
    local arg_text="${arg_long}"
    local arg_defs
    local arg_desc

    if [[ "${arg_type:0:1}" == "!" ]]; then
        arg_null=1
        arg_type="${arg_type:1}"
    fi

    if [[ ! -z "${arg_type}" ]] && [[ "${arg_type}" != "null" ]]; then
        if [[ ${arg_null} -eq 1 ]]; then
            arg_text="${arg_long}[=${arg_type^^}]"
        else
            arg_text="${arg_long}=${arg_type^^}"
        fi
    fi

    if [[ ${arg_name} == null ]]; then
        write_text \
            "     --%-16s" \
            "${arg_text}"
    else
        write_text \
            "  -%-1s --%-16s" \
            "${arg_name:0:1}" \
            "${arg_text}"
    fi

    for line in "${@}"; do
        if [[ ${line:0:8} == 'default=' ]]; then
            arg_defs="${line:8}"
        else
            arg_desc+=" ${line}"
        fi
    done

    write_line_styled "$(write_wrapped_lines '' 23 "${arg_desc}")" 'style:dim'

    if [[ ${arg_more} == 'true' ]] && [[ -n ${arg_defs} ]]; then
        write_text '                       '
        write_line_styled "$(
            write_wrapped_lines '' 23 "$(
                write_text \
                    '(default: "%s" [%s])' \
                    "${arg_defs#*|}" \
                    "${arg_defs%%|*}"
            )"
        )" 'fg:black style:bold style:dim'
    fi
}

#
# write usage info script description text
#
function write_usage_desc {
    write_line_styled "  $(write_wrapped_lines '' 2 "${@}")" 'style:dim'
    return
    for line in "${@}"; do
        write_line_styled "  ${line}" 'style:dim'
    done
}

#
# version string to ident (small/short text version)
#
function version_ident_sm {
    local v="${1}"

    write_text "$(sed -E 's/[^0-9]//g' <<< "${v}")"
}

#
# version string to ident (large/long text version)
#
function version_ident_lg {
    local v="${1}"

    write_text "php${v}"
}

#
# system package version information
#
function package_version_desc {
    local which="${1}"
    local v
    local b

    if [[ ! -e "${which}" ]]; then
        return 1
    fi

    v="$(
        "${which}" --version 2> /dev/null \
            | head -n 1 2> /dev/null \
            | sed -E 's/^(PHP )([^ ]+)(.+)$/\2/' 2> /dev/null
    )"

    b="$(
        "${which}" --version 2> /dev/null \
            | head -n 1 2> /dev/null \
            | grep -oE 'built: [^)]+' 2> /dev/null \
            | sed -E 's/built: //g' 2> /dev/null
    )"

    write_text 'pkg: %s' \
        "${v}"
}

#
# get installed debian package version info
#
function write_package_version {
    local where="${1^}"
    local which="${2}"
    local about

    write_text '%s "%s"' \
        "${where}" \
        "${which}"

    if about="$(package_version_desc "${which}")"; then
        write_text_styled \
            ' (%s)' \
            'fg:black style:dim style:bold' \
            "${about}"
    fi
}

#
# get installed debian package version for passed version ident
#
function write_package_version_for_ident {
    write_package_version 'located at' "${1}"
}

#
# get installed debian package version for passed version alias
#
function write_package_version_for_alias {
    write_package_version 'aliased to' "${1}"
}

#
# write script usage information
#
function write_usage {
    local more="${1:-false}"
    local desc=

    desc+='This script acts as a simple wrapper to the normal Composer executable and enabled easily'
    desc+=' managing systems with multiple versions of PHP installed on system globally side-by-side.'

    if [[ ${more} == 'true' ]]; then
        desc+=' After the first and only argument of the PHP version to use, all additional arguments are'
        desc+=' passed directly to the Compoaser executable. The desired PHP version will also be detected'
        desc+=' by reading in an auto-php-version definition file.'
    fi

    write_about ${more}

    write_usage_header 'Description'
    write_usage_desc "${desc}"

    write_nl

    write_usage_header 'Usage'
    write_line '  ./%s [PHP_VERSION] [RUNTIME_ARGUMENTS] -- [COMPOSER_ARGUMENTS]' "$(write_self_name)"

    write_nl

    write_usage_header 'Versions'
    for v in $(list_php_version_idents); do write_usage_version_ident "${v}"; done
    if [[ ${more} == 'true' ]]; then
        for v in $(list_php_version_majors); do write_usage_version_alias "${v}"; done
    fi

    write_nl

    write_usage_header 'Arguments'
    write_usage_argument ${more} 'a' 'auto-file' 'file' \
        'Assigns the php-auto-version selection file location, a file'\
        'containing a php version string that is used to select the php'\
        'runtime version used when calling composer.'\
        "default=string|${COMPOSEP_AUTO_FILE}"
    write_usage_argument ${more} 'N' 'no-auto-file' 'null' \
        'Disables the php-auto-version file search, causing the default'\
        'auto file, as well as a custom auto file set with "--auto-file",'\
        'to be ignored.'\
        'default=bool|false'
    write_usage_argument ${more} 'c' 'composer' 'FILE' \
        'Assigns the composer executable path used when calling composer.'\
        "default=string|$(write_usage_argument_composer_default)"
    write_usage_argument ${more} 'W' 'verbose-wrapper' 'null' \
        'Enables verbose output of the wrapper script only.'\
        'default=bool|false'
    if [[ ${more} == 'true' ]]; then
        write_usage_argument ${more} 'C' 'verbose-compose' 'null' \
            'Enables all output of "-W", plus verbose output of the external'\
            'composer executable.'\
            'default=bool|false'
    fi
    write_usage_argument ${more} 'P' 'verbose-profile' 'null' \
        'Enables all output of "-W" and "-C", plus profiling output of the'\
        'external composer executable.'\
        'default=bool|false'
    write_usage_argument ${more} 'q' 'quiet-wrapper' 'null' \
        'Disables all output of the wrapper script. The status return code'\
        'can be used to determine the final result.'\
        'default=bool|false'
    if [[ ${more} == 'true' ]]; then
        write_usage_argument ${more} 'Q' 'quiet-compose' 'null' \
            'Disables all output of the wrapper script and the external compose'\
            'executable. The status return code can be used to determine the'\
            'final result.'\
            'default=bool|false'
    fi
    write_usage_argument ${more} 'h' 'help' 'null' \
        'Display the basic help information, including a description,'\
        'general usage, available php versions, and available command'\
        'line arguments.'\
        'default=bool|false'
    write_usage_argument ${more} 'H' 'help-extras' 'null' \
        'Display the verbose help information, including all output of'\
        'the "--help" flag, plus all the default values for command line'\
        'arguments and php versions.'\
        'default=bool|false'
    write_usage_argument ${more} 'v' 'version' 'null' \
        'Display the basic version information of this script, including'\
        'the full version string, author name, and license name.'\
        'default=bool|false'
    if [[ ${more} == 'true' ]]; then
        write_usage_argument ${more} 'V' 'version-verbose' 'null' \
            'Display the verbose version information of this script, which'\
            'includes all output from "-v" plus the author email and link,'\
            'the license link, and the hosting link.'\
            'default=bool|false'
    fi
    write_nl
}

#
# locate the composer executable path within your PATH environment
#
function locate_composer {
    local path

    if ! path="$(which composer 2> /dev/null)"; then
        return 1
    fi

    write_text "${path}"
}

#
# locate the composer executable path within your PATH environment or display
# a simple text error (for use in user-displayed results)
#
function write_usage_argument_composer_default {
    local path


    if ! path="$(locate_composer)"; then
        write_text '(failed to locate locally installed composer path)'
    else
        write_text "${path}"
    fi
}

#
# sanitize php version input from user
#
function sanitize_php_version {
    local input="${1}"
    local ident

    if [[ ${#input} -eq 1 ]]; then
        if ! ident="$(locate_php_by_version_major ${input})"; then
            return 1
        fi
    fi

    for p in $(list_php_version_idents); do
        if [[ ${input} == "${p%%:*}" ]] || [[ ${input} == $(version_ident_sm "${p%%:*}") ]] || [[ ${input} == $(version_ident_lg "${p%%:*}") ]]; then
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
# shorten file name (when appropriate) for display
#
function file_name_shorten {
    local file="${1}"
    local work="${PWD}"

    if [[ ${file:0:${#work}} == ${work} ]]; then
        file=".${file:$((${#work}))}"
    fi

    write_text "${file}"
}

#
# main function
#
function main {
    local php_bin_path
    local php_ver_name
    local php_ver_file_relative="${COMPOSEP_AUTO_FILE}"
    local php_ver_file_disabled=0
    local php_ver_file_contents
    local composer_opt=''
    local composer_bin
    local self_verbose=0
    local comp_verbose=0

    while [[ $# -gt 0 ]]; do
        opt="${1}"
        shift

        case "${opt}" in
            -- )
                composer_opt="${@}"
                break 2
            ;;
            -a=* | --auto-file=* )
                php_ver_file_relative="${opt#*=}"
                write_note \
                    'argument parsing' \
                    'assigned auto-php-version detection file to provided value' \
                    "\${${php_ver_file_relative}}"
            ;;
            -N | --no-auto-file )
                php_ver_file_disabled=1
                write_note \
                    'toggling feature' \
                    'disabled auto-php-version detection file search' \
                    "\${${COMPOSEP_AUTO_FILE}}"
            ;;
            -c=* | --composer=* )
                if [[ ! -r ${opt#*=} ]] || [[ ! -e ${opt#*=} ]]; then
                    write_warn \
                        'argument parsing' \
                        'failed to assign composer path (non-existent, non-readable, or non-executable file path provided)' \
                        "\${${opt#*=}}"
                else
                    composer_bin="${opt#*=}"
                    write_note \
                        'argument parsing' \
                        'assigned composer path to provided value' \
                        "\${${composer_bin}}"
                fi
            ;;
            -W | --verbose-wrapper )
                COMPOSEP_VERBOSITY_SELF=1
                COMPOSEP_VERBOSITY_EXEC=0
                write_note \
                    'toggling feature' \
                    'enabled verbose output of wrapper script only'
            ;;
            -C | --verbose-compose )
                COMPOSEP_VERBOSITY_SELF=1
                COMPOSEP_VERBOSITY_EXEC=1
                write_note \
                    'toggling feature' \
                    'enabled verbose output of wrapper script and verbose output of composer'
            ;;
            -P | --verbose-profile )
                COMPOSEP_VERBOSITY_SELF=1
                COMPOSEP_VERBOSITY_EXEC=2
                write_note \
                    'toggling feature' \
                    'enabled verbose output of wrapper script and verbose/profiler output of composer'
            ;;
            -q | --quiet-wrapper )
                COMPOSEP_VERBOSITY_SELF=-1
                COMPOSEP_VERBOSITY_EXEC=0
                write_note \
                    'toggling feature' \
                    'disabled all output of wrapper script only'
            ;;
            -Q | --quiet-compose )
                COMPOSEP_VERBOSITY_SELF=-1
                COMPOSEP_VERBOSITY_EXEC=-1
                write_note \
                    'toggling feature' \
                    'disabled all output of wrapper script and all output of composer'
            ;;
            -h | --help )
                write_usage false
                exit 0
            ;;
            -H | --help-extras )
                write_usage true
                exit 0
            ;;
            -v | --version )
                write_about false
                exit 0
            ;;
            -V | --version-verbose )
                write_about true
                exit 0
            ;;
            * )
                if php_ver_name="$(sanitize_php_version "${opt}")"; then
                    if [[ ${opt} == ${php_ver_name} ]]; then
                        write_info \
                            'version selection' \
                            'assigning the active php runtime version (using the passed explicit version or fuzzy alias argument)' \
                            "\${${php_ver_name}}"
                    else
                        write_info \
                            'version selection' \
                            'assigning the active PHP runtime version (using the passed explicit version or fuzzy alias argument)' \
                            "\${${opt} -> ${php_ver_name}}"
                    fi
                    continue
                else
                    write_crit \
                        'invalid argument' \
                        'encountered an unknown/unsupported command line argument'
                        "\${${opt}}" \
                        'code=200'
                fi
            ;;
        esac

        if [[ ${s} -eq 1 ]]; then
            shift
        fi
    done

    if [[ -z "${php_ver_name}" ]]; then
        for file in $(ls -1 {${PWD},${HOME}}/${php_ver_file_relative} 2> /dev/null | uniq 2> /dev/null); do
            if [[ -r "${file}" ]]; then
                if [[ $(cat "${file}" 2> /dev/null | grep -oE '^.+$' 2> /dev/null | wc -l 2> /dev/null) -eq 0 ]]; then
                    write_warn \
                        'invalid version file' \
                        'failed to parse the version string within your automatic version detection file (empty contents)' \
                        "\${${file}}"
                    continue
                fi

                if [[ $(cat "${file}" 2> /dev/null | grep -oE '^.+$' 2> /dev/null | wc -l 2> /dev/null) -ne 1 ]]; then
                    write_warn \
                        'invalid version file' \
                        'failed to parse the version string within your automatic version detection file (too many lines)' \
                        "\${${file}}"
                    continue
                fi

                if ! php_ver_file_contents="$(cat "${file}" | grep -oE '^[0-9]+(\.[0-9](\.[0-9])?)?$' 2> /dev/null)"; then
                    write_warn \
                        'invalid version file' \
                        'failed to parse the version string within your automatic version detection file (invalid contents)' \
                        "\${${file}}"
                    continue
                fi

                if php_ver_name="$(sanitize_php_version "${php_ver_file_contents}")"; then
                    if [[ ${php_ver_file_contents} == ${php_ver_name} ]]; then
                        write_info \
                            'version selection' \
                            "assigning the active PHP runtime version (using auto selection file \"$(file_name_shorten "${file}")\" for version or alias)" \
                            "\${${php_ver_name}}"
                    else
                        write_info \
                            'version selection' \
                            "assigning the active PHP runtime version (using auto selection file \"$(file_name_shorten "${file}")\" for version or alias)" \
                            "\${${php_ver_file_contents} -> ${php_ver_name}}"
                    fi
                    break
                else
                    write_warn \
                        'invalid version file' \
                        'failed to parse the version string within your automatic version detection file (invalid version)' \
                        "\${${file}}"
                fi
            fi
        done
    fi

    if [[ -z "${php_ver_name}" ]]; then
        php_ver_name="$(
            list_php_version_idents \
                | tail -n 1 2> /dev/null \
                | grep -oE '^[0-9]\.[0-9]' 2> /dev/null
        )"
        write_info \
            'version selection' \
            'assigning the active PHP runtime version to the latest installed version (no explicit version was passed as an argument)' \
            "\${${php_ver_name}}"
    fi

    if ! php_bin_path="$(locate_php_by_version_ident "${php_ver_name}")"; then
        write_crit \
            'version find path' \
            'failed to locate the absolute PHP executable path for the runtime version assigned' \
            "\${${php_ver_name}}" \
            'code=201'
    fi

    [[ ${COMPOSEP_VERBOSITY_EXEC} -eq -1 ]] && composer_opt+=' --quiet'
    [[ ${COMPOSEP_VERBOSITY_EXEC} -eq 1 ]]  && composer_opt+=' -vvv'
    [[ ${COMPOSEP_VERBOSITY_EXEC} -eq 2 ]]  && composer_opt+=' -vvv --profile'

    write_info \
        'wrapping external' \
        'running the external composer executable using the selected php runtime and build command argument(s)' \
        "\${$(sed -E 's/[ ]$//g' <<< "${php_bin_path} $(which composer) ${composer_opt}")}"

    if ! composer_bin="$(which composer)"; then
        write_crit \
            'wrapping external' \
            'failed to locate the absolute composer executable path!' \
            'code=202'
    fi

    "${php_bin_path}" "${composer_bin}" ${composer_opt}

    write_done_code $?
    write_done_time
}

#
# write completion time (in seconds with microsecond precision)
#
function write_done_time {
    local time

    time=$(grep -oE '^([0-9])?\.[0-9]{3}' <<< "$(bc <<< "$(get_unix_time) - ${COMPOSEP_TIME_INIT}")")

    [[ ${time:0:1} == '.' ]] && time="0${time}"

    write_info \
        'completion summary info' \
        "external command execution and wrapping operations total time from initialization to end" \
        "\${$(write_unix_time "${time}") seconds}"
}

#
# write completion status code (using UNIX return code assumptions)
#
function write_done_code {
    local code=${1}
    local head='external command result'
    local type='write_info'
    local text='running the external Composer executable exited with a zero return code (signaling a likely success)'

    if [[ ${code} -ne 0 ]]; then
        type='write_fail'
        text='running the external Composer executable exited with a non-zero return code (signaling a likely error)'
    fi

    ${type} "${head}" "${text}" "\${${code}}"


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
