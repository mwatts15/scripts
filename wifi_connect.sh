#!/bin/sh

# Uses NetworkManager's nmcli to get information about access points,
# finds the one with the best signal and connects to it.
#
# Although there is iw* tools, nmcli has a simpler syntax

AUTO_CHOOSE=0
WC_CACHE=~/.wifi_connect_list

message ()
{
    kill $MESSAGE_PID 2>/dev/null
    twmnc --duration 2000 --title NetworkManager --content "${@}" 2>/dev/null
    MESSAGE_PID=$!
}

ARGS=$(getopt -o a -l auto -n "$0" -- "$@")
eval set -- "$ARGS"

n=0
limit=10

while [ $n -lt $limit ] ; do
    opt=$1;
    shift
    case "$opt" in
        -a|--auto)
            AUTO_CHOOSE=1
            ;;
        --)
            break;
            ;;
    esac
    $(( n = n+1))
done

connlist="$(nmcli -f name con |
tail -n +2  |
cat $WC_CACHE - | 
sed -r 's/^[[:space:]]+|[[:space:]]+$//g' |
egrep -e '.+' |
awk '!x[$0]++' -)"
connlist="$connlist
@new"

ncons=$(echo "$connlist" | wc -l)

limit=10
n=0
while [ $n -lt $limit ] ; do
    if [ $AUTO_CHOOSE -eq 1 ] ; then
        c=$(echo "$connlist" | head -n 1)
    else
        c=$(echo "$connlist" | dmenu -p "Which connection do you want?" -l $ncons)
    fi

    if [ "x$c" = x ] ; then 
        exit 0
    fi
    if [ "$c" = "@new" ] ; then
        aplist=$(nmcli -f bssid,ssid,signal,bars,chan,security,mode dev wifi 2>/dev/null | tail -n +2)
        apcount=$(echo "$aplist" | wc -l)
        c=$(echo "$aplist" | dmenu -p "Which AP?" -l $apcount | cut -f1 -d' ')
        nmcli dev wifi connect "$c"
        break
    else
        message "Attempting to connect to '$c'" & 

        timeout 10 nmcli con up id "$c" && message "connected." && break
        connlist="$(echo "$connlist" | grep -v "$c")\n$c"

        n=$((n+1))
    fi
done
