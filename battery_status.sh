#!/bin/sh -e

OUT="/tmp/${USER}-battery-status-pipe"
MYPID=$$
PIPESDIR=$(mktemp -d --suffix="-battery-status")
ETPIDFILE=$(mktemp -p $PIPESDIR)
LAST_UPDATE_FILE="$PIPESDIR/last_up"

if [ ! -e $OUT -o ! -p $OUT  ] ; then
    rm -f $OUT
    mkfifo -m 0777 $OUT || echo "couldn't make the pipe!" >&2 && exit 1;
fi

thresh_time=1 # At most, one event per second from acpi_listen

_notify_15=0  # Status variable for whether we've notified about battery charge 15%

should_update () {
    if [ -f "$LAST_UPDATE_FILE" ] ; then
        last_update=$(cat "$LAST_UPDATE_FILE")
    else
        last_update=0
    fi
    now=$(date +'%s')
    if [ $(( last_update + thresh_time )) -lt $now ] ; then
        return 0
    fi
    return 1
}

pass () {
   return 0
}

update_status () {
    should_update || return 0
    if [ -f /sys/class/power_supply/BAT0/charge_now ] ; then 
        charge_now_file=/sys/class/power_supply/BAT0/charge_now
        charge_full_file=/sys/class/power_supply/BAT0/charge_full
    elif [ -f /sys/class/power_supply/BAT0/energy_now ] ; then 
        charge_now_file=/sys/class/power_supply/BAT0/energy_now
        charge_full_file=/sys/class/power_supply/BAT0/energy_full
    else
        echo "Could not find the charge file"
        return 1
    fi

    charge_now=$(cat $charge_now_file)
    charge_full=$(cat $charge_full_file)
    charge_perc=$(echo "scale=0; 100 * $charge_now / $charge_full" | bc -lq)
    ac_on=$(cat /sys/class/power_supply/AC/online)
    status='<fc=#ff0000>BAT</fc>'
    scode=0
    if [ $ac_on -eq 1 ] ; then
        status=" AC"
        scode=1
    fi
    if [ $_notify_15 -ne 1 -a $charge_perc -le 15 -a $scode -ne 1 ] ; then
        _notify_15=1
        notify-send -u critical "Warning battery charge is only $charge_perc%"
    elif [ $_notify_15 -eq 1 -a $charge_perc -gt 15 ] ; then
        _notify_15=0
    fi
    if [ $charge_perc -lt 10 ] ; then
        charge_perc="<fc=#ff0000>$charge_perc</fc>"
    fi
    printf "%3s %3s%%\n" "${status}" "${charge_perc}" > $OUT
    date +'%s' > "$LAST_UPDATE_FILE"
}

start_acpi_events () {
    trap '' 0 1 2
    p1=${PIPESDIR}/p1
    p2=${PIPESDIR}/p2
    $(mkfifo $p1)
    $(mkfifo $p2)
    acpi_listen >$p1 &
    echo $! >> $ETPIDFILE
    egrep --line-buffered '^(battery|ac_adapter)' >$p2 <$p1 &
    echo $! >> $ETPIDFILE
    while read f ; do 
        update_status || pass
    done <$p2
}

start_file_events () {
    while [ 1 ] ; do
        inotifywait -e open "$OUT" || pass
        update_status || pass
    done
}

start_acpi_events &
echo $! >> $ETPIDFILE

start_file_events &
echo $! >> $ETPIDFILE

killem () {
    echo "${0} KILLING..."
    while read pid ; do 
        if [ $pid ] ; then
            kill -9 $pid 2> /dev/null || echo "kill error $? for $pid" >&2
        fi
    done < $ETPIDFILE
    rm -rf $PIPESDIR || echo "Failed to clean up the pipes directory: $PIPESDIR"
    pkill -9 -P $MYPID 2> /dev/null || echo "pkill error $?" >&2
}

trap killem 0 1 2 3 15 19

update_status
while [ 1 ] ; do
    sleep 30
    update_status
done
