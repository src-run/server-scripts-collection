#!/bin/zsh

##
## This file is part of the `robfrawley/twoface-scripts` project.
##
## (c) Rob Frawley 2nd <rmf@src.run>
##
## For the full copyright and license information, please view the LICENSE.md
## file that was distributed with this source code.
##

#
# output line of text
#

function out {
    local context="${1}"; shift
    local formats="${1}"; shift

    printf '[%s] (%s) ' "$(date +%s.%N | grep -oE '[0-9]+\.[0-9]{3}')" "${context:l}"
    printf "${formats}\n" "${@}"
}


#
# output notice line
#

function out_note {
    out note "${@}"
}


#
# output failure line
#

function out_fail {
    out fail "${@}"
}


#
# output failure line
#

function out_exit {
    local ret="${1}"; shift

    out_fail "${@}"
    exit ${ret}
}

#
# Wait a set amount of time to allow openvpn to start when this is called from screen
#

function wait {
    local seconds=${1}

    if [[ ${seconds} > 0 ]]; then
        out_note 'Waiting %f seconds before initiaizlization ...' ${seconds}
        sleep ${seconds}
    fi
}


#
# Resolve the pid of a bash service start script
#

function resolve_start_script_pid {
    local bin="${1}"

    ps aux 2> /dev/null \
        | grep -E "(${bin}|$(basename "${bin}" '.bash'))$" 2> /dev/null \
        | awk '{ print $2 }' 2> /dev/null
}


#
# resolve absolute path to bin
#

function resolve_bin_abs_path {
    local bin="${1}"
    local nil="${2:-false}"
    local abs

    abs="$(which ${bin} 2> /dev/null)"

    [[ $? -eq 0 ]] && [[ -n "${bin}" ]] \
        && echo "${abs}" \
        || echo "${bin}"
}


#
# Ensure rtorrent is not running, openvpn is running, and start using any passed options
#

function init {
    local openvpn_bin="$(resolve_bin_abs_path "${1}")"
    local openvpn_pid
    local torrent_bin="$(resolve_bin_abs_path "${2}")"
    local torrent_pid
    local torrent_opt
    local ip_tun_locl
    local ip_tun_extn
    local ip_tun_name="${4:-tun0}"
    local ip_info_bin="$(resolve_bin_abs_path "ip-info")"

    [[ -z "${torrent_bin}" ]] && torrent_bin="$(resolve_bin_abs_path ${HOME}/rtorrent/start)"
    [[ -z "${openvpn_bin}" ]] && openvpn_bin="$(resolve_bin_abs_path start-openvpn)"

    torrent_bin="${HOME}/rtorrent/start"
    openvpn_bin="${HOME}/openvpn/bin/start-openvpn"

    if [[ ! -x "${torrent_bin}" ]]; then
        out_exit 255 'Configured torrent start script (%s) does not exist or is not executable!' "${torrent_bin}"
    fi

    if [[ ! -x "${openvpn_bin}" ]]; then
        out_exit 255 'Configured openvpn start script (%s) does not exist or is not executable!' "${openvpn_bin}"
    fi

    if [[ ! -x "${ip_info_bin}" ]]; then
        out_exit 255 'Configured ip-info command exec (%s) does not exist or is not executable!' "${ip_info_bin}"
    fi

    torrent_pid=$(resolve_start_script_pid ${torrent_bin})
    openvpn_pid=$(resolve_start_script_pid ${openvpn_bin})

    if [[ -n "${torrent_pid}" ]]; then
        out_exit 255 'Unable to start rtorrent (%s) as it is already running with PID "%d"!' "${torrent_bin}" "${torrent_pid}"
    fi

    if [[ -z "${openvpn_pid}" ]]; then
        out_exit 255 'Unable to start rtorrent (%s) as openvpn (%s) is not running!' "${torrent_bin}" "${openvpn_bin}"
    fi

    out_note 'Found openvpn exec ("%s") process identifier ("%s") ...' "${openvpn_bin}" "${openvpn_pid}"

    ip_tun_locl="$(${ip_info_bin} -i=${ip_tun_name} -m -q)"

    [[ $? -ne 0 ]] && out_exit 255 'Failed to resolve local ip for "%s" interface using "%s" command.' "${ip_tun_name}" "${ip_info_bin} -i=${ip_tun_name} -m -q"

    ip_tun_extn="$(${ip_info_bin} -i=${ip_tun_name} -m -q -r)"

    [[ $? -ne 0 ]] && out_exit 255 'Failed to resolve remote ip for "%s" interface using "%s" command.' "${ip_tun_name}" "${ip_info_bin} -i=${ip_tun_name} -m -q"

    torrent_opt="${ip_tun_locl}"

    out_note 'Resolved %s interface remote ("%s") and local ("%s") ipv4 addresses ...' "${ip_tun_name}" "${ip_tun_extn}" "${ip_tun_locl}"
    out_note 'Invoking rtorrent command ("%s") ...' "${torrent_bin} ${torrent_opt}"

    ${torrent_bin} ${torrent_opt}
}


#
# main function
#

function main {
  init "${2:-}" "${3:-}" "${4:-}"
}

# go!
wait ${1:-180}
main "${@}"
