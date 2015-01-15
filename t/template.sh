#!/bin/bash
#
# This shell script is generic. To use it to wrap an AppleScript test file,
# just create a symlink to this file and name the symlink with the same
# basename as the AppleScript file that's being wrapped. For example:
#
#     t/
#     |-- 0001-first.applescript
#     |-- 0001-first.sh -> template.sh
#     `-- template.sh

PROGNAME="${0##*/}"
PROGNAME="${PROGNAME%.*}"
PROGDIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"

script -q /dev/null /usr/bin/osascript ${PROGDIR}/${PROGNAME}.applescript "$@"

exit
