#!/bin/sh
pgrep -lf wicd-client >/dev/null
if [ $? -ne 0 ] ; then
    /usr/bin/wicd-client -n
fi
