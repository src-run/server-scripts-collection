#!/usr/bin/env zsh

function main()
{
    local -r  call_name="${1}"
    local -ra call_opts=("${@:2}")
    local -r  call_user='plex'
    local -r  vars_path='/var/lib/plexmediaserver'
    local -r  libs_path='/usr/lib/plexmediaserver'
    local -r  call_path="$(
        command -v "${call_name}" || \
            printf -- '%s/%s\n' "${libs_path}" "${call_name}"
    )"
    local -r  sudo_text='Please enter the %p user password to run command as the "%U" user: '

    printf -- '##\n## CALL: sudo --login --user="%s" -- "%s" %s\n##\n' \
        "${call_user}" \
        "${call_path}" \
        "$(printf -- '"%s" ' "${(@v)call_opts}")"

    if [[ ! -x "${call_path}" ]]; then
        printf -- '!! FAIL: Command "%s" not found in PATH or default directory of "%s"!\n' "${call_name}" "${libs_path}" >&2
        return 1
    fi

    if ! id "${call_user}" &>/dev/null; then
        printf -- '!! FAIL: User "%s" does not exist!\n' "${call_user}" >&2
        return 1
    fi

    export LD_LIBRARY_PATH="${libs_path}"
    export PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR="${vars_path}/Library/Application Support"
    export PLEX_MEDIA_SERVER_HOME="${libs_path}"
    export PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS="$(lscpu | grep '^Core' | grep -oE '[0-9]+$')"
    export PLEX_MEDIA_SERVER_INFO_VENDOR="$(grep '^NAME=' /etc/os-release | awk -F= '{print $2}' | tr -d \")";
    export PLEX_MEDIA_SERVER_INFO_DEVICE="PC";
    export PLEX_MEDIA_SERVER_INFO_MODEL="$(uname -m)";
    export PLEX_MEDIA_SERVER_INFO_PLATFORM_VERSION="$(grep '^VERSION=' /etc/os-release | awk -F= '{print $2}' | tr -d \")";

    sudo \
        --login \
        --user="${call_user}" \
        --preserve-env='LD_LIBRARY_PATH,PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR,PLEX_MEDIA_SERVER_HOME,PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS,PLEX_MEDIA_SERVER_INFO_VENDOR,PLEX_MEDIA_SERVER_INFO_DEVICE,PLEX_MEDIA_SERVER_INFO_MODEL,PLEX_MEDIA_SERVER_INFO_PLATFORM_VERSION' \
        --prompt="${sudo_text}" \
        -- \
        "${call_path}" "${(@v)call_opts}"
}

main "${@}"
