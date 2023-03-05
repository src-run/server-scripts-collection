#!/usr/bin/env zsh

declare -ra DEPS_LIST=(
  'autoconf'
  'automake'
  'build-essential'
  'checkinstall'
  'cmake'
  'frei0r-plugins-dev'
  'gcc'
  'git'
  'git-core'
  'gnutls-dev'
  'ladspa-sdk'
  'libaom-dev'
  'libass-dev'
  'libavc1394-0'
  'libavc1394-dev'
  'libbluray-dev'
  'libbs2b-dev'
  'libbs2b0'
  'libcaca-dev'
  'libcdio-paranoia-dev'
  'libcodec2-dev'
  'libdc1394-22'
  'libdc1394-22-dev'
  'libdrm-dev'
  'libfdk-aac-dev'
  'libfontconfig1-dev'
  'libfreetype6-dev'
  'libfribidi-dev'
  'libgme-dev'
  'libgpac-dev'
  'libgsm1-dev'
  'libiec61883-0'
  'libiec61883-dev'
  'libjack-dev'
  'liblilv-dev'
  'libmodplug-dev'
  'libmp3lame-dev'
  'libopenal-dev'
  'libopencore-amrnb-dev'
  'libopencore-amrwb-dev'
  'libopenjp2-7-dev'
  'libopenmpt-dev'
  'libopus-dev'
  'libpulse-dev'
  'librsvg2-dev'
  'librtmp-dev'
  'librubberband-dev'
  'libsdl1.2-dev'
  'libsdl2-dev'
  'libshine-dev'
  'libsmbclient-dev'
  'libsnappy-dev'
  'libsoxr-dev'
  'libspeex-dev'
  'libssh-dev'
  'libtesseract-dev'
  'libtheora-dev'
  'libtool'
  'libtwolame-dev'
  'libv4l-dev'
  'libva-dev'
  'libvdpau-dev'
  'libvo-amrwbenc-dev'
  'libvorbis-dev'
  'libvpx-dev'
  'libwebp-dev'
  'libx11-dev'
  'libx264-dev'
  'libx265-dev'
  'libxcb-shm0-dev'
  'libxcb-xfixes0-dev'
  'libxcb1-dev'
  'libxext-dev'
  'libxfixes-dev'
  'libxml2-dev'
  'libxvidcore-dev'
  'libzvbi-dev'
  'nasm'
  'opencl-dev'
  'p11-kit'
  'pkg-config'
  'texi2html'
  'texinfo'
  'wget'
  'yasm'
  'zlib1g-dev'
)

declare -r WORK_PATH="${1:-/opt/ffmpeg-sources}"
declare -r MAKE_JOBS="$(cat /proc/cpuinfo | grep processor | wc -l)"
declare -r LOGS_FILE="${WORK_PATH}/build-ffmpeg.$(date +%s).log"

declare -r FDKA_VERS='2.0.2'
declare -r FDKA_PATH="${WORK_PATH}/libs_fdkaac-${FDKA_VERS}"
declare -r FDKA_LINK='https://github.com/mstorsjo/fdk-aac.git'

declare -r LAME_VERS='3.100'
declare -r LAME_PATH="${WORK_PATH}/libs_lame-${LAME_VERS}"
declare -r LAME_LINK="https://sourceforge.net/projects/lame/files/lame/${LAME_VERS}/lame-${LAME_VERS}.tar.gz"
declare -r LAME_DLFN="${WORK_PATH}/$(basename "${LAME_LINK}")"

declare -r FMPG_VERS='4.4.2'
declare -r FMPG_PATH="${WORK_PATH}/main_ffmpeg-${FMPG_VERS}"
declare -r FMPG_LINK="https://ffmpeg.org/releases/ffmpeg-${FMPG_VERS}.tar.gz"
declare -r FMPG_DLFN="${WORK_PATH}/$(basename "${FMPG_LINK}")"

