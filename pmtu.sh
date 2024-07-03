#! /bin/sh
#edit by stev-o - find the MTU available for current network

#Usage: $0 <exthost>
#
#$0 = Me
#<exthost> = custom host used for test, different from built-in ones, needed if they go down or close: this is optional
#
#P.S.:due to a limitation of busybox "ping" command, make sure the hosts passed reject fragmented packet, otherwise the test will be compromized...

export PATH=$PATH:"/usr/sbin:/bin:/usr/bin:/sbin"

MTU="32"
STEP="750"
STROKES_LIMIT="30"
PACKETS_HEADER="28"
HOST_1="www.grc.com"  #Hosts MUSTN'T reply packets greater than effective MTU so not all hosts are GOOD for test...
HOST_2="dns.it.net"
HOST_3="www.libero.it"
HOST_EXT="$1"

probe() {  #ping host with one icmp-echo packet of variable size: the output is passed through various shell filters
    if [ "$HOST" != "" ]; then  #avoid processing NULL, if exthost is not given
    echo "Sending $MTU bytes to $HOST"
    ping -s $MTU -c "1" $HOST > /dev/null 2>&1
    RESULT=$?
    #recursive output message
        if [ "$RESULT" = "0" ]; then
        echo "----> Contiguous"
        else
        echo "----> Fragmented"
        fi
    echo
    fi
}

answer() {
    echo
    echo "It's reasonable to say that $MTU_LASTGOOD bytes is the largest contiguous packet size ($MTU includes $PACKETS_HEADER ICMP/IP Headers)"
    echo
    echo "MTU should be set to $MTU"
    echo
}

#Let's start testing, with a small echo-packet, if the host is at least reachable
for HOST in "$HOST_EXT" "$HOST_1" "$HOST_2" "$HOST_3"
do
    probe
    if [ "$RESULT" = "0" ]; then  #If the 1st host fails, try the others
    HOSTGOOD="1"
    break
    else
    HOSTGOOD="0"
    fi
done

#No valid hosts founded: exit...
if [ "$HOSTGOOD" != "1" ]; then
echo "No reachable hosts"
exit 1
fi

#The host is pingable, so let's go on with larger packets....
MTU="$STEP"
STROKES="0"
while [ "$STROKES" -lt "$STROKES_LIMIT" ]
do
    STEP=`expr "$STEP" / 2 + "$STEP" % 2`
    probe
        if [ "$RESULT" = "0" ]; then
            if [ "$MTU" = "$MTU_LASTGOOD" ]; then
            break
            else
            MTU_LASTGOOD="$MTU"
            MTU=`expr "$MTU" + "$STEP"`
            fi
        else
        MTU=`expr "$MTU" - "$STEP"`
        fi
    STROKES=`expr "$STROKES" + 1`  #limit the max loop retries in case of successive host failures
done

#Maximum retries value reached: exit...
if [ "$STROKES" = "$STROKES_LIMIT" ]; then
echo
echo "Test limit exceeded"
exit 2
fi

#Add ICMP default header to the found value
MTU=`expr "$MTU" + "$PACKETS_HEADER"`
answer
