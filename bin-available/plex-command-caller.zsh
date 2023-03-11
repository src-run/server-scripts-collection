#!/usr/bin/env zsh

function main()
{
    local -r  call_name="${1}"
    local -ra call_opts=("${@:2}")
    local -r  call_user='plex'
    local -r  dflt_path='/usr/lib/plexmediaserver'
    local -r  call_path="$(
        command -v "${call_name}" || \
            printf -- '%s/%s\n' "${dflt_path}" "${call_name}"
    )"
    local -r  sudo_text='Please enter the %p user password to run command as the "%U" user: '

    printf -- '##\n## CALL: sudo --login --user="%s" -- "%s" %s\n##\n' \
        "${call_user}" \
        "${call_path}" \
        "$(printf -- '"%s" ' "${(@v)call_opts}")"

    if [[ ! -x "${call_path}" ]]; then
        printf -- '!! FAIL: Command "%s" not found in PATH or default directory of "%s"!\n' "${call_name}" "${dflt_path}" >&2
        return 1
    fi

    if ! id "${call_user}" &>/dev/null; then
        printf -- '!! FAIL: User "%s" does not exist!\n' "${call_user}" >&2
        return 1
    fi

    sudo --login --user="${call_user}" --prompt="${sudo_text}" -- "${call_path}" "${(@v)call_opts}"
}

main "${@}"
