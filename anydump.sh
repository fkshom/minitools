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
    echo "Usage: $PROGNAME [-w] [-i INTERFACE[,INTERFACE]] [-i INTERFACE[,INTERFACE]] [TCPDUMP_ARGS] [--] [TCPDUMP_ARGS]"
    echo
    echo "Options:"
    echo "  -h, --help"
    echo "  -i INTERFACE"
    echo "  -w: Write the raw packets to a file in pcap format."
    echo
    echo "Sample"
    echo "  $PROGNAME -i ens33,ens37 -i tun0 -s 100 --no-promiscuous-mode -nn -A icmp or port (53 or 5355)"
    exit 1
}

declare -a INTERFACES=()
declare -i ENABLE_WRITE_FILE=0
declare -a TCPDUMP_ARGS=()

set -x
while :; do
    [ "${1}" == '' ] && break
    case "${1}" in
        --)
            shift 1
            TCPDUMP_ARGS+=( "$@" )
            set --  #$@ を空にする
            break
            ;;
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
            IFS=',' read -r -a tmp <<< "$2"
            INTERFACES+=( "${tmp[@]}" )
            unset IFS tmp
            shift 2
            ;;
        *)
            if [[ ! -z "$1" ]]; then
                TCPDUMP_ARGS+=( "$1" )
                shift 1
            fi
            ;;
    esac
done

if [ -z "${INTERFACES}" ]; then
    INTERFACES=$(ls /sys/class/net)
fi

echo INTERFACES: "${INTERFACES[@]}"
echo TCPDUMP_ARGS: "${TCPDUMP_ARGS[@]}"
echo ENABLE_WRITE_FILE: "${ENABLE_WRITE_FILE}"

mytcpdump(){
  interface=$1
  interface_label=`printf %5s $interface`
  now=$(date +"%Y%m%d_%H%M%S")
  [ "${ENABLE_WRITE_FILE}" -eq 1 ] && output=${interface}_${now}.pcap || output=/dev/null

  tcpdump -U -l --immediate-mode -i $interface -w $output --print ${TCPDUMP_ARGS[@]} \
          | sed -u 's/^/['"$interface_label"'] /' 2>/dev/null
}

watch_interface_and_capture(){
  interface=$1
  while :; do
    if [ -e /sys/class/net/$interface ]; then
      mytcpdump $interface
    else
      ip monitor link | while read -r line; do
          if echo "$line" | grep -q "$interface.*UP,LOWER_UP" >/dev/null; then
              echo "Interface $interface is created. Start tcpdump." >&2
              mytcpdump $interface
          fi
      done
    fi
  done
}

for interface in ${INTERFACES[@]}; do
    watch_interface_and_capture $interface &
done
wait

