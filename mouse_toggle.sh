#!/bin/bash

id=$(xinput list | egrep ".*core.*pointer.*" | egrep -o -i -m 1 "id=[[:digit:]]+" | egrep -o "[[:digit:]]+")
kv_enabled=( $(xinput list-props $id | egrep "Device Enabled" | egrep -o "[[:digit:]]+") )

echo $id ${kv_enabled[2]}

if [ x"${kv_enabled[2]}" = x1 ] ; then
    new_status=0
else
    new_status=1
fi

echo xinput set-prop $id ${kv_enabled[1]} $new_status
xinput set-int-prop $id ${kv_enabled[1]} $new_status