function out() {
  local    type="${1}"
  local    pref="$(printf -- '[build-ffmpeg@%.03f] (%s)' "$(date +%s\.%N)" "${type}")"
  local    cols="$(($(tput cols) - 10 - ${#pref}))"
  local -a secs=("${(@f)$(printf -- "${@:2}" | fold -s -w "${cols}" | awk '{$1=$1;print}')}")
  local    ipos=1

  if [[ ! -d "${WORK_PATH}" ]]; then
    mkdir -p "${WORK_PATH}" &> /dev/null
    out 'action' 'created working directory: "%s"' "${WORK_PATH}"
  fi

  for l in ${(v)secs}; do
    printf '# ' | tee -a "${LOGS_FILE}" 2> /dev/null
    if [[ ${ipos} -eq 1 ]]; then
      printf -- '%s' "${pref}" | tee -a "${LOGS_FILE}" 2> /dev/null
      if [[ ${#secs[@]} -le 1 ]]; then
        printf -- ' ─────▶' | tee -a "${LOGS_FILE}" 2> /dev/null
      else
        printf -- ' ──┬──▶' | tee -a "${LOGS_FILE}" 2> /dev/null
      fi
    else
      for i in {1..${#pref}}; do printf -- ' ' | tee -a "${LOGS_FILE}" 2> /dev/null; done
      if [[ ${#secs[@]} -eq ${ipos} ]]; then
        printf -- '   └──▶' | tee -a "${LOGS_FILE}" 2> /dev/null
      else
        printf -- '   ├──▶' | tee -a "${LOGS_FILE}" 2> /dev/null
      fi
    fi
    printf ' %s\n' "${l}" | tee -a "${LOGS_FILE}" 2> /dev/null
    ipos=$((ipos + 1))
  done
}

function err() {
  out 'failed' "${@}"
  out 'failed' 'exiting due to prior error...'
  exit 1
}

out 'logger' 'writing command output to file "%s"' "${LOGS_FILE}"

for f in "${LAME_DLFN}" "${FMPG_DLFN}"; do
  if [[ -f "${f}" ]]; then
    out 'cleans' 'removing existing dependency release archive: "%s"' "${f}"
    rm -f "${f}" &>>| "${LOGS_FILE}" || err 'failed to remove file "%s"' "${f}"
  fi
done

for d in "${FDKA_PATH}" "${LAME_PATH}" "${LAME_PATH}"; do
  if [[ -d "${d}" ]]; then
    out 'cleans' 'cleaning up existing build directory: "%s"' "${d}"
    rm -fr "${d}" &>>| "${LOGS_FILE}" || err 'failed to remove directory "%s"' "${d}"
  fi
done

out 'system' 'updading package caches'
DEBIAN_FRONTEND=noninteractive apt-get update < /dev/null &>>| "${LOGS_FILE}"

out 'system' 'updading system packages'
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade < /dev/null &>>| "${LOGS_FILE}"

out 'system' 'installing dependencies: "%s"' "$(sed -E 's/[ ]/, /g' <<< "${DEPS_LIST[*]}")"
DEBIAN_FRONTEND=noninteractive apt-get -y install ${(v)DEPS_LIST} < /dev/null &>>| "${LOGS_FILE}" || err 'failed to install dependencies!'

#out 'action' 'entering working directory: "%s"' "${WORK_PATH}"
#cd "${WORK_PATH}" &>>| "${LOGS_FILE}" || err 'failed to enter directory!'
#
#out 'source' 'cloning tag "%s" of repository "%s" to "%s"' "${FDKA_VERS}" "${FDKA_LINK}" "${FDKA_PATH}"
#git clone --depth 1 -b "v${FDKA_VERS}" "${FDKA_LINK}" "${FDKA_PATH}" &>>| "${LOGS_FILE}" || err 'failed to clone repository!'
#
#out 'action' 'entering dependency source directory: "%s"' "${FDKA_PATH}"
#cd "${FDKA_PATH}" &>>| "${LOGS_FILE}" || err 'failed to enter directory!'
#
#out 'builds' 'configuring source of libfdk-acc'
#autoreconf -fiv &>>| "${LOGS_FILE}" || err 'failed to run autoreconf!'
#./configure \
#  --prefix="${WORK_PATH}" \
#  --enable-shared \
#    &>>| "${LOGS_FILE}" || err 'failed to run configure!'
#
#out 'builds' 'compiling libfdk-acc using %d jobs' "${MAKE_JOBS}"
#make -j${MAKE_JOBS} &>>| "${LOGS_FILE}" || err 'failed to run make!'
#
#out 'builds' 'installing libfdk-acc to prefix "%s"' "${WORK_PATH}"
#make install &>>| "${LOGS_FILE}" || err 'failed to run make install!'
#
#out 'builds' 'cleaning up source build artifacts'
#make distclean &>>| "${LOGS_FILE}" || err 'failed to run make distclean!'
#
#out 'action' 'entering working directory: "%s"' "${WORK_PATH}"
#cd "${WORK_PATH}" &>>| "${LOGS_FILE}" || err 'failed to enter directory!'
#
#out 'action' 'creating dependency source directory: "%s"' "${LAME_PATH}"
#mkdir -p "${LAME_PATH}" &>>| "${LOGS_FILE}" || err 'failed to create directory!'
#
#out 'source' 'downloading release "%s" from "%s" to "%s"' "${LAME_VERS}" "${LAME_LINK}" "${LAME_DLFN}"
#wget "${LAME_LINK}" -O "${LAME_DLFN}" &>>| "${LOGS_FILE}" || err 'failed to download release archive!'
#
#out 'source' 'extracting "%s" to "%s"' "${LAME_DLFN}" "${LAME_PATH}"
#tar -xzvf "${LAME_DLFN}" -C "${LAME_PATH}" --strip-components=1 &>>| "${LOGS_FILE}" || err 'failed to extract release archive!'
#
#out 'action' 'entering dependency source directory: "%s"' "${LAME_PATH}"
#cd "${LAME_PATH}" &>>| "${LOGS_FILE}" || err 'failed to enter directory!'
#
#out 'builds' 'configuring source of liblame'
#./configure \
#  --prefix="${WORK_PATH}" \
#  --enable-nasm \
#  --enable-shared \
#    &>>| "${LOGS_FILE}" || err 'failed to run configure!'
#
#out 'builds' 'compiling liblame using %d jobs' "${MAKE_JOBS}"
#make -j${MAKE_JOBS} &>>| "${LOGS_FILE}" || err 'failed to run make!'
#
#out 'builds' 'installing liblame to prefix "%s"' "${WORK_PATH}"
#make install &>>| "${LOGS_FILE}" || err 'failed to run make install!'
#
#out 'builds' 'cleaning up source build artifacts'
#make distclean &>>| "${LOGS_FILE}" || err 'failed to run make distclean!'

out 'action' 'entering working directory: "%s"' "${WORK_PATH}"
cd "${WORK_PATH}" &>>| "${LOGS_FILE}" || err 'failed to enter directory!'

out 'action' 'creating dependency source directory: "%s"' "${FMPG_PATH}"
mkdir -p "${FMPG_PATH}" &>>| "${LOGS_FILE}" || err 'failed to create directory!'

out 'source' 'downloading release "%s" from "%s" to "%s"' "${FMPG_VERS}" "${FMPG_LINK}" "${FMPG_DLFN}"
wget "${FMPG_LINK}" -O "${FMPG_DLFN}" &>>| "${LOGS_FILE}" || err 'failed to download release archive!'

out 'source' 'extracting "%s" to "%s"' "${FMPG_DLFN}" "${FMPG_PATH}"
tar -xzvf "${FMPG_DLFN}" -C "${FMPG_PATH}" --strip-components=1 &>>| "${LOGS_FILE}" || err 'failed to extract release archive!'

out 'action' 'entering dependency source directory: "%s"' "${FMPG_PATH}"
cd "${FMPG_PATH}" &>>| "${LOGS_FILE}" || err 'failed to enter directory!'

out 'builds' 'configuring source of ffmpeg'
export PKG_CONFIG_PATH="${WORK_PATH}/lib/pkgconfig"
./configure \
	--prefix="${WORK_PATH}" \
	--bindir="${WORK_PATH}/bin" \
  --disable-stripping \
	--enable-avresample \
	--enable-frei0r \
	--enable-gmp \
	--enable-gnutls \
	--enable-gpl \
	--enable-ladspa \
	--enable-libaom \
	--enable-libass \
	--enable-libbluray \
	--enable-libbs2b \
	--enable-libcaca \
	--enable-libcdio \
	--enable-libcodec2 \
	--enable-libdc1394 \
	--enable-libdrm \
	--enable-libfdk-aac \
	--enable-libfontconfig \
	--enable-libfreetype \
	--enable-libfribidi \
	--enable-libgme \
	--enable-libgsm \
	--enable-libiec61883 \
	--enable-libjack \
	--enable-libmodplug \
	--enable-libmp3lame \
	--enable-libopencore-amrnb \
	--enable-libopencore-amrwb \
	--enable-libopenjpeg \
	--enable-libopenmpt \
	--enable-libopus \
	--enable-libpulse \
	--enable-librsvg \
	--enable-librtmp \
	--enable-librubberband \
	--enable-libshine \
	--enable-libsnappy \
	--enable-libsoxr \
	--enable-libspeex \
	--enable-libssh \
	--enable-libtesseract \
	--enable-libtheora \
	--enable-libtwolame \
	--enable-libv4l2 \
	--enable-libvo-amrwbenc \
	--enable-libvorbis \
	--enable-libvpx \
	--enable-libwebp \
	--enable-libx264 \
	--enable-libx265 \
	--enable-libxml2 \
	--enable-libxvid \
	--enable-libzvbi \
	--enable-lv2 \
	--enable-nonfree \
	--enable-openal \
	--enable-opencl \
	--enable-opengl \
	--enable-sdl2 \
	--enable-small \
	--enable-version3 \
  --enable-shared \
	--extra-version="0ubuntu0.2" \
	--toolchain="hardened" \
    &>>| "${LOGS_FILE}" || err 'failed to run configure!'

#  --incdir="/usr/include/x86_64-linux-gnu" \
#  --libdir="/usr/lib/x86_64-linux-gnu" \

out 'builds' 'compiling ffmpeg using %d jobs' "${MAKE_JOBS}"
make -j${MAKE_JOBS} &>>| "${LOGS_FILE}" || err 'failed to run make!'

out 'builds' 'installing ffmpeg to prefix "%s" using bin directory "%s"' "${WORK_PATH}" "${WORK_PATH}/bin"
make install &>>| "${LOGS_FILE}" || err 'failed to run make install!'

out 'builds' 'cleaning up source build artifacts'
make distclean &>>| "${LOGS_FILE}" || err 'failed to run make distclean!'
