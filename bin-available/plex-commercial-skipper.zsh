#!/usr/bin/env zsh

function main()
{
    local -r  extn_name='Plex Commercial Skipper'
    local -ra call_opts=("${@}")
    local -r  call_name='plex-command-caller.zsh'
    local -r  self_path="${${(%):-%x}:A:h}"

    "${self_path}/${call_name}" "${extn_name}" "${(@v)call_opts}"
}

main "${@}"
