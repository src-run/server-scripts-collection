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
# output information message
#
function out_info {
	printf '[INFO] -- %s\n' "$(printf "${@}")"
}

#
# output warning message
#
function out_warn {
	>&2 printf '[WARN] ## %s\n' "$(printf "${@}")"
}

#
# output critical error
#
function out_crit {
	>&2 printf '[CRIT] !! %s\n' "$(printf "${@}")"
}

#
# resolve real path of input path
#
function resolve_real_path {
	local resolve_path="${1:-}"
	local readlink_bin='readlink'
	local readlink_opt='-m'
	local realpath_bin='realpath'
	local realpath_opt='-m'

	if [[ -z ${resolve_path} ]]; then
		out_warn 'Failed to resolve real path on empty provided path!'
		return
	fi

	if readlink_bin="$(which "${readlink_bin}" 2> /dev/null)"; then
		${readlink_bin} ${readlink_opt} "${resolve_path}"
		return $?
	fi

	if realpath_bin="$(which "${realpath_bin}" 2> /dev/null)"; then
		${realpath_bin} ${realpath_opt} "${resolve_path}"
		return $?
	fi

	out_warn 'Failed to resolve real path of "%s" (readlink and realpath must both be missing).' "${resolve_path}"
	printf '%s' "${resolve_path}"
}

#
# output usage information
#
function out_usage() {
  printf 'Usage: ./%s [OPTIONS]\n' "${_SELF_NAME}"
  printf '\t-%s | --%-11s %s\n' f fan-speed   'Output the speed of the radiator fan(s).'
  printf '\t-%s | --%-11s %s\n' p pump-speed  'Output the speed of the pump.'
  printf '\t-%s | --%-11s %s\n' l liquid-temp 'Output the liquid temperature of the loop.'
  printf '\t-%s | --%-11s %s\n' v fw-version  'Output the firmware version of the device controller.'
  printf '\t-%s | --%-11s %s\n' h help        'Output this usage information.'

  exit 0
}

#
# get raw kraken stats data
#
function get_kraken_stats_data {
	echo -n "${_DATA_KBIN}"
}

#
# get one kraken stats line
#
function get_kraken_stats_line {
	local index="${1}"
	declare -A STATS

	[[ -z ${index} ]] && return 255

	while IFS= read -r data; do
		STATS[${data%%=*}]="${data#*=}"
	done <<< $(get_kraken_stats_data)

	printf '%s\n' "${STATS[${index}]}"
}

#
# output requested data
#
function main {
	local opt="${1}"

	if [[ ${#} -ne 1 ]]; then
		out_crit 'Detected invalid number of arguments! Expected 1 but got %d...' ${#}
		out_usage
		exit 255
	fi

	case "${opt}" in
		-f|--fan-speed   ) get_kraken_stats_line fan_speed ;;
		-p|--pump-speed  ) get_kraken_stats_line pump_speed ;;
		-l|--liquid-temp ) get_kraken_stats_line liquid_temperature ;;
		-v|--fw-version  ) get_kraken_stats_line firmware_version ;;
		-h|--help        ) out_usage ;;
		*                ) out_crit "Invalid argument: '%s'..." "${opt}"; out_usage ;;
	esac
}

#
# determine real path name of self
#
readonly _SELF_REAL="$(resolve_real_path "${0}")"

#
# determine real file name of self
#
readonly _SELF_NAME="$(basename "${_SELF_REAL}")"

#
# determine real directory path of self
#
readonly _SELF_PATH="$(dirname "${_SELF_REAL}")"

#
# determine real file path to kraken library executable
#
readonly _LIBS_KBIN="$(resolve_real_path "${_SELF_PATH}/../lib/krakenx/bin/colctl")"

#
# read and format kraken status data
#
readonly _DATA_KBIN="$(
	${_LIBS_KBIN} -s 2> /dev/null \
		| tail -n4 \
		| sed -E 's/^([a-z_]+) ([0-9\.]+)$/\1=\2/'
)"

main "${@}"
