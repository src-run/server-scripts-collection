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
    write_line '  ./%s ARGUMENTS [ACTION CONTEXT]' "$(get_script_name)"

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
    write_usage_header 'Contexts'
    write_usage_action 'k' 'keyboard' \
        'Display the active (current) state of the internal keyboard.'
    write_usage_action 't' 'touch-pad' \
        'Enable (attach) the internal touch pad to the x environment.'
    write_usage_action 'p' 'track-point' \
        'Disable (detach) the internal track point from the x environment.'

    write_newline
    write_usage_header 'Arguments'
    write_usage_arg 'k' 'keyboard-slave-id' 'id' \
        'Specify the xinput slave keyboard device ID. The auto-detected ID'\
        "of \"$(get_xinput_keyboard_slave_id)\" will be used otherwise."
    write_usage_arg 'K' 'keyboard-master-id' 'id' \
        'Specify the xinput master keyboard device ID. The auto-detected ID'\
        "of \"$(get_xinput_keyboard_master_id)\" will be used otherwise."
    write_usage_arg 't' 'touch-pad-slave-id' 'id' \
        'Specify the xinput slave touch pad device ID. The auto-detected ID'\
        "of \"$(get_xinput_touch_pad_slave_id)\" will be used otherwise."
    write_usage_arg 'T' 'touch-pad-master-id' 'id' \
        'Specify the xinput master touch pad device ID. The auto-detected ID'\
        "of \"$(get_xinput_track_touch_pad_master_id)\" will be used otherwise."
    write_usage_arg 'p' 'track-point-slave-id' 'id' \
        'Specify the xinput slave track point device ID. The auto-detected ID'\
        "of \"$(get_xinput_track_point_slave_id)\" will be used otherwise."
    write_usage_arg 'P' 'track-point-master-id' 'id' \
        'Specify the xinput master track point device ID. The auto-detected'\
        "ID of \"$(get_xinput_track_touch_pad_master_id)\" will be used otherwise."
    write_usage_arg 'x' 'test' '!time' \
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
function get_xinput_track_point_slave_id {
    get_xinput_device_id 'TPPS/2 IBM TrackPoint'
}

#
# resolve the xinput device id of the keyboard
#
function get_xinput_touch_pad_slave_id {
    get_xinput_device_id 'SynPS/2 Synaptics TouchPad'
}

#
# resolve the xinput device id of the keyboard
#
function get_xinput_track_touch_pad_master_id {
    get_xinput_device_id 'Virtual core pointer'
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
    local context="${1}"
    local device_id_slave="${2}"
    local device_id_master="${3}"

    if [[ -z "${device_id_slave}" ]] || [[ -z "${device_id_master}" ]]; then
        write_critical 'Unresolved device' \
            'Failed to automatically resolve the device ID'
    fi

    xinput reattach ${device_id_slave} ${device_id_master}

    if [[ $? -ne 0 ]]; then
        write_critical 'Attach failure' \
            "Failed to attach slave device (${context}) to master!"
    fi

    write_line 'Device "%s" (%s) has been attached to "%s".' \
        "${device_id_slave}" \
        "${context}" \
        "${device_id_master}"

}

#
# do attach detach
#
function do_action_detach {
    local context="${1}"
    local device_id_slave="${2}"
    local device_id_master="${3}"

    if [[ -z "${device_id_slave}" ]] || [[ -z "${device_id_master}" ]]; then
        write_critical 'Unresolved device' \
            'Failed to automatically resolve the device ID'
    fi

    xinput float ${device_id_slave}

    if [[ $? -ne 0 ]]; then
        write_critical 'Detach failure' \
            "Failed to detach slave device (${context}) from master!"
    fi

    write_line 'Device "%s" (%s) has been detached from "%s".' \
        "${device_id_slave}" \
        "${context}" \
        "${device_id_master}"
}

