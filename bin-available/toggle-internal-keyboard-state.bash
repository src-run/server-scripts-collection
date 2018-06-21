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
# output new line
#
function write_newline {
    printf '\n'
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
# output (write) line of text using printf notation
#
function write_line {
    local format="${1}"
    shift

    write_text "${format}" "${@}"
    write_newline
}

#
# output error message to stderr
#
function write_error {
    local header="${1}"
    shift
    local format="${1}"
    shift
    local error

    error="$(printf "${format}" "${@}")"

    out_custom " ERROR: ${header} " \
        'fg:red bg:black style:bold style:reverse' >&2
    out_custom " ${error}" \
        'fg:red style:bold' >&2
    write_newline
}

#
# output error message to stderr
#
function write_critical {
    write_error "${@}"

    do_exit 255
}

function write_usage_header {
    local header="${1}"

    out_custom "${header^^}" 'style:bold' && \
        write_newline
}

function write_usage_action {
    local action_name="${1}"
    local action_long="${2}"
    local action_desc="${3}"

    write_text "  ${action_name:0:1}  $(printf '%-16s' "${action_long}")"
    out_custom "${action_desc}" 'style:dim'
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

    write_text "  -${arg_name:0:1} --$(printf '%-14s' "${arg_long_typed}")"

    for line in "${@}"; do
        if [[ ${num_desc} -gt 1 ]]; then
            printf '                     '
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

#
# output script usage information
#
function write_usage {
    write_newline

    write_usage_header 'Description'
    write_usage_desc \
        'This script toggles the attached/detached state of the internal' \
        'keyboard registered to the x environment. This effectively allows '\
        'you to turn a laptop keyboard on and off, which can be useful '\
        'when using an external keyboard.'

    write_newline
    write_usage_header 'Usage'
    write_line '  ./%s ARGUMENTS [ACTION]' "$(get_script_name)"

    write_newline
    write_usage_header 'Actions'
    write_usage_action 's' 'status' \
        'Display the active (current) state of the internal keyboard.'
    write_usage_action 'a' 'attach' \
        'Enable (attach) the internal keyboard to the x environment.'
    write_usage_action 'd' 'detach' \
        'Disable (detach) the internal keyboard from the x environment.'
    write_usage_action 'l' 'list' \
        'Output a list of all xinput devices with their respective IDs.'

    write_newline
    write_usage_header 'Arguments'
    write_usage_arg 's' 'slave-id' 'id' \
        'Specify the xinput slave keyboard device ID. The auto-detected ID'\
        "of \"$(get_xinput_keyboard_slave_id)\" will be used otherwise."
    write_usage_arg 'm' 'master-id' 'id' \
        'Specify the xinput master keyboard device ID. The auto-detected ID'\
        "of \"$(get_xinput_keyboard_master_id)\" will be used otherwise."
    write_usage_arg 't' 'test' '!time' \
        'Perform the requested changes in test mode where: they are applied,'\
        'we wait for the specified time, and then changes are rolled back.'
    write_usage_arg 'h' 'help' 'null' \
        'Display the help information for this script (what you are reading).'
    write_usage_arg 'v' 'version' 'null' \
        'Display the version information for this script.'
    write_newline
}

#
# resolve the xinput device if of the requested device name
#
function get_xinput_device_id {
    local name="${1}"

    xinput list 2> /dev/null | \
        grep "${name}" 2> /dev/null | \
        cut -f2 2> /dev/null | \
        cut -d'=' -f2 2> /dev/null
}

#
# resolve the xinput device id of the keyboard
#
function get_xinput_keyboard_slave_id {
    get_xinput_device_id 'AT Translated Set'
}

#
# resolve the xinput device id of the keyboard
#
function get_xinput_keyboard_master_id {
    get_xinput_device_id 'Virtual core keyboard'
}

#
# do attach action
#
function do_action_attach {
    local device_id_slave="${1}"
    local device_id_master="${2}"

    if [[ -z "${device_id_slave}" ]] || [[ -z "${device_id_master}" ]]; then
        write_critical 'Unresolved device' \
            'Failed to automatically resolve the device ID'
    fi

    xinput reattach ${device_id_slave} ${device_id_master}

    if [[ $? -ne 0 ]]; then
        write_critical 'Attach failure' \
            'Failed to attach slave device to master!'
    fi

    write_line 'Device "%s" has been attached to "%s".' \
        "${device_id_slave}" \
        "${device_id_master}"

}

#
# do attach detach
#
function do_action_detach {
    local device_id_slave="${1}"
    local device_id_master="${2}"

    if [[ -z "${device_id_slave}" ]] || [[ -z "${device_id_master}" ]]; then
        write_critical 'Unresolved device' \
            'Failed to automatically resolve the device ID'
    fi

    xinput float ${device_id_slave}

    if [[ $? -ne 0 ]]; then
        write_critical 'Detach failure' \
            'Failed to detach slave device!'
    fi

    write_line 'Device "%s" has been detached from "%s".' \
        "${device_id_slave}" \
        "${device_id_master}"
}

#
# do attach action
#
function do_action_status {
    local device_id_slave="${1}"
    local device_id_master="${2}"

    xinput | grep -E 'AT Translated Set.+floating slave' &> /dev/null

    if [[ $? -ne 0 ]]; then
        write_line 'Device "%s" is ATTACHED to "%s".' \
            "${device_id_slave}" \
            "${device_id_master}"
    else
        write_line 'Device "%s" is DETACHED.' \
            "${device_id_slave}"
    fi
}

#
# do attach action
#
function do_action_list {
    xinput | \
        grep -o -P '[A-Za-z][a-zA-Z0-9:\./ -]+\s+id=[0-9]+.+' | \
        sed -r -n -e 's/\[(slave|master)[ ]*([a-z]*)[ ]*\(([0-9]*)\)\]/master-id="\3"/p' | \
        sed -r -n -e 's/id=([0-9]+)/slave-id="\1"/p' | \
        sed -r -n -e 's/^([A-Za-z][a-zA-Z0-9:\./ -]+)/name="\1"/p' | \
        column
}

#
# main function
#
function main {
    local rollback=0
    local rollback_time=60
    local keyboard_slave_id
    local keyboard_master_id
    local action

    while [[ $# -gt 0 ]] && [[ ."-${1}" = .--* ]]; do
        opt="${1}"
        shift

        case "${opt}" in
            "--" )
                break 2
            ;;
            -s=* | --slave-id=* )
                keyboard_slave_id="${opt#*=}"
            ;;
            -m=* | --master-id=* )
                keyboard_master_id="${opt#*=}"
            ;;
            -t | --test )
                rollback=1
            ;;
            -t=* | --test=* )
                rollback=1
                rollback_wait="${opt#*=}"
            ;;
            -v | --version )
                printf '%s version 1.0.0\n' "$(get_script_name)"
                exit
            ;;
            -h | --help )
                write_usage
                exit
            ;;
            * )
                write_error 'Invalid option name' \
                    'An invalid argument option name was provided: "%s".' \
                    "${opt}"
                write_usage
                do_exit
            ;;
        esac

        if [[ ${s} -eq 1 ]]; then
            shift
        fi
    done

    if [[ -z "${keyboard_slave_id}" ]]; then
        keyboard_slave_id="$(get_xinput_keyboard_slave_id)"
    fi

    if [[ -z "${keyboard_master_id}" ]]; then
        keyboard_master_id="$(get_xinput_keyboard_master_id)"
    fi

    while [[ $# -gt 0 ]]; do
        if [[ ! -z "${action}" ]]; then
            write_critical 'Too many actions' \
                'Only one action can be specified (use "%s" or "%s").' \
                "${action}" \
                "${1,,}"
        fi
        action="${1,,}"
        shift
    done

    if [[ -z "${action}" ]]; then
        write_error 'Unspecified action' \
            'An action must be specified via the command arguments!'
        write_usage
        do_exit 255
    fi

    if [[ ${rollback} -eq 1 ]]; then
        write_critical 'Unimplemented' \
            'The testing/rollback functionality has not yet been implemented!'
    fi

    case "${action}" in
        a|attach )
            do_action_attach "${keyboard_slave_id}" "${keyboard_master_id}"
        ;;
        d|detach )
            do_action_detach "${keyboard_slave_id}" "${keyboard_master_id}"
        ;;
        s|status )
            do_action_status "${keyboard_slave_id}" "${keyboard_master_id}"
        ;;
        l|list )
            do_action_list
        ;;
        * )
            write_critical 'Invalid action' \
                'An unknown action was specified "%s"!' \
                "${action}"
        ;;
    esac
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
