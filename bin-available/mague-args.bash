#!/usr/bin/env bash

##
## This file is part of the `src-run/bash-server-scripts` project.
##
## (c) https://github.com/src-run/bash-server-scripts/graphs/contributors
##
## For the full copyright and license information, please view the LICENSE.md
## file that was distributed with this source code.
##

#=region-init:import

# import core modules

# source default module loader
source "$(
  dirname "$(
    readlink -m "${BASH_SOURCE[0]}"
  )"
)/../lib/resrc/setup.bash"

#=region-ends:modules
#=region-init:docs

mague__doc__='
  Pass any number of magnet links to this command as command line arguments.
'

#=region-ends:docs
#=region-init:variables

# resolve the real command file path
readonly mague_cmd_self="$(
  printf 'r="'"${BASH_SOURCE[0]}"'"; printf '%s' "${r:A}"' | /usr/bin/env zsh 2> /dev/null
)"

# resolve the real command directory path
readonly mague_cmd_path="$(
  dirname "${mague_cmd_self}" 2> /dev/null
)"

# resolve the real command file name
readonly mague_cmd_file="$(
  basename "${mague_cmd_self}" 2> /dev/null
)"

# resolve the real command name (file basename)
readonly mague_cmd_name="$(
  basename "${mague_cmd_self}" "$(
    grep -oE '\.[a-z0-9]+$' <<< "${mague_cmd_file}" 2> /dev/null
  )" 2> /dev/null
)"

# define the write path config file location
mague_write_path_cfg_loc="${mague_write_path_cfg_loc:-${HOME}/.mague-write-path.conf}"

# define the write path config default value
mague_write_path_cfg_def="${mague_write_path_cfg_def:-$(pwd)/${mague_cmd_name}/}"

# define the write path config runtime value
mague_write_path_cfg_val=''

#=region-ends:variables
#=region-init:functions

# write to stdout with printf-style replacements
mague_write_stdout() {
  printf -- "${@}"
}

# write to stderr with printf-style replacements
mague_write_stderr() {
  1>&2 printf -- "${@}"
}

#
# output help/usage message
#
mague_write_usage() {
  mague_write_stderr 'USAGE\n'
  mague_write_stderr '  ./%s mag_link_1 [mag_link_2] [...] [mag_link_n]\n\n' "${mague_cmd_file}"
  mague_write_stderr 'ARGUMENTS\n'
  mague_write_stderr '  -%s|--%-8s %s\n' o root 'Ignore globally configured path and output magnet files to this location instead.'
  mague_write_stderr '  -%s|--%-8s %s\n' v verbose 'Enable verbose logging of actions performed by this command.'
  mague_write_stderr '  -%s|--%-8s %s\n' d debug 'Enable debug-level logging of actions performed by this command.'
  mague_write_stderr '  -%s|--%-8s %s\n' u usage 'Output usage information for this command.'
}

# sets logger verbosity level
mague_set_verbosity() {
  local lev="${1:-info}"

  logging.set_level "${lev}"
  logging.set_commands_level "${lev}"
  logger.debg 'Setting runtime log level: "%s"...' "${lev}"
}

# create the magnet link output path config
function mague_cfg_write_path_make() {
  local write_path="${1}"

  if mkdir -p "${write_path}" 2> /dev/null; then
    logger.verb 'Creating magnet link output path: "%s"...' "${write_path}"
    return
  fi

  return 1
}

# check the magnet link output path config
function mague_cfg_write_path_check() {
  local write_path="${1}"

  if ([[ -d ${write_path} ]] && [[ -r ${write_path} ]]) || mague_cfg_write_path_make "${write_path}"; then
    logger.verb 'Resolved magnet link output path: "%s"...' "${write_path}"
    return
  fi

  return 1
}

# gets the magnet link output path config
function mague_cfg_write_path_set() {
  if [[ -f ${mague_write_path_cfg_loc} ]] && [[ -r ${mague_write_path_cfg_loc} ]]; then
    mague_write_path_cfg_val="$(
      cat "${mague_write_path_cfg_loc}" 
    )"
  else
    mague_write_path_cfg_val="${mague_write_path_cfg_def}"
  fi

  if ! mague_cfg_write_path_check "${mague_write_path_cfg_val}"; then
    logger.exit 'Failure encountered while resolving magnet link output path...'
  fi
}

# resolve the latest php executable path
function mague_get_php_bin() {
  local bin_path
  local possible=(php7.4 php7.3 php7.2 php7.1 php7.0 php7 php)

  for p in "${possible[@]}"; do
    if bin_path="$(command -v "${p}")"; then
      printf '%s' "${bin_path}" && return
    fi
  done

  return 1
}

