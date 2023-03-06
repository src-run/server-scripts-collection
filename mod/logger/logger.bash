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

# import core time module
core.import time

# start timer
time.timer_start

# import core ui module
core.import ui

# configure ui color
([[ "${TERM}" == *"xterm"* ]] || [[ "${TERM}" == *"color"* ]]) \
    && ui.enable_color

# configure ui glyphs
([[ "${LANG}" == *"UTF-8"* ]]) \
    && ui.enable_unicode_glyphs

# import core logging module
core.import logging

# import core array module
core.import array

#=region-ends:import
#=region-init:docs

logger__doc__='
    The available log levels are:
    error critical warn info debug
    The standard loglevel is critical
    >>> logger.get_level
    >>> logger.get_commands_level
    critical
    critical
    >>> logger.error error-message
    >>> logger.critical critical-message
    >>> logger.warn warn-message
    >>> logger.info info-message
    >>> logger.debug debug-message
    +doc_test_contains
    error-message
    critical-message
    If the output of commands should be printed, the commands_level needs to be
    greater than or equal to the log_level.
    >>> logging.set_level critical
    >>> logging.set_commands_level debug
    >>> echo foo
    >>> logging.set_level info
    >>> logging.set_commands_level info
    >>> echo foo
    foo
    Another logging prefix can be set by overriding "logging_get_prefix".
    >>> logging_get_prefix() {
    >>>     local level=$1
    >>>     echo "[myprefix - ${level}]"
    >>> }
    >>> logging.critical foo
    [myprefix - critical] foo
    "logging.plain" can be used to print at any log level and without the
    prefix.
    >>> logging.set_level critical
    >>> logging.set_commands_level debug
    >>> logging.plain foo
    foo
    "logging.cat" can be used to print files (e.g "logging.cat < file.txt")
    or heredocs. Like "logging.plain", it also prints at any log level and
    without the prefix.
    >>> echo foo | logging.cat
    foo
'

#=region-ends:docs
#=region-init:variables

# decorative logging glyphs array matches the order of logging levels
logger_levels_glyph=(
    "${ui_powerline_fail}"
    "${ui_powerline_fail}"
    "${ui_powerline_fail}"
    "${ui_powerline_pointingarrow}"
    "${ui_powerline_pointingarrow}"
    "${ui_powerline_pointingarrow}"
)

#=region-ends:variables
#=region-init:functions

