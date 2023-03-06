#!/bin/bash

##
## This file is part of the `src-run/user-scripts-server` project.
##
## (c) Rob Frawley 2nd <rmf@src.run>
##
## For the full copyright and license information, please view the LICENSE.md
## file that was distributed with this source code.
##

bash $(dirname "$(readlink -m "${0}")")/ip-info.bash -i=enp7s0 -m -q -r | tr -d '\n'