# decode special url characters
function mague_link_decode() {
  local mag_link="${1}"
  local dec_link
  local php_path

#sed -E 's/\$/-/g' <<< '!@#$%^&*()$$$'
#php7.3 -r 'echo(trim(preg_replace("{[_]+}", "_", preg_replace("{[^a-z0-9_-]+}i", "_", "!@#$%^&*()_+-=1234567890[]\{}|;:\",./<>?q!w@e#rt%y^u&i*o(pasdfghjklzxcvbnm")), "-_\t\n\r\0\x0B"));'

  if php_path="$(mague_get_php_bin)"; then
    dec_link="$(
      ${php_path} -r 'echo(trim(preg_replace("{[_]+}", "_", preg_replace("{[^a-z0-9?&[\\\._-]+}i", "_", str_replace([" ", "\t", "\r", "\n"], "_", urldecode($argv[1])))), "-_\t\n\r\0\x0B"));' "$(sed -E 's/\$/-/g' <<< "${mag_link}")"
#'echo(trim(preg_replace("{[_]+}", "_", preg_replace("{[^a-z0-9_-]+}i", "_", str_replace([" ", "\t", "\r", "\n"], "_", urldecode($argv[1])))), , "-_\t\n\r\0\x0B"));' "$(sed -E 's/\$/-/g' <<< "${mag_link}")" 
#2> /dev/null \
#        || printf '%s' "${mag_link}-decode-failed"
    )"
  fi

  #if php_path="$(mague_get_php_bin)"; then
  #  dec_link="$(
  #    ${php_path} -r 'echo(str_replace([" ", "\t", "\r", "\n"], "_", urldecode($argv[1])));' "${mag_link}" 2> /dev/null \
  #      || printf '%s' "${mag_link}"
  #  )"
  #fi

  printf '%s' "${dec_link:-${mag_link}}"
}

# encode special url characters
function mague_link_encode() {
  local mag_link="${1}"
  local dec_link
  local php_path

  if php_path="$(mague_get_php_bin)"; then
    dec_link="$(
      ${php_path} -r 'echo(rawurlencode($argv[1]));' "${mag_link}" 2> /dev/null
    )"
  fi

  printf '%s' "${dec_link:-${mag_link}}"
}

# handle the passed magnet link
mague_handle_link() {
  local out_path="${1}"
  local mag_link="${2}"
  local mag_file
  local mag_path

  if [[ -z "${mag_link}" ]]; then
    logger.warn 'An empty magnet link was provided. Skipping entry...'
    return
  fi

  logger.debg 'Parsing magnet of link: "%s"...' "$(mague_link_encode "${mag_link}")"

  mag_file="$(
    sed -E 's/ /_/g' <<< "$(
      mague_link_decode "$(
        grep -oE '=([^=&]+)' <<< "${mag_link}" 2> /dev/null | \
          head -n2 2> /dev/null | \
          tail -n1 2> /dev/null
      )"
    )" 2> /dev/null
  )"
  mag_file="$(
    grep -oE '[A-Za-z].+\.[A-Za-z0-9]{1,4}' 2> /dev/null <<< "${mag_file}" \
      || grep -oE '[A-Za-z].+$' 2> /dev/null <<< "${mag_file}"
  ).magnet"

  mag_path="${out_path}/${mag_file}"

  logger.debg 'Decoded magnet link path: "%s"...' "${mag_path}"
  logger.info 'Writing magnet link file: "%s"...' "${mag_file}"

  if echo "${mag_link}" > "${mag_path}" 2> /dev/null; then
    logger.debg 'Success writing magnet link file: "%s"...' "${mag_file}"
  else
    logger.debg 'Failure writing magnet link file: "%s"...' "${mag_file}"
  fi
}

# main command logic loop
mague_main() {
  local out_help=false
  local log_debg=false
  local log_verb=false
  local mag_urls=()
  local out_path

  arguments.set "${@}"
  mag_urls=($(arguments.get_parameters_not_named --debug -d --verbose -v --root -r))

  arguments.get_flag --usage -u --help -h out_help
  if "${out_help}"; then
    mague_write_usage
    exit 0
  fi

  arguments.get_flag --debug -d log_debg
  if "${log_debg}"; then
    mague_set_verbosity debug
  fi

  arguments.get_flag --verbose -v log_verb
  if "${log_verb}"; then
    mague_set_verbosity verbose
  fi

  arguments.get_parameter --root -r out_path
  arguments.get_keyword --root -r out_path

  if ! mague_cfg_write_path_check "${out_path}"; then
    mague_cfg_write_path_set
    out_path="${mague_write_path_cfg_val}"
  fi

  if [[ ${#mag_urls[@]} -eq 0 ]]; then
    logger.warn 'No magnet links were passed as arguments. Nothing to do...'
    exit 0
  fi

  for l in "${mag_urls[@]}"; do
    mague_handle_link "${out_path}" "${l}"
  done
}

#=region-ends:functions
#=region-init:interfaces

#=region-ends:interfaces
#=region-init:main-sub

if core.is_main; then
  mague_main "${@}"
  exit $?
fi

#=region-ends:main-sub

