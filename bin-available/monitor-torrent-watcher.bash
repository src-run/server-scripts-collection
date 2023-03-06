#!/bin/bash

##
## This file is part of the `robfrawley/twoface-scripts` project.
##
## (c) Rob Frawley 2nd <rmf@src.run>
##
## For the full copyright and license information, please view the LICENSE.md
## file that was distributed with this source code.
##

while true; do
    while [[ $(ps aux | grep magnet | grep -oE 'magnet:\?.+ -'| wc -l) -gt 0 ]]; do
        clear
        printf "Found %d magnet conversion process identifiers ... (%s)\n" "$(ps aux | grep magnet | grep -oE 'magnet:\?.+ -'| wc -l)" "$(date)"
        ps aux | grep magnet | grep -oE 'magnet:\?.+ -' | awk '{ printf "- %s\n", $1 }'
        sleep 2
    done

    clear
    echo "Found 0 magnet conversion process identifiers ... (sleeping)"
    sleep 2
done
