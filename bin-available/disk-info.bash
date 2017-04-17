#!/bin/bash

# exit on error
set -e

# internal variables
VERSION="0.1.0"
LSBLK_BIN="$(which lsblk)"

# behavior variables
OUTPUT_COLUMNS_DEFAULT_SIMPLE="NAME,FSTYPE,SIZE"
OUTPUT_COLUMNS_DEFAULT_EXTENDED="NAME,TYPE,FSTYPE,SIZE,UUID,MAJ:MIN,RM,RO,LABEL,MOUNTPOINT"
OUTPUT_COLUMNS=""
OUTPUT_OVERWRITE=1

# get script base name
function scriptBasename() {
  echo "$(basename $(realpath $BASH_SOURCE))"
}

# display script usage
function usage() {
  echo -en "Usage: ./$(scriptBasename) [OPTIONS]\n"
  echo -en "\t--version Show the script version.\n"
  echo -en "\t--help    Show this help text.\n"
  echo -en "\t-e        Extended default columns.\n"
  echo -en "\t-a        Add to the default columns (by default, only the columns specified will be shown)"
  echo -en "\t-o=COL    Specify columns to output for lsblk [NAME,FSTYPE,LABEL,UUID,MOUNTPOINT,SIZE,...]\n"
}

# parse script arguments
for arg in "$@"
do
  case $arg in
    --help)
      writeUsage
      exit 0
      ;;
    --version)
      writeVersion
      exit 0
      ;;
    -e)
      OUTPUT_COLUMNS_DEFAULT_SIMPLE="${OUTPUT_COLUMNS_DEFAULT_EXTENDED}"
      ;;
    -a)
      OUTPUT_OVERWRITE=0
      ;;
    -o=*)
      OUTPUT_COLUMNS="${OUTPUT_COLUMNS},${arg#*=}"
      ;;
  esac
done

# use user-provided columns or defaults
if [[ "${OUTPUT_COLUMNS}" != "" ]]; then
    OUTPUT_COLUMNS="${OUTPUT_COLUMNS:1}"
else
    OUTPUT_COLUMNS="${OUTPUT_COLUMNS_DEFAULT_SIMPLE}"
fi

# should columns overwrite or add to?
if [[ "${OUTPUT_OVERWRITE}" == 0 ]]; then
    OUTPUT_COLUMNS="+${OUTPUT_COLUMNS}"
fi

# call command
${LSBLK_BIN} -o ${OUTPUT_COLUMNS}

# EOF
