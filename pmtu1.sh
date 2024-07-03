#!/usr/bin/env bash

MTU=32
STEP=750
STROKES_LIMIT="30"
PACKETS_HEADER="28"
HOST=${1:-1.1.1.1}

probe() {
    if [ "$HOST" != "" ]; then
        ping -s $MTU -c "1" -M do $HOST > /dev/null 2>&1
        RESULT=$?
    fi
}

MTU="$STEP"
STROKES="0"
while [ "$STROKES" -lt "$STROKES_LIMIT" ]; do
    STEP=`expr "$STEP" / 2 + "$STEP" % 2`

    echo -n "[$STROKES/$STROKES_LIMIT] Sending $MTU bytes to $HOST"
    probe
    if [ "$RESULT" = "0" ]; then
        echo "  ----> NOT fragmented"
        if [ "$MTU" == "$MTU_LASTGOOD" ]; then
            break
        else
            MTU_LASTGOOD="$MTU"
            MTU=`expr "$MTU" + "$STEP"`
        fi
    else
        echo "  ----> fragmented"
        MTU=`expr "$MTU" - "$STEP"`
    fi
    STROKES=`expr "$STROKES" + 1`
done

if [ "$STROKES" = "$STROKES_LIMIT" ]; then
echo
echo "Test limit exceeded"
exit 2
fi

MTU=`expr "$MTU" + "$PACKETS_HEADER"`
echo
echo "MTU: $MTU bytes (= $MTU_LASTGOOD bytes payload + $PACKETS_HEADER bytes ICMP/IP Headers)"
