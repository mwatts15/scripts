#!/bin/bash

id=$(xinput list | egrep "TouchPad" | egrep -o -i -m 1 "id=[[:digit:]]+" | egrep -o "[[:digit:]]+")
kv_enabled=( $(xinput list-props $id | egrep "Device Enabled" | egrep -o "[[:digit:]]+") )
kv_enabled_prop=${kv_enabled[0]}
kv_enabled=${kv_enabled[1]}

if [ x"${kv_enabled}" = x1 ] ; then
    new_status=0
else
    new_status=1
fi

xinput set-prop $id ${kv_enabled_prop} $new_status