#
# do attach action
#
function do_action_status {
    local context="${1}"
    local device_id_slave="${2}"
    local device_id_master="${3}"
    local search

    case "${context}" in
        k|keyboard )
            search='AT Translated Set.+floating slave'
            ;;
        t|touch-pad )
            search='SynPS/2 Synaptics TouchPad.+floating slave'
            ;;
        p|track-point )
            search='TPPS/2 IBM TrackPoint.+floating slave'
            ;;
    esac

    xinput | grep -E "${search}" &> /dev/null

    if [[ $? -ne 0 ]]; then
        write_line 'Device "%s" (%s) is ATTACHED to "%s".' \
            "${device_id_slave}" \
            "${context}" \
            "${device_id_master}"
    else
        write_line 'Device "%s" (%s) is DETACHED.' \
            "${device_id_slave}" \
            "${context}"
    fi
}

#
# do attach action
#
function do_action_list {
    xinput | \
        grep -o -P '[A-Za-z][a-zA-Z0-9:\./ -]+\s+id=[0-9]+.+' | \
        sed -r -n -e 's/\[(slave|master)[ ]*([a-z]*)[ ]*\(([0-9]*)\)\]/master-id="\3"/p' | \
        sed -r -n -e 's/id=([0-9]+)/keyboard-slave-id="\1"/p' | \
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
    local touch_pad_slave_id
    local touch_pad_master_id
    local track_point_slave_id
    local track_point_master_id
    local action
    local contexts=()

    while [[ $# -gt 0 ]] && [[ ."-${1}" = .--* ]]; do
        opt="${1}"
        shift

        case "${opt}" in
            "--" )
                break 2
            ;;
            -k=* | --keyboard-slave-id=* )
                keyboard_slave_id="${opt#*=}"
            ;;
            -K=* | --keyboard-master-id=* )
                keyboard_master_id="${opt#*=}"
            ;;
            -t=* | --touch-pad-slave-id=* )
                touch_pad_slave_id="${opt#*=}"
            ;;
            -T=* | --touch-pad-master-id=* )
                touch_pad_master_id="${opt#*=}"
            ;;
            -p=* | --track-point-slave-id=* )
                track_point_slave_id="${opt#*=}"
            ;;
            -P=* | --track-point-master-id=* )
                track_point_master_id="${opt#*=}"
            ;;
            -x | --test )
                rollback=1
            ;;
            -x=* | --test=* )
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

    if [[ -z "${touch_pad_slave_id}" ]]; then
        touch_pad_slave_id="$(get_xinput_touch_pad_slave_id)"
    fi

    if [[ -z "${touch_pad_master_id}" ]]; then
        touch_pad_master_id="$(get_xinput_track_touch_pad_master_id)"
    fi

    if [[ -z "${track_point_slave_id}" ]]; then
        track_point_slave_id="$(get_xinput_track_point_slave_id)"
    fi

    if [[ -z "${track_point_master_id}" ]]; then
        track_point_master_id="$(get_xinput_track_touch_pad_master_id)"
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
        if [[ ! -z "${context}" ]]; then
            write_critical 'Too many contexts' \
                'Only one context can be specified (use "%s" or "%s").' \
                "${context}" \
                "${1,,}"
        fi
        context="${1,,}"
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

    local device_slave_id
    local device_master_id

    for c in ${context}; do
        case "${c}" in
            k|keyboard )
                c=keyboard
                device_slave_id=${keyboard_slave_id}
                device_master_id=${keyboard_master_id}
                ;;
            t|touch-pad )
                c=touch-pad
                device_slave_id=${touch_pad_slave_id}
                device_master_id=${touch_pad_master_id}
                ;;
            p|track-point )
                c=track-point
                device_slave_id=${track_point_slave_id}
                device_master_id=${track_point_master_id}
                ;;
            * )
                if [[ ${action} != l ]] && [[ ${action} != list ]]; then
                    write_critical 'Invalid context' \
                        'An unknown context was specified "%s"!' \
                        "${c}"
                fi
            ;;
        esac

        case "${action}" in
            a|attach )
                do_action_attach \
                    "${c}" \
                    "${device_slave_id}" \
                    "${device_master_id}"
            ;;
            d|detach )
                do_action_detach \
                    "${c}" \
                    "${device_slave_id}" \
                    "${device_master_id}"
            ;;
            s|status )
                do_action_status \
                    "${c}" \
                    "${device_slave_id}" \
                    "${device_master_id}"
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
    done
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
