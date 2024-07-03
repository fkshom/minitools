#!/bin/sh
# save as e.g. $HOME/.local/bin/cacheme
# and then chmod u+x $HOME/.local/bin/cacheme
# https://stackoverflow.com/questions/11900239/can-i-cache-the-output-of-a-command-on-linux-from-cli

# USAGE:
#   cacheme.sh 5 command
#   cacheme.sh command
VERBOSE=false
PROG="$(basename $0)"
DIR="${HOME}/.cache/${PROG}"
mkdir -p "${DIR}"
EXPIRY=600 # default to 10 minutes
# check if first argument is a number, if so use it as expiration (seconds)
[ "$1" -eq "$1" ] 2>/dev/null && EXPIRY=$1 && shift
[ "$VERBOSE" = true ] && echo "Using expiration $EXPIRY seconds"
CMD="$@"
HASH=$(echo "$CMD" | md5sum | awk '{print $1}')
CACHE="$DIR/$HASH"
test -f "${CACHE}" && [ $(expr $(date +%s) - $(date -r "$CACHE" +%s)) -le $EXPIRY ] || eval "$CMD" > "${CACHE}"
cat "${CACHE}"
