#!/bin/bash

##
## This file is part of the `robfrawley/twoface-scripts` project.
##
## (c) Rob Frawley 2nd <rmf@src.run>
##
## For the full copyright and license information, please view the LICENSE.md
## file that was distributed with this source code.
##

OPENVPN_SCR_NAME="$(basename "${BASH_SOURCE[0]}")"

OPENVPN_BIN_FILE="$(which openvpn)"
OPENVPN_VER_OVPN="$("${OPENVPN_BIN_FILE}" --version 2> /dev/null | grep -oE '(OpenVPN) [0-9\.]+' | sed -E 's/([a-zA-Z]+) ([0-9\.]+)/\1 v\2/g')"
OPENVPN_VER_OSSL="$("${OPENVPN_BIN_FILE}" --version 2> /dev/null | grep -oE '(OpenSSL) [0-9\.]+' | sed -E 's/([a-zA-Z]+) ([0-9\.]+)/\1 v\2/g')"
OPENVPN_VER_CLZO="$("${OPENVPN_BIN_FILE}" --version 2> /dev/null | grep -oE '(LZO) [0-9\.]+'     | sed -E 's/([a-zA-Z]+) ([0-9\.]+)/\1     v\2/g')"

OPENVPN_DIR_PATH="${HOME}/ovpn"
OPENVPN_RUN_FILE="${OPENVPN_DIR_PATH}/openvpn.status"
OPENVPN_PID_FILE="${OPENVPN_DIR_PATH}/openvpn.pid"
OPENVPN_LOG_FILE="${OPENVPN_DIR_PATH}/openvpn.log"
OPENVPN_LOG_LEVL=3
OPENVPN_DEV_NAME='tun0'
OPENVPN_CFG_FILE="${OPENVPN_DIR_PATH}/pia-vpn-usa.ovpm"
OPENVPN_BIN_OPTS="--cd ${OPENVPN_DIR_PATH} --status ${OPENVPN_RUN_FILE} 10 --config ${OPENVPN_CFG_FILE} --mute-replay-warnings --dev ${OPENVPN_DEV_NAME} --verb ${OPENVPN_LOG_LEVL}"

OPENVPN_PID_INTS="$(pidof ${OPENVPN_BIN_FILE})"
OPENVPN_RUN_OKAY=1
OPENVPN_RUN_WAIT=5

OPENVPN_VAR_PRFX='OPENVPN'
OPENVPN_VAR_KEYS=('BIN_FILE' 'VER_OVPN' 'VER_OSSL' 'VER_CLZO' 'DIR_PATH' 'RUN_FILE' 'PID_FILE' 'LOG_FILE' 'LOG_LEVL' 'DEV_NAME' 'CFG_FILE' 'BIN_OPTS' 'BIN_INTS' 'RUN_OKAY' 'RUN_WAIT')

function o_text {
  printf -- "${@}"
}

while true; do
  OPENVPN_RUN_OKAY=1
  OPENVPN_PID_INTS="$(pidof ${OPENVPN_BIN_FILE})"
  OPENVPN_RUN_WAIT="${OPENVPN_RUN_WAIT:-5}"

  clear

  o_text '\n##\n## DATE => "%s"\n## NAME => "%s"\n##\n' "$(date)" "${OPENVPN_SCR_NAME}"
  o_text '\n--\n-- RESOLVED RUNTIME CONFIGURATION\n--\n'

  for n in "${OPENVPN_VAR_KEYS[@]}"; do
    v="$(printf '%s_%s' "${OPENVPN_VAR_PRFX}" "${n}")"
    c="${!v}"

    o_text '-- • %s => "%s"' "${v}" "${c}"

    if [[ ${n} =~ PATH$ ]] && [[ ! -d ${!v} ]]; then
      o_text ' (Error: The configured path does not exist!)'
      OPENVPN_RUN_OKAY=0
      sleep 1
    fi

    if [[ ${n} =~ FILE$ ]] && [[ ! ${n} =~ (PID|LOG|RUN) ]] && [[ ! -f ${!v} ]]; then
      o_text ' (Error: The configured file does not exist!)'
      OPENVPN_RUN_OKAY=0
      sleep 1
    fi

    o_text '\n'
  done

  o_text '--\n'

  if [[ ${OPENVPN_PID_INTS} != "" ]]; then
    o_text '\n!!\n!! Unable to start openvpn as it is already running as "%s" ...\n!!\n' "${OPENVPN_PID}"
    OPENVPN_RUN_OKAY=0
  fi

  if [[ ${OPENVPN_RUN_OKAY} -eq 0 ]]; then
    o_text '\n!!\n!! Sleeping for %d seconds before restarts openvpn script due to failures detailed aboves ...\n!!\n' "${OPENVPN_RUN_WAIT}"
    sleep ${OPENVPN_RUN_WAIT}
    continue
  else
    o_text '\n!!\n!! Sleeping for %d seconds before invoking openvpn using the above configs ...\n!!\n' "${OPENVPN_RUN_WAIT}"
    sleep ${OPENVPN_RUN_WAIT}
  fi

  cd "${OPENVPN_DIR_PATH}"

  o_text '\n'

  sudo "${OPENVPN_BIN_FILE}" ${OPENVPN_BIN_OPTS}

  o_text '\n!!\n!! Caught exited openvpn process ... attempting to restart after waiting for %d seconds ...\n!!\n' "${OPENVPN_RUN_WAIT}"

  sleep ${OPENVPN_RUN_WAIT}
done

