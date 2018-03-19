#!/usr/bin/env bash

##
# This file is part of the `robfrawley/bash-scripts` project.
#
# (c) Rob Frawley 2nd <rmf@src.run>
#
# For the full copyright and license information, please view the LICENSE.md
# file that was distributed with this source code.
##

isRgbFormat()
{
  [[ ${1} =~ ^((2[0-4][0-9]|25[0-5]|[01]?[0-9]?[0-9]),?\s?){3}$ ]]; return $?
}

isHexFormat()
{
  [[ ${1} =~ ^[0-9A-Fa-f]{3}([0-9A-Fa-f]{3})?$ ]]; return  $?  
}

writeRgbAsHex()
{
  local rgb=($(echo ${1} | tr "," "\n"))

  printf "%02X%02X%02X\n" ${rgb[@]}
}

writeHexAsRgb()
{
  local h=${1}

  if [[ ${#h} == 3 ]]; then
    h=${h}${h}
  fi

  printf "%d,%d,%d\n" 0x${h:0:2} 0x${h:2:2} 0x${h:4:2}
}

sanitizeFormat()
{
  local f="${1}"
  local v=(${@})

  if [[ "${f:0:1}" == "#" ]]; then
    f="${f:1}"
  fi

  if [[ ${#v[@]} -ne 3 ]]; then
    printf "$(echo ${f} | tr -d '[:blank:]')"
  else
    printf "%'.03s,%'.03s,%'.03s" $(echo ${1} | sed 's/[^0-9]//g') $(echo ${2} | sed 's/[^0-9]//g') $(echo ${3} | sed 's/[^0-9]//g')
  fi
}

main() {
  local f=$(sanitizeFormat ${@})

  if isHexFormat ${f}; then
    writeHexAsRgb ${f}
  elif isRgbFormat ${f}; then
    writeRgbAsHex ${f}
  else
    printf "Usage: %s [hex | r g b]\n" $0
    exit 1
  fi
}

main "${@}"

