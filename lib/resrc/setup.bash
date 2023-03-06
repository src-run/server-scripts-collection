#!/usr/bin/env bash

##
## This file is part of the `src-run/bash-server-scripts` project.
##
## (c) https://github.com/src-run/bash-server-scripts/graphs/contributors
##
## For the full copyright and license information, please view the LICENSE.md
## file that was distributed with this source code.
##

#
# define self script fallback path
#
readonly _RESRC_SELF_PATH_FALLBACK="${0}"

#
# define self script bash-env path
#
readonly _RESRC_SELF_PATH_BASH_ENV="${BASH_SOURCE[0]}"

#
# fallback realpath implementation without reliance on realpath or readlink executables
#
# original implementation taken from https://github.com/morgant/realpath by morgan aldridge with
# the following license https://github.com/morgant/realpath#license
#
function _resrc_realpath_fallback() {
  local stat_code=0
  local args_path="${1}"
  local real_path
  local temp_path
  local base_file

  # make sure the string isn't empty as that implies something in further logic
  if [ -z "${args_path}" ]; then
    stat_code=1
  else
    # start with the file name (sans the trailing slash)
    args_path="${args_path%/}"

    # if we stripped off the trailing slash and were left with nothing, that means we're in the root directory
    if [ -z "${args_path}" ]; then
      args_path="/"
    fi

    # get the basename of the file (ignoring '.' & '..', because they're really part of the path)
    base_file="${args_path##*/}"
    if [[ ( "${base_file}" = "." ) || ( "${base_file}" = ".." ) ]]; then
      base_file=""
    fi

    # extracts the directory component of the full path, if it's empty then assume '.' (the current working directory)
    temp_path="${args_path%$base_file}"
    if [ -z "${temp_path}" ]; then
      temp_path='.'
    fi

    # attempt to change to the directory
    if ! cd "${temp_path}" &> /dev/null; then
      stat_code=1
    fi

    if [[ ${stat_code} -ne 1 ]]; then
      # does the filename exist?
      if [[ ( -n "${base_file}" ) && ( ! -e "${base_file}" ) ]]; then
        stat_code=1
      fi

      # get the absolute path of the current directory & change back to previous directory
      real_path="$(pwd -P 2> /dev/null)"
      cd "-" &> /dev/null

      # Append base filename to absolute path
      if [ "${real_path}" = "/" ]; then
        real_path="${real_path}${base_file}"
      else
        real_path="${real_path}/${base_file}"
      fi

      # output the absolute path
     printf '%s' "${real_path}"
    fi
  fi

  return ${stat_code}
}

#
# resolve realpath using the first successful attempt: readlink (executable cmd), realpath (executable cmd), fallback (bash func)
#
function _resrc_realpath() {
  local bin_read_link="$(
    which readlink 2> /dev/null
  )"
  local bin_real_path="$(
    which realpath 2> /dev/null
  )"
  local inputted_path="${1}"
  local res_temp_path
  local resolved_path

  for b in "${bin_read_link}" "${bin_real_path}"; do
    if [[ ! -x "${b}" ]]; then
      continue;
    fi

    res_temp_path="$(
      ${b} -m "${inputted_path}" \
        || ${b} "${inputted_path}"
    )"

    if [[ -e "${res_temp_path}" ]]; then
      resolved_path="${res_temp_path}"
      break
    fi
  done

  printf '%s' "${resolved_path:-$(_resrc_realpath_fallback)}"
}

#
# resolve real path of this script
#
function _resrc_self_real_path() {
  local self_path

  case "$(basename "${SHELL:-sh}")" in
    bash) self_path="${_RESRC_SELF_PATH_BASH_ENV}" ;;
    *   ) self_path="${_RESRC_SELF_PATH_BASH_ENV:-$_RESRC_SELF_PATH_FALLBACK}" ;;
  esac

  printf '%s' "$(_resrc_realpath "${self_path}")"
}

#
# resolve real directory path of this script
#
function _resrc_self_base_path() {
  local real_path="$(_resrc_self_real_path)"

  printf '%s' "$(dirname "${real_path}")"
}

#
# resolve real base file path of this script
#
function _resrc_self_base_file() {
  local real_path="$(_resrc_self_real_path)"

  printf '%s' "$(basename "${real_path}")"
}

#
# define real path of this script
#
readonly _RESRC_SELF_REAL_PATH="$(_resrc_self_real_path)"

#
# define real base path of this script
#
readonly _RESRC_SELF_BASE_PATH="$(_resrc_self_base_path)"

#
# define root path of all libraries
#
readonly _LIB_ROOT_PATH="$(_resrc_realpath "${_RESRC_SELF_BASE_PATH}/../")"

#
# define root path of all modules
#
readonly _MOD_ROOT_PATH="$(_resrc_realpath "${_LIB_ROOT_PATH}/../mod/")"

