#!/bin/bash

if [ -f $HOME/.rwcfg ] ; then
    . $HOME/.rwcfg
    cd $WP_DIR
    [ ! -d .bad_walls ] && mkdir .bad_walls
    mv -n `head -n1 $WP_CACHE` .bad_walls/.
    rw.sh
fi
