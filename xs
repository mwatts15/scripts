#!/bin/sh

# Xepher-start
# starts a program in a new Xephyr server
cmdline="$@"
PID=0
STAT=1
start_xephyr () {
    local disp
    disp=$1
    Xephyr -resizeable :${disp} &
    PID=$!
    sleep 1
    ps $PID 2>/dev/null >/dev/null
    STAT=$?
}

disp=0
while [ $STAT -ne 0 ] ; do
    disp=$((disp + 1))
    start_xephyr ${disp}
done

export DISPLAY=":${disp}"
echo $disp
DISPLAY=:${disp} $cmdline
