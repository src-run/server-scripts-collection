#!/bin/zsh

##
## This file is part of the `src-run/user-scripts-server` project.
##
## (c) Rob Frawley 2nd <rmf@src.run>
##
## For the full copyright and license information, please view the LICENSE.md
## file that was distributed with this source code.
##

printf '\n##\n## robfrawley/zsh-env\n## Wrapper script to ensure ZSH environment is properly loaded for the command being called.\n##\n\n'

if [[ -z "${ZSH}" ]] && [[ -r "${HOME}/.zshrc" ]]; then
    printf -- '-- Sourcing zshrc environment loader ... (found at "%s")\n' "${HOME}/.zshrc"
    source "${HOME}/.zshrc" &> /dev/null
else
    printf -- '-- Skipping zshrc environment loader ... (found it has already been loaded)\n'
fi

CALL_EXEC="${1}"; shift

printf -- '-- Invoking passed command and arguments ... (calling "%s")\n' ""${CALL_EXEC}" "${@}""
printf -- '!! Pausing for 10 seconds. Cancel using CNTL-C [00'

SLEEP_TICK=40
SLEEP_SECS=0

for i in $(seq 1 ${SLEEP_TICK}); do
  if [[ $((i % 4)) == 0 ]]; then
    ((SLEEP_SECS++))
    printf '%02d' "${SLEEP_SECS}"
  else
    printf '.'
  fi

  sleep 0.25
done

printf ']\n'

sleep 1 && clear

"${CALL_EXEC}" "${@}"

