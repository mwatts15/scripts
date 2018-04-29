#!/bin/sh -e

OUT="/tmp/${USER}-battery-status-pipe"
MYPID=$$
PIPESDIR=$(mktemp -d)
ETPIDFILE=$(mktemp -p $PIPESDIR)

if [ ! -e $OUT -o ! -p $OUT  ] ; then
    rm -f $OUT
    mkfifo -m 0777 $OUT || echo "couldn't make the pipe!" >&2 && exit 1;
fi

thresh_time=1 # At most, one event per second from acpi_listen

_notify_15=0  # Status variable for whether we've notified about battery charge 15%

update_status () {
    charge_now=$(cat /sys/class/power_supply/BAT0/charge_now)
    charge_full=$(cat /sys/class/power_supply/BAT0/charge_full)
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
}

start_acpi_events () {
    trap '' 0 1 2
    p1=${PIPESDIR}/p1
    p2=${PIPESDIR}/p2
    $(mkfifo $p1)
    $(mkfifo $p2)
    acpi_listen >$p1 &
    echo $! > $ETPIDFILE
    egrep --line-buffered '^(battery|ac_adapter)' >$p2 <$p1 &
    echo $! >> $ETPIDFILE
    while read f ; do 
        update_status
    done <$p2
}

start_acpi_events &

killem () {
    while read pid ; do 
        if [ $pid ] ; then
            kill -9 $pid || echo "kill error $? for $pid" >&2
        fi
    done < $ETPIDFILE
    rm -rf $PIPESDIR || echo "Failed to clean up the pipes directory: $PIPESDIR"
    pkill -9 -P $MYPID || echo "pkill error $?" >&2
}

trap killem 0 1 2
update_status
while [ 1 ] ; do
    sleep 30
    update_status
done
