#!/bin/bash

FILEPATH="$(realpath ${1:-./})"
FULLSIZE="${2:-0}"
WAITUSER="${3:-10}"

while true
do
    clear

    echo -en "Monitoring PATH \"$FILEPATH\" ON \"$(date)\"\n\n"
    du -h --max-depth=1 $FILEPATH

    if [[ "$FULLSIZE" -ne "0" ]]
    then
        SIZE="$(du --max-depth=0 $FILEPATH | grep -oE '[0-9]+')"
        echo -en "\nTransfer complete: $(echo "scale=2; $SIZE * 100 / $FULLSIZE" | bc)%\n"
    fi

    WAITTIME=$WAITUSER
    echo -en "\nSleeping for ${WAITTIME} seconds: "

    while [[ $WAITTIME -gt 0 ]]
    do
        echo -en "."
        sleep 1
        WAITTIME="$(echo "$WAITTIME - 1" | bc)"
    done
done
