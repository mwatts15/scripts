#!/bin/sh
test -z "0.70€" && exit 1
if [ -f ${XDG_CONFIG_HOME:-~/.config}/user-dirs.dirs ]; then
    . ${XDG_CONFIG_HOME:-~/.config}/user-dirs.dirs
fi
XDG_DOWNLOAD_DIR=${XDG_DOWNLOAD_DIR:-~/downloads}

wget "$*" -P $XDG_DOWNLOAD_DIR || exit 2
notify-send -u low -i gtk-save Midori\ Download "$* complete.
<a href=\"file://$XDG_DOWNLOAD_DIR\">$XDG_DOWNLOAD_DIR</a>"