#
# define root path of enabled bins
#
readonly _BIN_ENABLED_ROOT_PATH="$(_resrc_realpath "${_LIB_ROOT_PATH}/../bin-enabled/")"

#
# define root path of available bins
#
readonly _BIN_AVAILABLE_ROOT_PATH="$(_resrc_realpath "${_LIB_ROOT_PATH}/../bin-available/")"

#
# define root path of rebash library
#
readonly _REBASH_LIB_ROOT_PATH="$(_resrc_realpath "${_LIB_ROOT_PATH}/rebash/")"

#
# define real path of rebash core module
#
readonly _REBASH_MOD_CORE_PATH="$(_resrc_realpath "${_REBASH_LIB_ROOT_PATH}/core.sh")"

#
# build internal module paths
#
function _get_mod_abs() {
  local in_paths=("${_MOD_ROOT_PATH}" "${_LIB_ROOT_PATH}" "${_BIN_ENABLED_ROOT_PATH}" "${_BIN_AVAILABLE_ROOT_PATH}")
  local mod_name="${1}"
  local mod_path
  local tmp_path

  if [[ -z "${mod_name}" ]]; then
    printf 'Failed to build module path (empty mod name provided)...\n' 1>&2
    return 1
  fi

  mod_name="$(basename "${mod_name}" '.bash' 2> /dev/null)"

  for template in "%s" "%s.bash" "%s/%s" "%s/%s.bash"; do
    tmp_path="$(
      printf "${template}\n" "${mod_name}" "${mod_name}" \
        | head -n1
    )"

    for base_path in "${in_paths[@]}"; do
#      printf 'func::%s::%s (%s/%s) [%s]\n' "${FUNCNAME[0]}" "${mod_name}" "${base_path}/${tmp_path}" "${tmp_path}" 1>&2
      if [[ -d "${base_path}" ]] && [[ -f "${base_path}/${tmp_path}" ]]; then
        mod_path="$(_resrc_realpath "${base_path}/${tmp_path}")"
        break 2
      fi
    done
  done

  if [[ -z "${mod_path}" ]]; then
    printf 'Failed to build module path (unable to find "%s" in paths: %s)...\n' \
      "${mod_name}" \
      "${in_paths[*]}" 1>&2
  fi

  printf '%s' "${mod_path}"
}

#
# source rebash core module, import rebash logging module, and push debug log entry of success OR write failure message and exit
#
source "${_REBASH_MOD_CORE_PATH}" || (\
  printf \
    'Failed to locate rebash core module file path (attempted to resolved from "%s" to search path "%s" and failed sourcing at "%s")... Terminating execution.\n' \
    "${_RESRC_SELF_BASE_PATH}" \
    "${_REBASH_LIB_ROOT_PATH}" \
    "${_REBASH_MOD_CORE_PATH}" && \
  exit 255
)

#
# import custom rebash logger module
#
core.import "$(_get_mod_abs logger)"

#
# setup defaul logger levels
#
logging.set_level 'info'
logging.set_commands_level 'info'

# test timer
#logger.debg 'ran for "%d" milliseconds...' "$(time.timer_get_elapsed)"
#logger.debg 'sleeping for 01.0 seconds...'
#sleep 1
#logger.debg 'ran for "%d" milliseconds...' "$(time.timer_get_elapsed)"
#logger.debg 'sleeping for 00.7 seconds...'
#sleep .7
#logger.debg 'ran for "%d" milliseconds...' "$(time.timer_get_elapsed)"
#logger.debg 'sleeping for 04.0 seconds...'
#sleep 4
#logger.debg 'ran for "%d" milliseconds...' "$(time.timer_get_elapsed)"
#logger.debg 'sleeping for 13.0 seconds...'
#sleep 13
#logger.debg 'ran for "%d" milliseconds...' "$(time.timer_get_elapsed)"
#logger.debg 'sleeping for 08.0 seconds...'
#sleep 8
#logger.debg 'ran for "%d" milliseconds...' "$(time.timer_get_elapsed)"
#logger.debg 'sleeping for 99.0 seconds...'
#sleep 99
#logger.debg 'ran for "%d" milliseconds...' "$(time.timer_get_elapsed)"

# test logger
#logger.debg 'message with %d replacements for "%s" type' 2 debug
#logger.verb 'message with %d replacements for "%s" type' 2 verbose
#logger.info 'message with %d replacements for "%s" type' 2 informational
#logger.warn 'message with %d replacements for "%s" type' 2 warning
#logger.fail 'message with %d replacements for "%s" type' 2 failure/error
#logger.crit 'message with %d replacements for "%s" type' 2 critical
#logger.exit 'message with %d replacements for "%s" type' 2 exit