# normalize logger prefix color key
logger_nor_prefix_lev_key() {
  local level_key="${1}"

  if [[ ${level_key} -gt ${#logging_levels[@]} ]]; then
    level_key=0
  fi

  printf '%d' "${level_key}"
}

# normalize logger prefix level val
logger_nor_prefix_lev_val() {
  local level_val="${1}"

  if ! array.get_index "${level_val}" "${logging_levels[@]}" &> /dev/null; then
    level_val="critical"
  fi

  printf '%s' "${level_val}"
}

# get logger prefix reset color
logger_get_prefix_color_res_all() {
  printf \
    '%s' \
    "${ui_color_default}${ui_color_nobold}${ui_color_nodim}${ui_color_nounderline}${ui_color_noblink}${ui_color_noinvert}${ui_color_noinvisible}"
}

# get logger prefix generic dim color
logger_get_prefix_color_gen_dim() {
  printf \
    '%s' \
    "${ui_color_darkgray}"
}

# get logger prefix generic normal color
logger_get_prefix_color_gen_norm() {
  printf \
    '%s%s' \
    "${ui_color_gray}" \
    "${ui_color_dim}"
}

# get logger prefix generic bold color
logger_get_prefix_color_gen_bold() {
  printf \
    '%s' \
    "${ui_color_white}"
}

# get logger prefix level dim color
logger_get_prefix_color_lev_dim() {
  local level_key="${1:-info}"

  printf \
    '%s%s' \
    "${logging_levels_color[${level_key}]}" \
    "${ui_color_dim}"
}

# get logger prefix level normal color
logger_get_prefix_color_lev_norm() {
  local level_key="${1:-info}"

  printf \
    '%s' \
    "${logging_levels_color[${level_key}]}"
}

# get logger prefix level bold color
logger_get_prefix_color_lev_bold() {
  local level_key="${1:-info}"

  printf '%s%s' \
    "${logging_levels_color[${level_key}]}" \
    "${ui_color_bold}"
}

# format prefix elapsed time
logger_format_prefix_elapsed_time() {
  local elapse="$(echo "scale=4; $(time.timer_get_elapsed) / 1000" | bc)"
  local elaint="$(grep -Eo '^[0-9]+' <<< "${elapse}")"
  local offset="${#elaint}"
  local format='%%02.03f'
  local string="$(printf '%01.04f' "${elapse}")"
  local maxlen=6

  if [[ ${#elaint} -ge $((${maxlen} - 1)) ]]; then
    maxlen=$((${#elaint} + 2))
  fi

#  printf '{elapse=%s/elaint=%s/#elaint=%s/format=%s/string=%s/maxlen=%s/string:0:n=%s}' "${elapse}" "${elaint}" "${#elaint}" "${format}" "${string}" "${maxlen}" "${string:0:${maxlen}}"

  printf '%s' "${string:0:${maxlen}}"
}

# generate logger elapsed time
logger_get_prefix_elapsed_time() {
  printf \
    '%s%s%s' \
    "$(logger_get_prefix_color_gen_dim)" \
    "$(logger_format_prefix_elapsed_time)" \
    "$(logger_get_prefix_color_res_all)"
}

# generate logger prefix script name
logger_get_prefix_scr_name() {
  printf \
    '%s%s%s' \
    "$(logger_get_prefix_color_gen_norm)" \
    "$(basename "${BASH_SOURCE[$((${#BASH_SOURCE[@]} - 1))]}")" \
    "$(logger_get_prefix_color_res_all)"
}

# generate logger prefix datetime component
logger_get_prefix_datetime() {
  printf \
    '%s(%s%s%.04f%s%s|%s%s)%s' \
    "$(logger_get_prefix_color_gen_dim)" \
    "$(logger_get_prefix_color_res_all)" \
    "$(logger_get_prefix_color_gen_dim)" \
    "$(date +%s.%N)" \
    "$(logger_get_prefix_color_res_all)" \
    "$(logger_get_prefix_color_gen_dim)" \
    "$(logger_get_prefix_elapsed_time)" \
    "$(logger_get_prefix_color_gen_dim)" \
    "$(logger_get_prefix_color_res_all)"
}

# generate logger prefix glyph component
logger_get_prefix_glyph() {
  local level_key="${1:-info}"

  printf \
    '%s%s%s' \
    "$(logger_get_prefix_color_lev_bold "${level_key}")" \
    "${logger_levels_glyph[${level_key}]}" \
    "$(logger_get_prefix_color_res_all)"
}

# generate logger prefix line number component
logger_get_prefix_line_number() {
  local line_num_key="$((${#BASH_LINENO[@]} - 2))"

  if [[ ${line_num_key} -lt 0 ]]; then
    line_num_key=0
  fi

  printf \
    '%d' \
    "${BASH_LINENO[${line_num_key}]}"
}

# generate logger prefix level component
logger_get_prefix_level() {
  local level_val="${1}"
  local level_key="${2}"
  local line_numb="$(logger_get_prefix_line_number)"

  printf \
    '%s[%s%s%s%s' \
    "$(logger_get_prefix_color_lev_norm "${level_key}")" \
    "$(logger_get_prefix_color_res_all)" \
    "$(logger_get_prefix_color_lev_norm "${level_key}")" \
    "${level_val:0:4}" \
    "$(logger_get_prefix_color_res_all)"

  if [[ -n "${line_numb}" ]]; then
    printf \
      '%s:%s%s%05d%s' \
      "$(logger_get_prefix_color_lev_norm "${level_key}")" \
      "$(logger_get_prefix_color_res_all)" \
      "$(logger_get_prefix_color_lev_norm "${level_key}")" \
      "${line_numb}" \
      "$(logger_get_prefix_color_res_all)"
  fi

  printf  \
    '%s]%s' \
    "$(logger_get_prefix_color_lev_norm "${level_key}")" \
    "$(logger_get_prefix_color_res_all)"
}

# overwrite rebash base logging prefix function to customize styling
logging_get_prefix() {
  local level_val="${1}"
  local level_key="$(logger_nor_prefix_lev_key "${2}")"

  printf '%s %s %s %s' \
    "$(logger_get_prefix_datetime)" \
    "$(logger_get_prefix_scr_name)" \
    "$(logger_get_prefix_level "${level_val}" "${level_key}")" \
    "$(logger_get_prefix_glyph "${level_key}")"
}

# get auto-message text for specific contexts
logger_get_auto_message_text() {
  local level_val="${1}"

  case "${level_val}" in
    exit) printf -- '(terminating execution due to encountered error)'; return 0 ;;
  esac

  return 1
}

# normalize user message text
logger_nor_user_text_message() {
  local message="${1}"

  printf '%s' "$(
    sed -E 's/([^\.])$/\1.../' <<< "${message}"
  )"
}

# log passing context-type followed by printf-type args
logger_log() {
  local context="${1}"
  local message="${2}"
  local replace=("${@:3}")
  local add_txt

  message="$(logger_nor_user_text_message "${message}")"

  if add_txt="$(logger_get_auto_message_text "${context}")"; then
    message="${message} ${add_txt}"
  fi

  local evalstr="logging.$(logger_nor_prefix_lev_val "${context}") \"$(
    printf "${message}" "${replace[@]}" 2> /dev/null \
      || printf "${message}"
  )\""

  eval "${evalstr}"

  if [[ ${context} == "exit" ]]; then
    exit 255
  fi
}

#=region-ends:functions
#=region-init:interfaces

alias logger.text='logger_log'
alias logger.debg='logger_log debug'
alias logger.verb='logger_log verbose'
alias logger.info='logger_log info'
alias logger.warn='logger_log warn'
alias logger.fail='logger_log error'
alias logger.crit='logger_log critical'
alias logger.exit='logger_log exit'
alias logger.set_file_descriptors='logging.set_file_descriptors'
alias logger.set_log_file='logging.set_log_file'
alias logger.set_level='logging.set_level'
alias logger.set_commands_level='logging.set_commands_level'
alias logger.get_level='logging.get_level'
alias logger.get_commands_level='logging.get_commands_level'

#=region-ends:interfaces
#=region-init:main-sub

if core.is_main; then
  logger.critical 'This script should not be called directly; source this module to use.'
fi

#=region-ends:main-sub
