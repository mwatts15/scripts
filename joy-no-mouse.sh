#!/bin/zsh
id=$(xinput list | grep -e "WiseGroup.,Ltd TigerGame XBOX+PS2+GC Game Controller Adapter" |\
    grep -i pointer | grep -o -e "id=[[:digit:]]\+" | grep -o -e "[[:digit:]]\+")
kv_mouse=( $(xinput list-props $id | grep "Generate Mouse Events" | grep -o -e "[[:digit:]]\+") )
kv_key=( $(xinput list-props $id | grep "Generate Key Events" | grep -o -e "[[:digit:]]\+") )
xinput set-prop $id ${kv_mouse[1]} 0
xinput set-prop $id ${kv_key[1]} 0
