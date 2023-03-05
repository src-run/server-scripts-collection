#!/usr/bin/env zsh

declare -a BACK_PATHS=(
    '/code/'
    '/var/lib/sonarr/'
    '/home/ans/'
    '/home/linuxbrew/'
    '/home/rmf/'
    '/home/rto/'
    '/home/rtorrent/'
    '/home/srl/'
    '/home/stream/'
)

declare -a POOL_BASE_PATH_NAMES=(
    'backups'
    'backup-twoface'
    'cloud'
    'documents'
    'games'
    'google-drive'
    'openvpn-rto'
    'opt'
    'plexmediaserver'
    'projects'
    'repositories'
    'scripts'
    'scripts-rmf'
    'scripts-rto'
    'software'
    'torrent'
    'var'
    'vms'
    'web'
)

declare -a RSYNC_RUN_OPTS=()

for p in ${(v)POOL_BASE_PATH_NAMES}; do
    declare source_path="/pool/${p}/"
    declare target_path="/tank/pool/${p}/"

    RSYNC_RUN_OPTS+=("${source_path}" "${target_path}")
done

for p in ${(v)BACK_PATHS}; do
    declare source_path="$(sed -E 's/\/+/\//g' <<< "${p}")"
    declare target_path="/tank/pool/backup-twoface-2205/$(sed -E 's/\//--/g' <<< "${source_path}" | sed -E 's/(^-+|-+$)//g')/"

    RSYNC_RUN_OPTS+=("${source_path}" "${target_path}")
done

printf -- '##\n## date_time => "%s"\n## path_list => array(\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')"

i=1
for p in ${(v)RSYNC_RUN_OPTS}; do
    printf -- '##           %02i -> "%s"\n' \
        "${i}" \
        "${p}"
    i=$((i + 1))
done

printf '## ) [%d items]\n##\n' \
    "${#RSYNC_RUN_OPTS[@]}"

printf -- '--\n-- Press ENTER to continue (use ^C to cancel) ...\n--\n'
read

RSYNC_NON_INTERACTIVE=1 /home/rmf/rsync-run.bash 2 6 "${(@v)RSYNC_RUN_OPTS}"
