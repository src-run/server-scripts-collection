#!/bin/bash

set -e

readonly SELF_FILE_PATH="$(readlink -m ${BASH_SOURCE[0]})"
readonly SELF_BASE_NAME="$(basename "${SELF_FILE_PATH}" .bash)"
readonly SELF_WORK_PATH="/tmp/${SELF_BASE_NAME}-${RANDOM}"
readonly COMP_INST_LINK="https://getcomposer.org/installer"
readonly COMP_INST_FILE="composer-installer.php"
readonly COMP_INST_ALGO="sha384"
readonly COMP_INST_HASH="48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5"
readonly COMP_INST_SUMS="$(tr '[:lower:]' '[:upper:]' <<< "${COMP_INST_ALGO}")SUMS"

function format_text {
  local format="${1}"
  local argums=("${@:2}")

  printf -- '%s (%.06f) -- %s' \
    "${SELF_BASE_NAME}" \
    "$(date +%s.%N)" \
    "$(printf -- "${format}" "${argums[@]}")"
}

function format_line {
  format_text "${@}"
  printf '\n'
}

function action_definition {
  format_text "${1} ... " "${@:2}"
}

function action_def {
  action_definition "${@}"
}

function action_resolution {
  local status="${1:-0}"
  local format="${2:-}"
  local argums=("${@:3}")

#  printf '\nSTATUS[%d]\nFORMAT[%s]\n' "${status}" "${format}"
#  printf 'ARGUMS[%s]\n' "${argums[@]}"

  if [[ ${status} -ne ${expect} ]]; then
    printf '[FAIL]'

    if [[ -n ${format} ]]; then
      printf -- ' (%s)' \
        "$(printf -- "${format}" "${argums[@]}")"
    fi

    printf '\n'
    exit ${status}
  fi

  printf '[DONE]\n'
}

function action_res {
  action_resolution "${@}"
}

format_text 'Calling custom output function: "%s"' 'format_text'
format_line 'SAME LINE AS FIRST'

format_line 'FOO[%s] BAR[%s] BAZ[%s]' ${RANDOM} ${RANDOM} ${RANDOM}

action_definition 'Begin "%s" action and determine result afterwards' "foobar-${RANDOM}"
action_resolution 0 'could not determine "%s" or "%s" for "%s"' 'foo' 'bar' "${RANDOM}"
action_definition 'Begin "%s" action and determine result afterwards' "foobar-${RANDOM}"
action_resolution 1 'could not determine "%s" or "%s" for "%s"' 'foo' 'bar' "${RANDOM}"
action_definition 'Begin "%s" action and determine result afterwards' "foobar-${RANDOM}"
action_resolution 255 'could not determine "%s" or "%s" for "%d"' 'foo' 'bar' "${RANDOM}"
action_def 'Begin "%s" action and determine result afterwards' "foobar-${RANDOM}"
action_res 0 'could not determine "%s" or "%s" for "%s"' 'foo' 'bar' "${RANDOM}"
action_def 'Begin "%s" action and determine result afterwards' "foobar-${RANDOM}"
action_res 1 'could not determine "%s" or "%s" for "%s"' 'foo' 'bar' "${RANDOM}"
action_def 'Begin "%s" action and determine result afterwards' "foobar-${RANDOM}"
action_res 255 'could not determine "%s" or "%s" for "%s"' 'foo' 'bar' "${RANDOM}"
write_line 'Replacements with spaces: "%s", "%d", and "%s"' 'foo bar baz' 192883 'a b c d e f g'
action_def 'Begin "%s" action using replacements with spaces "%s" and "%s"' 'foo bar baz' 'a b c d e f g'
action_res 0 'explanation using replacements with spaces: "%s" or "bar"' 'foo bar baz' 'a b c d e f g'
action_def 'Begin "%s" action using replacements with spaces "%s" and "%s"' 'foo bar baz' 'a b c d e f g'
action_res 255 'explanation using replacements with spaces: "%s" or "bar"' 'foo bar baz' 'a b c d e f g'
action_definition 'Begin "%s" action using replacements with spaces "%s" and "%s"' 'foo bar baz' 'a b c d e f g'
action_resolution 0 'explanation using replacements with spaces: "%s" or "bar"' 'foo bar baz' 'a b c d e f g'
action_definition 'Begin "%s" action using replacements with spaces "%s" and "%s"' 'foo bar baz' 'a b c d e f g'
action_resolution 255 'explanation using replacements with spaces: "%s" or "bar"' 'foo bar baz' 'a b c d e f g'
exit


if [[ -d ${SELF_WORK_PATH} ]]; then
  format_line 'Removing temporary work directory: "%s" (from prior run)\n' "${SELF_WORK_PATH}"
  rm -vdr "${SELF_WORK_PATH}"
fi

printf 'Creating temporary work directory: "%s"\n' "${SELF_WORK_PATH}"
mkdir -p "${SELF_WORK_PATH}"

printf 'Entering temporary work directory: "%s"\n' "${SELF_WORK_PATH}"
cd "${SELF_WORK_PATH}"

printf 'Fetching composer installer script: "%s"\n' "${COMP_INST_LINK}"
curl -so "${COMP_INST_FILE}" "${COMP_INST_LINK}"

printf 'Creating composer installer hash integrety definition file: "%s"\n' "${}"

printf 'Checking composer installer script matches expected file hash: "%s"\n' "${COMP_INST_HASH}"
sha384sum -c installer.sha384 --status; echo $?; "48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5  installer.php"

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
chmod u+x composer.phar
sudo mv composer.phar /usr/local/bin/composer
