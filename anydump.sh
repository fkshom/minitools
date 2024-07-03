#!/usr/bin/env bash
#===================================================================================
#
# FILE: dump.sh
# USAGE: dump.sh [-i interface] [tcpdump-parameters]
# DESCRIPTION: tcpdump on any interface and add the prefix [Interace:xy] in front of the dump data.
# OPTIONS: same as tcpdump
# AUTHOR: Sebastian Haas
# VERSION: 1.2
# CREATED: 16.09.2014
# REVISION: 22.09.2014
#
#===================================================================================

# When this exits, exit all background processes:
trap 'kill $(jobs -p) &> /dev/null && sleep 0.2 &&  echo ' EXIT

# anydump.sh -w -i ens1 -i ens2 -nn icmp
PROGNAME=$(basename $0)
usage() {
    echo "Usage: $PROGNAME [-i INTERFACE [-i INTERFACE]] [TCPDUMP OPTIONS] [FILTER EXPRESSION}"
    echo
    echo "Options:"
    echo "  -h, --help"
    echo "  -i INTERFACE"
    echo
    echo "Sample"
    echo "  $PROGNAME -i ens33 -i ens37 -nn icmp or port (53 or 5355)"
    exit 1
}

declare -a INTERFACES=()
declare -a FILTEREXPRESSIONS=()
declare -a CAPTUREOPTS=()
declare -a PRINTOPTS=()
declare -i ENABLE_WRITE_FILE=0

for OPT in "$@"; do
    case $OPT in
        -h | --help)
            usage
            exit 1
            ;;
        -w)
            ENABLE_WRITE_FILE=1
            shift 1
            ;;
        -i)
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$PROGNAME: option requires an argument -- $1" 1>&2
                exit 1
            fi
            INTERFACES+=( "$2" )
            shift 2
            ;;
        +*)
            CAPTUREOPTS+=( "-${1:1}" )
            shift 1
            ;;
        -*)
            PRINTOPTS+=( "-${1:1}" )
            shift 1
            ;;
        --)
            shift 1
            FILTEREXPRESSIONS+=( "$@" )
            break
            ;;
        *)
            if [[ ! -z "$1" ]] && [[ ! "$1" =~ ^-+ ]]; then
                FILTEREXPRESSIONS+=( "$1" )
                shift 1
            fi
            ;;
    esac
done

if [ -z "${INTERFACES}" ]; then
    INTERFACES=$(ls /sys/class/net)
fi

echo "INTERFACES: ${INTERFACES[@]}"
echo "CAPTUREOPTS: ${CAPTUREOPTS[@]}"
echo "PRINTOPTS: ${PRINTOPTS[@]}"
echo "FILTEREXPRESSIONS: ${FILTEREXPRESSIONS[@]}"

for interface in ${INTERFACES[@]}; do
    interface=`printf %5s $interface`
    if [ "${ENABLE_WRITE_FILE}" -eq 1 ]; then
      tcpdump -U --immediate-mode -i $interface -w - -nn ${CAPTUREOPTS[@]} ${FILTEREXPRESSIONS[@]} 2>/dev/null \
          | tee $interface.pcap \
          | tcpdump -l -r - ${PRINTOPTS[@]} 2>/dev/null \
          | sed -u 's/^/['"$interface"'] /' 2>/dev/null &
    else
      tcpdump -U --immediate-mode -p -i $interface -w - -nn ${CAPTUREOPTS[@]} ${FILTEREXPRESSIONS[@]} 2>/dev/null \
          | tcpdump -l -r - ${PRINTOPTS[@]} 2>/dev/null \
          | sed -u 's/^/['"$interface"'] /' 2>/dev/null &
    fi
done
wait
exit

# Create one tcpdump output per interface and add an identifier to the beginning of each line:
if [[ $@ =~ -i[[:space:]]?[^[:space:]]+ ]]; then
    tcpdump -l $@ | sed 's/^/['"${BASH_REMATCH[0]:2}"'] /' &
else
#    for interface in $(ifconfig | grep '^[a-z0-9]' | awk '{print $1}'i | sed "/:[0-9]/d")
    for interface in $(ls /sys/class/net)
    do
       tcpdump -U -i $interface -w - -nn $@ | tee $interface.pcap | tcpdump -l -r - | sed 's/^/['"$interface"'] /' 2>/dev/null &
    done
fi
# wait .. until CTRL+C
wait
